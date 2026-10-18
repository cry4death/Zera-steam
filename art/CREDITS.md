# Источники арта

`globe_land.png`: контуры суши **Natural Earth**, масштаб 1:50m, public domain.
Разрешено коммерческое использование: https://www.naturalearthdata.com/about/terms-of-use/.
GeoJSON: https://github.com/nvkelso/natural-earth-vector, `ne_50m_land.geojson`, получен 2026-10-17.
Стилизация и растеризация: `tools/gen_art_campaign.py`; подпись также в `globe_credits.txt`.

`globe_regions.png`: условные оперативные зоны по ближайшему центру `CampaignCatalog.REGIONS`
на сфере, только на суше Natural Earth. Это не государственные границы.
`globe_cities.png`: условные городские огни для ночной стороны; координаты подобраны вручную,
плотность художественная, демографические данные не используются.

`ops_*.png`: собственный детерминированный пиксель-арт Z.E.R.A.,
`tools/gen_art_ops.py` (Pillow, палитры и функции `gen_art`), 2026-10-18.
Бегуны, плевальщики, элитная группа и Объект-7 используют кадры собственных
`zombie_atlas.png` и `boss.png`; знак снабжения — собственный `military_crate.png`.
Иконки наград в интерфейсе — существующие `hud_dna.png`, `hud_crate.png`.
Снимки восьми регионов и портрет Диспетчера — оригинальные процедурные рисунки,
внешние изображения и ImageGen не использовались.
