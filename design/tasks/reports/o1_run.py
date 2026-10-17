"""Один контролируемый запуск. Оконные и perf-прогоны всегда берут общий lock."""
from pathlib import Path
import os
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[3]
GODOT = 'C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe'
LOCK = 'C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh'
label, mode, *args = sys.argv[1:]
logs = ROOT / 'design/tasks/reports'
env = os.environ.copy()
env['APPDATA'] = str(logs / 'o1_runtime')
env['PYTHONDONTWRITEBYTECODE'] = '1'
(logs / 'o1_runtime').mkdir(exist_ok=True)
original = {}
if '--pre-e1b' in args:
    args.remove('--pre-e1b')
    for file in ('game.gd', 'weapons.gd', 'hazards.gd'):
        path = ROOT / 'scripts' / file
        original[path] = path.read_bytes()
        source = subprocess.check_output(['git', 'show', 'HEAD:scripts/' + file], cwd=ROOT)
        if file == 'game.gd':
            source = source.replace(b'func _ready() -> void:\n', b'func _ready() -> void:\n\tseed(81073)\n', 1)
        path.write_bytes(source)
command = [GODOT]
if mode == 'headless' or mode == 'import':
    command += ['--headless']
else:
    command += ['--disable-vsync']
command += ['--path', str(ROOT), '--log-file', str(logs / ('o1_' + label + '_engine.log'))]
if mode == 'import':
    command += ['--import']
else:
    command += ['--', *args]
if mode == 'window':
    command = ['C:/Program Files/Git/usr/bin/bash.exe', LOCK, *command]
print('RUN', label, ' '.join(command), flush=True)
start = time.monotonic()
try:
    with (logs / ('o1_' + label + '.log')).open('w', encoding='utf-8') as log:
        process = subprocess.Popen(command, cwd=ROOT, env=env, stdout=log, stderr=subprocess.STDOUT)
        try:
            code = process.wait(timeout=850 if mode == 'window' else 300)
        except subprocess.TimeoutExpired:
            subprocess.run(['taskkill', '/PID', str(process.pid), '/T', '/F'], stdout=subprocess.DEVNULL)
            code = 124
    print('EXIT', label, code, 'seconds=%.2f' % (time.monotonic()-start), flush=True)
    lines = (logs / ('o1_' + label + '.log')).read_text(encoding='utf-8', errors='replace').splitlines()
    interesting = [line for line in lines if any(t in line for t in ('GODOT_EXCLUSIVE', 'BENCH', 'OBSTEST', 'SIM ', 'TEST ', 'TEST ok', 'FXTEST', 'BOSS ', 'ALARM ', 'ERROR:', 'WARNING:'))]
    print('\n'.join(interesting[-60:]), flush=True)
finally:
    for path, source in original.items():
        path.write_bytes(source)
sys.exit(code)
