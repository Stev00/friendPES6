@echo off
rem 版本: v1.0 (2026-09-05)  zhangdansan(stevoo)
echo 【版本】 PC_host_1_启动服务器 v1.0 (2026-09-05)
:parse_args

setlocal EnableDelayedExpansion
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

if defined PES6_ROOT (cd /d "%PES6_ROOT%") else (cd /d "%~dp0..")
for %%i in (".") do set "ROOT=%%~fi"
if not exist "%ROOT%\mysql\mysql-5.7.44-winx64\bin\mysqld.exe" (
echo 【错误】 未能定位 pes6server 组件【当前解析目录=%CD%】
echo 请进入 pes6server 文件夹后直接双击 PC_host_1-启动服务器.bat
  if not defined NOPAUSE pause
  exit /b 1
)
title PES6 Home Server
cd /d "%ROOT%"

rem ============ 0. 自动探测本机内网 IP ============
set "LANIP="
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /c:"IPv4"') do (
  if not defined LANIP set "LANIP=%%i"
)
set "LANIP=%LANIP: =%"
if "%LANIP%"=="" set "LANIP=192.168.50.113"
echo 【信息】 本机内网 IP = %LANIP%

rem ============ 1. 获取当前公网 IP ============
set "PUBIP="
for /f "delims=" %%i in ('curl -4 -s --max-time 8 http://members.3322.org/dyndns/getip') do set "PUBIP=%%i"
if "%PUBIP%"=="" for /f "delims=" %%i in ('curl -4 -s --max-time 8 http://ip.3322.net') do set "PUBIP=%%i"
if "%PUBIP%"=="" (
echo 【错误】 两个源都无法获取公网 IP, STUN/ServerIP 需要它
echo 请检查外网连通性后重跑本脚本
  if not defined NOPAUSE pause
  exit /b 1
)
echo 【信息】 当前公网 IP = %PUBIP%

rem ============ 2. 自动生成 mysql\my.ini(基于真实目录) ============
> "%ROOT%\mysql\my.ini" echo [mysqld]
set "ROOT_FW=%ROOT:\=/%"
>> "%ROOT%\mysql\my.ini" echo basedir=%ROOT_FW%/mysql/mysql-5.7.44-winx64
>> "%ROOT%\mysql\my.ini" echo datadir=%ROOT_FW%/mysql/data
>> "%ROOT%\mysql\my.ini" echo port=3306
>> "%ROOT%\mysql\my.ini" echo bind-address=127.0.0.1
>> "%ROOT%\mysql\my.ini" echo character-set-server=utf8
>> "%ROOT%\mysql\my.ini" echo skip-log-bin
>> "%ROOT%\mysql\my.ini" echo innodb_buffer_pool_size=64M
>> "%ROOT%\mysql\my.ini" echo max_connections=30
>> "%ROOT%\mysql\my.ini" echo log_syslog=0

rem ============ 3. 把公网 IP 写进 sixserver.yaml ============
powershell -NoProfile -Command "$f='%ROOT%\fiveserver\etc\conf\sixserver.yaml'; (Get-Content $f) -replace '^ServerIP:.*$','ServerIP: %PUBIP%' | Set-Content $f -Encoding ASCII"

rem ============ 4. 启动 MySQL(带轮询) ============
set "MBIN=%ROOT%\mysql\mysql-5.7.44-winx64\bin"
"%MBIN%\mysqladmin.exe" -u root ping >nul 2>&1
if errorlevel 1 (
  if not exist "mysql\data\mysql" (
echo 【信息】 首次运行, 初始化数据库...
    "%MBIN%\mysqld.exe" --defaults-file=mysql\my.ini --initialize-insecure
  )
echo 【信息】 启动 MySQL...
  start "PES6-MySQL" /min cmd /c ""%MBIN%\mysqld.exe" --defaults-file="%ROOT%\mysql\my.ini" --console"
  set /a TRY=0
  :wait_mysql
  ping -n 4 127.0.0.1 >nul
  "%MBIN%\mysqladmin.exe" -u root ping >nul 2>&1 && goto mysql_ok
  set /a TRY+=1
  if !TRY! LSS 10 goto wait_mysql
echo 【错误】 MySQL 30 秒内未启动, 请查看 mysql\data\*.err 日志
  goto mysql_done
  :mysql_ok
echo 【OK】 MySQL 已就绪
) else (
echo 【OK】 MySQL 已在运行
)
:mysql_done

rem ============ 5. 首次建库导表 ============
"%MBIN%\mysql.exe" -u root -e "SELECT 1" >nul 2>&1
if errorlevel 1 (
echo 【跳过】 MySQL 未运行, 跳过建库
  goto db_done
)
"%MBIN%\mysql.exe" -u root -e "CREATE DATABASE IF NOT EXISTS sixserver CHARACTER SET utf8; CREATE USER IF NOT EXISTS 'sixserver'@'localhost' IDENTIFIED BY 'proevo'; CREATE USER IF NOT EXISTS 'sixserver'@'127.0.0.1' IDENTIFIED BY 'proevo'; GRANT ALL PRIVILEGES ON sixserver.* TO 'sixserver'@'localhost'; GRANT ALL PRIVILEGES ON sixserver.* TO 'sixserver'@'127.0.0.1'; FLUSH PRIVILEGES;" >nul 2>&1
"%MBIN%\mysql.exe" -u root -D sixserver -e "SELECT 1 FROM users LIMIT 1;" >nul 2>&1
if errorlevel 1 (
echo 【信息】 导入数据表...
  "%MBIN%\mysql.exe" -u root sixserver < "fiveserver\doc\sql\schema6.sql" >nul 2>&1 && echo 【OK】 建表完成 || echo 【错误】 建表失败, 查看 mysql\data\*.err
  "%MBIN%\mysql.exe" -u root sixserver < "fiveserver\doc\sql\alter6_001_modify_profiles.sql" >nul 2>&1
  "%MBIN%\mysql.exe" -u root sixserver < "fiveserver\doc\sql\alter_001_add_settings.sql" >nul 2>&1
echo 【OK】 补丁 SQL 已应用
) else (
echo 【OK】 数据表已存在
)
:db_done

rem ============ 6. 启动 STUN(已在运行则跳过) ============
netstat -ano -p udp | findstr /c:":3478 " >nul
if errorlevel 1 (
  start "PES6-STUN" /min python "%ROOT%\stun\stun_server.py" --public-ip %PUBIP% --lan-ip %LANIP%
echo 【信息】 STUN 已启动
) else (
echo 【信息】 STUN 已在运行, 跳过
)

rem ============ 7. 启动 Sixserver(已在运行则跳过) ============
netstat -ano -p tcp | findstr /c:":20202 " | findstr LISTENING >nul
if errorlevel 1 (
  cd fiveserver
  start "PES6-Sixserver" /min cmd /c "twistd -ny etc\server6.tac -l log\sixserver.log"
  cd ..
echo 【信息】 Sixserver 已启动
) else (
echo 【信息】 Sixserver 已在运行, 跳过
)

echo.
echo ======== 服务器组件启动流程结束 ========
echo 注册页面: http://127.0.0.1:8190/
echo 管理页面: https://127.0.0.1:8191/  (账号 fives 密码 fives)
echo 公网 IP : %PUBIP%
echo 内网 IP : %LANIP%
echo 日志    : fiveserver\log\sixserver.log
if not defined NOPAUSE pause
