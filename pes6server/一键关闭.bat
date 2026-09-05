@echo off
cd /d "%~dp0"
if /i not "%~1"=="/inner" (
  cmd /k ""%~f0" /inner"
  exit /b
)
rem 版本: v1.0 (2026-09-05)  zhangdansan(stevoo)
echo 【版本】 一键关闭 v1.0 (2026-09-05)
if not exist "scripts\PC_host_1_启动服务器.bat" (
echo 【错误】 未能定位 pes6server 目录【当前目录=%CD%】
echo 请不要从别处启动本脚本: 进入 pes6server 文件夹后, 直接双击它
  pause
  exit /b 1
)
net session >nul 2>&1
if errorlevel 1 (
echo 正在请求管理员权限【整个关闭流程只需这一次】...
  powershell -NoProfile -Command "Start-Process -Verb RunAs -FilePath cmd.exe -ArgumentList '/k','\"%~f0\" /inner'"
  if errorlevel 1 (
echo 【提示】 未获得管理员权限, 无法还原 hosts/防火墙, 关闭流程中止
    pause
  )
  exit
)
title PES6 一键关闭
echo ============================================================
echo PES6 一键关闭
echo ============================================================
echo 【选择角色】  1 = 主机 (host)   2 = 客机 (client)
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
echo 【1/3】停止服务器服务(含验证与日志尾部)
call "%~dp0scripts\PC_host_1_关闭服务器.bat" /nopause

echo.
echo ============================================================
echo 【2/3】还原 hosts(恢复到修改前)
call "%~dp0scripts\PC_host_3_改hosts指向本机_还原.bat" /yes /nopause

echo.
echo ============================================================
rem ===== 方案1: 防火墙规则常驻, 关闭时不再删除(需恢复时取消下一行注释) =====
rem call "%~dp0scripts\PC_host_4_添加防火墙放行_还原.bat" /yes /nopause

echo.
echo ============================================================
echo 【3/3】路由器还原指引(iKuai)
call "%~dp0scripts\PC_host_5_设置ikuai端口转发_还原.bat" /nopause
:ask_router
set "RD="
set /p "RD=是否已按上面指引撤销路由器的 DMZ/端口映射? (Y=已撤销 N=稍后自己处理) (输入后按回车): "
if /i "%RD%"=="Y" goto router_done
if /i "%RD%"=="N" goto router_later
echo 【提示】 请输入 Y 或 N
goto ask_router
:router_later
echo 【注意】 路由器仍对公网开放, 请尽快按上面指引撤销
:router_done
echo ============================================================
echo 一键关闭流程结束【主机】
echo 按任意键关闭本窗口...
pause >nul
exit

:CLIENT
echo.
echo ============================================================
echo 【1/2】还原 hosts
call "%~dp0scripts\PC_client_1_改hosts_还原.bat" /yes /nopause
echo.
echo ============================================================
echo 【2/2】完成^^! Windows 防火墙无需动作
echo 按任意键关闭本窗口...
pause >nul
exit
