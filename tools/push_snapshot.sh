#!/usr/bin/env bash
# Отправка на GitHub «только необходимого»: один коммит-снимок поверх origin/main с деревом локального main,
# но без тяжёлых доказательств из design/tasks/reports (кадры, логи, json/csv, звук, видео) — остаются только *.md.
# Полная история с кадрами живёт локально. Решение автора 2026-10-21.
# Запуск из корня репозитория: bash tools/push_snapshot.sh ["сообщение"]
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
git fetch -q origin
msg=${1:-"Снимок main $(git log -1 --format=%h main) от $(date +%Y-%m-%d): код и ресурсы игры, без кадров отчётов"}
idx=$(mktemp)
trap 'rm -f "$idx"' EXIT
export GIT_INDEX_FILE=$idx
git read-tree main
git ls-files -z -- design/tasks/reports | grep -z -v '\.md$' | xargs -0 -r git rm -q --cached --
tree=$(git write-tree)
unset GIT_INDEX_FILE
if [ "$tree" = "$(git rev-parse origin/main^{tree})" ]; then echo "Изменений нет — отправлять нечего."; exit 0; fi
commit=$(git commit-tree "$tree" -p origin/main -m "$msg

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>")
echo "Снимок $commit, дерево $tree"
git push origin "$commit:refs/heads/main"
