# Z1 — итоговая проверка

```text
Z1FINAL branch=task/z1 commit_created=false
Z1FINAL tracked_scope=true untracked_scope=true original_task_file_untouched=true
Z1FINAL git_diff_check=0 generated_bus_exact_HEAD=true prior_e1_pngs_exact_HEAD=true report_links=true
Z1FINAL required_routes=9 exit_zero=9 script_errors=0 parse_errors=0
Z1FINAL benchmark_deliver_foreign_during=[] for_each_of_3=true
Z1FINAL observed_godot_pids=[] own_runner_sessions_completed=true
```

Все собственные runner-процессы завершились после ожидания дочернего Godot; открытых окон и фоновых циклов исполнителя нет. Чужие процессы не завершались.

Удаление служебных Z1_runtime/Z1_test и двух собственных pyc отклонено автоматической проверкой (`blocked by policy`), обхода не было. Пути перечислены в Z1.md. Два игнорируемых pyc вне разрешённых префиксов — автоматический мусор, не часть результата. Повторная генерация отключает запись bytecode.

## SHA-256 исходников

```json
{
  "scripts/game.gd": "932ce80779c5325bb414bf99d21c0313d01cb8f772902742a0a5521555beb2c0",
  "scripts/gore.gd": "242d2482678de38d9b57e46d6c5d3ca5617fc941eef4313fe8b2bfc5e0de5080",
  "scripts/horde.gd": "a66e60ba38161601fa5233049699497562579da8d7f381ffe4d9097c1f9d2b08",
  "scripts/pixel_art.gd": "6fb62ede1fbc9c70a24a63d2aa257e8d7f707984c45c89ef6cd1d258616992bd",
  "shaders/flash.gdshader": "ddb652ad37bcf04efa1f018fd7bba68aef1d142dfbbf35cff5e9097d282e198c",
  "tools/gen_art.py": "3daa1b24a945075bd8f1bcea5a45c195a3f689e7ec1e3fb7d0eb1d9ae7e8cc7a",
  "tools/gen_art_z1.py": "09b0b0e66308e5e9ab29beb60caa659ba954c9ffee32fe0d769274bf64196080"
}
```

## Tracked diff

```text
art/zombie_atlas.png
art/zombie_headless_6.png
art/zombie_top_6.png
art/zombie_whole_6.png
scripts/game.gd
scripts/gore.gd
scripts/horde.gd
scripts/pixel_art.gd
shaders/flash.gdshader
tools/gen_art.py
```
