"""Музыка: исходники автора (Suno, WAV/MP3) → music/*.ogg с выровненной громкостью.

Запуск (нужен numpy и soundfile ≥ 0.12 с libsndfile 1.1+ для MP3/Vorbis):
    python tools/prep_music.py <папка с исходниками>

Исходники лежат вне репозитория: Desktop\\zera-assets\\music_src\\tracks.
Громкость — простое усиление к RMS −16 dBFS, пик не выше −1 dBFS (без лимитера).
"""
import os
import sys

import numpy as np
import soundfile as sf

# Выходное имя → начало имени исходника (в именах автора есть пометки по-русски).
TRACKS = {
	"protocol_zero": "Protocol Zero",
	"orbit_of_extinction": "Orbit of Extinction",
	"descent_into_madness_a": "Descent Into Madness класс",
	"descent_into_madness_b": "Descent Into Madness оч",
	"delirious_charge": "Delirious Charge",
	"delirium_charge": "Delirium Charge",
	"infected_among_us": "Infected Among Us",
	"mechanical_suffocation": "Mechanical Suffocation",
	"mechanical_survival": "Mechanical Survival",
	"obsessive_groove": "Obsessive Groove",
	"pressurized_chamber": "Pressurized Chamber",
	"quarantine_zone": "Quarantine Zone",
	"rattling_machine": "Rattling Machine",
	"sirenes_des_cendres": "Sirenes des Cendres",
	"suffocating_tension": "Suffocating Tension",
	"por": "пор",
}
TARGET_RMS_DB = -16.0
PEAK_CEILING_DB = -1.0
FADE_IN_S = 0.02
FADE_OUT_S = 1.5
VORBIS_COMPRESSION = 0.65  # libsndfile: 0 — лучшее качество; 0.65 ≈ 110–120 кбит/с


def main(src: str) -> None:
	out_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "music")
	os.makedirs(out_dir, exist_ok=True)
	files = sorted(os.listdir(src))
	for name, prefix in TRACKS.items():
		match = [f for f in files if f.startswith(prefix)]
		if len(match) != 1:
			sys.exit(f"{name}: ожидался один исходник «{prefix}…», найдено {match}")
		x, sr = sf.read(os.path.join(src, match[0]), dtype="float64", always_2d=True)
		rms = 20 * np.log10(np.sqrt(np.mean(x.mean(axis=1) ** 2)) + 1e-12)
		peak = 20 * np.log10(np.abs(x).max() + 1e-12)
		gain = min(TARGET_RMS_DB - rms, PEAK_CEILING_DB - peak)
		x *= 10 ** (gain / 20)
		n_in, n_out = int(FADE_IN_S * sr), int(FADE_OUT_S * sr)
		x[:n_in] *= np.linspace(0, 1, n_in)[:, None]
		x[-n_out:] *= np.linspace(1, 0, n_out)[:, None] ** 2
		path = os.path.join(out_dir, name + ".ogg")
		# Блоками: запись Vorbis одним большим вызовом роняет libsndfile (переполнение стека).
		with sf.SoundFile(path, "w", sr, x.shape[1], format="OGG", subtype="VORBIS", compression_level=VORBIS_COMPRESSION) as f:
			for i in range(0, len(x), 4096):
				f.write(x[i:i + 4096].astype(np.float32))
		print(f"{name:24s} {len(x) / sr / 60:4.1f} мин  усиление {gain:+5.1f} дБ  {os.path.getsize(path) / 1e6:5.1f} МБ  ← {match[0]}")


if __name__ == "__main__":
	main(sys.argv[1])
