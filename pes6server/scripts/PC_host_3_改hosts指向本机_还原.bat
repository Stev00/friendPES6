@echo off
rem 版本: v1.0 (2026-09-05)  zhangdansan(stevoo)
echo 【版本】 PC_host_3_改hosts指向本机_还原 v1.0 (2026-09-05)
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
set "HOSTS=%WINDIR%\System32\drivers\etc\hosts"
echo ===== 还原前检测 =====
findstr /i "winning-eleven" "%HOSTS%" >nul 2>&1 && (
echo 【检测到】 hosts 中存在 PES6 相关行:
  findstr /i "winning-eleven" "%HOSTS%"
) || (
echo 【检测到】 hosts 中没有 PES6 相关行
)
if exist "%HOSTS%.pes6bak" (
echo 【检测到】 修改前备份存在: %HOSTS%.pes6bak
  set "RESTORE_FROM=bak"
) else (
echo 【未检测到】 备份不存在, 将只删除 PES6 相关行,【其余内容不动】
  set "RESTORE_FROM=del"
)
echo.
if defined AUTOYES (
echo 【自动确认】 Y
  goto AY_1
)
choice /c YN /m "确认执行还原? (Y=执行 N=取消)"
if not defined AUTOYES if errorlevel 2 (
echo 已取消, 未做任何修改
  if not defined NOPAUSE pause
  exit /b
)
:AY_1
if "%RESTORE_FROM%"=="bak" (
  copy /y "%HOSTS%.pes6bak" "%HOSTS%" >nul
echo 【执行】 已从备份 hosts.pes6bak 还原整个 hosts
) else (
  findstr /i /v /c:"winning-eleven" "%HOSTS%" > "%HOSTS%.tmp"
  copy /y "%HOSTS%.tmp" "%HOSTS%" >nul
  del /q "%HOSTS%.tmp" >nul 2>&1
echo 【执行】 已删除 hosts 中的 PES6 相关行
)
ipconfig /flushdns >nul
echo.
echo ===== 还原后验证 =====
findstr /i "winning-eleven" "%HOSTS%" >nul 2>&1 && (
echo 【注意】 当前仍有以下 winning-eleven 行,【若来自备份则属于修改前原有内容】:
  findstr /i "winning-eleven" "%HOSTS%"
) || (
echo 【OK】 hosts 已无任何 PES6 相关行
)
echo 【OK】 DNS 缓存已刷新
echo.
echo 【完成】 hosts 还原结束
if not defined NOPAUSE pause
