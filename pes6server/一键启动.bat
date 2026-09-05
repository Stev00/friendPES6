@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"
if /i not "%~1"=="/inner" (
  cmd /k ""%~f0" /inner"
  exit /b
)
rem 版本: v1.0 (2026-09-05)  zhangdansan(stevoo)
echo [版本] 一键启动 v1.0 (2026-09-05)
if not exist "scripts\PC_host_1_启动服务器.bat" (
  echo   [错误] 未能定位 pes6server 目录【当前目录=%CD%】
  echo   请不要从别处启动本脚本: 进入 pes6server 文件夹后, 直接双击它
  pause
  exit /b 1
)
for %%i in (".") do set "ROOT=%%~fi"
title PES6 一键启动
for %%i in ("%~dp0..") do set "GAME_DIR=%%~fi"
for %%i in ("%~dp0..\PES6.exe") do set "GAME_EXE=%%~fi"

echo ============================================================
echo   PES6 一键启动
echo ============================================================
echo   [选择角色]  1 = 主机 (host, 跑服务器的这台)
echo              2 = 客机 (client, 连过去玩的那台)
:ask_role
set "ROLE="
set /p "ROLE=请输入 1 或 2 (输入后按回车): "
if "%ROLE%"=="1" goto HOST
if "%ROLE%"=="2" goto CLIENT
echo   [提示] 请输入 1 或 2
goto ask_role

:HOST
echo.
echo ============================================================
echo   【1/6】启动服务器服务(MySQL+大厅+STUN, 已运行的自动跳过)
set "PES6_ROOT=%ROOT%"
pushd "%ROOT%"
call "scripts\PC_host_1_启动服务器.bat" /nopause
popd
echo.
echo ============================================================

echo.
echo ============================================================
echo   【2/6】检查 hosts(指向本机 127.0.0.1)
findstr /c:"127.0.0.1 pes6gate-ec" "%WINDIR%\System32\drivers\etc\hosts" >nul 2>&1
if errorlevel 1 (
  echo   [需要设置] 调起管理员窗口修改 hosts...
  call "scripts\PC_host_3_改hosts指向本机.bat" /nopause
  echo   完成后按任意键继续检测...
  pause >nul
  findstr /c:"127.0.0.1 pes6gate-ec" "%WINDIR%\System32\drivers\etc\hosts" >nul 2>&1 && echo   [OK] hosts 已指向本机 || echo   [X] 未设置成功, 可手动运行 scripts\PC_host_3_改hosts指向本机.bat
) else (
  echo   [跳过] hosts 已指向本机
)
echo.
echo ============================================================

echo.
echo ============================================================
echo   【3/6】检查防火墙放行规则
netsh advfirewall firewall show rule name="PES6-SERVER-TCP" 2>&1 | findstr "PES6-SERVER-TCP" >nul
if errorlevel 1 (
  echo   [需要设置] 调起管理员窗口添加放行规则...
  call "scripts\PC_host_4_添加防火墙放行.bat" /nopause
  echo   完成后按任意键继续检测...
  pause >nul
  netsh advfirewall firewall show rule name="PES6-SERVER-TCP" 2>&1 | findstr "PES6-SERVER-TCP" >nul && echo   [OK] 规则已添加 || echo   [X] 规则未添加, 可手动运行 scripts\PC_host_4_添加防火墙放行.bat
) else (
  echo   [跳过] 放行规则已存在
)
echo.
echo ============================================================

echo.
echo ============================================================
echo   【4/6】路由器 DMZ/端口映射(iKuai)
echo   此项无法在本机自动检测/设置
set /p "IK=路由器 DMZ 或端口映射已经设置好了吗? (Y=已设置 N=显示指引) (输入后按回车): "
:ask_ik
if /i "%IK%"=="Y" (
  echo   [OK] 跳过
) else if /i "%IK%"=="N" (
  call "scripts\PC_host_5_设置ikuai端口转发.bat" /nopause
  echo   手动设置完成后按任意键继续...
  pause >nul
) else (
  echo   [提示] 请输入 Y 或 N
  set /p "IK=路由器 DMZ 或端口映射已经设置好了吗? (Y/N) (输入后按回车): "
  goto ask_ik
)
echo.
echo ============================================================

echo.
echo ============================================================
echo   【5/6】检查注册账号
set "USERCNT="
set "MYSQL_EXE=%ROOT%\mysql\mysql-5.7.44-winx64\bin\mysql.exe"
for /f %%c in ('"%MYSQL_EXE%" -u root -D sixserver -N -e "SELECT COUNT(*) FROM users" 2^>nul') do set "USERCNT=%%c"
if not defined USERCNT (
  echo   [跳过] MySQL 未运行, 跳过账号检查
) else if !USERCNT! GEQ 2 (
  echo   [跳过] 已有 !USERCNT! 个账号
) else (
  echo   [提示] 当前仅 !USERCNT! 个账号, 建议 2 个【主机+客机各一】
  call "scripts\PC_host_2_注册账号-打开网页.bat" /nopause
  echo   注册完成后按任意键继续...
  pause >nul
)
echo.
echo ============================================================
echo   【6/6】全部完成!
echo   公网/内网 IP 见上方启动输出; 注册页 http://127.0.0.1:8190/
echo   日志: fiveserver\log\sixserver.log
:ask_game_h
set "G="
set /p "G=现在启动游戏吗? (Y/N) (输入后按回车): "
if /i "%G%"=="Y" (
  if exist "%GAME_EXE%" (
    start "" /D "%GAME_DIR%" "%GAME_EXE%"
  ) else (
    set /p "GP=上一级未找到 PES6.exe, 请输入完整路径 (输入后按回车): "
    for %%i in ("%GP%") do set "GPD=%%~dpi"
    start "" /D "%GPD%" "%GP%"
  )
)
if /i not "%G%"=="N" (
  echo   [提示] 请输入 Y 或 N
  goto ask_game_h
)
echo ============================================================
echo   一键启动流程结束【主机】
pause
goto :EOF

:CLIENT
echo.
echo ============================================================
echo   【1/5】检测游戏与 install.bat
if exist "%GAME_EXE%" (
  echo   [OK] 找到游戏: %GAME_EXE%
) else (
  echo   [X] 未在 pes6server 上一级找到 PES6.exe
  set /p "GP=请输入 PES6.exe 完整路径 (输入后按回车): "
)
reg query "HKLM\SOFTWARE\WOW6432Node\KONAMIPES6" >nul 2>&1
if errorlevel 1 (
  echo   [需要设置] 未检测到 install.bat 的注册信息, 不运行它游戏可能打不开
  echo   请双击游戏目录下的 install.bat, 完成后按任意键继续...
  pause >nul
  reg query "HKLM\SOFTWARE\WOW6432Node\KONAMIPES6" >nul 2>&1 && echo   [OK] 注册信息已写入 || echo   [警告] 仍未检测到, 若游戏打不开请重跑 install.bat
) else (
  echo   [跳过] install.bat 已运行过
)
echo.
echo ============================================================

echo.
echo ============================================================
echo   【2/5】检查 settings.dat【UDP 端口自动补丁为 5730; "自动"勾选与 UPnP 需在 settings.exe 手动不勾】
set "SDAT="
if exist "%USERPROFILE%\Documents\KONAMI\Pro Evolution Soccer 6\settings.dat" set "SDAT=%USERPROFILE%\Documents\KONAMI\Pro Evolution Soccer 6\settings.dat"
if not defined SDAT if defined OneDrive if exist "%OneDrive%\Documents\KONAMI\Pro Evolution Soccer 6\settings.dat" set "SDAT=%OneDrive%\Documents\KONAMI\Pro Evolution Soccer 6\settings.dat"
if defined SDAT (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$p='%SDAT%'; if(!(Test-Path ($p+'.pes6bak'))){Copy-Item $p ($p+'.pes6bak')}; $b=[IO.File]::ReadAllBytes($p); $old=$b[416]+$b[417]*256; $b[416]=0x62; $b[417]=0x16; [IO.File]::WriteAllBytes($p,$b); Write-Host ('  [OK] UDP 端口已设为 5730 【原值 '+$old+'】, 备份在 settings.dat.pes6bak')"
  echo   [提示] "自动"勾选与 UPnP 无法自动修改; 若处于勾选状态, 请在 settings.exe 里取消一次
) else (
  echo   [警告] 未找到 settings.dat【还没保存过游戏设置】, 请手动做一次:
  echo     双击游戏目录的 settings.exe: UDP 端口取消"自动"勾选并填 5730, UPnP 不勾, 点保存
  echo   完成后按任意键继续检测...
  pause >nul
)
echo.
echo ============================================================

echo.
echo ============================================================
echo   【3/5】修改 hosts 指向 PChost 公网 IP
echo   【公网 IP 以 PChost 上运行一键启动时显示的为准】
set /p "PUBIP=请输入 PChost 公网 IP (输入后按回车): "
if "%PUBIP%"=="" (
  echo   [X] 未提供公网 IP, 跳过 hosts 修改
) else (
  call "scripts\PC_client_1_改hosts.bat" %PUBIP% /nopause
  findstr /c:"%PUBIP% pes6gate-ec" "%WINDIR%\System32\drivers\etc\hosts" >nul 2>&1 && echo   [OK] hosts 已指向 %PUBIP% || echo   [X] 未设置成功, 可手动运行 scripts\PC_client_1_改hosts.bat
)
echo.
echo ============================================================

echo.
echo ============================================================
echo   【4/5】防火墙提示
echo   游戏首次联网若被拦, 弹窗中"专用+公用"都勾允许, 或临时关闭防火墙
echo.
echo ============================================================

echo.
echo ============================================================
echo   【5/5】链路验证
start "" "http://%PUBIP%:8190/"
echo   已在浏览器打开 http://%PUBIP%:8190/
echo   能看到注册页 = 链路通; 打不开 = 路由器 DMZ/端口映射未配好
echo   检查完按任意键继续...
pause >nul
:ask_game_c
set "G="
set /p "G=现在启动游戏吗? (Y/N) (输入后按回车): "
if /i "%G%"=="Y" (
  if exist "%GAME_EXE%" (
    start "" /D "%GAME_DIR%" "%GAME_EXE%"
  ) else (
    set /p "GP=请输入 PES6.exe 完整路径 (输入后按回车): "
    for %%i in ("%GP%") do set "GPD=%%~dpi"
    start "" /D "%GPD%" "%GP%"
  )
)
if /i not "%G%"=="N" (
  echo   [提示] 请输入 Y 或 N
  goto ask_game_c
)
echo ============================================================
echo   一键启动流程结束【客机】
pause

:EOF
