@echo off
rem 版本: v1.0 (2026-09-05)  zhangdansan(stevoo)
echo 【版本】 PC_host_5_设置ikuai端口转发_还原 v1.0 (2026-09-05)
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

cd /d "%~dp0.."
set "LANIP="
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /c:"IPv4"') do (
  if not defined LANIP set "LANIP=%%i"
)
set "LANIP=%LANIP: =%"
if "%LANIP%"=="" set "LANIP=192.168.50.113"
echo 本脚本不自动修改路由器, 只打印"撤销开放"需要手动做的内容
echo.
echo 【0】 打开路由器后台:
echo iKuai:  http://192.168.50.1  或  https://192.168.50.1:50501
echo 其他路由器: 浏览器填网关地址(ipconfig 里的"默认网关")
echo.
echo 【1】 还原前检测(进后台人工确认这两项):
echo a. DMZ 主机: 是否对 %LANIP% 启用着?
echo b. 端口映射列表: 是否存在以下规则?
echo TCP : 8190, 8191, 10881, 20200, 20201, 20202, 20203
echo UDP : 3478, 3479, 5730-5740
echo.
echo 【2】 执行还原(按你实际用过的项):
echo 用过 DMZ     ── 关闭 DMZ 主机功能,或移除 %LANIP%
echo 用过端口映射 ── 逐条删除上面列出的 TCP/UDP 规则
echo 两样都用过   ── 两个都撤(撤 DMZ + 删映射)
echo.
echo 【3】 还原后验证(在 PCclient / 任何外网机器上):
echo 浏览器打开 http://公网IP:8190/ 应该【打不开】= 已关闭
echo 打不开才是安全状态; 若还能打开, 回后台继续检查映射/DMZ
echo.
echo 【4】 其他路由器同理: 找到对应菜单删除规则/关闭 DMZ 即可
echo.
if not defined NOPAUSE pause
