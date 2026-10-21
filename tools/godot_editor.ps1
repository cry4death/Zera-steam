# Открыть редактор Godot для работы через Godot Editor MCP (только Opus или назначенный агент интеграции).
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools/godot_editor.ps1 [-Project <папка>]
# Редактор — оконный Godot, поэтому на всю сессию берётся общая блокировка zera-assets\locks\godot.lock (как у
# godot_exclusive.ps1): чужие оконные тесты и замеры FPS ждут, пока редактор не закроют. Скрипт работает, пока
# открыт редактор (запускайте в фоне), раз в минуту обновляет блокировку — иначе через 20 минут её сочтут зависшей.
# Токен моста берётся из %LOCALAPPDATA%\zera\godot_mcp_bridge.token (его создаёт godot_mcp_setup.ps1) и
# передаётся только окружению редактора.
param(
	[string]$Project = "",
	[string]$Godot = "C:\Users\Dev\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe",
	[int]$WaitMinutes = 15
)
$ErrorActionPreference = "Stop"
if ($Project -eq "") { $Project = Split-Path -Parent $PSScriptRoot }
$TokenFile = Join-Path $env:LOCALAPPDATA "zera\godot_mcp_bridge.token"
$Lock = "C:\Users\Dev\Desktop\zera-assets\locks\godot.lock"

if (-not (Test-Path $TokenFile)) { throw "Нет токена моста. Сначала: tools/godot_mcp_setup.ps1" }
if (-not (Test-Path (Join-Path $Project "addons\godot_mcp\plugin.cfg"))) { throw "В $Project нет addons/godot_mcp" }

# Очередь на общую блокировку (mkdir атомарен), как в godot_exclusive.ps1.
$deadline = (Get-Date).AddMinutes($WaitMinutes)
while ($true) {
	try { New-Item -ItemType Directory -Path $Lock -ErrorAction Stop | Out-Null; break } catch {
		if ((Test-Path $Lock) -and ((Get-Date) - (Get-Item $Lock).LastWriteTime).TotalMinutes -gt 20) { Remove-Item $Lock -Force -ErrorAction SilentlyContinue }
		if ((Get-Date) -gt $deadline) { throw "Блокировка Godot занята дольше $WaitMinutes мин (идёт оконный тест или бенч)." }
		Start-Sleep -Seconds 5
	}
}
try {
	$others = @(Get-Process -Name "Godot*" -ErrorAction SilentlyContinue)
	Write-Host "GODOT_EDITOR lock=taken other_godot_processes=$($others.Count) project=$Project"
	# Токен — только в окружении этого процесса и его потомков, не в системных переменных.
	$env:GODOT_MCP_BRIDGE_TOKEN = (Get-Content -Raw $TokenFile).Trim()
	# Вывод редактора (ошибки addon'ов, моста) — в tmp/ проекта, папка не в git.
	$log = Join-Path $Project "tmp\godot_editor.log"
	New-Item -ItemType Directory -Force (Split-Path -Parent $log) | Out-Null
	# Прямой CreateProcess, как у консольных запусков: Start-Process идёт через ShellExecute и может молча ждать
	# проверки SmartScreen.
	$psi = New-Object Diagnostics.ProcessStartInfo $Godot, "--editor --path `"$Project`" --log-file `"$log`""
	$psi.UseShellExecute = $false
	$psi.WorkingDirectory = $Project
	$p = [Diagnostics.Process]::Start($psi)
	Write-Host "GODOT_EDITOR pid=$($p.Id) — закройте редактор, чтобы снять блокировку"
	while (-not $p.WaitForExit(60000)) { (Get-Item $Lock).LastWriteTime = Get-Date }
} finally {
	Remove-Item $Lock -Force -ErrorAction SilentlyContinue
	Write-Host "GODOT_EDITOR closed, lock released"
}
