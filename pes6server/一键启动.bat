@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"
if /i not "%~1"=="/inner" (
  cmd /k ""%~f0" /inner"
  exit /b
)
rem 版本: v1.1 (2026-09-05)  zhangdansan(stevoo)
echo 【版本】 一键启动 v1.1 (2026-09-05)
if not exist "scripts\PC_host_1_启动服务器.bat" (
echo 【错误】 未能定位 pes6server 目录【当前目录=%CD%】
echo 请不要从别处启动本脚本: 进入 pes6server 文件夹后, 直接双击它
echo 按任意键关闭本窗口...
  pause >nul
  exit 1
)
net session >nul 2>&1
if errorlevel 1 (
echo 正在请求管理员权限【整个启动流程只需这一次】...
  powershell -NoProfile -Command "Start-Process -Verb RunAs -FilePath cmd.exe -ArgumentList '/k','\"%~f0\" /inner'"
  if errorlevel 1 (
echo 【提示】 未获得管理员权限, 无法自动修改 hosts/防火墙, 流程中止
    pause
  )
  exit
)
for %%i in (".") do set "ROOT=%%~fi"
title PES6 一键启动
for %%i in ("%~dp0..") do set "GAME_DIR=%%~fi"
for %%i in ("%~dp0..\PES6.exe") do set "GAME_EXE=%%~fi"

echo ============================================================
echo PES6 一键启动
echo ============================================================
echo 【注意】 若 Windows 防火墙弹窗询问某程序是否允许访问网络:
echo 请把 专用网络 与 公用网络 都勾选, 再点 允许访问
echo 即使误点取消, 下次一键启动也会自动修复
echo 【选择角色】  1 = 主机 (host, 跑服务器的这台)
echo               2 = 客机 (client, 连过去玩的那台)
:ask_role
set "ROLE="
set /p "ROLE=请输入 1 或 2 (输入后按回车): "
if "%ROLE%"=="1" goto HOST
if "%ROLE%"=="2" goto CLIENT
echo 【提示】 请输入 1 或 2
goto ask_role

:HOST
echo.
echo ============================================================
echo 【1/6】环境预置与启动服务器服务(MySQL+大厅+STUN, 已运行的自动跳过)
rem ===== 方案1: 防火墙规则常驻, 启动/关闭均不再增删(需恢复清雷+重建时取消下一行注释) =====
rem call "%~dp0scripts\PC_host_4_添加防火墙放行.bat" /nopause
set "NEEDINST=1"
for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\WOW6432Node\KONAMIPES6\PES6" /v installdir 2^>nul ^| findstr /i installdir') do if /i "%%b"=="%GAME_DIR%" set "NEEDINST=0"
if "%NEEDINST%"=="1" (
echo 【需要设置】 首次使用或目录已变更: 正在自动运行 install.bat 写入注册信息...
  call "%~dp0scripts\install.bat" /nopause
) else (
echo 【跳过】 install.bat 注册路径与当前一致
)
if exist "%GAME_DIR%\kitserver\kload.cfg" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\kit_resolution.ps1" "%GAME_DIR%\kitserver\kload.cfg"
) else (
echo 【跳过】 kitserver 未安装, 跳过分辨率适配
)
set "PES6_ROOT=%ROOT%"
pushd "%ROOT%"
call "%~dp0scripts\PC_host_1_启动服务器.bat" /nopause
popd

echo.
echo ============================================================
echo 【2/6】检查 hosts(指向本机 127.0.0.1)
findstr /c:"127.0.0.1 pes6gate-ec" "%WINDIR%\System32\drivers\etc\hosts" >nul 2>&1
if errorlevel 1 (
echo 【需要设置】 正在修改 hosts【需管理员权限】...
  call "%~dp0scripts\PC_host_3_改hosts指向本机.bat" /nopause
  findstr /c:"127.0.0.1 pes6gate-ec" "%WINDIR%\System32\drivers\etc\hosts" >nul 2>&1 && echo 【OK】 hosts 已指向本机 || echo 【X】 未设置成功, 可手动运行 scripts\PC_host_3_改hosts指向本机.bat
) else (
echo 【跳过】 hosts 已指向本机
)

echo.
echo ============================================================
echo 【3/6】验证防火墙放行规则
netsh advfirewall firewall show rule name=all 2>&1 | findstr /c:"PES6-SERVER-TCP" /c:"PES6-TCP-in" >nul && echo 【OK】 端口放行规则在位 || echo 【X】 端口放行规则缺失, 重跑一键启动可修复
netsh advfirewall firewall show rule name=all 2>&1 | findstr /c:"PES6-app-twistd" /c:"PES6-TCP-in" >nul && echo 【OK】 程序放行规则在位 || echo 【X】 程序放行规则缺失, 重跑一键启动可修复

echo.
echo ============================================================
echo 【4/6】路由器 DMZ/端口映射(iKuai)
echo 此项无法在本机自动检测/设置
set /p "IK=路由器 DMZ 或端口映射已经设置好了吗? (Y=已设置 N=显示指引) (输入后按回车): "
:ask_ik
if /i "%IK%"=="Y" (
echo 【OK】 跳过
) else if /i "%IK%"=="N" (
  call "%~dp0scripts\PC_host_5_设置ikuai端口转发.bat" /nopause
echo 手动设置完成后按任意键继续...
  pause >nul
) else (
echo 【提示】 请输入 Y 或 N
  set /p "IK=路由器 DMZ 或端口映射已经设置好了吗? (Y/N) (输入后按回车): "
  goto ask_ik
)

echo.
echo ============================================================
echo 【5/6】检查注册账号
set "USERCNT="
set "MYSQL_EXE=%ROOT%\mysql\mysql-5.7.44-winx64\bin\mysql.exe"
set "UCFILE=%TEMP%\pes6_usercount.txt"
"%MYSQL_EXE%" -u root -D sixserver -N -e "SELECT COUNT(*) FROM users" > "%UCFILE%" 2>nul
set /p USERCNT=<"%UCFILE%" 2>nul
del /q "%UCFILE%" 2>nul
if not defined USERCNT (
echo 【跳过】 MySQL 未运行, 跳过账号检查
) else if !USERCNT! GEQ 2 (
echo 【跳过】 已有 !USERCNT! 个账号
) else (
echo 【提示】 当前仅 !USERCNT! 个账号, 建议 2 个【主机+客机各一】
  call "%~dp0scripts\PC_host_2_注册账号-打开网页.bat" /nopause
echo 注册完成后按任意键继续...
  pause >nul
)
echo.
echo ============================================================
echo 【6/6】全部完成^^!
echo 公网/内网 IP 见上方启动输出; 注册页 http://127.0.0.1:8190/
echo 日志: fiveserver\log\sixserver.log
:ask_game_h
set "G="
set /p "G=现在启动游戏吗? (Y/N) (输入后按回车): "
if /i "%G%"=="Y" goto do_game_h
if /i "%G%"=="N" goto no_game_h
echo 【提示】 请输入 Y 或 N
goto ask_game_h
:do_game_h
if exist "%GAME_EXE%" (
  start "" /D "%GAME_DIR%" "%GAME_EXE%"
  goto no_game_h
)
set /p "GP=上一级未找到 PES6.exe, 请输入完整路径 (输入后按回车): "
for %%i in ("%GP%") do set "GPD=%%~dpi"
start "" /D "%GPD%" "%GP%"
:no_game_h
echo ============================================================
echo 一键启动流程结束【主机】
echo 【注意】 任务栏最小化的 PES6-MySQL / PES6-STUN / PES6-Sixserver 窗口
echo 是服务器服务: 服务器运行期间请勿关闭它们
echo 全部下线时用 一键关闭.bat 收尾, 不要直接点 X
echo 60 秒后自动关闭本窗口; 按任意键保留窗口...
timeout /t 60
if errorlevel 1 exit /b
exit

:CLIENT
echo.
echo ============================================================
echo 【1/5】检测游戏与 install.bat
if exist "%GAME_EXE%" (
echo 【OK】 找到游戏: %GAME_EXE%
) else (
echo 【X】 未在 pes6server 上一级找到 PES6.exe
  set /p "GP=请输入 PES6.exe 完整路径 (输入后按回车): "
)
set "NEEDINST=1"
for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\WOW6432Node\KONAMIPES6\PES6" /v installdir 2^>nul ^| findstr /i installdir') do if /i "%%b"=="%GAME_DIR%" set "NEEDINST=0"
if "%NEEDINST%"=="1" (
echo 【需要设置】 首次使用或目录已变更: 正在自动运行 install.bat 写入注册信息...
  call "%~dp0scripts\install.bat" /nopause
  reg query "HKLM\SOFTWARE\WOW6432Node\KONAMIPES6\PES6" /v installdir 2>nul | findstr /i "%GAME_DIR%" >nul && echo 【OK】 注册信息已写入 || echo 【X】 注册未成功, 请检查 scripts\install.bat
) else (
echo 【跳过】 install.bat 已运行过
)

echo.
echo ============================================================
if exist "%GAME_DIR%\kitserver\kload.cfg" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\kit_resolution.ps1" "%GAME_DIR%\kitserver\kload.cfg"
) else (
echo 【跳过】 kitserver 未安装, 跳过分辨率适配
)
echo 【2/5】检查 settings.dat【UDP 端口自动补丁为 5730】
echo 【重要】 settings.exe 里 UPnP 请保持勾选! 它是对战 P2P 联机的关键(自动在路由器开端口)
set "SDAT="
if exist "%USERPROFILE%\Documents\KONAMI\Pro Evolution Soccer 6\settings.dat" set "SDAT=%USERPROFILE%\Documents\KONAMI\Pro Evolution Soccer 6\settings.dat"
if not defined SDAT if defined OneDrive if exist "%OneDrive%\Documents\KONAMI\Pro Evolution Soccer 6\settings.dat" set "SDAT=%OneDrive%\Documents\KONAMI\Pro Evolution Soccer 6\settings.dat"
if defined SDAT (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$p='%SDAT%'; if (-not (Test-Path ($p+'.pes6bak'))){Copy-Item $p ($p+'.pes6bak')}; $b=[IO.File]::ReadAllBytes($p); $old=$b[416]+$b[417]*256; $b[416]=0x62; $b[417]=0x16; [IO.File]::WriteAllBytes($p,$b); Write-Host ('  【OK】 UDP 端口已设为 5730 【原值 '+$old+'】, 备份在 settings.dat.pes6bak')"
echo 【提示】 若对战黑屏: 打开 settings.exe 确认 UPnP 处于勾选状态, 保存后重启游戏重连
echo        ("自动"勾选已被自动补丁处理; UPnP 是客机对战的关键, 千万别取消)
) else (
echo 【警告】 未找到 settings.dat【还没保存过游戏设置】, 请手动做一次:
echo 双击游戏目录的 settings.exe: UDP 端口取消"自动"勾选并填 5730, UPnP 不勾, 点保存
echo 完成后按任意键继续检测...
  pause >nul
)

echo.
echo ============================================================
echo 【3/5】修改 hosts 指向 PChost 公网 IP
echo 【公网 IP 以 PChost 上运行一键启动时显示的为准】
set /p "PUBIP=请输入 PChost 公网 IP (输入后按回车): "
if "%PUBIP%"=="" (
echo 【X】 未提供公网 IP, 跳过 hosts 修改
) else (
  call "%~dp0scripts\PC_client_1_改hosts.bat" %PUBIP% /nopause
  findstr /c:"%PUBIP% pes6gate-ec" "%WINDIR%\System32\drivers\etc\hosts" >nul 2>&1 && echo 【OK】 hosts 已指向 %PUBIP% || echo 【X】 未设置成功, 可手动运行 scripts\PC_client_1_改hosts.bat
)

echo.
echo ============================================================
echo 【4/5】防火墙提示
echo 游戏首次联网若被拦, 弹窗中"专用+公用"都勾允许, 或临时关闭防火墙

echo.
echo ============================================================
echo 【5/5】链路验证(TCP 直连 8190/8191/10881, 不走 ping/ICMP)
if "%PUBIP%"=="" (
echo 【跳过】 未提供公网 IP, 无法链路验证
) else (
  powershell -NoProfile -Command "8190,8191,10881 | ForEach-Object {$c=New-Object Net.Sockets.TcpClient;$r=$c.BeginConnect('%PUBIP%',$_,$null,$null);if($r.AsyncWaitHandle.WaitOne(5000,$true) -and $c.Connected){Write-Host ('  【OK】 TCP '+$_+' 可达')}else{Write-Host ('  【X】 TCP '+$_+' 连不上')};$c.Close()}"
echo 【说明】 有【OK】即链路通【这是 TCP 检测, 与 ping/ICMP 无关】; 正式收尾删了 8190 映射的话, 8190 不通属正常
echo          全部不通才需排查: 主机服务是否在跑 / 防火墙 TCP 规则 / 路由器 DMZ 端口映射
)
:ask_game_c
set "G="
set /p "G=现在启动游戏吗? (Y/N) (输入后按回车): "
if /i "%G%"=="Y" goto do_game_c
if /i "%G%"=="N" goto no_game_c
echo 【提示】 请输入 Y 或 N
goto ask_game_c
:do_game_c
if exist "%GAME_EXE%" (
  start "" /D "%GAME_DIR%" "%GAME_EXE%"
  goto no_game_c
)
set /p "GP=请输入 PES6.exe 完整路径 (输入后按回车): "
for %%i in ("%GP%") do set "GPD=%%~dpi"
start "" /D "%GPD%" "%GP%"
:no_game_c
echo ============================================================
echo 一键启动流程结束【客机】
echo 60 秒后自动关闭本窗口; 按任意键保留窗口...
timeout /t 60
if errorlevel 1 exit /b
exit

:EOF
