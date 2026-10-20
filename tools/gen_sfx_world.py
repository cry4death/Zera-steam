"""Звуки мира (Z2): сигнализация машины. Синтез, без внешних записей; детерминированно.

Запуск: python tools/gen_sfx_world.py  → sfx/world/car_alarm_0.wav, car_alarm_1.wav
Потом Godot --import. Формат как у остальных звуков мира: 48 кГц, 16 бит, моно.
"""
from pathlib import Path
import wave

import numpy as np

RATE = 48000
OUT = Path(__file__).resolve().parent.parent / "sfx" / "world"


def one_pole(x: np.ndarray, cutoff: float) -> np.ndarray:
    a = np.exp(-2.0 * np.pi * cutoff / RATE)
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1.0 - a) * v + a * acc
        y[i] = acc
    return y


def siren(seed: int, low: float, high: float, step: float) -> np.ndarray:
    """Один «гудок» сигнализации ~1 с: два тона чередуются, жёсткий динамик-пищалка."""
    rng = np.random.default_rng(seed)
    n = RATE
    t = np.arange(n) / RATE
    # тон переключается каждые step секунд, с коротким скольжением между тонами
    phase_sel = (np.floor(t / step) % 2).astype(float)
    smooth = one_pole(phase_sel, 60.0)
    freq = low + (high - low) * smooth
    freq *= 1.0 + 0.004 * np.sin(2 * np.pi * 5.5 * t)
    ph = 2 * np.pi * np.cumsum(freq) / RATE
    # почти меандр: нечётные гармоники — «пищалка», мягкий клиппинг — дешёвый динамик
    wave_ = np.tanh(3.2 * np.sin(ph)) + 0.18 * np.sin(3 * ph)
    wave_ += 0.01 * rng.standard_normal(n)
    body = one_pole(wave_, 3800.0) - one_pole(wave_, 450.0)  # полоса динамика
    env = np.minimum(1.0, t / 0.008) * np.minimum(1.0, (1.0 - t) / 0.06)
    out = body * env
    out /= np.max(np.abs(out)) + 1e-9
    return out * 10 ** (-6.0 / 20.0)


def write(path: Path, data: np.ndarray) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    pcm = np.clip(np.round(data * 32767.0), -32768, 32767).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(pcm.tobytes())


def main() -> None:
    write(OUT / "car_alarm_0.wav", siren(7101, 760.0, 1020.0, 0.125))
    write(OUT / "car_alarm_1.wav", siren(7102, 690.0, 960.0, 0.16))
    print("world: car_alarm_0..1")


if __name__ == "__main__":
    main()
