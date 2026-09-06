@echo off
rem 版本: v1.0 (2026-09-05)  zhangdansan(stevoo)
echo 【版本】 PC_host_1_关闭服务器 v1.0 (2026-09-05)
cd /d "%~dp0.."
for %%i in (".") do set "ROOT=%%~fi"
if not exist "%ROOT%\mysql\mysql-5.7.44-winx64\bin\mysqladmin.exe" (
echo 【错误】 未能定位 pes6server 组件【当前解析目录=%CD%】
  if not defined NOPAUSE pause
  exit /b 1
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
title PES6 Home Server - STOP

echo 【1/4】 停止 Sixserver 大厅服务...
for %%p in (20202 20201 20200 10881 8190) do (
  for /f "tokens=5" %%a in ('netstat -ano -p tcp ^| findstr /c:":%%p " ^| findstr LISTENING') do taskkill /F /PID %%a >nul 2>&1
)
taskkill /F /IM twistd.exe >nul 2>&1

echo 【2/4】 停止 STUN 应答器...
for /f "tokens=4" %%a in ('netstat -ano -p udp ^| findstr /c:":3478 "') do taskkill /F /PID %%a >nul 2>&1
for /f "tokens=4" %%a in ('netstat -ano -p udp ^| findstr /c:":5735 "') do taskkill /F /PID %%a >nul 2>&1

echo 【3/4】 停止 MySQL(先优雅关闭, 失败再强制)...
mysql\mysql-5.7.44-winx64\bin\mysqladmin.exe -u root shutdown >nul 2>&1
ping -n 4 127.0.0.1 >nul
for /f "tokens=5" %%a in ('netstat -ano -p tcp ^| findstr /c:":3306 " ^| findstr LISTENING') do taskkill /F /PID %%a >nul 2>&1

echo 【4/4】 验证端口释放...
ping -n 3 127.0.0.1 >nul
set "FAIL=0"
for %%p in (20202 10881 8190) do (
  netstat -ano -p tcp | findstr /c:":%%p " | findstr LISTENING >nul && (
echo 【X】 TCP %%p 仍在运行
    set "FAIL=1"
  ) || (
echo 【OK】 TCP %%p 已停止
  )
)
netstat -ano -p udp | findstr /c:":3478 " >nul && (
echo 【X】 UDP 3478 仍在运行
  set "FAIL=1"
) || (
echo 【OK】 UDP 3478 已停止
)
netstat -ano -p tcp | findstr /c:":3306 " | findstr LISTENING >nul && (
echo 【X】 MySQL 3306 仍在运行
  set "FAIL=1"
) || (
echo 【OK】 MySQL 3306 已停止
)

echo.
echo ------ sixserver.log 最后10行 ------
if exist "fiveserver\log\sixserver.log" (
  powershell -NoProfile -Command "Get-Content 'fiveserver\log\sixserver.log' -Tail 10"
) else (
echo (无日志文件)
)
echo ------------------------------------
echo.
if "%FAIL%"=="1" (
echo 【结果】 存在未停止的服务: 可再跑一次本脚本, 或任务管理器按 PID 处理
) else (
echo 【结果】 全部服务已停止
)
if not defined NOPAUSE pause
