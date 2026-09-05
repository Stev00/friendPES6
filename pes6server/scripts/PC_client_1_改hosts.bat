@echo off
rem 版本: v1.0 (2026-09-05)  zhangdansan(stevoo)
echo 【版本】 PC_client_1_改hosts v1.0 (2026-09-05)
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
if /i "%~1"=="/yes" (
  set "AUTOYES=1"
  shift
  goto parse_args
)
rem ---- 位置参数(公网 IP) ----
if not "%~1"=="" (
  set "HOSTIP=%~1"
  shift
  goto parse_args
)

rem ---- 提权后工作目录会变成 System32, 回到脚本真实目录 ----

pushd "%~dp0" 2>nul

net session >nul 2>&1
if errorlevel 1 (
echo 正在请求管理员权限...
  popd
  powershell -NoProfile -Command "Start-Process -Verb RunAs -FilePath cmd.exe -ArgumentList '/k','\"%SELF%\" /nopause /yes'"
  exit /b
)
set "HOSTS=%WINDIR%\System32\drivers\etc\hosts"
echo 本脚本把本机 hosts 指向 PChost 的公网 IP
if not defined HOSTIP set /p "HOSTIP=请输入 PChost 公网 IP (输入后按回车): "
if "%HOSTIP%"=="" (
echo 【X】 未输入 IP, 中止
  if not defined NOPAUSE pause
  exit /b 1
)
echo ===== 修改前检测 =====
findstr /i "winning-eleven" "%HOSTS%" >nul 2>&1 && (
echo 【检测到】 已有 PES6 相关行:
  findstr /i "winning-eleven" "%HOSTS%"
) || (
echo 【检测到】 无 PES6 相关行
)
if not exist "%HOSTS%.pes6bak" (
  copy /y "%HOSTS%" "%HOSTS%.pes6bak" >nul
echo 【OK】 已备份原 hosts 到 hosts.pes6bak
) else (
echo 【跳过】 备份已存在, 不覆盖
)
findstr /i /v /c:"winning-eleven" "%HOSTS%" > "%HOSTS%.tmp"
>>"%HOSTS%.tmp" echo.
>>"%HOSTS%.tmp" echo %HOSTIP% pes6gate-ec.winning-eleven.net
>>"%HOSTS%.tmp" echo %HOSTIP% we9stun.winning-eleven.net
copy /y "%HOSTS%.tmp" "%HOSTS%" >nul
del /q "%HOSTS%.tmp" >nul 2>&1
ipconfig /flushdns >nul
echo ===== 修改后验证 =====
findstr /c:"%HOSTIP% pes6gate-ec" "%HOSTS%" >nul 2>&1 && (
echo 【OK】 hosts 已指向 %HOSTIP%:
  findstr /i "winning-eleven" "%HOSTS%"
) || (
echo 【X】 hosts 修改失败, 请检查
)
echo 【完成】 hosts 配置结束
if not defined NOPAUSE pause
