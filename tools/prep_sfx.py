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


# ---- A4: орда, gore, игрок, интерфейс -----------------------------------------
# Источники голосов — два CC0-пака (см. CREDITS.md). Gore и игрок — синтез.
# Все случайные числа — от независимых seed A4_SEED + <группа>*1000 + <вариант>, поэтому
# сборка детерминирована, а добавление звука не меняет остальные.
DEFAULT_ZSRC = Path(r"C:\Users\Dev\Desktop\zera-assets\zombies_cc0\extracted")
A4_SEED = SEED + 30000
# Пики, дБFS. Голоса и гул тише gore: gore звучит на каждом попадании, голосов много.
HORDE_PEAKS = {"groan": -14, "attack": -9, "death": -9, "runner": -10, "fat": -10, "spit": -11,
               "boss_roar": -3, "hit": -12, "splat": -8, "gib": -5, "bone": -9,
               "hurt": -6, "heartbeat": -9, "click": -17, "confirm": -14, "deny": -16}
HORDE_RMS = {"horde_0": -34.0, "horde_1": -26.0}   # RMS всего лупа, дБFS


def _monster(i: int) -> str:
    return f"monsters/Monster-Sounds-Volume-2/{'Monster' if i <= 8 else 'monster'}-{i}.wav"


def _zombie(i: int) -> str:
    return f"zombies/zombie-{i}.wav"


def biquad(x: np.ndarray, kind: str, f: float, q: float = .70710678, gain_db: float = 0.0) -> np.ndarray:
    """БИХ-фильтр RBJ (lowpass/highpass/bandpass/peaking), моно. bandpass — усиление 0 дБ в пике."""
    w, a_gain = 2 * np.pi * f / RATE, 10 ** (gain_db / 40)
    c, alpha = np.cos(w), np.sin(w) / (2 * q)
    if kind == "lowpass":
        b0, b1, b2, a0, a1, a2 = (1 - c) / 2, 1 - c, (1 - c) / 2, 1 + alpha, -2 * c, 1 - alpha
    elif kind == "highpass":
        b0, b1, b2, a0, a1, a2 = (1 + c) / 2, -(1 + c), (1 + c) / 2, 1 + alpha, -2 * c, 1 - alpha
    elif kind == "bandpass":
        b0, b1, b2, a0, a1, a2 = alpha, 0.0, -alpha, 1 + alpha, -2 * c, 1 - alpha
    else:
        b0, b1, b2 = 1 + alpha * a_gain, -2 * c, 1 - alpha * a_gain
        a0, a1, a2 = 1 + alpha / a_gain, -2 * c, 1 - alpha / a_gain
    b0, b1, b2, a1, a2 = b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0
    out = [0.0] * len(x)
    z1 = z2 = 0.0
    for i, s in enumerate(x.tolist()):
        y = b0 * s + z1
        z1 = b1 * s - a1 * y + z2
        z2 = b2 * s - a2 * y
        out[i] = y
    return np.array(out)


def svf(x: np.ndarray, fc: np.ndarray, q: float, mode: str) -> np.ndarray:
    """Фильтр с переменной частотой (TPT state-variable): мокрые «ползущие» полосы."""
    g = np.tan(np.pi * np.minimum(fc, RATE * .42) / RATE)
    k = 1 / q
    a1 = 1 / (1 + g * (g + k))
    a2, a3 = g * a1, g * g * a1
    ic1 = ic2 = 0.0
    out = [0.0] * len(x)
    for i, (s, b1, b2, b3) in enumerate(zip(x.tolist(), a1.tolist(), a2.tolist(), a3.tolist())):
        v3 = s - ic2
        v1 = b1 * ic1 + b2 * v3
        v2 = ic2 + b2 * ic1 + b3 * v3
        ic1, ic2 = 2 * v1 - ic1, 2 * v2 - ic2
        out[i] = v1 if mode == "bp" else v2
    return np.array(out)


def sweep(n: int, f0: float, f1: float, length: float, start: float = 0.0) -> np.ndarray:
    """Экспоненциальная траектория частоты f0 -> f1 за length секунд, дальше f1."""
    t = np.maximum(np.arange(n) / RATE - start, 0)
    return f1 + (f0 - f1) * np.exp(-t / (length / 3))


def env_exp(n: int, start: float, attack: float, tau: float) -> np.ndarray:
    local = np.maximum(np.arange(n) / RATE - start, 0)
    return (np.arange(n) / RATE >= start) * (1 - np.exp(-local / attack)) * np.exp(-local / tau)


def slow_noise(rng: np.random.Generator, n: int, hz: float) -> np.ndarray:
    """Плавный случайный сигнал единичной дисперсии с шириной полосы порядка hz (косинусная интерполяция)."""
    step = max(1, round(RATE / hz))
    knots = rng.standard_normal(n // step + 3)
    pos = np.arange(n) / step
    i = pos.astype(int)
    frac = (1 - np.cos(np.pi * (pos - i))) / 2
    out = knots[i] * (1 - frac) + knots[i + 1] * frac
    return out / max(out.std(), 1e-9)


def white(rng: np.random.Generator, n: int) -> np.ndarray:
    return rng.standard_normal(n)


def place(buf: np.ndarray, clip: np.ndarray, start: float, gain: float = 1.0) -> None:
    offset = round(start * RATE)
    size = max(0, min(len(clip), len(buf) - offset))
    if size:
        buf[offset:offset + size] += gain * clip[:size]


# ---- Строительные блоки gore (все моно, длина n) ------------------------------
def g_slap(rng, n, start, fc0, fc1, q, tau, gain):
    """Шлепок плоти: шум через широкую полосу, частота быстро падает; мягкая атака 0.3 мс."""
    local = np.arange(n) / RATE
    body = svf(white(rng, n), sweep(n, fc0, fc1, .03, start), q, "bp")
    return gain * env_exp(n, start, .0003, tau) * body * 2.0 * (1 + .25 * np.sin(2 * np.pi * rng.uniform(60, 140) * local))


def g_thud(rng, n, start, f0, f1, tau, gain):
    """Низкий «тук»: падающая синусоида, смешанная с низким шумом — не чистый тон."""
    t = np.maximum(np.arange(n) / RATE - start, 0)
    phase = 2 * np.pi * (f1 * t + (f0 - f1) * .018 * (1 - np.exp(-t / .018)))
    grit = biquad(white(rng, n), "lowpass", 220, .8) * 6
    return gain * env_exp(n, start, .0006, tau) * (np.sin(phase) + .5 * grit)


def g_drip(rng, n, start, f0, f1, length, gain):
    """Капля/пузырь: растущая широкая шумовая полоса + шипящая кромка, без осциллятора."""
    m = max(8, round(length * RATE))
    t = np.arange(m) / RATE
    env = np.sin(np.pi * np.minimum(t / length, 1)) ** 1.4 * np.exp(-t / (length * .55))
    center = f0 + (f1 - f0) * np.minimum(t / length, 1) ** 1.2
    bubble = svf(white(rng, m), center, rng.uniform(1.0, 1.7), "bp")
    bubble /= max(bubble.std(), 1e-9)
    hiss = biquad(white(rng, m), "bandpass", rng.uniform(1500, 3800), .9) * 1.4
    clip = (bubble * .48 + hiss * .65) * env
    out = np.zeros(n)
    place(out, clip, start, gain)
    return out


def g_crack(rng, n, start, gain, fmin=1800, fmax=4500, tau_range=(.0015, .004)):
    """Хруст: импульс + три широких шумовых резонанса кости, затухание за несколько мс."""
    m = round(.02 * RATE)
    t = np.arange(m) / RATE
    clip = white(rng, m) * np.exp(-t / .0005) * .5
    for _ in range(3):
        f = rng.uniform(fmin, fmax)
        resonance = biquad(white(rng, m), "bandpass", f, rng.uniform(1.3, 2.3))
        resonance /= max(resonance.std(), 1e-9)
        clip += rng.uniform(.4, 1.0) * resonance * np.exp(-t / rng.uniform(*tau_range))
    clip *= 1 - np.exp(-t / .00012)
    out = np.zeros(n)
    place(out, clip, start, gain)
    return out


def g_rip(rng, n, start, length, gain, f0=600, f1=2800):
    """Рвущийся шум: полоса ползёт вверх, амплитуда — зернистая («волокна»), плюс редкие щелчки."""
    local = np.arange(n) / RATE - start
    window = np.clip(local / length, 0, 1)
    shape = np.sin(np.pi * window) ** .8 * (local >= 0) * (local <= length)
    grain = np.maximum(.15 + slow_noise(rng, n, 150) * .8, 0) ** 1.6
    band = svf(white(rng, n), sweep(n, f0, f1, length, start) * (.5 + .5 * np.minimum(window * 3, 1)), 1.4, "bp") * 2.4
    sticks = (rng.random(n) < 260 / RATE) * rng.standard_normal(n) * 6
    sticks = biquad(sticks, "bandpass", rng.uniform(2200, 3600), .8)
    return gain * shape * (band * grain + .25 * sticks)


def g_gush(rng, n, start, length, gain, f0=3000, f1=700):
    """Фонтан/хлюп: низкочастотный шум, частота падает, амплитуда булькает (медленный случайный AM)."""
    local = np.arange(n) / RATE - start
    body = svf(white(rng, n), sweep(n, f0, f1, length, start), .8, "lp")
    bubbling = np.maximum(.3 + .95 * slow_noise(rng, n, 38), 0) ** 1.4
    return gain * env_exp(n, start, .006, length / 2.2) * (local >= 0) * body * bubbling * 1.3


def g_chunk(rng, n, start, gain):
    """Шлепок куска о землю: приглушённый шлепок + глухой тук + пузырёк."""
    return (g_slap(rng, n, start, rng.uniform(600, 1100), rng.uniform(220, 380), .9, rng.uniform(.012, .022), gain)
            + g_thud(rng, n, start, rng.uniform(95, 140), rng.uniform(55, 80), rng.uniform(.02, .035), gain * .55)
            + g_drip(rng, n, start + rng.uniform(.008, .02), rng.uniform(250, 500), rng.uniform(700, 1400),
                     rng.uniform(.012, .026), gain * .35))


def gore_hit(rng, variant):
    n = round(.14 * RATE)
    out = g_slap(rng, n, 0, rng.uniform(900, 1500), rng.uniform(300, 600), rng.uniform(.7, 1.1), rng.uniform(.010, .018), 1.0)
    out += g_slap(rng, n, .002, 1200, 500, .8, rng.uniform(.028, .042), .25)   # влажный «хвост» шлепка
    out += g_thud(rng, n, 0, rng.uniform(100, 125), rng.uniform(70, 85), rng.uniform(.022, .035), .8)
    out += g_crack(rng, n, 0, rng.uniform(.12, .28), 2000, 4200, (.001, .002))
    for _ in range(rng.integers(2, 4)):
        out += g_drip(rng, n, rng.uniform(.035, .11), rng.uniform(300, 700), rng.uniform(800, 1500),
                      rng.uniform(.010, .022), rng.uniform(.10, .24))
    return out


def gore_splat(rng, variant, builder):
    n = round(.78 * RATE)
    out = g_slap(rng, n, 0, rng.uniform(800, 1200), rng.uniform(220, 320), .8, rng.uniform(.035, .05), 1.2)
    out += g_thud(rng, n, 0, rng.uniform(65, 80), rng.uniform(42, 55), rng.uniform(.07, .10), 1.0)
    out += g_gush(rng, n, rng.uniform(.01, .025), rng.uniform(.26, .38), rng.uniform(.8, 1.05))
    for _ in range(rng.integers(2, 4)):
        out += g_chunk(rng, n, rng.uniform(.07, .32), rng.uniform(.28, .5))
    for k in range(rng.integers(6, 11)):
        t0 = rng.uniform(.18, .70)
        out += g_drip(rng, n, t0, rng.uniform(250, 600), rng.uniform(700, 1700), rng.uniform(.012, .03),
                      .22 * np.exp(-(t0 - .18) / .3))
    # Мокрые призвуки из исходников: щелчки/бульканье монстров 11–15, питч ниже, без верха
    src = _monster(int(rng.choice([10, 11, 12, 13, 14, 15])))
    frag = revoice(load_voice(builder, src), rng.uniform(.8, 1.0))
    a = int(rng.uniform(0, max(1, len(frag) - round(.3 * RATE))))
    frag = biquad(frag[a:a + round(.3 * RATE)], "lowpass", 2800)
    frag = frag * np.sin(np.linspace(0, np.pi, len(frag))) ** 2
    place(out, frag, rng.uniform(.04, .12), rng.uniform(.22, .34))
    return out, src


def gore_gib(rng, variant):
    n = round(.95 * RATE)
    out = g_slap(rng, n, 0, 1400, 280, .8, .05, 1.3)
    out += g_thud(rng, n, 0, rng.uniform(60, 75), rng.uniform(38, 48), .11, 1.4)
    out += g_gush(rng, n, .005, rng.uniform(.25, .34), 1.0, 3400, 600)
    out += g_rip(rng, n, .0, rng.uniform(.17, .26), 1.1, rng.uniform(500, 800), rng.uniform(2300, 3200))
    # хруст костей — серия из 7–12 щелчков в первые 220 мс
    for _ in range(rng.integers(7, 13)):
        out += g_crack(rng, n, rng.uniform(.01, .22), rng.uniform(.35, .9), 1900, 4200)
    # шлепки кусков с задержками 50–300 мс
    for t0 in np.sort(rng.uniform(.05, .30, rng.integers(3, 6))):
        out += g_chunk(rng, n, t0, rng.uniform(.4, .75) * (1.2 - t0))
    # дальний шлепок и капли
    out += g_chunk(rng, n, rng.uniform(.38, .52), .25)
    for k in range(rng.integers(8, 14)):
        t0 = rng.uniform(.2, .88)
        out += g_drip(rng, n, t0, rng.uniform(250, 600), rng.uniform(700, 1700), rng.uniform(.012, .03),
                      .22 * np.exp(-(t0 - .2) / .3))
    return out


def gore_bone(rng, variant):
    n = round(.24 * RATE)
    out = np.zeros(n)
    t0 = 0.0
    for k in range(rng.integers(3, 6)):                # серия: излом идёт по кости ступенями
        out += g_crack(rng, n, t0, rng.uniform(.6, 1.0) * (1 - .1 * k), 1500, 4300, (.002, .0045))
        out += g_slap(rng, n, t0, rng.uniform(1800, 2600), 900, 1.2, .004, .25)
        t0 += rng.uniform(.006, .028)
    out += g_thud(rng, n, 0, rng.uniform(150, 230), rng.uniform(90, 130), rng.uniform(.012, .02), .55)
    out += g_crack(rng, n, t0 + .02, .35, 1200, 3000, (.003, .006))
    return out


# ---- Голоса ------------------------------------------------------------------
def load_voice(builder: Builder, rel: str) -> np.ndarray:
    """Исходник → моно 48 кГц: ФВЧ 60 Гц (Баттерворт 2-го порядка), обрезка тишины (−42 дБ), пик 1."""
    cache = builder.__dict__.setdefault("voices", {})
    if rel in cache:
        return cache[rel]
    path = builder.zsrc / rel
    raw, rate = read_pcm(path)
    if rate != 44100:
        raise ValueError(f"Expected 44.1 kHz: {path}")
    x = pitch(raw.mean(axis=1, keepdims=True), rate / RATE)[:, 0]
    x = biquad(x, "highpass", 60)
    env = np.sqrt(np.convolve(x * x, np.ones(240) / 240, "same"))
    loud = np.flatnonzero(env > env.max() * 10 ** (-42 / 20))
    x = x[max(0, loud[0] - 288):min(len(x), loud[-1] + 288)]
    cache[rel] = x / np.abs(x).max()
    builder.source_info[f"zombies_cc0/{rel}"] = {
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "seconds": round(len(raw) / rate, 4), "kept_s": round(len(x) / RATE, 4)}
    return cache[rel]


def revoice(x: np.ndarray, ratio: float, tilt: float = 0.0, eq: tuple | None = None) -> np.ndarray:
    """Ресемплинг (питч и форманты вместе) + лёгкий наклон тембра и/или колокол EQ (f, Q, дБ)."""
    y = pitch(x[:, None], ratio)[:, 0]
    if tilt:
        low = lowpass(y[:, None], 1800)[:, 0]
        y = low * (1 - tilt) + (y - low) * (1 + tilt)
    if eq:
        y = biquad(y, "peaking", *eq)
    return y


def warp(x: np.ndarray, r0: float, r1: float) -> np.ndarray:
    """Ресемплинг с плавно меняющимся питчем (r0 → r1): «падающий» предсмертный хрип."""
    count = int(len(x) / min(r0, r1)) + 1
    steps = np.exp(np.linspace(np.log(r0), np.log(r1), count))
    pos = np.cumsum(steps) - steps[0]
    pos = pos[pos < len(x) - 1]
    cutoff = .46 / max(1.0, r0, r1)
    out = np.empty(len(pos))
    offsets = np.arange(-32, 33)
    for start in range(0, len(pos), 4096):
        p = pos[start:start + 4096]
        idx = np.floor(p).astype(int)[:, None] + offsets
        delta = p[:, None] - idx
        w = 2 * cutoff * np.sinc(2 * cutoff * delta)
        w *= np.where(np.abs(delta) < 33, .5 + .5 * np.cos(np.pi * delta / 33), 0)
        w /= w.sum(axis=1, keepdims=True)
        out[start:start + len(p)] = (w * x[np.clip(idx, 0, len(x) - 1)]).sum(axis=1)
    return out


def sat(x: np.ndarray, drive: float) -> np.ndarray:
    return np.tanh(drive * x) / np.tanh(drive)


def fade_in_out(x: np.ndarray, fade_in: float) -> np.ndarray:
    x = x.copy()
    m = min(round(fade_in * RATE), len(x) // 3)
    x[:m] *= np.sin(np.linspace(0, np.pi / 2, m)) ** 2
    return x


# (источник, ресемплинг, наклон тембра, колокол EQ) — каждый источник один раз: повторов не узнать
GROAN_VOICES = [(_zombie(1), 1.00, 0.00, None), (_zombie(2), .95, .04, (700, 1.0, 3.0)),
                (_zombie(3), 1.06, -.03, None), (_zombie(7), .92, .05, (1400, 1.2, -3.0)),
                (_zombie(8), 1.00, .00, (900, 1.0, 3.0)), (_zombie(14), 1.09, -.04, None),
                (_zombie(15), .90, .03, None), (_zombie(18), 1.03, .05, (1100, 1.1, 3.5)),
                (_zombie(20), .96, -.04, None), (_zombie(21), 1.07, .02, (1800, 1.0, -3.0)),
                (_zombie(22), .87, .04, None), (_zombie(23), 1.12, -.05, (600, 1.0, 3.0)),
                (_zombie(4), .80, .06, (1000, 1.0, 3.0)), (_zombie(17), 1.18, .0, None)]
ATTACK_VOICES = [(_zombie(24), 1.00, 0), (_zombie(5), 1.06, 0), (_zombie(11), .94, 0), (_zombie(13), 1.00, 0),
                 (_monster(5), .90, 1), (_monster(7), .85, 1)]
DEATH_VOICES = [(_zombie(12), .95, .78), (_zombie(19), 1.00, .80), (_zombie(9), .92, .75), (_zombie(10), 1.00, .82),
                (_zombie(6), .96, .74), (_monster(1), .90, .72), (_monster(2), .86, .70), (_monster(3), 1.00, .78)]
RUNNER_VOICES = [(_monster(4), 1.36), (_monster(6), 1.30), (_monster(7), 1.46), (_monster(8), 1.26),
                 (_monster(16), 1.40), (_monster(18), 1.30)]
FAT_VOICES = [(_monster(11), .68), (_monster(12), .72), (_monster(13), .62), (_monster(14), .70),
              (_monster(15), .66), (_zombie(16), .68)]
BOSS_LAYERS = [  # (источник, ресемплинг, смещение с, усиление)
    [(_monster(2), .55, 0, 1.0), (_zombie(17), .60, .02, .8), (_monster(1), .78, .06, .45)],
    [(_monster(3), .52, 0, 1.0), (_zombie(16), .56, .03, .8), (_monster(7), .74, .08, .4)],
    [(_monster(1), .50, 0, 1.0), (_zombie(18), .58, .04, .8), (_monster(2), .70, .1, .45)]]


def voice_groan(builder, i):
    src, ratio, tilt, eq = GROAN_VOICES[i]
    y = revoice(load_voice(builder, src), ratio, tilt, eq)[:round(1.4 * RATE)]
    y = fade_in_out(y, .03)
    return y, src, ratio


def voice_attack(builder, rng, i):
    src, ratio, big = ATTACK_VOICES[i]
    y = revoice(load_voice(builder, src), ratio, .05)
    y = sat(y * 1.2, 2.2)
    n = len(y) + round(.05 * RATE)
    out = np.zeros(n)
    place(out, y, 0)
    if i >= 3:                                         # укус: сухой щелчок челюсти + шлепок
        out += g_crack(rng, n, .0, .55, 1500, 3200, (.002, .004)) + g_slap(rng, n, .0, 1400, 500, 1.0, .02, .5)
        out += g_crack(rng, n, rng.uniform(.045, .07), .4, 1200, 2800, (.002, .004))
    return fade_in_out(out, .002), src, ratio


def voice_death(builder, rng, i):
    src, r0, r1 = DEATH_VOICES[i]
    y = warp(load_voice(builder, src), r0, r1)         # питч падает: затухающий хрип
    low = biquad(y, "lowpass", 2400)
    mix = np.linspace(0, 1, len(y)) ** 1.3             # к концу темнее
    y = y * (1 - mix) + low * mix
    out = np.zeros(len(y) + round(.25 * RATE))
    place(out, y, 0)
    for _ in range(rng.integers(2, 5)):                # хрип переходит в бульканье
        out += g_drip(rng, len(out), rng.uniform(.25, .9) * len(y) / RATE, rng.uniform(200, 450),
                      rng.uniform(500, 1100), rng.uniform(.018, .04), rng.uniform(.12, .22))
    return fade_in_out(out, .006), src, r0


def voice_runner(builder, rng, i):
    src, ratio = RUNNER_VOICES[i]
    y = revoice(load_voice(builder, src), ratio)
    t = np.arange(len(y)) / RATE
    y *= 1 - .3 * (.5 + .5 * np.sin(2 * np.pi * rng.uniform(17, 27) * t))   # злая дрожь визга
    y = sat(y * 1.6, 2.8)
    y = biquad(biquad(y, "highpass", 170), "lowpass", 9500)
    y = biquad(y, "peaking", rng.uniform(2200, 3200), 1.0, 4.0)
    return fade_in_out(y, .004), src, ratio


def voice_fat(builder, rng, i):
    src, ratio = FAT_VOICES[i]
    y = biquad(revoice(load_voice(builder, src), ratio, -.1), "lowpass", 3000)
    n = len(y) + round(.2 * RATE)
    out = np.zeros(n)
    place(out, y, 0)
    for _ in range(rng.integers(5, 9)):                # утробные пузыри и бульканье
        out += g_drip(rng, n, rng.uniform(0, len(y) / RATE), rng.uniform(110, 260), rng.uniform(260, 700),
                      rng.uniform(.04, .09), rng.uniform(.25, .5))
    t = np.arange(n) / RATE
    envelope = biquad(np.abs(out), "lowpass", 14)
    out += np.sin(2 * np.pi * rng.uniform(46, 58) * t) * envelope * 1.2   # низ «в животе»
    return fade_in_out(sat(out, 1.4), .01), src, ratio


def voice_spit(builder, rng, i):
    n = round(.5 * RATE)
    spray = svf(white(rng, n), sweep(n, 5200, 1900, .15), .9, "bp") * env_exp(n, 0, .003, .08) * 4.0
    spray += svf(white(rng, n), sweep(n, 3200, 2200, .3), 1.2, "bp") * env_exp(n, .02, .02, .17) * 1.4
    out = spray + g_thud(rng, n, 0, 160, 90, .02, .5) + g_slap(rng, n, 0, 1300, 450, .9, .015, .5)
    for _ in range(rng.integers(4, 8)):
        out += g_drip(rng, n, rng.uniform(.02, .30), rng.uniform(450, 900), rng.uniform(1200, 2200),
                      rng.uniform(.012, .03), rng.uniform(.18, .4))
    src = _monster((9, 10, 17, 14)[i])
    frag = biquad(revoice(load_voice(builder, src), 1.15 + .05 * i)[:round(.16 * RATE)], "lowpass", 4200)
    place(out, frag * np.sin(np.linspace(0, np.pi, len(frag))), .01, .35)
    return out, src, 1.15 + .05 * i


def voice_boss(builder, rng, i):
    n = round(2.9 * RATE)
    mix = np.zeros(n)
    for src, ratio, offset, gain in BOSS_LAYERS[i]:
        place(mix, fade_in_out(revoice(load_voice(builder, src), ratio), .03), offset, gain)
    t = np.arange(n) / RATE
    mix *= 1 + .35 * np.sin(2 * np.pi * (17 + 2 * i) * t + rng.uniform(0, 6))   # рычащая дрожь
    dist = sat(mix * 2.5, 3.2)
    out = dist + biquad(dist, "lowpass", 150) * 1.2
    length = (1.9, 2.1, 2.3)[i]
    envelope = biquad(np.abs(out), "lowpass", 9)
    out += np.sin(2 * np.pi * (40 + 3 * i) * t) * envelope * 1.0              # суб
    out = out[:round(length * RATE)] * (1 - np.exp(-np.arange(round(length * RATE)) / RATE / .04))
    return out, "+".join(s for s, *_ in BOSS_LAYERS[i]), BOSS_LAYERS[i][0][1]


def emit_voices(builder: Builder) -> None:
    def put(group, variant, y, source, ratio, fade=.05, **extra):
        clip = normalize(finish(y, fade), HORDE_PEAKS[group])
        builder.emit(f"zombies/{group}_{variant}.wav", clip, f"{source}", pitch_ratio=round(float(ratio), 3),
                     peak_db=HORDE_PEAKS[group], **extra)
        return clip

    builder.groans = []
    for i in range(len(GROAN_VOICES)):
        y, src, ratio = voice_groan(builder, i)
        builder.groans.append(put("groan", i, y, src, ratio, .08))
    for i in range(len(ATTACK_VOICES)):
        rng = np.random.default_rng(A4_SEED + 100 + i)
        y, src, ratio = voice_attack(builder, rng, i)
        put("attack", i, y, src + (" + synthesized bite" if i >= 3 else ""), ratio, .04, seed=A4_SEED + 100 + i)
    for i in range(len(DEATH_VOICES)):
        rng = np.random.default_rng(A4_SEED + 200 + i)
        y, src, ratio = voice_death(builder, rng, i)
        put("death", i, y, src + " (pitch glide down) + drips", ratio, .12, seed=A4_SEED + 200 + i)
    for i in range(len(RUNNER_VOICES)):
        rng = np.random.default_rng(A4_SEED + 300 + i)
        y, src, ratio = voice_runner(builder, rng, i)
        put("runner", i, y, src + " (pitch up, saturation, tremolo)", ratio, .05, seed=A4_SEED + 300 + i)
    for i in range(len(FAT_VOICES)):
        rng = np.random.default_rng(A4_SEED + 400 + i)
        y, src, ratio = voice_fat(builder, rng, i)
        put("fat", i, y, src + " (pitch down) + gurgles + sub", ratio, .1, seed=A4_SEED + 400 + i)
    for i in range(4):
        rng = np.random.default_rng(A4_SEED + 500 + i)
        y, src, ratio = voice_spit(builder, rng, i)
        put("spit", i, y, f"synthesis: spray, thud, drips + {src} fragment", ratio, .08, seed=A4_SEED + 500 + i)
    for i in range(3):
        rng = np.random.default_rng(A4_SEED + 600 + i)
        y, src, ratio = voice_boss(builder, rng, i)
        put("boss_roar", i, y, src.replace("+", " + ") + " (3 layers, pitch x0.5-0.8, saturation, sub 40 Hz)", ratio,
            .35, seed=A4_SEED + 600 + i)


# ---- Gore --------------------------------------------------------------------
def emit_gore(builder: Builder) -> None:
    for group, make, count, fade, desc in (
            ("hit", gore_hit, 10, .035, "synthesis: bandpass flesh slap, 70-125 Hz thud, snap, drips"),
            ("splat", gore_splat, 8, .25, "synthesis: slap + sub thud, bubbling gush, chunk slaps, drip tail + monster gurgle fragment"),
            ("gib", gore_gib, 6, .3, "synthesis: wet burst + sub, tearing, bone crack series, chunk slaps 50-300 ms, drips"),
            ("bone", gore_bone, 6, .05, "synthesis: stepped crack series (three broad noise resonances), knock")):
        for variant in range(count):
            seed = A4_SEED + {"hit": 1000, "splat": 2000, "gib": 3000, "bone": 4000}[group] + variant
            rng = np.random.default_rng(seed)
            if group == "splat":
                y, src = make(rng, variant, builder)
                note = desc + f" ({src})"
            else:
                y, note = make(rng, variant), desc
            y = biquad(y, "highpass", 40)
            builder.emit(f"gore/{group}_{variant}.wav", normalize(finish(y, fade), HORDE_PEAKS[group]), note,
                         seed=seed, peak_db=HORDE_PEAKS[group])


# ---- Лупы: орда и сердцебиение -------------------------------------------------
def circ_filter(x: np.ndarray, lo: float, hi: float) -> np.ndarray:
    """Нуль-фазовый полосовой фильтр в частотной области: циркулярный, значит лупы замкнуты по построению."""
    spectrum = np.fft.rfft(x)
    f = np.maximum(np.fft.rfftfreq(len(x), 1 / RATE), 1e-6)
    spectrum *= 1 / (1 + (lo / f) ** 4) / (1 + (f / hi) ** 4)
    return np.fft.irfft(spectrum, len(x))


def fft_convolve(x: np.ndarray, kernel: np.ndarray) -> np.ndarray:
    size = 1 << int(np.ceil(np.log2(len(x) + len(kernel))))
    return np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(kernel, size), size)[:len(x) + len(kernel) - 1]


def add_wrap(buf: np.ndarray, clip: np.ndarray, start: int, left: float, right: float) -> None:
    """Сложить клип в стерео-буфер по кругу: хвост за концом лупа ложится на его начало."""
    n = len(buf)
    for part in range(0, len(clip), n):
        piece = clip[part:part + n]
        index = (start + part + np.arange(len(piece))) % n
        buf[index, 0] += left * piece
        buf[index, 1] += right * piece


def step_clip(rng: np.random.Generator) -> np.ndarray:
    """Один шаг по асфальту/обломкам: шорох ботинка + глухой упор."""
    m = round(.2 * RATE)
    scuff = biquad(white(rng, m), "bandpass", rng.uniform(700, 1500), .6) * env_exp(m, 0, .005, rng.uniform(.035, .07)) * 2.2
    drag = biquad(white(rng, m), "lowpass", 2000) * env_exp(m, rng.uniform(.03, .06), .03, .06) * .7
    thud = g_thud(rng, m, 0, rng.uniform(90, 130), rng.uniform(55, 75), .03, .5)
    clip = scuff + drag + thud
    return clip / np.abs(clip).max()


def horde_loop(builder: Builder, index: int) -> tuple[np.ndarray, dict]:
    """Луп толпы: десятки стонов (сдвиг питча, затемнение «издалека», панорама), гул, шарканье.

    Круговое наложение сохраняет голоса на стыке; финальный кроссфейд 100 мс
    соединяет перекрывающиеся края. Экспорт моно по CONTRACTS §9.
    """
    rng = np.random.default_rng(A4_SEED + 7000 + index)
    seconds = (10.0, 12.0)[index] + .1
    n = round(seconds * RATE)
    out = np.zeros((n, 2))
    t = np.arange(n) / RATE

    def modulation() -> np.ndarray:                    # целое число периодов: модуляция замкнута
        return 1 + .3 * np.sin(2 * np.pi * rng.integers(1, 4) / seconds * t + rng.uniform(0, 6.3))

    rumble = circ_filter(white(rng, n), 32, 130) * modulation()
    murmur = circ_filter(white(rng, n), 140, 700) * modulation() * (1 + .4 * np.sin(2 * np.pi * 2 / seconds * t + 1))
    rumble /= rumble.std()
    murmur /= murmur.std()
    bed = (.9, 1.25)[index] * rumble + (.35, .6)[index] * murmur
    out += bed[:, None] * 0.018
    # стоны: случайный исходный голос, питч .7–1.12, чем тише, тем темнее и «в зале»
    count = (26, 76)[index]
    for _ in range(count):
        voice = builder.groans[rng.integers(len(builder.groans))]
        clip = pitch(voice, rng.uniform(.7, 1.12))
        far = rng.uniform(0, 1)
        clip = lowpass(clip, 3400 - 2300 * far)[:, 0]
        room = np.zeros(round(.16 * RATE))
        room[0] = 1
        room += (.25 + .5 * far) * white(rng, len(room)) * np.exp(-np.arange(len(room)) / RATE / .045)
        clip = fft_convolve(clip, room)
        gain = 10 ** ((-8 - 16 * far) / 20)
        angle = (rng.uniform(-.9, .9) + 1) * np.pi / 4
        add_wrap(out, clip, int(rng.integers(n)), gain * np.cos(angle), gain * np.sin(angle))
    # шарканье: каждый «ходок» — цепочка шагов с неровным интервалом
    pool = [step_clip(np.random.default_rng(A4_SEED + 7100 + 10 * index + k)) for k in range(24)]
    walkers = (7, 22)[index]
    for _ in range(walkers):
        angle = (rng.uniform(-.9, .9) + 1) * np.pi / 4
        gain = 10 ** (rng.uniform(-30, -21) / 20)
        interval = rng.uniform(.42, .8)
        time = rng.uniform(0, interval)
        while time < seconds:
            add_wrap(out, pool[rng.integers(len(pool))], int(time * RATE), gain * np.cos(angle) * rng.uniform(.6, 1),
                     gain * np.sin(angle) * rng.uniform(.6, 1))
            time += interval * rng.uniform(.8, 1.25)
    out = loop_crossfade(out.mean(axis=1, keepdims=True), .1)
    out -= out.mean(axis=0)
    out *= 10 ** (HORDE_RMS[f"horde_{index}"] / 20) / np.sqrt(np.mean(out ** 2))
    return out, {"seconds": len(out) / RATE, "groans": count, "walkers": walkers, "crossfade_s": .1}


def loop_crossfade(x: np.ndarray, seconds: float) -> np.ndarray:
    """Склеить перекрытие cos²/sin²; длина результата = вход минус перекрытие."""
    n = round(seconds * RATE)
    weight = np.sin(np.linspace(0, np.pi / 2, n))[:, None] ** 2
    join = x[-n:] * (1 - weight) + x[:n] * weight
    return np.concatenate((join, x[n:-n]))


def heartbeat_loop(variant: int) -> np.ndarray:
    """«Лаб-даб»: два глухих удара за 1 с (лаб в 0, даб в ~0.33 с), низ + глухой щелчок; период ровно 1 с."""
    rng = np.random.default_rng(A4_SEED + 8000 + variant)
    n = RATE + round(.05 * RATE)
    out = np.zeros(n)
    for start, gain, f0 in ((.10, 1.0, 62 + 3 * variant), (.40 + .015 * variant, .72, 74 + 3 * variant)):
        body = g_thud(rng, n, start, f0 * 1.25, f0 * .62, .075, 1.0)
        mud = biquad(white(rng, n), "lowpass", 420 + 60 * variant, .8) * env_exp(n, start, .004, .018) * 2.2
        valve = biquad(white(rng, n), "bandpass", 900, .7) * env_exp(n, start + .004, .003, .012) * .35
        out += gain * (body + mud + valve)
    out = loop_crossfade(sat(out, 1.3)[:, None], .05)
    out -= out.mean()
    return out


# ---- Игрок --------------------------------------------------------------------
# (длительность, f0 начало, f0 конец, форманты (Гц, ширина, усиление), дыхание, насыщение)
HURT_KINDS = [
    (.24, 150, 112, [(650, 110, 1.0), (1150, 130, .6), (2500, 200, .3)], .30, 1.8),   # «хнх»: короткий кряк
    (.46, 175, 105, [(760, 120, 1.0), (1250, 140, .55), (2600, 220, .3)], .25, 2.2),  # «ааа!»: крик боли с падением
    (.30, 135, 100, [(560, 100, 1.0), (1000, 120, .5), (2400, 200, .25)], .45, 1.6),  # «ухх»: удар в живот
    (.26, 190, 150, [(380, 90, 1.0), (1750, 150, .6), (2600, 220, .3)], .35, 2.0),    # «нгх»: сквозь зубы
    (.38, 160, 120, [(700, 130, 1.0), (1100, 130, .65), (2450, 200, .3)], .55, 1.7),  # хрип-выдох
    (.20, 205, 165, [(620, 100, 1.0), (1350, 130, .55), (2700, 220, .3)], .25, 2.4),  # короткий выкрик
]


def hurt_voice(rng: np.random.Generator, variant: int) -> np.ndarray:
    dur, f_a, f_b, formants, breath, drive = HURT_KINDS[variant]
    n = round((dur + .08) * RATE)
    t = np.arange(n) / RATE
    f0 = np.linspace(f_a, f_b, n) * (1 + .035 * slow_noise(rng, n, 28)) * rng.uniform(.95, 1.06)
    phase = np.cumsum(f0) / RATE
    harmonics = max(8, int(8500 / f0.max()))
    source = sum(np.sin(2 * np.pi * k * phase) / k ** 1.25 for k in range(1, harmonics + 1))
    source *= 1 + .22 * slow_noise(rng, n, 45)                              # дрожь амплитуды (шимер)
    excitation = source / np.abs(source).max() + breath * white(rng, n) * (.6 + .4 * np.sin(np.pi * f0 * t) ** 2)
    voice = sum(g * biquad(excitation, "bandpass", f, f / bw) for f, bw, g in formants)
    envelope = (1 - np.exp(-t / .01)) * np.exp(-t / (dur * .55)) * np.clip((dur + .06 - t) / .06, 0, 1)
    voice = sat(voice * envelope * 2.5, drive)                              # охриплость
    out = voice / np.abs(voice).max()
    out += .55 * (g_thud(rng, n, 0, 105, 62, .045, 1.0) + g_slap(rng, n, 0, 700, 280, .9, .02, .6))   # удар в тело
    return biquad(out, "highpass", 70)


# ---- Интерфейс (из механики A2) ------------------------------------------------
def ui_source(builder: Builder, name: str, ratio: float = 1.0, length: float = .12) -> np.ndarray:
    x, _ = read_pcm(builder.out / name)
    x = x[:round(length * 1.3 * RATE), :1]
    x = pitch(x, ratio)[:round(length * RATE), 0]
    return x / np.abs(x).max()


def emit_player_ui(builder: Builder) -> None:
    for i in range(len(HURT_KINDS)):
        seed = A4_SEED + 9000 + i
        y = hurt_voice(np.random.default_rng(seed), i)
        builder.emit(f"player/hurt_{i}.wav", normalize(finish(y, .05), HORDE_PEAKS["hurt"]),
                     "synthesis: glottal harmonic source through vowel formants + breath, saturation, body-hit layer",
                     seed=seed, peak_db=HORDE_PEAKS["hurt"])
    beat = heartbeat_loop(0)
    builder.emit("player/heartbeat_0.wav", normalize(beat, HORDE_PEAKS["heartbeat"]),
                 "synthesis: lub-dub, noisy sub thuds + muffled valve click, exactly 1.000 s loop",
                 seed=A4_SEED + 8000, peak_db=HORDE_PEAKS["heartbeat"], loop=True)
    # click: мягче оригинала (ФНЧ 4.5 кГц, плавный вход), три высоты
    for i, (name, ratio) in enumerate((("weapons/pistol/dry_0.wav", .96), ("weapons/pistol/dry_1.wav", 1.06),
                                       ("weapons/smg/dry_0.wav", 1.0))):
        x = biquad(ui_source(builder, name, ratio, .07), "lowpass", 4500)
        x = fade_in_out(x, .0012)
        builder.emit(f"ui/click_{i}.wav", normalize(finish(x, .02), HORDE_PEAKS["click"]),
                     f"{name} x{ratio} (A2 mechanics), lowpass 4.5 kHz, soft attack", pitch_ratio=ratio)
    # confirm: два щелчка «клик-клак», второй выше
    for i, (a, b) in enumerate((("weapons/pistol/dry_1.wav", "weapons/smg/dry_0.wav"),
                                ("weapons/rifle/dry_0.wav", "weapons/pistol/dry_0.wav"))):
        out = np.zeros(round(.2 * RATE))
        place(out, biquad(ui_source(builder, a, 1.0, .07), "lowpass", 4200), 0, 1.0)
        place(out, biquad(ui_source(builder, b, 1.28, .07), "lowpass", 5200), .075, .8)
        builder.emit(f"ui/confirm_{i}.wav", normalize(finish(fade_in_out(out, .0012), .05), HORDE_PEAKS["confirm"]),
                     f"{a} + {b} x1.28 (A2 mechanics), two clicks 75 ms apart", pitch_ratio=1.28)
    # deny: глухой «туп» — револьверный щелчок ниже питчем, без верха, с низким ударом
    for i, ratio in enumerate((.6, .52)):
        rng = np.random.default_rng(A4_SEED + 9500 + i)
        out = np.zeros(round(.22 * RATE))
        click = biquad(ui_source(builder, "weapons/revolver/dry_0.wav", ratio, .1), "lowpass", 1100)
        place(out, click, 0, 1.0)
        place(out, click, .085, .55)
        out += g_thud(rng, len(out), 0, 120, 70, .035, .9) + g_thud(rng, len(out), .085, 100, 62, .03, .5)
        out = biquad(out, "highpass", 50)
        builder.emit(f"ui/deny_{i}.wav", normalize(finish(out, .08), HORDE_PEAKS["deny"]),
                     f"weapons/revolver/dry_0.wav x{ratio} (A2 mechanics), lowpass 1.1 kHz + dull thud, two soft knocks",
                     pitch_ratio=ratio, seed=A4_SEED + 9500 + i)


def horde(builder: Builder) -> None:
    """A4: голоса орды (CC0-паки), gore (синтез), лупы орды и сердцебиения, игрок, интерфейс."""
    emit_voices(builder)
    emit_gore(builder)
    builder.loop_info = {}
    for index in range(2):
        loop, info = horde_loop(builder, index)
        builder.loop_info[f"ambience/horde_{index}.wav"] = info
        builder.emit(f"ambience/horde_{index}.wav", loop,
                     f"synthesis: {info['groans']} groans of zombies/groan (pitch .7-1.12, distance lowpass, pan) + "
                     f"rumble + murmur + {info['walkers']} shuffling walkers, mono, circular layers + 100 ms crossfade",
                     seed=A4_SEED + 7000 + index, rms_db=HORDE_RMS[f"horde_{index}"], loop=True)
    emit_player_ui(builder)


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
             "A4: [Zombies Sound Pack](https://opengameart.org/content/zombies-sound-pack) — artisticdude, CC0 1.0 (24 recordings).",
             "[Monster Sound Pack, Volume 1](https://opengameart.org/content/monster-sound-pack-volume-1) — Ogrebane, CC0 1.0 (18 recordings; archive folder Monster-Sounds-Volume-2).",
             "A4 voice edits, gore/player synthesis and UI edits are dedicated to CC0 1.0. Original voice packs: 24-bit stereo 44.1 kHz; export: PCM16 mono 48 kHz, including ambience. Loops use forward playback; ambience has 100 ms overlap, heartbeat 50 ms.", "",
             "| Output file | Source / synthesis | Take; original crop; pitch |", "|---|---|---|"]
    for e in builder.entries:
        edit = f"take {e['take']}; {e['crop_start_s']:.6f}–{e['crop_end_s']:.6f} s; ×{e['pitch_ratio']}" if "take" in e else f"seed {e['seed']}" if "seed" in e else f"×{e['pitch_ratio']}"
        lines.append(f"| `{e['file']}` | {e['source']} | {edit} |")
    (builder.out / "CREDITS.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--src", type=Path, default=DEFAULT_SRC)
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT)
    parser.add_argument("--zsrc", type=Path, default=DEFAULT_ZSRC, help="A4: zombies_cc0/extracted")
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    builder = Builder(args.src, args.out)
    builder.zsrc = args.zsrc
    shots(builder)
    synthesis(builder)
    mechanics(builder)
    burst_tails(builder)
    models(builder)
    horde(builder)
    metadata(builder)
    size = sum((args.out / e["file"]).stat().st_size for e in builder.entries)
    print(f"Generated {len(builder.entries)} WAV files: PCM16, 48000 Hz; {size} bytes")
    print("Recorded shots: pistol=4 revolver=4 smg=5 rifle=4 sniper=4 shotgun=4; launcher=3 rail=3")
    print("Synthesis: brass_small=6 brass_rifle=6 shell=6 mag_drop=6 grenade=4")
    print("Peak guard: <= -1.01 dBFS; source hashes and exact cuts: manifest.json")


if __name__ == "__main__":
    main()
