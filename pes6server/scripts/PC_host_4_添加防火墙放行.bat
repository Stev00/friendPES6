@echo off
rem 版本: v1.0 (2026-09-05)  zhangdansan(stevoo)
echo 【版本】 PC_host_4_添加防火墙放行 v1.0 (2026-09-05)
set "SELF=%~f0"
if not exist "%SELF%" (
  pushd "%~dp0" 2>nul
  set "SELF=%CD%\%~nx0"
  popd
)
:parse_args

if /i "%~1"=="/nopause" (

  set "NOPAUSE=1"

  shift

  goto parse_args

)

rem ---- 提权后工作目录会变成 System32, 回到脚本真实目录 ----

pushd "%~dp0" 2>nul

if /i "%~1"=="/yes" (

  set "AUTOYES=1"

  shift

  goto parse_args

)

net session >nul 2>&1
if errorlevel 1 (
echo 正在请求管理员权限...
  popd
  powershell -NoProfile -Command "Start-Process -Verb RunAs -FilePath cmd.exe -ArgumentList '/k','\"%SELF%\" /nopause /yes'"
  exit /b
)
netsh advfirewall firewall delete rule name="PES6-SERVER-TCP" >nul 2>&1
netsh advfirewall firewall delete rule name="PES6-SERVER-UDP" >nul 2>&1
rem ---- 清除历史遗留的程序级阻止规则(弹窗点取消/X 会生成, 优先级高于端口放行) ----
netsh advfirewall firewall delete rule name="twistd" >nul 2>&1
netsh advfirewall firewall delete rule name="pes6.exe" >nul 2>&1
netsh advfirewall firewall delete rule name="python.exe" >nul 2>&1
netsh advfirewall firewall delete rule name="stun-server" >nul 2>&1
netsh advfirewall firewall delete rule name="GoalServer6 Alpha" >nul 2>&1
rem ---- 程序级允许规则(双保险, 且此后不再弹询问窗) ----
if exist "%~dp0..\fiveserver\twistd.exe" netsh advfirewall firewall add rule name="PES6-app-twistd" dir=in action=allow program="%~dp0..\fiveserver\twistd.exe" profile=any >nul
set "PYPATH="
for /f "delims=" %%i in ('where python 2^>nul') do if not defined PYPATH set "PYPATH=%%i"
if defined PYPATH netsh advfirewall firewall add rule name="PES6-app-python" dir=in action=allow program="%PYPATH%" profile=any >nul
if exist "%~dp0..\..\PES6.exe" netsh advfirewall firewall add rule name="PES6-app-pes6" dir=in action=allow program="%~dp0..\..\PES6.exe" profile=any >nul
netsh advfirewall firewall add rule name="PES6-SERVER-TCP" dir=in action=allow protocol=TCP localport=8190,8191,10881,20200,20201,20202,20203 profile=any >nul
netsh advfirewall firewall add rule name="PES6-SERVER-UDP" dir=in action=allow protocol=UDP localport=3478,3479,5730-5740 profile=any >nul
echo ===== 添加后验证 =====
netsh advfirewall firewall show rule name="PES6-SERVER-TCP" 2>&1 | findstr "PES6-SERVER-TCP" >nul && (
echo 【OK】 PES6-SERVER-TCP 规则已生效
) || (
echo 【X】 PES6-SERVER-TCP 添加失败
)
netsh advfirewall firewall show rule name="PES6-SERVER-UDP" 2>&1 | findstr "PES6-SERVER-UDP" >nul && (
echo 【OK】 PES6-SERVER-UDP 规则已生效
) || (
echo 【X】 PES6-SERVER-UDP 添加失败
)
netsh advfirewall firewall show rule name="PES6-app-twistd" 2>&1 | findstr "PES6-app-twistd" >nul && (
echo 【OK】 twistd 程序放行已生效
) || (
echo 【X】 twistd 程序放行失败
)
echo 【完成】 防火墙放行结束
if not defined NOPAUSE pause
