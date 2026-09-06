param([string]$cfgPath)
$ms = Get-WmiObject Win32_VideoController | Where-Object { $_.CurrentHorizontalResolution } | ForEach-Object { "{0}x{1}" -f $_.CurrentHorizontalResolution, $_.CurrentVerticalResolution } | Sort-Object -Unique
if(-not $ms){ Write-Host "KLOAD-SKIP no-resolution-detected"; exit 1 }
if($ms -isnot [array]){ $ms = @($ms) }
if($ms.Count -gt 1){
  Write-Host "检测到多个显示器分辨率:"
  $i=1; foreach($m in $ms){ Write-Host ("  "+$i+") "+$m); $i++ }
  $sel = Read-Host "请输入序号选择游戏画面使用的分辨率(直接回车=1)"
  if(-not $sel){ $sel = "1" }
  $sel = [int]$sel
  $res = $ms[$sel-1]
} else {
  $res = $ms[0]
  Write-Host ("检测到屏幕分辨率: "+$res)
}
$parts = $res.Split("x"); $w = $parts[0]; $h = $parts[1]
$lines=[System.IO.File]::ReadAllLines($cfgPath)
$map=@{ "dx.fullscreen.width"="$w"; "dx.fullscreen.height"="$h"; "internal.resolution.width"="$w"; "internal.resolution.height"="$h" }
$changed=0; $out=@()
foreach($l in $lines){
  $done=$false
  foreach($k in $map.Keys){
    if($l -match ('^'+[regex]::Escape($k)+'[ ]*=')){
      if($l.Trim() -ne ($k+' = '+$map[$k])){ $changed++ }
      $out+=($k+" = "+$map[$k]); $done=$true; break
    }
  }
  if(-not $done){ $out+=$l }
}
if($changed -eq 0){ Write-Host ("KLOAD-MATCH screen="+$res); exit 0 }
[System.IO.File]::WriteAllLines($cfgPath,$out,[System.Text.Encoding]::Default)
Write-Host ("KLOAD-UPDATED screen="+$res+" keys="+$changed)
