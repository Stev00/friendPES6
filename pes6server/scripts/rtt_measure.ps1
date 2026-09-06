param([string]$hostIp = "222.90.31.149")
$u = New-Object System.Net.Sockets.UdpClient
$u.Connect($hostIp, 5735)
$u.Client.ReceiveTimeout = 9000
$h = [System.Text.Encoding]::ASCII.GetBytes("RTT-HELLO")
[void]$u.Send($h, $h.Length)
$ep = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
$n = 0
try {
  while($true){
    $d = $u.Receive([ref]$ep)
    [void]$u.Send($d, $d.Length)
    $n++
  }
} catch {}
Write-Host ("【OK】 延迟测量完成: 回应 {0} 个探测包, 结果在主机日志" -f $n)
