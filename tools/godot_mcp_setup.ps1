# Регистрация Godot Editor MCP в Claude Code для рабочей копии Opus (по умолчанию — основной worktree, Desktop\zera).
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools/godot_mcp_setup.ps1 [-Toolsets inspection] [-Remove]
# По умолчанию только чтение (inspection; core включён всегда). Запуск игры (runtime) пишет настоящий профиль
# автора — включать на время задачи: -Toolsets inspection,runtime.
# Scope «local»: запись в ~/.claude.json только для этой папки, не в git. Поэтому сервер видят только сессии Claude
# в рабочей копии Opus, а не исполнители в своих worktree, и токен моста не попадает в репозиторий.
# Токен моста (GODOT_MCP_BRIDGE_TOKEN) лежит в %LOCALAPPDATA%\zera\godot_mcp_bridge.token; его же читает
# tools/godot_editor.ps1. Без токена headless-импорт в любом worktree (addon включён в project.godot) мог бы
# подключиться к мосту и вытеснить редактор Opus.
# После запуска перезапустите сессию Claude Code: список инструментов MCP читается при старте сессии.
param(
	[string]$Toolsets = "inspection",
	[string]$Project = "",
	[string]$Version = "2026.10.15",
	[switch]$Remove
)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$GodotBin = "C:\Users\Dev\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
$TokenFile = Join-Path $env:LOCALAPPDATA "zera\godot_mcp_bridge.token"

if ($Project -eq "") {
	# Первый worktree в списке git — основной (Desktop\zera).
	$first = git -C $Root worktree list --porcelain | Select-Object -First 1
	$Project = ($first -replace "^worktree ", "") -replace "/", "\"
}
if (-not (Test-Path (Join-Path $Project "project.godot"))) { throw "Не проект Godot: $Project" }

$claude = Get-Command claude -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source
if (-not $claude -and $env:CLAUDE_CODE_EXECPATH) { $claude = $env:CLAUDE_CODE_EXECPATH }
if (-not $claude) { throw "Не найден CLI claude. Запустите скрипт из терминала Claude Code или добавьте claude в PATH." }

Push-Location $Project
try {
	# Нет старой записи — не ошибка.
	try { & $claude mcp remove godot -s local 2>&1 | Out-Null } catch {}
	if ($Remove) {
		Write-Host "Godot MCP удалён из конфигурации Claude Code для $Project"
		return
	}
	if (-not (Get-Command uvx -ErrorAction SilentlyContinue)) {
		throw "Нет uvx. Установите uv: python -m pip install uv"
	}
	if (-not (Test-Path $TokenFile)) {
		New-Item -ItemType Directory -Force (Split-Path -Parent $TokenFile) | Out-Null
		$bytes = New-Object byte[] 32
		[Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
		-join ($bytes | ForEach-Object { $_.ToString("x2") }) | Set-Content -NoNewline -Encoding ASCII $TokenFile
	}
	$token = (Get-Content -Raw $TokenFile).Trim()
	& $claude mcp add godot -s local `
		-e "GODOT_MCP_BRIDGE_TOKEN=$token" `
		-e "GODOT_MCP_GODOT_BIN=$GodotBin" `
		-e "GODOT_MCP_DEFAULT_TOOLSETS=$Toolsets" `
		-e "FASTMCP_CHECK_FOR_UPDATES=off" `
		-- uvx "godot-editor-mcp@$Version"
	if ($LASTEXITCODE -ne 0) { throw "claude mcp add завершился с кодом $LASTEXITCODE" }
	Write-Host "Godot MCP $Version зарегистрирован для $Project (toolsets: $Toolsets). Перезапустите сессию Claude Code."
} finally {
	Pop-Location
}
