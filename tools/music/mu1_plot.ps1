param([string]$Log = 'design/tasks/reports/mu1_timeline.log')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$rows = @(Get-Content -Encoding UTF8 $Log | Where-Object { $_.StartsWith('MUSIC {') } | ForEach-Object { $_.Substring(6) | ConvertFrom-Json })
if ($rows.Count -lt 2 -or $rows[-1].time -lt 590) { throw 'Нужен полный MUSIC-лог --sim=600.' }
$bitmap = New-Object Drawing.Bitmap 1600,760
$g = [Drawing.Graphics]::FromImage($bitmap)
$g.Clear([Drawing.Color]::White)
$g.SmoothingMode = 'AntiAlias'
$font = New-Object Drawing.Font 'Segoe UI',11
$small = New-Object Drawing.Font 'Segoe UI',9
$title = New-Object Drawing.Font 'Segoe UI',17
$ink = [Drawing.Brushes]::Black
$palette = @{scout='#a6b8ba';build='#d8b367';peak='#bc6259';decay='#b69e7a';relax='#b9c6b5';calm='#b9c6b5';evac='#6c97ac';boss='#8d6e95'}
$tracks = @($rows.track | Sort-Object -Unique)
$starts = @()
$lastSerial = -1
foreach ($row in $rows) {
    if ($row.track_serial -ne $lastSerial) { $starts += $row; $lastSerial = $row.track_serial }
}
$changes = $starts.Count - 1
function X([double]$t) { return [single](150 + $t / 600 * 1400) }
function Label([string]$text, [single]$x, [single]$y, $f=$font) { $g.DrawString($text,$f,$ink,$x,$y) }
function Band([string]$property,[single]$y,[single]$height,[bool]$events=$false) {
    $start = 0
    for ($i=1; $i -le $rows.Count; $i++) {
        if ($i -lt $rows.Count -and $rows[$i].$property -eq $rows[$start].$property) { continue }
        $value = $rows[$start].$property
        $end = if ($i -lt $rows.Count) { $rows[$i].time } else { $rows[-1].time }
        $left = X $rows[$start].time
        $width = (X $end) - $left
        if ((-not $events -or $value) -and $width -gt 0) {
            $color = if ($events) {'#bc6259'} else {$palette[$value]}
            $brush = New-Object Drawing.SolidBrush ([Drawing.ColorTranslator]::FromHtml($color))
            $g.FillRectangle($brush,$left,$y,[single]$width,$height)
            $brush.Dispose()
            $code = if ($value -eq 'boss') {'X'} else {$value.ToString().Substring(0,1).ToUpper()}
            if (-not $events -and $width -gt 10) { Label $code ($left+$width/2-4) ($y+$height/2-9) $small }
        }
        $start=$i
    }
}
Label 'MU1 — музыка и бой / SIM 600 секунд' 30 18 $title
Label ("Фактический SIM, headless. Смен трека: $changes; фазы меняют громкость и фильтр. Метки: конец / тревога / босс / эвак / затишье→пик.") 30 51 $small
for ($t=0; $t -le 600; $t+=60) {
    $x = X $t
    $g.DrawLine([Drawing.Pens]::LightGray,$x,85,$x,470)
    Label ('{0}:00' -f ($t/60)) ($x-12) 474 $small
}
Label 'Режиссёр' 20 97
Band 'phase' 94 36
Label 'Тревога' 20 151
Band 'alarm' 148 20 $true
Label 'Босс / анонс' 20 184
Band 'boss' 181 20 $true
Label 'Эвакуация' 20 217
Band 'evac' 214 20 $true
Label 'Интенсивность' 20 269
Band 'state' 264 40
Label 'Трек (номер)' 20 352
$reasonNames = @{begin='старт';ended='конец';alarm='тревога';boss='босс';evac='эвак';long_quiet_peak='затишье→пик'}
$lastLabelTime = -100
$lowerLabel = $false
foreach ($row in $starts) {
    $lowerLabel = ($row.time - $lastLabelTime -lt 30) -and -not $lowerLabel
    $lastLabelTime = $row.time
    $number = [array]::IndexOf($tracks,$row.track)+1
    $g.DrawLine([Drawing.Pens]::Gray,(X $row.time),340,(X $row.time),379)
    Label "$number" ((X $row.time)+3) $(if ($lowerLabel) { 366 } else { 350 }) $small
    Label $reasonNames[$row.track_reason] ((X $row.time)+3) $(if ($lowerLabel) { 331 } else { 315 }) $small
}
Label 'Music, dB *' 20 413
Label '-1' 124 391 $small
Label '-7' 124 409 $small
$points=New-Object 'Collections.Generic.List[Drawing.PointF]'
foreach ($row in $rows) { $points.Add((New-Object Drawing.PointF (X $row.time),([single](397-$row.db*3)))) }
$pen=New-Object Drawing.Pen ([Drawing.Color]::FromArgb(62,92,110)),2
$g.DrawLines($pen,$points.ToArray())
Label '* Цель усиления плееров до шины Music (-7 dB), не RMS записи. Фильтр: calm 3.2 kHz → peak 20.5 kHz.' 150 510 $small
for ($i=0; $i -lt $tracks.Count; $i++) {
    Label ('{0,2}  {1}' -f ($i+1),$tracks[$i]) (150+700*($i%2)) (548+26*[math]::Floor($i/2)) $small
}
Label 'Режиссёр: S scout · B build · P peak · D decay · R relax. Музыка: C calm · B build · P peak · D decay · E evac · X boss.' 150 738 $small
$bitmap.Save((Join-Path $PWD 'design/tasks/reports/mu1_timeline.png'),[Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bitmap.Dispose(); $font.Dispose(); $small.Dispose(); $title.Dispose(); $pen.Dispose()
Write-Output ('MUSIC_TIMELINE samples={0} seconds={1} tracks={2} track_changes={3}' -f $rows.Count,$rows[-1].time,$tracks.Count,$changes)
foreach ($row in $starts) { Write-Output ('MUSIC_START time={0} track={1} entry={2} reason={3}' -f $row.time,$row.track,$row.entry,$row.track_reason) }
