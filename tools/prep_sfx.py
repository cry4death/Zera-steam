"""A1: deterministic CC0 firearm preparation; Python 3 + numpy only.

Run from any directory. A2 can implement mechanics() using the shared helpers
and Builder.emit(); no change to shots() or synthesis() is required.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import wave

import numpy as np

RATE = 48000
SEED = 104729
DEFAULT_SRC = Path(r"C:\Users\Dev\Desktop\zera-assets\firearm_cc0\extracted\Prepared SFX Library")
DEFAULT_OUT = Path(__file__).resolve().parents[1] / "sfx"
# RMS of the first 100 ms, dBFS; deliberately retain transient headroom.
# Exact ascending energy, without clipping/compressing the recorded attacks.
SHOT_LEVELS = {"smg": -26, "pistol": -25, "revolver": -24,
               "rifle": -23, "shotgun": -22, "sniper": -21,
               # A3: модели из ящиков, по ощущению калибра (механика = выстрел - 12 дБ)
               "m4": -24, "shkval": -22, "guard": -26, "cowboy": -27,
               "osa": -27, "winchester": -22}
PEAK_LEVELS = {"brass_small": -21, "brass_rifle": -20, "shell": -22,
               "mag_drop": -19, "grenade": -3, "launcher": -5, "rail": -6,
               # A3: синтез Копья и Улья (пик, дБFS)
               "spear": -5, "hive": -6, "stick": -10}
SOURCES = {"pistol": ("1911/A_42P.wav", .65),
           "revolver": ("Smith & Wesson 642/V_27P.wav", .85),
           "smg": ("PPSh/P_30P.wav", .20),
           "rifle": ("AK-47/C_28P.wav", .24),
           "sniper": ("Mosin Nagant/M_21P.wav", 1.20),
           "shotgun": ("Nova/O_21P.wav", 1.05)}


# ---- Shared processing ----------------------------------------------------
def read_pcm(path: Path) -> tuple[np.ndarray, int]:
    """Read signed PCM, explicitly sign-extending little-endian 24-bit data."""
    with wave.open(str(path), "rb") as stream:
        width, rate, channels = stream.getsampwidth(), stream.getframerate(), stream.getnchannels()
        raw = stream.readframes(stream.getnframes())
    if width == 3:
        b = np.frombuffer(raw, np.uint8).reshape(-1, 3).astype(np.int32)
        v = b[:, 0] | (b[:, 1] << 8) | (b[:, 2] << 16)
        data = ((v ^ 0x800000) - 0x800000) / 8388608.0
    elif width == 2:
        data = np.frombuffer(raw, "<i2").astype(np.float64) / 32768.0
    else:
        raise ValueError(f"Unsupported PCM width {width}: {path}")
    return data.reshape(-1, channels), rate


def lowpass(data: np.ndarray, cutoff: float, rate: int = RATE, taps: int = 193) -> np.ndarray:
    """Linear-phase, unity-DC Blackman-windowed sinc FIR; compensated delay."""
    n = np.arange(taps) - (taps - 1) / 2
    kernel = 2 * cutoff / rate * np.sinc(2 * cutoff / rate * n) * np.blackman(taps)
    kernel /= kernel.sum()
    return np.column_stack([np.convolve(data[:, c], kernel, "same") for c in range(data.shape[1])])


def resample_48k(data: np.ndarray, rate: int) -> np.ndarray:
    if rate == RATE:
        return data.copy()
    if rate != 96000:
        raise ValueError(f"Expected 96 or 48 kHz, got {rate}")
    # Passband <20 kHz, transition centred on 21.5 kHz, before decimation.
    return lowpass(data, 21500, rate)[::2].copy()


def pitch(data: np.ndarray, ratio: float) -> np.ndarray:
    """Bandlimited interpolation, also used to slow the launcher source."""
    positions = np.arange(int(len(data) / ratio)) * ratio
    result = np.empty((len(positions), data.shape[1]))
    offsets = np.arange(-32, 33)
    cutoff = .46 / max(1.0, ratio)
    for start in range(0, len(positions), 4096):
        p = positions[start:start + 4096]
        indices = np.floor(p).astype(int)[:, None] + offsets
        delta = p[:, None] - indices
        weights = 2 * cutoff * np.sinc(2 * cutoff * delta)
        weights *= np.where(np.abs(delta) < 33, .5 + .5 * np.cos(np.pi * delta / 33), 0)
        weights /= weights.sum(axis=1, keepdims=True)
        samples = data[np.clip(indices, 0, len(data) - 1)]
        result[start:start + len(p)] = np.einsum("ij,ijk->ik", weights, samples)
    return result


def detect_attacks(data: np.ndarray, rate: int = RATE) -> list[int]:
    """Find loud shot groups, then refine to the leading edge (not the peak).

    0.5 ms bins and a 35 ms refractory interval separate even PPSh bursts.
    A 5% leading-edge threshold rejects outdoor noise and quiet pre-shot clicks.
    """
    hop = rate // 2000
    envelope = np.max(np.abs(data), axis=1)
    binned = envelope[:len(envelope) // hop * hop].reshape(-1, hop).max(axis=1)
    active = np.flatnonzero(binned > .18 * binned.max())
    groups = np.split(active, np.flatnonzero(np.diff(active) > .035 * rate / hop) + 1)
    attacks = []
    for group in groups:
        if not len(group):
            continue
        coarse = int(group[0] * hop)
        lo = max(0, coarse - int(.004 * rate))
        candidates = np.flatnonzero(envelope[lo:coarse + hop] > .05 * envelope.max())
        attacks.append(lo + int(candidates[0]) if len(candidates) else coarse)
    return attacks


def cut_shot(data: np.ndarray, attack: int, duration: float) -> tuple[np.ndarray, int, int]:
    start = max(0, attack - round(.0015 * RATE))
    end = min(len(data), start + round(duration * RATE))
    return data[start:end].copy(), start, end


def finish(data: np.ndarray, fade_out: float = .06) -> np.ndarray:
    data = np.asarray(data, dtype=np.float64).copy()
    if data.ndim == 1:
        data = data[:, None]
    fade_in_n = min(round(.00025 * RATE), len(data) // 4)
    fade_out_n = min(round(fade_out * RATE), len(data) // 3)
    data[:fade_in_n] *= np.sin(np.linspace(0, np.pi / 2, fade_in_n))[:, None] ** 2
    data[-fade_out_n:] *= np.cos(np.linspace(0, np.pi / 2, fade_out_n))[:, None] ** 2
    # Remove mean using an endpoint-zero correction; subtracting a constant
    # after fades would reintroduce a discontinuity at the file boundaries.
    window = np.sin(np.linspace(0, np.pi, len(data))) ** 2
    data -= window[:, None] * data.mean(axis=0) / window.mean()
    data[0] = data[-1] = 0
    return data


def normalize(data: np.ndarray, db: float, rms: bool = False) -> np.ndarray:
    current = np.sqrt(np.mean(data[:RATE // 10] ** 2)) if rms else np.max(np.abs(data))
    data = data * (10 ** (db / 20) / max(current, 1e-12))
    if np.max(np.abs(data)) > 10 ** (-1.01 / 20):
        raise ValueError("Target level would exceed -1 dBFS; revise target, do not clip")
    return data


def write_pcm(path: Path, data: np.ndarray) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    quantized = np.rint(data * 32768).astype("<i2")
    with wave.open(str(path), "wb") as stream:
        stream.setnchannels(data.shape[1])
        stream.setsampwidth(2)
        stream.setframerate(RATE)
        stream.writeframes(quantized.tobytes())


class Builder:
    def __init__(self, src: Path, out: Path):
        self.src, self.out = src, out
        self.entries: list[dict] = []
        self.source_info: dict = {}
        self.shot_audio: dict[str, list[np.ndarray]] = {}

    def emit(self, name: str, data: np.ndarray, source: str, **details) -> None:
        write_pcm(self.out / name, data)
        self.entries.append({"file": name, "source": source, **details})


# ---- Recorded shots -------------------------------------------------------
def shots(builder: Builder) -> None:
    for gun, (source, duration) in SOURCES.items():
        raw, rate = read_pcm(builder.src / source)
        if rate != 96000 or raw.shape[1] != 2:
            raise ValueError(f"Expected stereo 96 kHz source: {source}")
        audio = resample_48k(raw, rate)
        attacks = detect_attacks(audio)
        expected = {"pistol": 2, "revolver": 2, "smg": 5, "rifle": 4, "sniper": 4, "shotgun": 2}[gun]
        if len(attacks) != expected:
            raise ValueError(f"{source}: expected {expected} attacks, found {len(attacks)}")
        builder.source_info[source] = {
            "sha256": hashlib.sha256((builder.src / source).read_bytes()).hexdigest(),
            "attacks_seconds": [round(a / RATE, 6) for a in attacks],
            "source_samples_at_full_scale": int(np.sum(np.abs(raw) >= 1 - 1 / 8388608)),
        }
        builder.shot_audio[gun] = []
        count = max(4, len(attacks))
        for variant in range(count):
            take = variant % len(attacks)
            clip, start, end = cut_shot(audio, attacks[take], duration)
            ratio, tilt = 1.0, 0.0
            if variant >= len(attacks):
                ratio = (.982, 1.021)[variant % 2]
                tilt = (-.055, .055)[variant % 2]
                clip = pitch(clip, ratio)
                low = lowpass(clip, 1800)
                clip = low * (1 - tilt) + (clip - low) * (1 + tilt)
            # Preserve initial body; reduce diffuse tails for rapid overlap.
            if gun in ("smg", "rifle"):
                t = np.arange(len(clip)) / RATE
                clip *= np.exp(-np.maximum(t - .035, 0) / .065)[:, None]
            clip = normalize(finish(clip, .04 if gun in ("smg", "rifle") else .08), SHOT_LEVELS[gun], True)
            builder.emit(f"weapons/{gun}/shot_{variant}.wav", clip, source,
                         take=take + 1, attack_s=round(attacks[take] / RATE, 6),
                         crop_start_s=round(start / RATE, 6), crop_end_s=round(end / RATE, 6),
                         pitch_ratio=ratio, eq_tilt=tilt, rms100_target_db=SHOT_LEVELS[gun])
            builder.shot_audio[gun].append(clip)


# ---- Synthesis ------------------------------------------------------------
def noise(rng: np.random.Generator, n: int, cutoff: float) -> np.ndarray:
    return lowpass(rng.standard_normal((n, 1)), cutoff)[:, 0]


def casing(rng: np.random.Generator, kind: str) -> np.ndarray:
    t = np.arange(round(.70 * RATE)) / RATE
    audio = np.zeros(len(t))
    scale = rng.uniform(.94, 1.06)
    # Inharmonic cylinder modes, not harmonics of a musical oscillator.
    frequencies = {"brass_small": [3250, 4320, 5790, 7110, 8680],
                   "brass_rifle": [1890, 2710, 3860, 5130, 6790],
                   "shell": [420, 730, 1380, 2830, 4760],
                   "mag_drop": [190, 367, 821, 1460, 2690]}[kind]
    gap = rng.uniform(.14, .18)
    times = [0, gap, gap * 1.58]
    gains = [1, .48, .22]
    for bounce, (time, gain) in enumerate(zip(times, gains)):
        local = np.maximum(t - time, 0)
        onset = (t >= time) * (1 - np.exp(-local / .00022))
        hit = noise(rng, len(t), 11000) * np.exp(-local / .0025) * .19
        for j, frequency in enumerate(frequencies):
            decay = (.032 if kind in ("shell", "mag_drop") else .055) / (1 + j * .24)
            hit += (.52 / (1 + j * .32)) * np.sin(2 * np.pi * frequency * scale * local + rng.uniform(-.1, .1)) * np.exp(-local / decay)
        if kind in ("shell", "mag_drop"):
            hit += 1.2 * np.sin(2 * np.pi * (130 if kind == "mag_drop" else 240) * local) * np.exp(-local / .018)
        audio += gain * onset * hit
    # Irregular quiet grit/rolling at the end, with small surface contacts.
    roll_t = np.maximum(t - times[-1] - .035, 0)
    roll_env = (t > times[-1] + .035) * (1 - np.exp(-roll_t / .008)) * np.exp(-roll_t / .07)
    audio += .065 * noise(rng, len(t), 6500) * roll_env * (.6 + .4 * np.sin(2 * np.pi * 57 * t) ** 2)
    if kind == "mag_drop":
        for time in [.055, .082, .104]:
            local = np.maximum(t - time, 0)
            audio += .13 * (t > time) * noise(rng, len(t), 4200) * np.exp(-local / .009)
    return audio


def grenade(rng: np.random.Generator) -> np.ndarray:
    t = np.arange(round(1.75 * RATE)) / RATE
    attack = 1 - np.exp(-t / .0008)
    f = rng.uniform(49, 66)
    sub = 1.5 * np.sin(2 * np.pi * (f * t + 12 * .07 * (1 - np.exp(-t / .07)))) * np.exp(-t / .16)
    blast = noise(rng, len(t), 8500) * np.exp(-t / .070) * 1.7
    rumble = noise(rng, len(t), 420) * np.exp(-t / .32) * 2.1
    audio = attack * (sub + blast + rumble)
    for delay, gain in [(.047, .20), (.091, .13), (.157, .09)]:
        offset = round(delay * RATE)
        audio[offset:] += gain * audio[:len(audio) - offset].copy()
    for _ in range(19):
        start = round(rng.uniform(.22, 1.18) * RATE)
        n = round(rng.uniform(.008, .035) * RATE)
        local = np.arange(n) / RATE
        audio[start:start + n] += rng.uniform(.015, .045) * noise(rng, n, 8000) * np.sin(np.linspace(0, np.pi, n)) ** 2 * np.exp(-local / .012)
    return audio


def synthesis(builder: Builder) -> None:
    # Stable independent seeds: adding an A2 effect never changes A1 assets.
    for kind_id, kind in enumerate(("brass_small", "brass_rifle", "shell", "mag_drop")):
        for variant in range(6):
            rng = np.random.default_rng(SEED + kind_id * 100 + variant)
            clip = normalize(finish(casing(rng, kind)), PEAK_LEVELS[kind])
            builder.emit(f"casings/{kind}_{variant}.wav", clip, f"synthesis: {kind}, 5 inharmonic modes, 3 impacts + grit", seed=SEED + kind_id * 100 + variant)
    for variant in range(4):
        seed = SEED + 1000 + variant
        clip = normalize(finish(grenade(np.random.default_rng(seed)), .16), PEAK_LEVELS["grenade"])
        builder.emit(f"explosions/grenade_{variant}.wav", clip, "synthesis: 49-66 Hz sub, filtered blast, rumble, reflections, debris", seed=seed)
    for variant in range(3):
        base = builder.shot_audio["shotgun"][variant]
        clip = lowpass(pitch(base, .57 + variant * .015), 1700)[:round(.48 * RATE)]
        t = np.arange(len(clip)) / RATE
        clip *= np.exp(-t / .13)[:, None]
        clip += (.16 * np.sin(2 * np.pi * (83 * t + 3 * (1 - np.exp(-t / .025)))) * np.exp(-t / .055))[:, None]
        clip = normalize(finish(clip), PEAK_LEVELS["launcher"])
        builder.emit(f"weapons/launcher/shot_{variant}.wav", clip, f"weapons/shotgun/shot_{variant}.wav + synthesized thump", pitch_ratio=.57 + variant * .015)
        seed = SEED + 2000 + variant
        rng = np.random.default_rng(seed)
        t = np.arange(round(.34 * RATE)) / RATE
        crack = noise(rng, len(t), 18000) - noise(rng, len(t), 1400) * .2
        pulse = np.exp(-t / .018) + .26 * np.exp(-np.maximum(t - .027, 0) / .012) * (t > .027)
        whip = np.sin(2 * np.pi * (630 * t + 4100 * .018 * (1 - np.exp(-t / .018)))) * np.exp(-t / .043)
        mono = (1 - np.exp(-t / .0003)) * (.7 * crack * pulse + .35 * whip)
        stereo = np.column_stack((mono, mono * .94))
        stereo[round(.003 * RATE):, 1] += .10 * mono[:-round(.003 * RATE)]
        clip = normalize(finish(stereo, .055), PEAK_LEVELS["rail"])
        builder.emit(f"weapons/rail/shot_{variant}.wav", clip, "synthesis: broadband electrical crack + descending whip", seed=seed)


def highpass80(data: np.ndarray) -> np.ndarray:
    """ФВЧ Баттерворта второго порядка, 80 Гц, без резонансного горба."""
    k = np.tan(np.pi * 80 / RATE)
    norm = 1 / (1 + np.sqrt(2) * k + k * k)
    b0, b1, b2 = norm, -2 * norm, norm
    a1, a2 = 2 * (k * k - 1) * norm, (1 - np.sqrt(2) * k + k * k) * norm
    out = np.empty_like(data)
    z1 = np.zeros(data.shape[1])
    z2 = np.zeros(data.shape[1])
    for i, sample in enumerate(data):
        value = b0 * sample + z1
        z1 = b1 * sample - a1 * value + z2
        z2 = b2 * sample - a2 * value
        out[i] = value
    return out


def burst_tails(builder: Builder) -> None:
    """Отражения после одиночного near-выстрела, без атаки и второго выстрела."""
    for gun in ("rifle", "smg"):
        source = SOURCES[gun][0]
        raw, rate = read_pcm(builder.src / source)
        audio = resample_48k(raw, rate)
        attacks = detect_attacks(audio)
        for variant in range(3):
            # После 150 мс остаётся раскат стрельбища; между дублями > 3 секунд.
            start = attacks[variant] + round(.15 * RATE)
            end = start + round((1.05 + .08 * variant) * RATE)
            clip = audio[start:end].mean(axis=1, keepdims=True)
            clip = highpass80(lowpass(clip, 8500))
            t = np.arange(len(clip)) / RATE
            clip *= (1 - np.exp(-t / .035))[:, None] ** 2
            clip *= np.exp(-t / .6)[:, None]
            clip = normalize(finish(clip, .16), -20 if gun == "rifle" else -22)
            builder.emit(f"weapons/{gun}/tail_{variant}.wav", clip, source,
                         take=variant + 1, crop_start_s=round(start / RATE, 6),
                         crop_end_s=round(end / RATE, 6), pitch_ratio=1.0,
                         highpass_hz=80, fade_in_s=.035)


# ---- A2 extension point ----------------------------------------------------
def mechanics(builder: Builder) -> None:
    """A2: Raw tracks -> mag_out/in, rack, dry, cylinder, eject/load, shell_in.

    Use builder.emit() to retain A1 provenance and shared credit generation.
    Do not regenerate/replace A1 casings/mag_drop unless the task requests it.
    """
    import zipfile

    # Only the selected raw tracks are cached, inside this worktree.
    root = Path(__file__).resolve().parents[1]
    cache = root / "tmp"
    cache.mkdir(exist_ok=True)
    (cache / ".gdignore").write_text("", encoding="utf-8")
    archive = DEFAULT_SRC.parents[1] / "raw_master_tracks.zip"
    # Windows are reviewed takes, not individual peaks of a compound action.
    # Each take may contain several parts; Mosin gaps are shortened, not omitted.
    specs = {
        "pistol": ("1911", {
            "mag_out": ("A_3", [[(1.12, 1.45)]]),
            "mag_in": ("A_4", [[(.87, 1.01)], [(2.93, 3.08)]]),
            "rack": ("A_11", [[(.72, .86)], [(2.55, 2.70)]]),
            "dry": ("A_19", [[(.68, .77)]])}),
        "smg": ("PPSh", {
            "mag_out": ("P_7", [[(.14, .23)], [(.54, .66)]]),
            "mag_in": ("P_6", [[(.28, .63)], [(2.20, 2.63)]]),
            "rack": ("P_8", [[(.75, 1.10)], [(2.73, 3.04)]]),
            "dry": ("P_1", [[(.95, 1.05)], [(4.04, 4.14)]])}),
        "rifle": ("AK-47", {
            "mag_out": ("C_11", [[(.27, .38)]]),
            "mag_in": ("C_10", [[(.20, .39)]]),
            "rack": ("C_14", [[(.23, .66)], [(1.15, 1.61)]]),
            "dry": ("C_7", [[(.31, .41)]])}),
        "sniper": ("Mosin Nagant", {
            "rack": ("M_14", [
                [(.61, .74), (.87, 1.04), (1.13, 1.36), (1.47, 1.60)],
                [(3.09, 3.34), (3.42, 3.60), (3.69, 3.91), (4.07, 4.15)]]),
            "mag_in": ("M_1", [[(.93, 1.44)], [(3.15, 4.10)]]),
            "mag_out": ("M_8", [[(.60, .90)], [(3.71, 4.05)]]),
            "dry": ("M_10", [[(1.18, 1.29)]])}),
        "shotgun": ("Nova", {
            "rack": ("O_6", [[(.98, 1.49)]]),
            "shell_in": ("O_3", [[(1.28, 1.93)], [(6.88, 7.44)]]),
            "dry": ("O_8", [[(.23, .36)]])}),
        "revolver": ("Smith & Wesson 642", {
            "cyl_open": ("V_9", [[(1.23, 1.59)]]),
            "eject": ("V_3", [[(1.14, 1.25)]]),
            "load": ("V_18", [[(1.30, 1.51), (3.46, 3.60), (5.22, 5.39),
                                  (7.51, 7.63), (9.54, 9.74)]]),
            "cyl_close": ("V_10", [[(1.44, 1.63)]]),
            "dry": ("V_5", [[(1.52, 1.62)]])}),
    }
    with zipfile.ZipFile(archive) as master:
        for gun, (folder, events) in specs.items():
            for event, (track, takes) in events.items():
                source = f"Master Tracks/{folder}/{track}.wav"
                path = cache / source
                expected_hash = hashlib.sha256(master.read(source)).hexdigest()
                if not path.exists() or hashlib.sha256(path.read_bytes()).hexdigest() != expected_hash:
                    master.extract(source, cache)
                raw, rate = read_pcm(path)
                original_rate = rate
                mono = raw.mean(axis=1, keepdims=True)
                # Actual Raw masters are 192 kHz (Prepared A1 was 96 kHz).
                if rate == 192000:
                    mono = lowpass(mono, 43000, rate)[::2].copy()
                    rate = 96000
                audio = resample_48k(mono, rate)
                builder.source_info[source] = {"sha256": expected_hash, "rate": original_rate,
                                               "channels": raw.shape[1]}
                for variant in range(2):
                    take = variant % len(takes)
                    parts, cuts = [], []
                    for lo, hi in takes[take]:
                        start, end = round(lo * RATE), round(hi * RATE)
                        window = audio[start:end]
                        # Keep quiet internal mechanics; trim only the edges.
                        threshold = max(float(np.abs(window).max()) * .025, 1e-5)
                        active = np.flatnonzero(np.abs(window[:, 0]) > threshold)
                        if not len(active):
                            raise ValueError(f"No event: {source} {lo}-{hi}")
                        left = max(0, int(active[0]) - round(.002 * RATE))
                        right = min(len(window), int(active[-1]) + round(.016 * RATE) + 1)
                        parts.append(finish(window[left:right], .012))
                        cuts.append([round((start + left) / RATE, 6), round((start + right) / RATE, 6)])
                    gap = np.zeros((round((.05 if event == "load" else .008) * RATE), 1))
                    clip = np.concatenate([part for i, block in enumerate(parts)
                                           for part in ((gap, block) if i else (block,))])
                    ratio = 1.015 if len(takes) == 1 and variant else 1.0
                    limit = .6 if gun == "sniper" and event == "rack" else .5 if gun == "shotgun" and event == "rack" else None
                    if limit:
                        ratio = max(ratio, len(clip) / (RATE * (limit - .002)))
                    if ratio != 1.0:
                        clip = pitch(clip, ratio)
                    layer_seed = None
                    if event == "eject":
                        # V_3 records the extractor, without audible falling brass.
                        # Add five irregular brass contacts, reusing A1's synthesis
                        # function with independent seeds; never write A1 assets.
                        layer_seed = SEED + 3000 + variant * 10
                        scatter = np.zeros((round(.78 * RATE), 1))
                        scatter[:len(clip)] += clip
                        for i, delay in enumerate((.045, .081, .139, .202, .283)):
                            ring = casing(np.random.default_rng(layer_seed + i), "brass_small")[:round(.40 * RATE)]
                            ring *= (.70, .52, .63, .38, .32)[i] * np.abs(clip).max() / max(np.abs(ring).max(), 1e-12)
                            offset = round(delay * RATE)
                            scatter[offset:offset + len(ring), 0] += ring
                        clip = scatter
                    target = SHOT_LEVELS[gun] - 12
                    clip = finish(highpass80(clip), .018)
                    # Compound motions can start with quiet handling. Calibrate
                    # their loudest 100 ms to A1 shot RMS100 minus 12 dB.
                    power = np.pad(clip[:, 0] ** 2, (0, max(0, RATE // 10 - len(clip))))
                    energy = np.concatenate(([0.0], np.cumsum(power)))
                    loudest = np.sqrt(np.max(energy[RATE // 10:] - energy[:-RATE // 10]) / (RATE // 10))
                    first = np.sqrt(np.mean(clip[:RATE // 10] ** 2))
                    clip = normalize(clip, target + 20 * np.log10(first / loudest), True)
                    builder.emit(f"weapons/{gun}/{event}_{variant}.wav", clip, source,
                                 take=take + 1, crop_start_s=cuts[0][0], crop_end_s=cuts[-1][1],
                                 segments_s=cuts, pitch_ratio=ratio,
                                 rmsmax100_target_db=target, scatter_seed=layer_seed, highpass_hz=80)


# ---- A3: голоса моделей из ящиков -------------------------------------------
# gun -> (Prepared near-запись, число найденных атак, какие из них настоящие
#         выстрелы (остальное — эхо стрельбища), длина, спад (начало, tau) или None, fade)
MODEL_SHOTS = {
    "m4": ("AR-15/D_32P.wav", 2, [0, 1], .30, (.035, .065), .04),
    "shkval": ("Model 12/K_22P.wav", 2, [0, 1], .60, (.06, .13), .06),
    "guard": ("Walther PPQ/X_39P.wav", 3, [0, 1, 2], .50, None, .08),
    "cowboy": ("Ruger Single Six/S_14P.wav", 5, [0, 2], .30, (.035, .065), .04),
    "osa": ("Carl Gustav M45/G_31P.wav", 3, [0, 1, 2], .20, (.035, .065), .04),
    "winchester": ("Marlin 336/I_22P.wav", 2, [0, 1], .90, None, .08),
}
# gun -> (папка в Raw, {событие: [дубль = (дорожка, [окна (с, с)])]}). Дубль с несколькими
# окнами — составное движение (ход рычага/помпы, несколько гильз). Если дубль один,
# второй вариант получается небольшим изменением скорости.
MODEL_MECH = {
    "m4": ("AR-15", {
        "mag_out": [("D_5", [(1.20, 1.70)]), ("D_3", [(3.78, 4.04)])],
        "mag_in": [("D_4", [(.93, 1.40)]), ("D_2", [(8.03, 8.20)])],
        "rack": [("D_14", [(.50, .80)]), ("D_15", [(.30, .60)])],
        "dry": [("D_16", [(.36, .43)])]}),
    "shkval": ("Model 12", {
        # K_6 (full cycle loaded) в архиве почти пустая — берём K_2 (full cycle empty)
        "rack": [("K_2", [(.77, .90), (1.02, 1.18)]), ("K_2", [(3.81, 3.93), (4.04, 4.19)])],
        "shell_in": [("K_3", [(1.57, 1.97)]), ("K_3", [(7.35, 7.75)])],
        "dry": [("K_7", [(1.07, 1.16)]), ("K_7", [(3.44, 3.54)])]}),
    "guard": ("Walther PPQ", {
        "mag_out": [("X_5", [(1.33, 1.43)]), ("X_5", [(3.59, 3.69)])],
        "mag_in": [("X_4", [(.88, .98)]), ("X_4", [(3.01, 3.14)])],
        "rack": [("X_11", [(.75, .85)]), ("X_9", [(2.99, 3.06)])],
        "dry": [("X_19", [(.81, .88)]), ("X_19", [(2.90, 2.96)])]}),
    "cowboy": ("Ruger Single Six", {
        "cyl_open": [("S_0", [(.39, .45)]), ("S_10", [(1.30, 1.37)])],
        "cyl_close": [("S_1", [(.48, .54)])],
        "eject": [("S_3", [(3.31, 3.38), (14.19, 14.27), (17.80, 17.87)]),
                  ("S_3", [(12.59, 12.65), (23.32, 23.39), (8.42, 8.49)])],
        "load": [("S_2", [(1.55, 1.62), (4.54, 4.61), (7.35, 7.43)]),
                 ("S_2", [(9.97, 10.04), (11.48, 11.55), (13.00, 13.07)])],
        "hammer": [("S_6", [(4.08, 4.19)]), ("S_6", [(5.72, 5.82)])],
        "dry": [("S_8", [(.89, .96)]), ("S_8", [(2.70, 2.76)])]}),
    "osa": ("Carl Gustav M45:Swedish K", {
        "mag_out": [("G_9", [(1.19, 1.27)]), ("G_9", [(.44, .53)])],
        "mag_in": [("G_8", [(.50, .57)]), ("G_8", [(1.86, 1.93)])],
        "rack": [("G_2", [(.91, .97), (1.13, 1.20)]), ("G_2", [(4.92, 4.98), (5.15, 5.22)])],
        "dry": [("G_3", [(.70, .78)]), ("G_3", [(2.39, 2.47)])]}),
    "winchester": ("Marlin 336", {
        "rack": [("I_10", [(.84, 1.00), (1.11, 1.28)]), ("I_9", [(1.06, 1.20), (1.32, 1.48)])],
        "shell_in": [("I_0", [(3.50, 3.72)]), ("I_0", [(8.08, 8.28)])],
        "dry": [("I_8", [(.91, .98)])]}),
}
MODEL_RACK_LIMIT = {"shkval": .40, "winchester": .45}   # ход помпы / рычага, с
MODEL_GAP = {"rack": .03, "eject": .07, "load": .07}      # пауза между окнами дубля, с


def model_shots(builder: Builder) -> None:
    for gun, (source, found, use, duration, decay, fade) in MODEL_SHOTS.items():
        raw, rate = read_pcm(builder.src / source)
        if rate != 96000 or raw.shape[1] != 2:
            raise ValueError(f"Expected stereo 96 kHz source: {source}")
        audio = resample_48k(raw, rate)
        attacks = detect_attacks(audio)
        if len(attacks) != found:
            raise ValueError(f"{source}: expected {found} attacks, found {len(attacks)}")
        builder.source_info[source] = {
            "sha256": hashlib.sha256((builder.src / source).read_bytes()).hexdigest(),
            "attacks_seconds": [round(a / RATE, 6) for a in attacks],
            "used_attacks": use,
            "source_samples_at_full_scale": int(np.sum(np.abs(raw) >= 1 - 1 / 8388608)),
        }
        for variant in range(4):
            take = use[variant % len(use)]
            clip, start, end = cut_shot(audio, attacks[take], duration)
            ratio, tilt = 1.0, 0.0
            if variant >= len(use):
                ratio = (.982, 1.021)[variant % 2]
                tilt = (-.055, .055)[variant % 2]
                clip = pitch(clip, ratio)
                low = lowpass(clip, 1800)
                clip = low * (1 - tilt) + (clip - low) * (1 + tilt)
            if decay:
                t = np.arange(len(clip)) / RATE
                clip *= np.exp(-np.maximum(t - decay[0], 0) / decay[1])[:, None]
            clip = normalize(finish(clip, fade), SHOT_LEVELS[gun], True)
            builder.emit(f"weapons/{gun}/shot_{variant}.wav", clip, source,
                         take=take + 1, attack_s=round(attacks[take] / RATE, 6),
                         crop_start_s=round(start / RATE, 6), crop_end_s=round(end / RATE, 6),
                         pitch_ratio=ratio, eq_tilt=tilt, rms100_target_db=SHOT_LEVELS[gun])


def model_mechanics(builder: Builder) -> None:
    import zipfile

    root = Path(__file__).resolve().parents[1]
    cache = root / "tmp"
    cache.mkdir(exist_ok=True)
    (cache / ".gdignore").write_text("", encoding="utf-8")
    archive = DEFAULT_SRC.parents[1] / "raw_master_tracks.zip"
    with zipfile.ZipFile(archive) as master:
        for gun, (folder, events) in MODEL_MECH.items():
            for event, takes in events.items():
                for variant in range(2):
                    take = variant % len(takes)
                    track, windows = takes[take]
                    source = f"Master Tracks/{folder}/{track}.wav"
                    # «:» в имени папки архива недопустим в пути Windows
                    path = cache / source.replace(":", "_")
                    data = master.read(source)
                    expected_hash = hashlib.sha256(data).hexdigest()
                    if not path.exists() or hashlib.sha256(path.read_bytes()).hexdigest() != expected_hash:
                        path.parent.mkdir(parents=True, exist_ok=True)
                        path.write_bytes(data)
                    raw, rate = read_pcm(path)
                    original_rate = rate
                    mono = raw.mean(axis=1, keepdims=True)
                    if rate == 192000:
                        mono = lowpass(mono, 43000, rate)[::2].copy()
                        rate = 96000
                    audio = resample_48k(mono, rate)
                    builder.source_info[source] = {"sha256": expected_hash, "rate": original_rate,
                                                   "channels": raw.shape[1]}
                    parts, cuts = [], []
                    for lo, hi in windows:
                        start, end = round(lo * RATE), round(hi * RATE)
                        window = audio[start:end]
                        threshold = max(float(np.abs(window).max()) * .025, 1e-5)
                        active = np.flatnonzero(np.abs(window[:, 0]) > threshold)
                        if not len(active):
                            raise ValueError(f"No event: {source} {lo}-{hi}")
                        left = max(0, int(active[0]) - round(.002 * RATE))
                        right = min(len(window), int(active[-1]) + round(.016 * RATE) + 1)
                        parts.append(finish(window[left:right], .012))
                        cuts.append([round((start + left) / RATE, 6), round((start + right) / RATE, 6)])
                    gap = np.zeros((round(MODEL_GAP.get(event, .008) * RATE), 1))
                    clip = np.concatenate([part for i, block in enumerate(parts)
                                           for part in ((gap, block) if i else (block,))])
                    ratio = 1.03 if len(takes) == 1 and variant else 1.0
                    limit = MODEL_RACK_LIMIT.get(gun) if event == "rack" else None
                    if limit:
                        ratio = max(ratio, len(clip) / (RATE * (limit - .002)))
                    if ratio != 1.0:
                        clip = pitch(clip, ratio)
                    target = SHOT_LEVELS[gun] - 12
                    clip = finish(highpass80(clip), .018)
                    # Как в A2: громчайшие 100 мс = RMS выстрела - 12 дБ.
                    power = np.pad(clip[:, 0] ** 2, (0, max(0, RATE // 10 - len(clip))))
                    energy = np.concatenate(([0.0], np.cumsum(power)))
                    loudest = np.sqrt(np.max(energy[RATE // 10:] - energy[:-RATE // 10]) / (RATE // 10))
                    first = np.sqrt(np.mean(clip[:RATE // 10] ** 2))
                    clip = normalize(clip, target + 20 * np.log10(first / loudest), True)
                    builder.emit(f"weapons/{gun}/{event}_{variant}.wav", clip, source,
                                 take=take + 1, crop_start_s=cuts[0][0], crop_end_s=cuts[-1][1],
                                 segments_s=cuts, pitch_ratio=ratio,
                                 rmsmax100_target_db=target, scatter_seed=None, highpass_hz=80)


def rail_voice(seed: int) -> np.ndarray:
    """Голос рельсы A1 (трескучий хруст + падающий свист), стерео, до нормализации."""
    rng = np.random.default_rng(seed)
    t = np.arange(round(.34 * RATE)) / RATE
    crack = noise(rng, len(t), 18000) - noise(rng, len(t), 1400) * .2
    pulse = np.exp(-t / .018) + .26 * np.exp(-np.maximum(t - .027, 0) / .012) * (t > .027)
    whip = np.sin(2 * np.pi * (630 * t + 4100 * .018 * (1 - np.exp(-t / .018)))) * np.exp(-t / .043)
    mono = (1 - np.exp(-t / .0003)) * (.7 * crack * pulse + .35 * whip)
    stereo = np.column_stack((mono, mono * .94))
    stereo[round(.003 * RATE):, 1] += .10 * mono[:-round(.003 * RATE)]
    return stereo


def bubble(rng: np.random.Generator, n: int, start: float, f0: float, f1: float,
           length: float, gain: float) -> np.ndarray:
    """Мокрый «пузырь»: короткий восходящий тон с шумовой кромкой."""
    out = np.zeros(n)
    m = round(length * RATE)
    local = np.arange(m) / RATE
    phase = 2 * np.pi * (f0 * local + (f1 - f0) * length / 2 * (local / length) ** 2)
    env = np.sin(np.pi * np.minimum(local / length, 1)) ** 1.5 * np.exp(-local / (length * .6))
    pop = np.sin(phase) * env + .35 * noise(rng, m, 2600) * env
    offset = round(start * RATE)
    size = max(0, min(m, n - offset))
    out[offset:offset + size] = gain * pop[:size]
    return out


def model_synthesis(builder: Builder) -> None:
    # «Копьё»: рельса A1, ниже и тяжелее, длиннее хвост, плюс низкий удар.
    ratios = (.80, .78, .82, .79)
    for variant in range(4):
        seed = SEED + 2000 + variant
        base = rail_voice(seed)
        base /= np.abs(base).max()
        clip = pitch(base, ratios[variant])
        clip = lowpass(clip, 9500) * .85 + lowpass(clip, 1500) * .45
        n = round(.80 * RATE)
        out = np.zeros((n, 2))
        out[:len(clip)] += clip
        low = lowpass(clip, 2500)
        for delay, gain in [(.085, .34), (.17, .21), (.29, .13)]:
            offset = round(delay * RATE)
            size = min(len(low), n - offset)
            out[offset:offset + size] += gain * low[:size]
        rng = np.random.default_rng(SEED + 4000 + variant)
        t = np.arange(n) / RATE
        rumble = noise(rng, n, 700) * np.exp(-t / .20) * 1.4 * (1 - np.exp(-t / .004))
        thump = np.sin(2 * np.pi * (46 * t + 52 * .05 * (1 - np.exp(-t / .05)))) * np.exp(-t / .10) * .6
        out += (rumble + thump)[:, None] * np.array([1.0, .96])
        out = normalize(finish(out, .20), PEAK_LEVELS["spear"])
        builder.emit(f"weapons/spear/shot_{variant}.wav", out,
                     f"synthesis: rail A1 voice (seed {seed}) pitch x{ratios[variant]}, reflections, 46 Hz thump + rumble",
                     seed=SEED + 4000 + variant, pitch_ratio=ratios[variant])
    # «Улей»: хлопок «Грома» A1 (из дробовика) + мокрый «чпок»; отдельно шлепок прилипания.
    for variant in range(4):
        base = builder.shot_audio["shotgun"][variant]
        ratio = .60 + variant * .012
        clip = lowpass(pitch(base, ratio), 2300)[:round(.52 * RATE)]
        t = np.arange(len(clip)) / RATE
        clip *= np.exp(-t / .12)[:, None]
        clip += (.16 * np.sin(2 * np.pi * (76 * t + 3 * (1 - np.exp(-t / .025)))) * np.exp(-t / .055))[:, None]
        peak = np.abs(clip).max()
        seed = SEED + 6000 + variant
        rng = np.random.default_rng(seed)
        wet = (bubble(rng, len(t), .014, 260, 760, .042, .85) + bubble(rng, len(t), .071, 190, 520, .05, .5)
               + bubble(rng, len(t), .128, 330, 900, .028, .28)) * peak
        clip += wet[:, None] * np.array([1.0, .93])
        clip = normalize(finish(clip), PEAK_LEVELS["hive"])
        builder.emit(f"weapons/hive/shot_{variant}.wav", clip,
                     f"weapons/shotgun/shot_{variant}.wav pitch x{ratio:.3f} (launcher recipe) + synthesized wet pops",
                     seed=seed, pitch_ratio=ratio)
        seed = SEED + 5000 + variant
        rng = np.random.default_rng(seed)
        n = round(.24 * RATE)
        t = np.arange(n) / RATE
        onset = 1 - np.exp(-t / .0003)
        slap = noise(rng, n, 3200) * np.exp(-t / .011) * .9
        thud = np.sin(2 * np.pi * (170 * t - 600 * t ** 2)) * np.exp(-t / .028) * .7
        wobble = .55 + .45 * np.sin(2 * np.pi * rng.uniform(32, 44) * t + rng.uniform(0, 6)) ** 2
        squelch = noise(rng, n, 1900) * np.exp(-t / .075) * wobble * .30
        pops = (bubble(rng, n, rng.uniform(.028, .036), 280, 880, .026, .55)
                + bubble(rng, n, rng.uniform(.066, .078), 210, 640, .034, .42)
                + bubble(rng, n, rng.uniform(.112, .125), 340, 950, .022, .26))
        stick = normalize(finish(onset * (slap + thud + squelch) + pops, .06), PEAK_LEVELS["stick"])
        builder.emit(f"weapons/hive/stick_{variant}.wav", stick,
                     "synthesis: wet slap, 170 Hz thud, squelch, three rising bubble pops", seed=seed)


def models(builder: Builder) -> None:
    """A3: голоса моделей из ящиков — выстрелы, механика, синтез Копья и Улья."""
    model_shots(builder)
    model_mechanics(builder)
    model_synthesis(builder)


def metadata(builder: Builder) -> None:
    manifest = {"format": "PCM16 48000 Hz; shots stereo, other effects mono", "seed": SEED,
                "source_files": builder.source_info, "files": builder.entries}
    (builder.out / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    lines = ["# Sound credits / CC0", "", "Recorded sources: The Free Firearm Sound Library / Still North Media.",
             "Authors: Ben Jaszczak, Brian Nelson, Kevin Heras, Matthew Nanney.",
             "Source and license: [OpenGameArt — The Free Firearm Sound Library](https://opengameart.org/content/the-free-firearm-sound-library), CC0 1.0.",
             "All A1 procedural synthesis and edits are also dedicated to CC0 1.0.", "",
             "Shots/tails: Prepared near recordings; mechanics: Raw master tracks. Originals remain outside this repository.",
             "Times refer to the original file; FIR delay is compensated. Exact edits/seeds and source SHA256 are in manifest.json.", "",
             "A3: model voices (m4, shkval, guard, cowboy, osa, winchester) use Prepared near shots and Raw mechanics from the same library; spear and hive are synthesized from A1 voices. Edits are CC0 1.0.", "",
             "W2: all mechanics use a second-order Butterworth high-pass at 80 Hz. Burst tails use attack-free near reflections, 35 ms smooth entry, 160 ms fade out; A1 files unchanged.", "",
             "| Output file | Source / synthesis | Take; original crop; pitch |", "|---|---|---|"]
    for e in builder.entries:
        edit = f"take {e['take']}; {e['crop_start_s']:.6f}–{e['crop_end_s']:.6f} s; ×{e['pitch_ratio']}" if "take" in e else f"seed {e['seed']}" if "seed" in e else f"×{e['pitch_ratio']}"
        lines.append(f"| `{e['file']}` | {e['source']} | {edit} |")
    (builder.out / "CREDITS.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--src", type=Path, default=DEFAULT_SRC)
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT)
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    builder = Builder(args.src, args.out)
    shots(builder)
    synthesis(builder)
    mechanics(builder)
    burst_tails(builder)
    models(builder)
    metadata(builder)
    size = sum((args.out / e["file"]).stat().st_size for e in builder.entries)
    print(f"Generated {len(builder.entries)} WAV files: PCM16, 48000 Hz; {size} bytes")
    print("Recorded shots: pistol=4 revolver=4 smg=5 rifle=4 sniper=4 shotgun=4; launcher=3 rail=3")
    print("Synthesis: brass_small=6 brass_rifle=6 shell=6 mag_drop=6 grenade=4")
    print("Peak guard: <= -1.01 dBFS; source hashes and exact cuts: manifest.json")


if __name__ == "__main__":
    main()
