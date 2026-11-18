<#
.SYNOPSIS
Replaces the walkthrough on the judges' page with a recording pulled from the headset, then publishes it.

.EXAMPLE
powershell -NoProfile -ExecutionPolicy Bypass -File tools/Update-Recording.ps1 -Take <path to Recordings/Quest/<take>> -PosterFrame 0070_069.00s.jpg
#>
param(
    # A take folder made by Pull-QuestRecordings.ps1 (it holds recording.mp4 and index.json).
    [Parameter(Mandatory = $true)][string]$Take,
    # Optional: a file name from the take's frames folder to use as the video's cover image.
    [string]$PosterFrame
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$media = Join-Path $repo 'media'

$index = Get-Content (Join-Path $Take 'index.json') -Raw | ConvertFrom-Json
$name = Split-Path $Take -Leaf
if ($name -notmatch '_(\d{8})_(\d{6})_\d{3}Z_') { throw "Cannot read the recording time from '$name'." }
$utc = [datetime]::ParseExact($Matches[1] + $Matches[2], 'yyyyMMddHHmmss', [Globalization.CultureInfo]::InvariantCulture)

Copy-Item (Join-Path $Take 'recording.mp4') (Join-Path $media 'walkthrough.mp4') -Force
if ($PosterFrame) { Copy-Item (Join-Path $Take "frames/$PosterFrame") (Join-Path $media 'poster.jpg') -Force }

$json = "{`n  `"recordedUtc`": `"$($utc.ToString('yyyy-MM-ddTHH:mm:ss'))Z`",`n  `"seconds`": $([math]::Round([double]$index.durationSeconds))`n}`n"
[IO.File]::WriteAllText((Join-Path $media 'recording.json'), $json, (New-Object Text.UTF8Encoding $false))

git -C $repo add media
git -C $repo commit -m "Show the walkthrough recorded $($utc.ToString('yyyy-MM-dd HH:mm')) UTC"
git -C $repo push
Write-Host "Published. The page updates within a few minutes: https://geoscout-ai.github.io/MarketScout-VR/"
