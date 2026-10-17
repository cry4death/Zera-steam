"""Грубая симуляция MVP-забега: спавн, убийства, опыт, уровни, кредиты.

Не симулирует бой — считает, что игрок убивает примерно всё, что заспавнилось
(с поправкой KILL_EFF). Нужна, чтобы быстро проверить кривые из BALANCE.md.
Запуск: python tools/balance_sim.py
"""

STEP = 5  # секунд на шаг симуляции

# (начало_сек, спавн/сек, лимит живых, доли: шарк, бегун, толстяк, плевальщик)
SPAWN = [
    (0,   1.5, 60,  (1.00, 0.00, 0.00, 0.00)),
    (60,  3.0, 100, (1.00, 0.00, 0.00, 0.00)),
    (120, 4.0, 150, (0.80, 0.20, 0.00, 0.00)),
    (210, 5.0, 200, (0.70, 0.20, 0.10, 0.00)),
    (240, 6.0, 250, (0.70, 0.20, 0.10, 0.00)),
    (300, 7.0, 300, (0.60, 0.20, 0.10, 0.10)),
    (360, 8.0, 350, (0.60, 0.20, 0.10, 0.10)),
    (420, 24.0, 500, (0.50, 0.35, 0.10, 0.05)),  # Кровавая тревога
    (450, 9.0, 400, (0.55, 0.25, 0.10, 0.10)),
    (480, 11.0, 500, (0.55, 0.25, 0.10, 0.10)),
    (540, 3.0, 100, (0.70, 0.30, 0.00, 0.00)),   # затишье + торговец
    (570, 4.0, 150, (0.70, 0.30, 0.00, 0.00)),   # предупреждение
    (600, 4.0, 150, (0.70, 0.30, 0.00, 0.00)),   # босс + фоновая орда
]
RUN_END = 675  # 10:00 + ~75 с на босса

ALARM = (420, 450)
ALARM_REWARD_MULT = 2.0
KILL_EFF = 0.95        # доля заспавненных, которых игрок успевает убить
KILL_EFF_ALARM = 0.60  # в тревогу многое не успеваешь
PICKUP_EFF = 0.85      # доля подобранного опыта

#            HP   XP  шанс_кредита кредиты
ENEMIES = [(10,   1,  0.06,        1),   # шаркающий
           (6,    1,  0.06,        1),   # бегун
           (60,   4,  0.40,        2),   # толстяк
           (15,   2,  0.20,        2)]   # плевальщик
HP_PER_MIN = 0.12

ELITE_EVERY = 30       # сек, начиная с 5:00
ELITE_START = 300
ELITE_XP = 25          # элитка = ×5 HP, ×5 опыта от «среднего» врага
ELITE_CREDITS = 10
ALARM_ELITES = 4


# --- Оружие (серийные модели). Урон, выстр/с, магазин, перезарядка, снарядов за выстрел, крит
#     L1 — как выдаётся, L5 — после 4 апгрейдов в забеге (см. BALANCE.md §3)
WEAPONS = {
    "Автомат АК-С":     {"L1": (7, 6.0, 30, 1.5, 1, 0.05),  "L5": (13, 6.9, 45, 1.05, 2, 0.05)},
    "Дробовик Мясник":  {"L1": (5, 1.1, 6, 2.2, 6, 0.05),   "L5": (7, 1.1, 8, 1.76, 11, 0.05)},
    "Рейлган Игла":     {"L1": (30, 0.7, 4, 2.5, 1, 0.15),  "L5": (70, 0.84, 6, 2.5, 1, 0.30)},
    "Гранатомёт Гром":  {"L1": (22, 0.8, 4, 2.8, 1, 0.05),  "L5": (42, 0.8, 4, 1.96, 2, 0.05)},
    "Автомат Оса":      {"L1": (4, 11.0, 50, 1.8, 1, 0.05)},
    "Дробовик Шквал":   {"L1": (4, 2.2, 10, 2.6, 5, 0.05)},
    "Рейлган Копьё":    {"L1": (60, 0.4, 3, 2.5, 1, 0.15)},
    "Гранатомёт Улей":  {"L1": (10, 0.9, 6, 3.0, 3, 0.05)},
}
CRIT_MULT = 2.0
# доля снарядов, попадающих в одну крупную цель (босса)
BOSS_HIT_SHARE = {"Автомат АК-С": 1.0, "Дробовик Мясник": 0.6, "Рейлган Игла": 1.0, "Гранатомёт Гром": 1.0}

BOSS_HP = 24000
BOSS_ARMOR_P1 = 0.25     # фаза 1: −25% входящего урона
BOSS_UPTIME = 0.6        # доля времени, когда оружие реально бьёт босса (уворот, тараны)
PASSIVES_MULT = 1.45     # ~+25% урона и ~+16% скорострельности к концу забега
MODULES_MULT = 1.3
META_MULT_FULL = 1.35    # дерево класса + мастерская на максимуме

UPGRADE_COST = [20, 40, 70, 110, 160]  # ДНК за уровень стата в мастерской


def eff_dps(dmg, rate, mag, reload, proj, crit):
    """Средний DPS по одной цели с учётом перезарядки и критов."""
    fire_time = mag / rate
    uptime = fire_time / (fire_time + reload)
    return dmg * proj * rate * uptime * (1 + crit * (CRIT_MULT - 1)), uptime


def dna(minutes, kills, elites, win):
    base = minutes * 10 + kills / 50 + elites * 5
    return base * (1.5 if win else 1.0)


def class_level_dna(n):
    return round(80 * (n - 1) ** 1.5)


def xp_to_next(level):
    return round(6 * level ** 1.3)


def phase_at(t):
    cur = SPAWN[0]
    for p in SPAWN:
        if t >= p[0]:
            cur = p
    return cur


def main():
    level, xp, credits, kills, elites = 1, 0.0, 0.0, 0.0, 0
    report = {}
    for t in range(0, RUN_END, STEP):
        _, rate, _, mix = phase_at(t)
        in_alarm = ALARM[0] <= t < ALARM[1]
        eff = KILL_EFF_ALARM if in_alarm else KILL_EFF
        mult = ALARM_REWARD_MULT if in_alarm else 1.0
        k = rate * STEP * eff
        kills += k
        for share, (hp, exp, cchance, cval) in zip(mix, ENEMIES):
            xp += k * share * exp * PICKUP_EFF * mult
            credits += k * share * cchance * cval * mult
        if t >= ELITE_START and t % ELITE_EVERY == 0 and t < 600:
            elites += 1
            xp += ELITE_XP
            credits += ELITE_CREDITS
        if t == ALARM[0]:
            elites += ALARM_ELITES
            xp += ELITE_XP * ALARM_ELITES
            credits += ELITE_CREDITS * ALARM_ELITES
        while xp >= xp_to_next(level):
            xp -= xp_to_next(level)
            level += 1
        if (t + STEP) % 60 == 0 or t + STEP == ALARM[1] or t + STEP == RUN_END:
            report[t + STEP] = (level, int(kills), int(credits), elites)

    print("XP до следующего уровня:")
    print("  ", ", ".join(f"L{l}:{xp_to_next(l)}" for l in (1, 2, 3, 5, 10, 15, 20, 25, 30)))
    print("\nВремя   Уровень  Убийства  Кредиты(накоплено)  Элитки")
    for t, (lv, kl, cr, el) in report.items():
        print(f"{t // 60:>2}:{t % 60:02d}   {lv:>5}    {kl:>6}    {cr:>8}            {el:>3}")

    print("\nHP врагов по минутам (множитель 1 + 0.12·мин):")
    names = ["Шарк", "Бегун", "Толстяк", "Плевальщик"]
    for m in (0, 3, 5, 7, 9, 10):
        mult = 1 + HP_PER_MIN * m
        row = "  ".join(f"{n}:{round(e[0] * mult)}" for n, e in zip(names, ENEMIES))
        print(f"  {m:>2} мин ×{mult:.2f}: {row}")

    print("\nТребуемая пропускная способность (урон/с, чтобы не копилась орда):")
    for t in (60, 180, 300, 420, 480, 540):
        _, rate, _, mix = phase_at(t)
        mult = 1 + HP_PER_MIN * t / 60
        avg_hp = sum(s * e[0] for s, e in zip(mix, ENEMIES)) * mult
        print(f"  {t // 60}:{t % 60:02d}  спавн {rate:>4}/с × ср.HP {avg_hp:5.1f} = {rate * avg_hp:6.0f} урона/с")


    print("\nОружие: эффективный DPS по одной цели (с перезарядкой и критами):")
    print("  Модель              Ур.  DPS   % времени стреляет")
    for name, lv in WEAPONS.items():
        for key, st in lv.items():
            d, up = eff_dps(*st)
            print(f"  {name:<19} {key}  {d:5.1f}   {up * 100:4.0f}%")

    l5 = sum(eff_dps(*WEAPONS[n]["L5"])[0] * share for n, share in BOSS_HIT_SHARE.items())
    print(f"\nБосс «Объект-7» ({BOSS_HP} HP). Сумма L5-оружия по боссу: {l5:.0f} DPS")
    for label, meta in (("без меты", 1.0), ("мета на максимуме", META_MULT_FULL)):
        dps = l5 * PASSIVES_MULT * MODULES_MULT * meta * BOSS_UPTIME
        t = (BOSS_HP / 2) / (dps * (1 - BOSS_ARMOR_P1)) + (BOSS_HP / 2) / dps
        print(f"  {label:<18} эфф. DPS {dps:5.0f} → бой ≈ {t:4.0f} с")

    print("\nДНК за забег:")
    print(f"  смерть на 5:00        ≈ {dna(5, 1083, 0, False):4.0f}")
    print(f"  смерть на 8:00        ≈ {dna(8, 2626, 10, False):4.0f}")
    print(f"  победа (~11 мин)      ≈ {dna(11, 3700, 14, True):4.0f}")
    print("\nУровень класса (накопленная ДНК):",
          ", ".join(f"L{n}:{class_level_dna(n)}" for n in (2, 3, 4, 5, 6, 8, 10)))
    per_stat = sum(UPGRADE_COST)
    print(f"Мастерская: один стат до max = {per_stat} ДНК, ствол (4 стата) = {per_stat * 4},"
          f" все 8 стволов = {per_stat * 4 * 8}")


if __name__ == "__main__":
    main()
