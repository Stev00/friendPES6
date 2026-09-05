@echo off
rem 版本: v1.0 (2026-09-05)  zhangdansan(stevoo)
echo [版本] PC_host_3_改hosts指向本机 v1.0 (2026-09-05)
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
set "HOSTS=%WINDIR%\System32\drivers\etc\hosts"
echo ===== 修改前检测 =====
findstr /i "winning-eleven" "%HOSTS%" >nul 2>&1 && (
  echo   [检测到] 已有 PES6 相关行:
  findstr /i "winning-eleven" "%HOSTS%"
) || (
  echo   [检测到] 无 PES6 相关行
)
if not exist "%HOSTS%.pes6bak" (
  copy /y "%HOSTS%" "%HOSTS%.pes6bak" >nul
  echo   [OK] 已备份原 hosts 到 hosts.pes6bak
) else (
  echo   [跳过] 备份已存在, 不覆盖: hosts.pes6bak
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$f=\"$env:WINDIR\System32\drivers\etc\hosts\"; $b=$f+'.pes6bak'; if(!(Test-Path $b)){Copy-Item $f $b}; $c=Get-Content $f | Where-Object {$_ -notmatch 'winning-eleven\.net'}; $c+='127.0.0.1 pes6gate-ec.winning-eleven.net'; $c+='127.0.0.1 we9stun.winning-eleven.net'; [IO.File]::WriteAllLines($f,$c)"
ipconfig /flushdns >nul
echo.
echo ===== 修改后验证 =====
findstr /c:"127.0.0.1 pes6gate-ec" "%HOSTS%" >nul 2>&1 && (
  echo   [OK] hosts 已指向本机:
  findstr /i "winning-eleven" "%HOSTS%"
) || (
  echo   [X] hosts 修改失败, 请检查
)
echo [完成] hosts 配置结束
if not defined NOPAUSE pause
