@echo off
rem 版本: v1.0 (2026-09-05)  zhangdansan(stevoo)
echo [版本] PC_host_4_添加防火墙放行 v1.0 (2026-09-05)
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
  powershell -NoProfile -Command "Start-Process -Verb RunAs -FilePath cmd.exe -ArgumentList '/k','\"%SELF%\" /nopause /yes'"
  exit /b
)
netsh advfirewall firewall delete rule name="PES6-SERVER-TCP" >nul 2>&1
netsh advfirewall firewall delete rule name="PES6-SERVER-UDP" >nul 2>&1
netsh advfirewall firewall add rule name="PES6-SERVER-TCP" dir=in action=allow protocol=TCP localport=8190,8191,10881,20200,20201,20202,20203 profile=any >nul
netsh advfirewall firewall add rule name="PES6-SERVER-UDP" dir=in action=allow protocol=UDP localport=3478,3479,5730-5740 profile=any >nul
echo ===== 添加后验证 =====
netsh advfirewall firewall show rule name="PES6-SERVER-TCP" 2>&1 | findstr "PES6-SERVER-TCP" >nul && (
  echo   [OK] PES6-SERVER-TCP 规则已生效
) || (
  echo   [X] PES6-SERVER-TCP 添加失败
)
netsh advfirewall firewall show rule name="PES6-SERVER-UDP" 2>&1 | findstr "PES6-SERVER-UDP" >nul && (
  echo   [OK] PES6-SERVER-UDP 规则已生效
) || (
  echo   [X] PES6-SERVER-UDP 添加失败
)
echo [完成] 防火墙放行结束
if not defined NOPAUSE pause
