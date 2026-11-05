# 长庚·东沙旧事 —— Windows 发布包构建脚本
#
# 用法（在工程根目录）:
#   powershell -ExecutionPolicy Bypass -File tools\package.ps1 -Version 0.28
#   powershell -ExecutionPolicy Bypass -File tools\package.ps1 -Version 0.28 -DryRun
#
# 产出:
#   <上级目录>\Changgeng-v<版本>\changgeng\...   解压后的可直接查看目录
#   <上级目录>\Changgeng-v<版本>.zip             分发包（内含 changgeng/ 一层）
#
# 与 v0.27 包保持一致: 不含 engine/、不含 .godot/，含 tests/ 与 previews/。
# 玩家需自备引擎，见 INSTALL.txt。

param(
	[string]$Version = "",
	[switch]$DryRun,
	[switch]$IncludeReferenceArt
)

# 参考图：只给美术定稿对照用，运行时并不加载（main.gd 只从 assets/art/hero.png
# 与 npcs.png 取图，其余场景由 world_ground.gd 程序化绘制）。
# 不含它们，包体约 26MB；含它们约 41MB。v0.27 发布包是不含的。
$referenceArt = @(
	"assets\art\village.png",
	"assets\art\village_large.png",
	"assets\art\wall.png",
	"assets\art\barracks.png",
	"assets\art\field.png",
	"assets\art\home.png"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if (-not $Version) {
	# 从最新的 DEVELOPMENT-vX.Y.md 推断当前版本
	$latest = Get-ChildItem -Path $root -Filter "DEVELOPMENT-v*.md" |
		ForEach-Object { if ($_.Name -match 'DEVELOPMENT-v(\d+\.\d+)\.md') { [pscustomobject]@{ Ver = $matches[1]; Num = [double]$matches[1] } } } |
		Sort-Object Num | Select-Object -Last 1
	$Version = $latest.Ver
	Write-Host "未指定 -Version，按最新开发日志推断为 v$Version" -ForegroundColor Yellow
}

$parent     = Split-Path -Parent $root
$staging    = Join-Path $parent "Changgeng-v$Version"
$inner      = Join-Path $staging "changgeng"
$zipPath    = Join-Path $parent "Changgeng-v$Version.zip"

# 不入包的内容
$excludeDirs  = @(".git", ".godot", ".godot-user", "engine", "_userdata", "build")
$excludeFiles = @("Thumbs.db", "desktop.ini")
$excludePaths = @("tests\_logs")

Write-Host "工程根目录: $root"
Write-Host "目标目录  : $staging"
Write-Host "目标压缩包: $zipPath"

if ($DryRun) {
	Write-Host "`n=== DRY RUN，不写入任何文件 ===" -ForegroundColor Cyan
}

if (-not $DryRun) {
	if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
	if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
	New-Item -ItemType Directory -Path $inner -Force | Out-Null
}

$copied = 0
$bytes  = 0
$skippedRef = 0

Get-ChildItem -Path $root -Recurse -File -Force | ForEach-Object {
	$rel = $_.FullName.Substring($root.Length + 1)
	$top = ($rel -split '\\')[0]

	if ($excludeDirs -contains $top) { return }
	if ($excludeFiles -contains $_.Name) { return }
	if ($Version -and $rel -like "*.zip") { return }
	if (-not $IncludeReferenceArt) {
		foreach ($r in $referenceArt) { if ($rel -eq $r) { $script:skippedRef++; return } }
	}
	foreach ($p in $excludePaths) { if ($rel -like "$p*") { return } }

	if ($DryRun) {
		$copied++
		$bytes += $_.Length
		return
	}

	$dest = Join-Path $inner $rel
	$dir  = Split-Path -Parent $dest
	if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
	Copy-Item -LiteralPath $_.FullName -Destination $dest -Force
	$copied++
	$bytes += $_.Length
}

$mb = [math]::Round($bytes / 1MB, 1)
Write-Host ("`n文件数: {0}   原始体积: {1} MB" -f $copied, $mb)
if ($skippedRef -gt 0) {
	Write-Host ("已跳过 {0} 张参考图（不参与运行）。需要一起打包请加 -IncludeReferenceArt" -f $skippedRef) -ForegroundColor DarkGray
}

if ($DryRun) {
	Write-Host "`n=== DRY RUN 结束，未生成文件 ===" -ForegroundColor Cyan
	return
}

Compress-Archive -Path $inner -DestinationPath $zipPath -CompressionLevel Optimal
$zipMb = [math]::Round((Get-Item $zipPath).Length / 1MB, 1)

Write-Host `
	("`n完成: {0}  ({1} MB)" -f $zipPath, $zipMb) -ForegroundColor Green
Write-Host "内部结构: changgeng/ 一层，不含 engine/"
Write-Host "提醒: 发版前确认 INSTALL.txt 与 DEVELOPMENT-v$Version.md 已同步更新。"
