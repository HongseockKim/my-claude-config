# OtoMON-K Claude Code 설정 스크립트
# 관리자 권한 PowerShell에서 실행 필요

param(
    [string]$ProjectPath = "C:\Users\user\IdeaProjects\OtoMON-K",
    [string]$ConfigPath = "C:\Users\user\my-claude-configs\OtoMON-K"
)

Write-Host "=== OtoMON-K Claude Code Setup ===" -ForegroundColor Cyan

# 프로젝트 폴더 확인
if (-not (Test-Path $ProjectPath)) {
    Write-Host "Error: Project path not found: $ProjectPath" -ForegroundColor Red
    exit 1
}

# 설정 폴더 확인
if (-not (Test-Path $ConfigPath)) {
    Write-Host "Error: Config path not found: $ConfigPath" -ForegroundColor Red
    Write-Host "Run: git clone https://github.com/HongseockKim/my-claude-config.git my-claude-configs" -ForegroundColor Yellow
    exit 1
}

Set-Location $ProjectPath

# 기존 .claude 처리
if (Test-Path ".claude") {
    $item = Get-Item ".claude" -Force
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        Write-Host ".claude symlink already exists" -ForegroundColor Green
    } else {
        Write-Host "Removing existing .claude folder..." -ForegroundColor Yellow
        Remove-Item ".claude" -Recurse -Force
        cmd /c mklink /J .claude "$ConfigPath\.claude"
        Write-Host ".claude junction created" -ForegroundColor Green
    }
} else {
    cmd /c mklink /J .claude "$ConfigPath\.claude"
    Write-Host ".claude junction created" -ForegroundColor Green
}

# 기존 .mcp.json 처리
if (Test-Path ".mcp.json") {
    $item = Get-Item ".mcp.json" -Force
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        Write-Host ".mcp.json symlink already exists" -ForegroundColor Green
    } else {
        Write-Host "Removing existing .mcp.json file..." -ForegroundColor Yellow
        Remove-Item ".mcp.json" -Force
        cmd /c mklink .mcp.json "$ConfigPath\.mcp.json"
        Write-Host ".mcp.json symlink created" -ForegroundColor Green
    }
} else {
    cmd /c mklink .mcp.json "$ConfigPath\.mcp.json"
    Write-Host ".mcp.json symlink created" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Setup Complete ===" -ForegroundColor Green
Write-Host "Restart Claude Code to apply changes" -ForegroundColor Cyan
