import io,sys,os
B=chr(92)
tmp=os.path.normpath(sys.argv[1]+'/codex_tmp')
files={'G4':'G4_art_m5.md','G5':'G5_results.md','G6':'G6_boss.md'}
for id,f in files.items():
    p=f"""Задача: {id}

Ты исполнитель в проекте игры на Godot 4.7. Проект игры — C:{B}Users{B}Dev{B}Desktop{B}zera (только чтение), задачи и документы — C:{B}Users{B}Dev{B}Desktop{B}GameZ. Работаешь автономно, вопросов не задаёшь.

ВАЖНО: в zera параллельно работает другой исполнитель в своей git-ветке. Ничего в zera не создавай, не меняй, не переключай ветки. Свои файлы пиши ТОЛЬКО в GameZ{B}tasks{B}inbox{B}{id}{B}. Временные файлы и копию проекта для проверок — только в {tmp}{B}{id}, в конце удали.

1. Прочитай целиком: GameZ{B}tasks{B}README.md, GameZ{B}tasks{B}CONTRACTS.md (раздел M5) и свою задачу GameZ{B}tasks{B}M5{B}{f}. Нужные разделы GameZ{B}BALANCE.md и GameZ{B}MVP.md — по ссылкам из задачи.
2. Изучи код в zera, на который ссылается задача, и пиши в его стиле. Контракт — буква в букву.
3. Сделай результат и проверь его, как описано в задаче. Godot: C:{B}Users{B}Dev{B}Desktop{B}Godot_v4.7.2-stable_win64.exe{B}Godot_v4.7.2-stable_win64_console.exe. Если какого-то инструмента нет (например Python) — не обходи это самодельными заменами, а опиши в notes.md.
4. Скриншоты/превью, которые делаешь, посмотри сам и доработай, если плохо.
5. GameZ{B}tasks{B}inbox{B}{id}{B}notes.md по шаблону GameZ{B}tasks{B}templates{B}report.md: что сделано, вывод проверок дословно, отступления и почему.
6. В конце коротко: какие файлы в inbox и что не получилось.
"""
    io.open(f'runs/{id}_prompt.txt','w',encoding='utf-8').write(p)
