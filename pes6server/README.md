# PES6 自建服务器 · 使用说明（README-部署说明.md 已更名 README.md）
> 章节编号说明：下方"零"为快速入口，"一"~"十五"为详尽章节（历史编号保持不变，避免外部引用失效）

> **PChost** = 主机 A 机（跑服务器、有公网 IP）｜ **PCclient** = 客机 B 机
> 修改人：zhangdansan(stevoo) ｜ 最后更新：2026-09-05 ｜ 本文档随每次改动同步更新
>
> **标注约定（持续要求，本文档所有结论必须遵守）**：
> 【已验证】= 本次实测过；【高可能】= 公开资料/社区经验一致但未实测；【待验证】= 必须实际测试才能下结论。
> 未经实测的结论不得标【已验证】；【待验证】项在实测通过后须更新为【已验证】并注明日期。
>
> **目录结构（分居后）**：
> - `D:\Games\friendPES6\dev` —— 开发区（游戏本体 + pes6server + git 仓库；本文档所有相对路径均基于此处）
> - `D:\Games\friendPES6\mess` —— 个人文件区（文本包存档等；不发布、不入库）
> - `D:\Games\friendPES6\release` —— 发布区（`make_release.bat` 同步工具 + 输出包 `friendPES6_release1.2`，主机/客机双角色可用）


> **文案约定（持续要求）**：全部脚本与文档的方括号一律用全角【】（含 [OK]→【OK】、步骤号→【1/6】）；
> 括号块内的 echo 文本禁止半角圆括号，一律用【】（半角 ) 会被 cmd 当作块结束符）。

## 零、两分钟看懂（先读这里）

**这是一套 PES6 联机服务器系统。** 仓库只含脚本+文档；游戏本体（版权）与 MySQL/Python（体积）不入库，按下述步骤补齐即可。

### 主机（你，需要有公网 IP 的宽带，从零开始 5 步）

1. **下载本仓库**（Code → Download ZIP，或 git clone），得到 `pes6server` 文件夹
2. **下载游戏本体**：PES6 完整游戏目录（PES6.exe / settings.exe / dat\），与 `pes6server` 并排放置：
   ```
   某个目录   ├── PES6.exe / settings.exe / dat   └── pes6server\        ← 仓库下载的文件夹
   ```
3. **下载 MySQL 5.7.44**：mysql-5.7.44-winx64.zip（MySQL 官网归档或社区镜像均可），解压为 `pes6server\mysql\mysql-5.7.44-winx64\`
4. **安装 Python 3.x**（python.org 下载，勾选 Add to PATH）——STUN/中继/RTT 组件运行环境
5. 双击 `pes6server\一键启动.bat` → 输入 `1` → UAC 确认 → 全自动（写注册表/起服务/配防火墙）→ 路由器开 DMZ 或按第六节做端口映射（一次性）→ 进游戏 NETWORK 建房，把**公网 IP**（一键启动窗口会显示）告诉朋友

### 客机（朋友，家庭宽带即可，不需要 Python/MySQL）

1. **主机把整个游戏目录打包发给他**（游戏 + pes6server 整套；主机侧 `release\make_release.bat` 可产出标准发布包，约 2.9G）——**MySQL/Python 都包含在内或不需要，客机零环境配置**
2. 解压后双击 `pes6server\一键启动.bat` → 输入 `2` → 输入主机公网 IP → 全自动（写注册表/补 UDP 端口/改 hosts/测延迟）
3. 浏览器开 `http://主机公网IP:8190/` 注册账号 → 进游戏 NETWORK → 登录 → 加房对战

### 关服

双方各跑一遍 `一键关闭.bat`（主机选 1 / 客机选 2）。

### 一图看懂分工

| | 主机（开服的人） | 客机（来玩的人） |
|---|---|---|
| 需要 | 公网 IP 宽带 + 游戏 + 仓库 + MySQL + Python | 只需完整包（含一切） |
| 操作 | 一键启动选 1 + 路由器设置一次 | 一键启动选 2 + 输入主机 IP |

## 一、这套东西是什么

在 PChost（有公网 IP 的那台电脑）上跑一个 PES6 联机大厅服务器（Fiveserver 0.4.8 社区开源版，PES6 模式俗称 Sixserver）+ 自建 STUN 应答器 + 便携版 MySQL。

- 全部"双击 bat"启动/关闭，不依赖 PVE / Docker / 任何第三方服务
- PCclient（朋友那台）通过互联网连进来，账号自己注册

## 二、环境要求

### PChost 主机（A 机）

| 项目 | 要求 | 说明 |
| --- | --- | --- |
| 操作系统 | Windows 10 / 11 | 已实测 Win10 |
| Python 3.x | **需要**（STUN 应答器用） | 已装 3.13 ✓；重装系统后装一个即可，勾选 Add to PATH |
| curl | Win10 系统自带 | 取公网 IP 用（双源在线检测） |
| MySQL / 大厅服务 | 已内置便携版 | 随 `pes6server` 文件夹分发，零安装 |
| 网络 | **真实公网 IPv4**（PPPoE 桥接拨号） | 已实测无运营商级 NAT |
| 路由器 | ikuai 后台权限 | 配置 DMZ 或端口映射（见第六节） |
| 目录布局 | 游戏文件夹与 `pes6server` **平级** | 一键启动默认按 `..\PES6.exe` 找游戏（找不到会提示手输路径） |
| 防火墙 | 开启时需放行游戏端口 | 跑 `PC_host_4` 脚本或允许弹窗 |

### PCclient 客机（B 机）

| 项目 | 要求 | 说明 |
| --- | --- | --- |
| 操作系统 | Windows 10 / 11 | — |
| 网络 | **家庭宽带**（电信/联通/移动均可） | ⚠ **手机热点不可用**：端口受限 NAT 过不了 STUN 检测（已实测无解） |
| Python | **不需要** | 家宽方案客机零脚本依赖 |
| 服务器组件 | 不需要运行 | `pes6server` 文件夹拷过去只是为一键脚本，其中服务组件闲置 |
| 游戏本体 | 与主机**同一版本**的游戏文件夹 | 首次一键启动会**自动运行 `install.bat`**（已随 `pes6server\scripts\` 分发），无需手动 |
| settings.exe | UDP 端口固定 5730（取消"自动"勾选）、UPnP 不勾 | 端口值一键流程会自动补丁并先备份；"自动"勾选与 UPnP 需在 settings.exe 手动取消一次 |
| 防火墙 | 允许 PES6.exe | 首次联网弹窗"专用+公用"都勾，或临时关闭 |
| 自家路由器 | 一般无需配置 | 若客机也卡 573x（NAT 偏严格），在客机自家路由器给它开 DMZ/端口映射 |
| 账号 | 自己注册一个 | 不能与主机同时使用同一账号（会顶号） |

### 目录与文件结构（分居后，实测对齐）

```
D:\Games\friendPES6\
├── dev\                            ← 开发区（游戏 + 项目 + git 仓库；本文所有相对路径基于此）
│   ├── PES6.exe / settings.exe     ← 游戏主程序与设置
│   ├── dat\                        ← 游戏数据（1.4G）
│   ├── kitserver\                  ← Kitserver 6.8.0（mod 框架；GDB 为球衣/球场等资源）
│   └── pes6server\                 ← 项目主体
│       ├── 一键启动.bat / 一键关闭.bat   ← 双击入口（先选角色：1 主机 / 2 客机）
│       ├── README.md               ← 本文档
│       ├── scripts\                ← 分步脚本（一键流程内部调用，也可单独跑）
│       │   ├── install.bat         ← 注册表写入（一键启动自动运行；目录变更自动重注册）
│       │   ├── PC_host_1_启动/关闭服务器.bat
│       │   ├── PC_host_2_注册账号-打开网页.bat
│       │   ├── PC_host_3_改hosts指向本机.bat / _还原.bat
│       │   ├── PC_host_4_添加防火墙放行.bat / _还原.bat（方案1 后休眠：防火墙规则常驻）
│       │   ├── PC_host_5_设置ikuai端口转发.bat / _还原.bat
│       │   ├── PC_client_1_改hosts.bat / _还原.bat   ← 客机用
│       │   ├── kit_resolution.ps1  ← kitserver 分辨率自适应
│       │   └── rtt_measure.ps1     ← 客机链路延迟测量
│       ├── mysql\                  ← 便携 MySQL 5.7.44（1.4G，data 内含账号库）
│       ├── fiveserver\             ← 大厅服务 Fiveserver 0.4.8
│       │   ├── etc\conf\sixserver.yaml  ← 服务配置（ServerIP 由一键启动自动写入）
│       │   ├── etc\keys            ← 协议密钥
│       │   └── log\sixserver.log   ← 大厅日志
│       ├── stun\                   ← 自建 STUN v8.1（单进程三线程）
│       │   ├── stun_server.py      ← STUN 3478/3479 + 中继 5731 + RTT 5735
│       │   └── log\                ← stun_run.log / rtt_results.log
│       └── _archive\               ← 归档（早期文档/构建物，不入库）
│
├── mess\                           ← 个人文件区（文本包存档等；不发布、不入库）
│
└── release\                        ← 发布区（仓库外）
    ├── make_release.bat            ← 双击：同步 dev 到下方输出包
    └── friendPES6_release1.2\      ← 输出包（2.9G，主机/客机双角色可用）
```
## 三、快速开始

### PChost 主机

1. 双击 `一键启动.bat` → 输入 `1`（主机）
2. 流程自动：启动服务（已运行跳过）→ 检查 hosts（没指对本机就自动改）→ 检查防火墙放行（没加就自动加）→ 询问路由器是否已设置 → 检查账号数（不足 2 个会打开注册页）→ 最后询问是否启动游戏
3. 进游戏 NETWORK → 网络测试 → 登录 → 进大厅

### PCclient 客机（家庭宽带环境）

1. 拷贝游戏文件夹 + `pes6server` 文件夹到客机
2. 首次运行一键启动时会**自动执行** `install.bat` 写注册表（新电脑无需手动）
3. 双击 `pes6server\一键启动.bat` → 输入 `2`（客机）
4. 流程自动：检测 install.bat → 检查/补丁 settings.dat（UDP 5730 自动补丁；"自动"勾选与 UPnP 需在 settings.exe 手动取消）→ 改 hosts 指向公网 IP → 防火墙提示 → 浏览器验证链路 → 询问启动游戏
5. 进游戏 NETWORK → 网络测试 → 登录 → 进大厅 → 加房对战

### 关服 / 断开

- **主机**：双击 `一键关闭.bat` → 输入 `1`（自动停服 + 还原 hosts + 删防火墙规则，最后打印路由器还原指引，按提示手动撤销 DMZ/映射）
- **客机**：双击 `一键关闭.bat` → 输入 `2`（自动还原 hosts）

## 四、分步脚本说明

`scripts\` 里的脚本是一键流程的"零件"，正常情况不需要手动跑；单独双击也完全可用（行为与一键流程一致）。

| 正向 | 还原 | 版本 |
| --- | --- | --- |
| PC_host_1_启动服务器 | PC_host_1_关闭服务器 | v1.0 |
| PC_host_2_注册账号-打开网页 | — | v1.0 |
| PC_host_3_改hosts指向本机 | PC_host_3_改hosts指向本机_还原 | v1.0 |
| PC_host_4_添加防火墙放行 | PC_host_4_添加防火墙放行_还原 | v1.0 |
| PC_host_5_设置ikuai端口转发 | PC_host_5_设置ikuai端口转发_还原 | v1.0 |
| PC_client_1_改hosts | PC_client_1_改hosts_还原 | v1.0 |

一键启动 / 一键关闭 当前均为 v1.0 (2026-09-05)。每个 bat 运行时会在窗口首行打印自己的版本号；版本变更规则：功能或行为有实质变化时递增小版本（v1.1），仅文案微调递增修订（v1.0.1）。

还原脚本都会：先检测现状 → Y/N 确认 → 执行 → 再验证并打印结果。

## 五、账号注册（双方各自有账号；同一账号两台机器同时登录会顶号）

浏览器打开 `http://127.0.0.1:8190/`（客机上则用 `http://公网IP:8190/`）

- 用户名：3 位以上字母数字
- 序列号：20 位游戏安装码，如 `A6V9D5HXPT62H4PFWA45`
- 密码：3 位以上

**游戏内登录格式（重要）**：

- 序列号栏 = 注册时的 20 位序列号
- 密码栏 = `用户名-密码`（减号连接，例如 `zhangdansan-abc123`）

哈希公式（与游戏客户端完全一致，已实测）：`md5(序列号大写去横线 + 补NUL到36位 + 用户名 + '-' + 密码)`

## 六、ikuai 路由器（PChost 侧，一次性；PC_host_5 脚本会打印同样内容）

端口转发（指向 PChost 内网 IP，如 `192.168.50.113`）：

| 协议 | 端口 |
| --- | --- |
| TCP | 8190, 8191, 10881, 20200, 20201, 20202, 20203 |
| UDP | 3478, 3479, 5730-5740 |

- 测试期可用 DMZ 代替；正式玩建议撤 DMZ 只留以上精确转发
- 建议：给 PChost 内网 IP 做 DHCP 静态绑定，防止 IP 漂移

## 七、公网 IP 变化（约每周一次）

重跑 `一键启动.bat`（主机）会在线实测新 IP 并写进配置和 STUN（双源检测：3322 两个源，都取不到会明确报错停止，不使用缓存文件）；客机重新双击 `一键启动.bat`（客机），按提示输入新 IP 即可（IP 以主机一键启动窗口显示的为准）。

## 八、已知限制与说明

- 手机热点（蜂窝 CGNAT）作为客机网络时，STUN 检测过不去（端口受限型 NAT，服务端已尽力，实测无解）——**客机请用家庭宽带**
- 客机家宽的路由器若也是端口受限型（少见），在客机自家路由器上给客机电脑开 DMZ/端口映射即可解决
- STUN 的"换IP"语义在单公网 IP 下用"换端口"替代（已实测可通过）
- 游戏内登录报 verification 错误：看 `fiveserver\log\sixserver.log` 的 authenticate_3003 段落定位
- MySQL 曾被强制断电/杀进程：InnoDB 会自动恢复，实测数据无损

## 九、安全收紧清单（联机跑通后建议执行）

1. ikuai 撤 DMZ，只留第七节的精确转发
2. Windows 防火墙全开 + 跑 `PC_host_4_添加防火墙放行.bat`
3. 修改管理页密码：`fiveserver\etc\conf\admin6.yaml`（默认 fives/fives）
4. 账号注册齐后，删除 ikuai 上 8190 端口的转发（关闭公网注册通道）
5. 定期备份 `mysql\data` 文件夹（账号与战绩都在里面）

## 十、排障速查

- **对战开始黑屏 = P2P UDP 握手失败**：登录/进房走服务器 TCP，对战是双方 P2P UDP(5730)。大厅日志中玩家的 udpPort1(公网出口端口)若 ≠ 5730(如被 NAT 改写为 30660)，主机按通告端口回发的对战流会被对方路由器丢弃【已验证 2026-09-05 实战：Andriy_Han udpPort1=30660 → 黑屏】。解决=在**对方**路由器给他开 DMZ 或 UDP 5730 映射，改后 udpPort1 变 5730 即生效
- **客机 ping 公网 IP 超时 ≠ 链路不通**：ping 走 ICMP，ikuai/Windows 默认丢弃 ICMP 而 TCP 正常放行【已验证 2026-09-05：外部节点 ping 全超时但 TCP 8190/10881 秒连】。正确验证方式=浏览器开 `http://公网IP:8190/` 看注册页，或直接游戏内网络测试

| 现象 | 看哪里 |
| --- | --- |
| 连接测试报"无法连接服务器"（STUN 阶段失败） | 客机 hosts 是否指向公网 IP；ikuai 转发/DMZ；PChost 防火墙是否放行 |
| 报 "Unable to transmit using UDP port 573x"（573x 收发检查失败） | 主机侧 DMZ/端口映射（UDP 5730-5740）是否生效 |
| 登录报 verification 错误 | `fiveserver\log\sixserver.log` 的 authenticate_3003 段落 |
| 大厅进不去但测试通过 | TCP 20200/20201/20202 转发 |
| 一键启动里出现 [X] 项 | 按提示手动跑对应分步脚本 |

## 十一、待办事项（TODO）

### 待验证 · 明天

- [ ] 一键启动.bat 主机模式全流程实测（含 MySQL 修复后的真实启动）
- [ ] 一键启动.bat 客机模式全流程实测（B 机家庭宽带）
- [ ] 一键关闭.bat 主机/客机两种模式实测（含还原效果确认）
- [ ] 游戏 A↔B 实际对战一局，确认 P2P 直连与延迟
- [ ] 对战确认后执行第十节安全收紧，并复测一切正常

### 后期增强路线

**⑧ 中文汉化**

- 【失败作废 2026-09-06】2009 中文版 e_text.afs 与本游戏 dat 结构不兼容：新建房间必现 0xc0000005@0x55dd24(二分法排除 kitserver 与分辨率)；已全量复原英文原版(PES6_Base)，中文文件以 .chinese 后缀保留于 dev/1.0/1.1 三处 dat；- 【待找】兼容原版 PES6 1.0 dat 结构的正规汉化补丁；AFS 文本条目结构不匹配是崩溃根因，换补丁时必须核对目标游戏版本
- 【待验证】roster hash 是否含 e_text 成分：11:35 朋友登录 hash 仍为 {57ce0623...}，但无法确定其当时文本版本(用户回退英文与朋友同步的时间点无记录)；"两边必须同版汉化否则 hash 分叉"维持【怀疑】。当前两边均为英文(用户确认)；主机须保持英文(中文 e_text 建房间必崩【已验证】)
- 【待办】新 e_text.afs 必须发给朋友覆盖其 dat 内同名文件(英文旧版)，否则 roster hash 分叉 → 开局同步失败
- 原英文版未入 git(dat/ 排除)；D:\Games 下其他 PES6 目录有同版英文文件可还原
- "联机必须英文文本"的旧说法：双侧同版即可，中英文本身不设限【待验证，以明日实战为准】

**⑨ Kitserver**

- PES6 通用 mod 框架（球衣/球场/足球/参数/lod）
- 版本已确定【已验证 2026-09-05 官方 history.txt】：权威版本源=kitserver.mapote.com/ks6/history.txt，最新为 **6.8.2**(2021-04-22, skinserver+窗口化)，其后为 6.8.1(2020-05-05)/6.8.0(2020-05-02, juce&robbie, 用户手中持有, 联机功能完全够用)；6.8.x 二进制经社区渠道分发(EvoWeb/Facebook EFLPatchPES6 的 mediafire)，mapote 官方文件库仅托管到 kitserver-572；源码：github.com/kitserver/kitserver6
- 安装：解压至游戏根目录(dev)→运行 setup.exe；两台机器必须同版本；装完后 make_release 复制清单需补 kitserver 目录及根目录新增 dll【待办】
- 官方 howto 提到 kitserver 的 network.cfg 可直接指定 network.server=服务器地址——在 PES6 下是否同样生效【待验证】，若可用可替代改 hosts 的方案

**⑩ 统一 Option File**

- 双方存档/编辑数据必须完全一致，否则对战时 roster hash 对比失败（sixserver 配置 Roster.compareHash=true）
- 方案：在 PChost 上定稿 OF 后，随打包统一分发

**⑪ 最终打包给朋友**

- 打包与同步：双击 `D:\Games\friendPES6\release\make_release.bat`，把 `dev` 同步到 `release\friendPES6_release1.0\`；内容=游戏本体(PES6.exe/settings.exe/dat)+pes6server 完整组件(主机+客机双角色：一键启动/一键关闭/scripts/mysql/fiveserver/stun/README)；自动排除 _archive、日志、编译缓存；robocopy /MIR 增量+关键文件校验(主机与客机各一组)
- 附精简说明：注册地址/游戏内登录格式/常见问题三条
- 验收标准：找一台全新电脑，按包内说明从零走到进大厅

### 后续可选

- [ ] 热点场景后手：客机本地 UDP 中继脚本（未实施，需要时再做）
- [ ] DDNS 自动化：公网 IP 变化时客机 hosts 自动跟随（现为手动）
- [ ] 日志改名：`fiveserver\log\sixserver.log` → 更直观的名字（待确认）
- [ ] 管理页默认密码修改（admin6.yaml，fives/fives → 自定义）
- [ ] mysql\data 定期备份（账号/档案/战绩）
- [ ] 二进制等长补丁："SYSTEM: Fiveserver v0.4.8" 横幅字样定制（仅外观）
- [ ] UPnP 标志位定位：拿到"勾选/不勾"两份 settings.dat 做 diff 找到标志字节后，客机流程可自动关闭 UPnP（现为一键提示+手动）

### 明日联机清单（2026-09-06，按此执行不遗漏）

**主机侧（用户动手）**
1. 装 Kitserver 6.8.0：解压到 `dev\`（PES6.exe 同目录）→ 运行 setup.exe → 游戏启动见 kitserver 横幅
   （直链 MEGA：https://mega.nz/file/JV01zAab#g2vjKk0yqdNsQGd8VikBySgj3ucuoMaO98ckAl2_qrU ）
2. 装完告诉 ZCode：补 make_release 复制清单（kitserver 目录 + 根目录新增 dll）→ 同步 release
3. 把 `kitserver\` 文件夹 + 根目录新增 dll 通过 QQ/网盘发给朋友，朋友放进他的游戏根目录（两边版本必须一致）
4. 主机栈重启：release\...\一键关闭.bat → 一键启动.bat，主窗口确认【OK】 STUN 中继 5731 已监听

**ZCode（开赛时）**
1. 确认 5731 监听 + 中继日志出现两个端点（主机回环端点 + 朋友公网端点）
2. 赛后拉取：中继统计(双方收包数)/STUN 探测/sixserver 房间事件/防火墙收发记录
3. 【已验收 2026-09-06 实战】中继修复后首战：端点还原生效(统计显示 192.168.50.113:5730 而非死路地址 192.168.50.1:5730)，双向流 26/23 包每秒、防火墙零丢包，用户体感明显改善——黑屏问题终结 ✓；剩余延迟构成=双方帧率+PES6 联机固有输入延迟+朋友 WiFi/RTT
6. 【v8 准备顺序修复待实战】实测确认"朋友先准备→黑屏"机制：朋友先准备的流到达中继时主机游戏尚未开始流，中继转发到 SNAT 假地址(192.168.50.1:5730)成死路，朋友的同步窗口耗尽即黑屏(日志实证: 双端点出现间隔 34-42 秒的局全部黑屏, 间隔 2 秒的成功)。v8 预注册主机游戏固定端点(192.168.50.113:5730)为永久中继目标——朋友先准备的流从第一包起即直达主机游戏，准备顺序从此无关。本地模拟实测通过；需重启一次栈生效
5. 【RTT 实测 2026-09-06】客机【5/5】自动测量结果：朋友链路平均 13.0ms(最小 11.3/最大 21.2, 20/20 全回应, 零丢包)——网络层全链路验收完毕, 无可优化空间；结果存于 stun\log
tt_results.log(每局自动追加)
4. 【注意】主机已回退英文 e_text——须确认朋友侧同为英文版；若朋友已装中文版则两侧 roster hash 分叉风险
5. 【用户决定 2026-09-06】路由器维持 DMZ（端口映射 6 条规则清单已给出，用户选择暂不加）——DMZ 下全链路已实测验收(TCP/中继/RTT 13ms)；端口映射清单保留在本记录上方，随时可切换

**朋友侧（转告，共 3 件）**
1. 完全退出游戏重新启动、重新登录 Andriy_Han（必须，重新 STUN 拿中继地址）
2. 把收到的 kitserver 文件放进他的游戏根目录（与主机同版本）
3. 防火墙保持关闭/360 保持退出（或给 PES6 放行）；他家光猫**无需任何配置**（中继已绕开）
5. 【补充】internal.resolution **无需两人一致**【机制确定】：它是 kitserver 的纯本地渲染参数，不进入联机同步数据流（锁步同步交换的是操作输入）；两边各自按机器性能调，帧率优先——主机 4K 渲染与朋友降载调低互不影响
4. 汉化暂缓：当前为英文界面联机版；找到兼容原版 1.0 的汉化补丁后，两台机器统一替换
5. 【已自动化】RTT 测量融入客机【5/5】：主机栈常驻 RTT 应答器(udp/5735, 随一键启动/关闭启停)，客机一键启动到【5/5】时自动完成 20 次探测并回传结果，主机日志 `stun\log
tt_results.log` 逐包记录 RTT——朋友零操作【2026-09-06 实测回环 0.2-0.5ms 全通】

**判定标准**
- 开赛后 stun_run.log 中继统计出现双方端点且收包数持续增长 = 对战流经中继互通
- 若中继统计双向正常但仍黑屏 → 问题不在网络，转查游戏本体（Win7 兼容/游戏报错截图）

## 十二、Git 版本管理

- 仓库根：`D:\Games\friendPES6\dev`（游戏 + pes6server 整体管理；release 在仓库外），分支 `main`
- 提交身份（仓库级）：`zhangdansan(stevoo)` / `stevoo@users.noreply.github.com`
  —— 推送 GitHub 前建议把 email 换成真实邮箱：`git config user.email "你的邮箱"`
- **不入库内容**（.gitignore 已配置）及原因：

  | 排除项 | 原因 |
  | --- | --- |
  | PES6.exe / settings.exe / dat\ / opmov\ | Konami 版权文件，公开仓库有 DMCA 风险；AFS 单文件数百 MB 超 GitHub 限制 |
  | pes6server\mysql\（程序+数据） | MySQL 程序 1.3GB 远超限制；data 含账号数据 |
  | 各日志目录、_archive\_build\ | 体积大且非交付物 |

- 因此 GitHub 仓库只含"脚本 + 配置 + 文档 + 小体积服务端件"；**全新机器部署时，MySQL 程序与游戏本体需另行分发**（与⑪最终打包一致）
- 推送 GitHub 步骤（届时）：GitHub 建仓库（建议 **Private**）→ `git remote add origin https://github.com/<用户名>/<仓库名>.git` → `git push -u origin main`


## 十三、项目引用与致谢

> 完整修改历史见 [CHANGELOG.md](./CHANGELOG.md)（280+ 条逐时记录）

- Kitserver 6.8.x —— juce & robbie（版本记录：https://kitserver.mapote.com/ks6/history.txt ｜ 源码：https://github.com/kitserver/kitserver6 ）
- Fiveserver 0.4.8 —— PES6/WE2007 大厅服务端（evo-league 社区项目分支）
- MySQL 5.7.44 —— Oracle Community Edition（便携版打包）
- 自建 STUN/中继/RTT（stun_server.py）—— 本项目原创组件（RFC3489 语义 + 端点学习式中继）
- PES6vn 方案调研参考 —— https://pes6.online/huong-dan （已归档于 _archive）

## 十四、支持作者（微信收款码）

如果这套自建服务器帮你和朋友重新踢上了实况，请作者喝杯饮料：

![微信收款码](./weixin_qrcode.png)

（将 `weixin_qrcode.png` 放在本 README 同目录即可显示）

---

| 2026-09-07 13:09 | 发布准备：①sixserver.yaml 脱敏(ServerIP 置空待运行时自动写入, 管理密码占位 CHANGE-ME)；②修复文档头部目录结构块的 3 处控制字符残损(/ 转义坑, friendPES6/release 被吞字母)并规范化为带完整路径与连接符的三行清单；③文末新增【十四、项目引用与致谢】【十五、支持作者(微信收款码占位 ./weixin_qrcode.png)】

| 2026-09-07 13:11 | 游戏设置状态确认：settings.dat UDP=5730 ✓("自动"不勾/UPnP 勾选为当前有效配置，随包分发的一键启动会自动补丁+校验)；git 仓库不含 settings.exe/dat(gitignore)，发布包内含——游戏设置与 GitHub 发布无交集
【维护约定】本文档随每次改动同步更新，不另行通知。
| 2026-09-07 13:20 | 规范化：①README-部署说明.md 更名 README.md；②头部新增【零、两分钟看懂】(主机/客机各3步+完整包获取说明, 回答小白下载即玩预期)；③修复文尾粘连

【维护约定】本文档随每次改动同步更新，不另行通知。
| 2026-09-07 13:35 | 文档瘦身：①目录与文件结构重写为标准树形图(├── 全级展开)；②全文再清 3 处控制字符残损；③十三节修改记录拆分至 CHANGELOG.md(README 引用之)，引用/致谢/收款码重排为十三/十四
