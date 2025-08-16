$ErrorActionPreference = "Stop"

function Log($msg){
  $f = "C:\VideoBot\logs\doctor_{0}.log" -f (Get-Date -Format "yyyyMMdd")
  $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  "[$ts] $msg" | Tee-Object -FilePath $f -Append
}

Write-Host "== Environment Check ==" -ForegroundColor Cyan
Log "Starting diagnostics"

# 1) Directories
$dirs = "C:\VideoBot","C:\VideoBot\in","C:\VideoBot\out","C:\VideoBot\done","C:\VideoBot\temp","C:\VideoBot\logs","C:\VideoBot\agent"
foreach($d in $dirs){ 
  if(!(Test-Path $d)){ 
    New-Item $d -ItemType Directory -Force | Out-Null
    Log "Created directory: $d" 
  } 
}

# 2) Dependencies
function Must($tool){
  $p = (Get-Command $tool -ErrorAction SilentlyContinue).Source
  if(-not $p){ throw "Missing dependency: $tool not in PATH" }
  Log "Found $tool -> $p"
}
Must "ffmpeg"
Must "ffprobe"
Must "curl.exe"

# 3) OpenAI Key
if([string]::IsNullOrWhiteSpace($env:OPENAI_API_KEY)){
  Write-Host "[!] OPENAI_API_KEY not found" -ForegroundColor Yellow
  $k = Read-Host "Please enter your OpenAI API Key"
  if([string]::IsNullOrWhiteSpace($k)){ throw "OPENAI_API_KEY not set" }
  [Environment]::SetEnvironmentVariable("OPENAI_API_KEY",$k,"User")
  $env:OPENAI_API_KEY = $k
  Log "Set OPENAI_API_KEY to user environment"
}

Log "Diagnostics completed"
Write-Host "== Diagnostics completed, starting main Agent ==" -ForegroundColor Green