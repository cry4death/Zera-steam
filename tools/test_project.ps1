# Единая проверка проекта ZERA для Opus и Codex. Запуск из корня worktree:
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools/test_project.ps1 [-Suite fast|full|gdunit|bench]
# fast   — импорт + GdUnit4 + быстрые штатные проверки (--meta-test, --gore-checks). Во время итераций.
# full   — импорт + GdUnit4 + все проверки из AGENTS.md «Проверки перед сдачей». Перед сдачей задачи.
# gdunit — импорт + только GdUnit4 (res://tests).
# bench  — замер --loadout --bench=500 x3 через общую блокировку Godot, медиана avg_fps. Только оконный.
# Все наборы, кроме bench, — headless, окно Godot не открывается и блокировка не нужна.
# Логи и отчёты: tmp/test_results/<время>/ (папка tmp/ не в git). Код выхода 0 — всё прошло.
param(
	[ValidateSet("fast", "full", "gdunit", "bench")]
	[string]$Suite = "fast",
	[string]$Godot = "",
	[string]$Out = "",
	[switch]$SkipImport,
	[int]$TimeoutSec = 1200
)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
if ($Godot -eq "") {
	$Godot = if ($env:ZERA_GODOT) { $env:ZERA_GODOT } else { "C:\Users\Dev\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" }
}
$Lock = "C:\Users\Dev\Desktop\zera-assets\locks\godot_exclusive.ps1"
$ExpectedVersion = "4.7.2.stable"
if ($Out -eq "") { $Out = Join-Path $Root ("tmp\test_results\" + (Get-Date -Format "yyyyMMdd-HHmmss")) }
New-Item -ItemType Directory -Force $Out | Out-Null
# Godot не должен импортировать отчёты как ресурсы.
$resultsRoot = Join-Path $Root "tmp\test_results"
if ((Split-Path -Parent $Out) -eq $resultsRoot -and -not (Test-Path (Join-Path $resultsRoot ".gdignore"))) {
	New-Item -ItemType File (Join-Path $resultsRoot ".gdignore") | Out-Null
}
$results = New-Object System.Collections.Generic.List[object]
$gitBefore = @(git -C $Root status --porcelain --untracked-files=no 2>$null)

# Запуск процесса с логом stdout+stderr и таймаутом. Возвращает код выхода (124 — таймаут).
function Invoke-Logged([string]$Name, [string]$Exe, [string]$Arguments) {
	$log = Join-Path $Out "$Name.log"
	$err = Join-Path $Out "$Name.stderr.log"
	$sw = [Diagnostics.Stopwatch]::StartNew()
	$p = Start-Process -FilePath $Exe -ArgumentList $Arguments -WorkingDirectory $Root -NoNewWindow -PassThru `
		-RedirectStandardOutput $log -RedirectStandardError $err
	$null = $p.Handle
	$code = 0
	if (-not $p.WaitForExit($TimeoutSec * 1000)) {
		try { $p.Kill() } catch {}
		$code = 124
	} else {
		$p.WaitForExit()
		$code = $p.ExitCode
	}
	if ((Test-Path $err) -and (Get-Item $err).Length -gt 0) { Get-Content $err | Add-Content $log }
	Remove-Item $err -ErrorAction SilentlyContinue
	return @{ Code = [int]$code; Log = $log; Seconds = [math]::Round($sw.Elapsed.TotalSeconds) }
}

function Add-Result([string]$Name, [bool]$Ok, [string]$Detail, $Run) {
	$results.Add([pscustomobject]@{ Check = $Name; Ok = $Ok; Detail = $Detail; Seconds = $(if ($Run) { $Run.Seconds } else { 0 }) })
	$mark = if ($Ok) { "OK  " } else { "FAIL" }
	Write-Host ("[{0}] {1}  {2}" -f $mark, $Name, $Detail)
}

# Итоговая строка проверки из лога (checks=…, ok=…), чтобы не читать весь лог.
function Get-Verdict([string]$Log) {
	$line = Select-String -Path $Log -Pattern "checks=|ok=(true|false)|TESTRESULT|SIM 10:00" -ErrorAction SilentlyContinue | Select-Object -Last 1
	if ($line) { return $line.Line.Trim() }
	return ""
}

# 1. Godot доступен и той версии, на которую рассчитан проект.
if (-not (Test-Path $Godot)) {
	Add-Result "godot" $false "не найден: $Godot (укажите -Godot или ZERA_GODOT)" $null
	exit 2
}
$version = (& $Godot --version 2>$null | Select-Object -Last 1)
if ($version -notlike "$ExpectedVersion*") {
	Add-Result "godot" $false "версия '$version', ожидается $ExpectedVersion" $null
	exit 2
}
Add-Result "godot" $true $version $null

# 2. Импорт ресурсов. Godot возвращает 0 и при ошибках разбора, поэтому смотрим лог.
if (-not $SkipImport) {
	$run = Invoke-Logged "import" $Godot "--headless --path . --import"
	$bad = @(Select-String -Path $run.Log -Pattern "SCRIPT ERROR|Parse Error|Failed to load script" -ErrorAction SilentlyContinue)
	Add-Result "import" ($run.Code -eq 0 -and $bad.Count -eq 0) ("exit={0} script_errors={1}" -f $run.Code, $bad.Count) $run
}

if ($Suite -eq "bench") {
	# Оконный замер — только через общую блокировку, по одному на машину.
	if (-not (Test-Path $Lock)) { Add-Result "bench" $false "нет скрипта блокировки $Lock" $null; exit 1 }
	$fps = @()
	for ($i = 1; $i -le 3; $i++) {
		$run = Invoke-Logged "bench_$i" "powershell.exe" ("-NoProfile -ExecutionPolicy Bypass -File `"$Lock`" `"$Godot`" --disable-vsync --path . -- --loadout --bench=500 --fresh-save")
		$others = Select-String -Path $run.Log -Pattern "other_godot_processes=(\d+)" | Select-Object -First 1
		$line = Select-String -Path $run.Log -Pattern "^BENCH .*avg_fps=([\d.]+)" | Select-Object -Last 1
		# в параллельном режиме блокировки (locks\parallel.on) замер шумный, но засчитывается
		$parallel = Select-String -Path $run.Log -Pattern "mode=parallel" -Quiet
		$clean = $parallel -or ($others -and $others.Matches[0].Groups[1].Value -eq "0")
		if ($line) { $fps += [double]$line.Matches[0].Groups[1].Value }
		Add-Result "bench_$i" ($run.Code -eq 0 -and $line -and $clean) ("exit={0} {1}{3} {2}" -f $run.Code, $(if ($others) { $others.Matches[0].Value } else { "lock?" }), $(if ($line) { $line.Line.Trim() } else { "нет строки BENCH" }), $(if ($parallel) { " (параллельно, шумно)" } else { "" })) $run
	}
	if ($fps.Count -gt 0) { Write-Host ("BENCH median avg_fps={0}" -f (($fps | Sort-Object)[[int][math]::Floor($fps.Count / 2)])) }
} else {
	# 3. GdUnit4: юнит-тесты в res://tests. Без флагов автозагрузка Meta читает (и может переписать) настоящий
	# профиль, а --fresh-save включает её тестовый логгер, который на первой ошибке завершает процесс посреди прогона.
	# Поэтому — отдельный несуществующий файл профиля: Meta стартует с чистого профиля и ничего не пишет.
	$report = Join-Path $Out "gdunit"
	$profile = "res://tmp/test_results/gdunit_profile.json"
	$args4 = "--headless --path . -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -c -a res://tests -rd `"$report`" -rc 1 -- --save-file=$profile"
	$run = Invoke-Logged "gdunit" $Godot $args4
	Remove-Item (Join-Path $Root "tmp\test_results\gdunit_profile.json*") -ErrorAction SilentlyContinue
	$xml = Get-ChildItem -Path $report -Recurse -Filter "results.xml" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime | Select-Object -Last 1
	if ($null -eq $xml) {
		Add-Result "gdunit" $false ("exit={0}, results.xml не создан — тесты не запустились" -f $run.Code) $run
	} else {
		[xml]$doc = Get-Content -Raw -Encoding UTF8 $xml.FullName
		$cases = @($doc.SelectNodes("//testcase"))
		$failed = @($doc.SelectNodes("//testcase[failure or error]")).Count
		$skipped = @($doc.SelectNodes("//testcase[skipped]")).Count
		$ok = $run.Code -eq 0 -and $cases.Count -gt 0 -and $failed -eq 0 -and $skipped -eq 0
		Add-Result "gdunit" $ok ("exit={0} tests={1} failed={2} skipped={3} report={4}" -f $run.Code, $cases.Count, $failed, $skipped, (Split-Path -Parent $xml.FullName)) $run
	}

	# 4. Штатные проверки ZERA (код выхода 1 при любой ошибке).
	$legacy = @("--meta-test", "--fresh-save --gore-checks")
	if ($Suite -eq "full") {
		$legacy = @("--meta-test", "--campaign-test", "--q1-test --fresh-save", "--fresh-save --gore-checks",
			"--obstacles-test --fresh-save", "--activities-test --fresh-save", "--sim=600 --fresh-save")
	}
	if ($Suite -ne "gdunit") {
		foreach ($flags in $legacy) {
			$name = ($flags -replace "[^a-z0-9]+", "_").Trim("_")
			$run = Invoke-Logged $name $Godot "--headless --path . -- $flags"
			Add-Result $flags ($run.Code -eq 0) ("exit={0} {1}" -f $run.Code, (Get-Verdict $run.Log)) $run
		}
	}
}

# 5. Итог. Проверки не должны менять файлы под git (--sim=600 известно перезаписывает отчёт hd1_trace_after.json).
$gitAfter = @(git -C $Root status --porcelain --untracked-files=no 2>$null)
$touched = @($gitAfter | Where-Object { $gitBefore -notcontains $_ })
if ($touched.Count -gt 0) {
	Write-Host ("WARN проверки изменили файлы под git: {0}" -f (($touched | ForEach-Object { $_.Substring(3) }) -join ", "))
}
$results | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $Out "summary.csv")
$failedCount = @($results | Where-Object { -not $_.Ok }).Count
$summary = "ZERA_TEST suite={0} checks={1} failed={2} out={3}" -f $Suite, $results.Count, $failedCount, $Out
$summary | Set-Content -Encoding UTF8 (Join-Path $Out "summary.txt")
Write-Host $summary
if ($failedCount -gt 0) { exit 1 }
exit 0
