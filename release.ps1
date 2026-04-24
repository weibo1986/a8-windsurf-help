param(
  [Parameter(Mandatory = $true)]
  [string]$Version,

  [Parameter(Mandatory = $true)]
  [string]$VsixPath,

  [string]$Announcement,

  [string]$Tagline,

  [switch]$Push
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $projectRoot 'version.json'
$plugDir = Join-Path $projectRoot 'plug'
$targetVsix = Join-Path $plugDir 'a8-windsurf-helper-latest.vsix'

if (-not (Test-Path $VsixPath)) {
  throw "找不到 VSIX 文件: $VsixPath"
}

if (-not (Test-Path $configPath)) {
  throw "找不到配置文件: $configPath"
}

$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
$config.version = $Version
$config.downloadUrl = '/plug/a8-windsurf-helper-latest.vsix'

if ($PSBoundParameters.ContainsKey('Announcement')) {
  $config.announcement = $Announcement
}

if ($PSBoundParameters.ContainsKey('Tagline')) {
  $config.tagline = $Tagline
}

New-Item -ItemType Directory -Force -Path $plugDir | Out-Null
Copy-Item -Path $VsixPath -Destination $targetVsix -Force

(($config | ConvertTo-Json -Depth 10) + "`n") | Set-Content -Path $configPath -Encoding UTF8

Write-Host "已更新 version.json -> $Version"
Write-Host "已复制插件 -> $targetVsix"

if ($Push) {
  Push-Location $projectRoot
  try {
    & git add .
    if ($LASTEXITCODE -ne 0) { throw 'git add 失败' }

    & git commit -m "release $Version"
    if ($LASTEXITCODE -ne 0) { throw 'git commit 失败' }

    & git push
    if ($LASTEXITCODE -ne 0) { throw 'git push 失败' }
  }
  finally {
    Pop-Location
  }
}
