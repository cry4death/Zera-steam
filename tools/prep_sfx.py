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
               "rifle": -23, "shotgun": -22, "sniper": -21}
PEAK_LEVELS = {"brass_small": -21, "brass_rifle": -20, "shell": -22,
               "mag_drop": -19, "grenade": -3, "launcher": -5, "rail": -6}
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


# ---- A2 extension point ----------------------------------------------------
def mechanics(builder: Builder) -> None:
    """A2: Raw tracks -> mag_out/in, rack, dry, cylinder, eject/load, shell_in.

    Use builder.emit() to retain A1 provenance and shared credit generation.
    Do not regenerate/replace A1 casings/mag_drop unless the task requests it.
    """
    pass


def metadata(builder: Builder) -> None:
    manifest = {"format": "PCM16 48000 Hz; shots stereo, other effects mono", "seed": SEED,
                "source_files": builder.source_info, "files": builder.entries}
    (builder.out / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    lines = ["# Sound credits / CC0", "", "Recorded sources: The Free Firearm Sound Library / Still North Media.",
             "Authors: Ben Jaszczak, Brian Nelson, Kevin Heras, Matthew Nanney.",
             "Source and license: [OpenGameArt — The Free Firearm Sound Library](https://opengameart.org/content/the-free-firearm-sound-library), CC0 1.0.",
             "All A1 procedural synthesis and edits are also dedicated to CC0 1.0.", "",
             "Only Prepared near-distance recordings are used. Originals remain outside this repository.",
             "Times refer to the original file; FIR delay is compensated. Exact edits/seeds and source SHA256 are in manifest.json.", "",
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
    metadata(builder)
    size = sum((args.out / e["file"]).stat().st_size for e in builder.entries)
    print(f"Generated {len(builder.entries)} WAV files: PCM16, 48000 Hz; {size} bytes")
    print("Recorded shots: pistol=4 revolver=4 smg=5 rifle=4 sniper=4 shotgun=4; launcher=3 rail=3")
    print("Synthesis: brass_small=6 brass_rifle=6 shell=6 mag_drop=6 grenade=4")
    print("Peak guard: <= -1.01 dBFS; source hashes and exact cuts: manifest.json")


if __name__ == "__main__":
    main()
