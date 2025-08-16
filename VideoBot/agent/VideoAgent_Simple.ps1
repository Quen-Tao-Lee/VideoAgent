# VideoAgent - 超简版，零错误
param()

# 固定路径配置
$InDir = "C:\VideoBot\in"
$OutDir = "C:\VideoBot\out" 
$DoneDir = "C:\VideoBot\done"
$TempDir = "C:\VideoBot\temp"
$LogDir = "C:\VideoBot\logs"

# 确保目录存在
@($InDir, $OutDir, $DoneDir, $TempDir, $LogDir) | ForEach-Object {
    if(-not (Test-Path $_)) { New-Item -Path $_ -ItemType Directory -Force | Out-Null }
}

function Write-SimpleLog {
    param($msg)
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMsg = "[$time] $msg"
    Write-Host $logMsg -ForegroundColor Green
}

function Process-SimpleVideo {
    param($inputFile)
    
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($inputFile)
    $outputFile = Join-Path $OutDir ($fileName + "_converted.mp4")
    $doneFile = Join-Path $DoneDir ([System.IO.Path]::GetFileName($inputFile))
    
    Write-SimpleLog "Processing: $([System.IO.Path]::GetFileName($inputFile))"
    
    try {
        # 超简单的FFmpeg命令
        $cmd = "ffmpeg -i `"$inputFile`" -c:v libx264 -preset fast -crf 23 -c:a aac `"$outputFile`" -y"
        
        Write-SimpleLog "Running: $cmd"
        
        # 执行命令
        Invoke-Expression "cmd /c $cmd"
        
        # 检查是否成功
        if(Test-Path $outputFile) {
            # 移动原文件
            Move-Item $inputFile $doneFile -Force
            Write-SimpleLog "SUCCESS: Created $([System.IO.Path]::GetFileName($outputFile))"
            return $true
        } else {
            Write-SimpleLog "ERROR: Output file not created"
            return $false
        }
    } catch {
        Write-SimpleLog "ERROR: $($_.Exception.Message)"
        return $false
    }
}

# 主循环
Write-Host "VideoAgent Simple - Starting..." -ForegroundColor Cyan
Write-Host "Monitoring: $InDir" -ForegroundColor Cyan

while($true) {
    try {
        # 查找视频文件
        $videoFiles = Get-ChildItem $InDir -File | Where-Object { $_.Extension -match "\.(mp4|mov|mkv|m4v)$" }
        
        if($videoFiles.Count -gt 0) {
            Write-SimpleLog "Found $($videoFiles.Count) video files"
            
            foreach($file in $videoFiles) {
                Write-SimpleLog "Processing: $($file.Name)"
                
                # 等待文件稳定
                $size1 = $file.Length
                Start-Sleep -Seconds 3
                $file.Refresh()
                $size2 = $file.Length
                
                if($size1 -eq $size2) {
                    # 文件稳定，开始处理
                    $result = Process-SimpleVideo $file.FullName
                    if($result) {
                        Write-Host "✅ SUCCESS: $($file.Name)" -ForegroundColor Green
                    } else {
                        Write-Host "❌ FAILED: $($file.Name)" -ForegroundColor Red
                    }
                } else {
                    Write-SimpleLog "File still being written: $($file.Name)"
                }
            }
        } else {
            Write-Host "." -NoNewline -ForegroundColor Gray
        }
        
    } catch {
        Write-SimpleLog "Loop error: $($_.Exception.Message)"
    }
    
    Start-Sleep -Seconds 5
}