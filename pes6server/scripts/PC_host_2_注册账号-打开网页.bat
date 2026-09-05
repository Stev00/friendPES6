@echo off
rem 版本: v1.0 (2026-09-05)  zhangdansan(stevoo)
echo 【版本】 PC_host_2_注册账号-打开网页 v1.0 (2026-09-05)
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

start http://127.0.0.1:8190/
echo 浏览器已打开注册页(需先运行 PC_host_1-启动服务器.bat)。
if not defined NOPAUSE pause
