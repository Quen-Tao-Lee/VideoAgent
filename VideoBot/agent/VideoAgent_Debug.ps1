$ErrorActionPreference = "Stop"

$IN_DIR = "C:\VideoBot\in"
$OUT_DIR = "C:\VideoBot\out"
$DONE_DIR = "C:\VideoBot\done"
$TMP_DIR = "C:\VideoBot\temp"
$LOG_DIR = "C:\VideoBot\logs"

function Log($msg){
  $logFile = Join-Path $LOG_DIR ("agent_" + (Get-Date -Format "yyyyMMdd") + ".log")
  $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $logLine = "[$timestamp] $msg"
  Write-Host $logLine
  $logLine | Add-Content -Path $logFile -Encoding UTF8
}

Write-Host "== VideoAgent DEBUG Running ==" -ForegroundColor Cyan
Write-Host "Monitoring directory: $IN_DIR" -ForegroundColor Cyan
Log "Agent started in DEBUG mode"

if(-not (Test-Path $IN_DIR)){
  Log "ERROR: Input directory does not exist: $IN_DIR"
  throw "Input directory missing"
}

$loopNumber = 0
while($true){
  $loopNumber++
  Write-Host ""
  Write-Host "=== LOOP $loopNumber ===" -ForegroundColor Yellow
  Log "Loop $loopNumber: Starting scan"
  
  # List ALL files first
  try{
    $allFiles = Get-ChildItem $IN_DIR -ErrorAction SilentlyContinue
    Write-Host "Total files in directory: $($allFiles.Count)" -ForegroundColor Cyan
    Log "Total files found: $($allFiles.Count)"
    
    foreach($file in $allFiles){
      $sizeKB = [math]::Round($file.Length / 1024, 2)
      Write-Host "  - $($file.Name) ($sizeKB KB)" -ForegroundColor White
      Log "  File: $($file.Name) Size: $($file.Length) bytes"
    }
  } catch {
    Write-Host "ERROR listing files: $($_.Exception.Message)" -ForegroundColor Red
    Log "ERROR listing files: $($_.Exception.Message)"
  }
  
  # Find video files specifically
  try{
    $videoFiles = Get-ChildItem $IN_DIR -File | Where-Object { $_.Extension -match '\.(mp4|mov|mkv|m4v)$' }
    Write-Host "Video files detected: $($videoFiles.Count)" -ForegroundColor Green
    Log "Video files found: $($videoFiles.Count)"
    
    foreach($video in $videoFiles){
      $sizeMB = [math]::Round($video.Length / 1MB, 2)
      Write-Host "  VIDEO: $($video.Name) ($sizeMB MB)" -ForegroundColor Green
      Log "  Video: $($video.Name) Size: $($video.Length) bytes"
    }
    
    if($videoFiles.Count -gt 0){
      Write-Host "Found videos! Processing should start..." -ForegroundColor Green
      Log "Videos detected - processing should begin"
    } else {
      Write-Host "No video files found, waiting..." -ForegroundColor Yellow
      Log "No videos found, continuing to monitor"
    }
    
  } catch {
    Write-Host "ERROR finding videos: $($_.Exception.Message)" -ForegroundColor Red
    Log "ERROR finding videos: $($_.Exception.Message)"
  }
  
  Write-Host "Waiting 5 seconds before next scan..." -ForegroundColor Gray
  Start-Sleep -Seconds 5
}