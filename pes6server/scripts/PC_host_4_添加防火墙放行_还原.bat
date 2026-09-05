@echo off
rem 版本: v1.0 (2026-09-05)  zhangdansan(stevoo)
echo 【版本】 PC_host_4_添加防火墙放行_还原 v1.0 (2026-09-05)
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
echo ===== 还原前检测 =====
netsh advfirewall firewall show rule name="PES6-SERVER-TCP" 2>&1 | findstr "PES6-SERVER-TCP" >nul && (
echo 【检测到】 规则存在: PES6-SERVER-TCP
) || (
echo 【未检测到】 规则不存在: PES6-SERVER-TCP
)
netsh advfirewall firewall show rule name="PES6-SERVER-UDP" 2>&1 | findstr "PES6-SERVER-UDP" >nul && (
echo 【检测到】 规则存在: PES6-SERVER-UDP
) || (
echo 【未检测到】 规则不存在: PES6-SERVER-UDP
)
echo 【信息】 防火墙配置文件状态,【还原脚本不改动它, 仅显示】:
netsh advfirewall show allprofiles state | findstr /c:"配置文件" /c:"状态"
echo.
if defined AUTOYES (
echo 【自动确认】 Y
  goto AY_1
)
choice /c YN /m "确认删除这两条放行规则? (Y=删除 N=取消)"
if not defined AUTOYES if errorlevel 2 (
echo 已取消, 未做任何修改
  if not defined NOPAUSE pause
  exit /b
)
:AY_1
echo 【执行】 删除规则...
netsh advfirewall firewall delete rule name="PES6-SERVER-TCP" >nul 2>&1
netsh advfirewall firewall delete rule name="PES6-SERVER-UDP" >nul 2>&1
rem 方案二: 程序级放行规则 PES6-app-* 常驻保留, 避免下次启动弹防火墙询问窗
echo.
echo ===== 还原后验证 =====
netsh advfirewall firewall show rule name="PES6-SERVER-TCP" 2>&1 | findstr "PES6-SERVER-TCP" >nul && (
echo 【X】 PES6-SERVER-TCP 仍存在
  set "FAIL=1"
) || (
echo 【OK】 PES6-SERVER-TCP 已删除
)
netsh advfirewall firewall show rule name="PES6-SERVER-UDP" 2>&1 | findstr "PES6-SERVER-UDP" >nul && (
echo 【X】 PES6-SERVER-UDP 仍存在
  set "FAIL=1"
) || (
echo 【OK】 PES6-SERVER-UDP 已删除
)
echo 【信息】 防火墙配置文件状态,【未改动】:
netsh advfirewall show allprofiles state | findstr /c:"配置文件" /c:"状态"
echo.
echo 【完成】 防火墙放行还原结束
if not defined NOPAUSE pause
