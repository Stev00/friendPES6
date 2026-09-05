@echo off
cd /d "%~dp0"
if /i not "%~1"=="/inner" (
  cmd /k ""%~f0" /inner"
  exit /b
)
rem 版本: v1.0 (2026-09-05)  zhangdansan(stevoo)
echo [版本] 一键关闭 v1.0 (2026-09-05)
if not exist "scripts\PC_host_1_启动服务器.bat" (
  echo   [错误] 未能定位 pes6server 目录【当前目录=%CD%】
  echo   请不要从别处启动本脚本: 进入 pes6server 文件夹后, 直接双击它
  pause
  exit /b 1
)
title PES6 一键关闭
echo ============================================================
echo   PES6 一键关闭
echo ============================================================
echo   [选择角色]  1 = 主机 (host)   2 = 客机 (client)
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
echo   【1/4】停止服务器服务(含验证与日志尾部)
call "scripts\PC_host_1_关闭服务器.bat" /nopause
echo.
echo ============================================================

echo.
echo ============================================================
echo   【2/4】还原 hosts(恢复到修改前)
call "scripts\PC_host_3_改hosts指向本机_还原.bat" /yes /nopause
echo.
echo ============================================================

echo.
echo ============================================================
echo   【3/4】删除防火墙放行规则
call "scripts\PC_host_4_添加防火墙放行_还原.bat" /yes /nopause
echo.
echo ============================================================

echo.
echo ============================================================
echo   【4/4】路由器还原指引(iKuai)
call "scripts\PC_host_5_设置ikuai端口转发_还原.bat" /nopause
echo   手动撤销完成后按任意键结束...
pause >nul
echo ============================================================
echo   一键关闭流程结束【主机】
pause
goto :EOF

:CLIENT
echo.
echo ============================================================
echo   【1/2】还原 hosts
call "scripts\PC_client_1_改hosts_还原.bat" /yes /nopause
echo.
echo ============================================================
echo   【2/2】完成! Windows 防火墙无需动作
pause
