param([string]$cfgPath)
Add-Type -AssemblyName System.Windows.Forms | Out-Null
$b=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$w=$b.Width; $h=$b.Height
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
if($changed -eq 0){ Write-Host ("KLOAD-MATCH screen={0}x{1}" -f $w,$h); exit 0 }
[System.IO.File]::WriteAllLines($cfgPath,$out,[System.Text.Encoding]::Default)
Write-Host ("KLOAD-UPDATED screen={0}x{1} keys={2}" -f $w,$h,$changed)
