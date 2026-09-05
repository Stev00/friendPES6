@echo off
rem 版本: v1.0 (2026-09-05)  zhangdansan(stevoo)
echo 【版本】 PC_host_5_设置ikuai端口转发 v1.0 (2026-09-05)
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
echo 本脚本不自动修改路由器, 只打印需要手动配置的内容
echo.
echo 【0】 打开路由器后台:
echo iKuai:  http://192.168.50.1  或  https://192.168.50.1:50501
echo 其他路由器: 浏览器填网关地址(ipconfig 里的"默认网关")
echo.
echo 【1】 本机内网 IP(下面要填的就是它): %LANIP%
echo 建议在路由器里给这个 IP 做静态绑定, 防止以后变动
echo.
echo 【2】 方式一(简单, 测试期推荐): DMZ 主机
echo 后台找 "DMZ主机" / "DMZ" 菜单, 填 %LANIP% 并启用
echo 效果: 该电脑所有端口对公网开放 —— 仅测试期用
echo.
echo 【3】 方式二(精确, 正式推荐): 端口映射 / 端口转发
echo 后台找 "端口映射" / "端口转发" / "虚拟服务器" 菜单:
echo 协议  外部端口                                内部地址  内部端口
echo TCP   8190,8191,10881,20200,20201,20202,20203  %LANIP%  同外部
echo UDP   3478,3479,5730-5740                      %LANIP%  同外部
echo.
echo 【4】 验证是否生效(在 PCclient / 任何外网机器上):
echo 浏览器打开 http://公网IP:8190/  能看到注册页 = 链路通
echo 公网 IP 可先双击 PC_host_1-启动服务器.bat, 窗口里会显示
echo.
echo 【5】 其他路由器同理: 菜单名不同(虚拟服务器/转发规则/NAT),
echo 填法完全一致
echo.
if not defined NOPAUSE pause
