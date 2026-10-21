# W5 — прослушивание выхода Master

Без нормализации громкости: сначала `before`, затем `after`, не менять громкость между файлами. Первые ~250 мс — тишина. Все записи получены через настоящий Sfx, шины и эффекты Master (`AudioEffectRecord`, Dummy driver). Это звуковой стенд, не запись живого боя.

| Ствол | До | После | Характер сборки |
|---|---|---|---|
| Пистолет | [before](pistol_before.wav) | [after](pistol_after.wav) | короткий сухой crack, давление 118 Гц |
| Револьвер | [before](revolver_before.wav) | [after](revolver_after.wav) | более низкий удар 91 Гц, длиннее отражения |
| ППШ | [before](smg_before.wav) | [after](smg_after.wav) | короткий резкий треск, лёгкий удар 140 Гц |
| АК | [before](rifle_before.wav) | [after](rifle_after.wav) | плотная середина, удар 106 Гц |
| Дробовик | [before](shotgun_before.wav) | [after](shotgun_after.wav) | широкий хлопок, тяжёлый удар 74 Гц |
| Мосин | [before](sniper_before.wav) | [after](sniper_after.wav) | длинный crack, самый низкий удар 62 Гц |
| Рельса | [before](rail_before.wav) | [after](rail_after.wav) | электрический crack и нисходящий свист |
| Гранатомёт | [before](launcher_before.wav) | [after](launcher_after.wav) | глухой выброс, давление 57 Гц |
| Очередь ППШ | [before](smg_burst_before.wav) | [after](smg_burst_after.wav) | 28 выстрелов за 2 с, одно отражение в конце |
| Очередь АК | [before](rifle_burst_before.wav) | [after](rifle_burst_after.wav) | 16 выстрелов за 2 с, одно отражение в конце |
| Бой | [before](battle_before.wav) | [after](battle_after.wav) | 5 с, 95 выстрелов четырёх стволов, орда, попадания, гильзы |

Дубли и небольшой jitter не выравнивались искусственно. После W5 одиночные АК/ППШ получают отражение после паузы; до W5 у них был только короткий shot. WAV одиночных стволов не включают отложенную игровую перезарядку/помпу; механика и гильзы в игре сохранены.

[Отчёт](../W5.md) · [Метрики Master](../w5_master_metrics.csv) · [Графики первых 150 мс](../w5_waveforms.png)
