# X86 v3：透明网桥代理构建

工作流：`.github/workflows/X86-v3.yml`，基于 v2，保留 x86_64、SquashFS、Passwall、ZeroTier 和默认 LAN IP `10.1.1.99`。v2 不变。v3 使用触发工作流的提交，手动运行时使用所选分支，不再固定 checkout master。

## 编译内容

- 使用 Passwall 官方的 `passwall` 和 `passwall_packages` feeds；在 runner 上排除 helloworld feed 和 SSR Plus，避免重复代理包。
- 使用 LEDE 默认 firewall3 / iptables 后端，显式包含 Xray、TPROXY、socket、NAT、ipset 和 dnsmasq-full 的 ipset 支持。
- 包含 `kmod-br-netfilter`、`iptables-mod-physdev`、`ip-full`、`ip-bridge`，用于桥接流量接管、物理端口匹配及诊断。
- 不包含 TurboACC LuCI 包。此选项不等于运行时所有加速机制均已关闭，尤其是保留旧配置升级时。
- `make defconfig` 后检查必要选项，缺包即停止。独立的 `-config` artifact 保存完整配置、精简配置、feed 地址和实际提交版本。

两个本地目录并列放置不会自动进入 Actions；工作流通过远端 feeds 拉取。feeds 当前跟随 main，保存提交号用于追踪本次构建，不代表已锁定依赖版本。

## 刷机后仍需配置

固件只准备模块和工具，不自动改变物理网口，不自动打开 bridge netfilter。启用过滤前需要同时准备正确的防火墙和代理规则，否则可能中断桥接通信。

1. 确认实际网口名。两个业务口分别连接主路由 LAN 和下游交换机，加入同一网桥；第三口建议用不同网段作独立管理口。
2. 业务网桥设置主路由 LAN 网段内不冲突的 IP，默认网关和 DNS 指向主路由。若该网段不是 `10.1.1.0/24`，需调整默认地址。原 WAN 接口不能继续占用已加入网桥的网口。
3. 关闭业务网桥的 DHCPv4、DHCPv6 服务和 RA 通告，由主路由继续分配地址；不要为了关闭 DHCP 而停掉 Passwall 需要的 DNS 服务。
4. 本固件的模块默认配置将 `net.bridge.bridge-nf-call-iptables` 和 `net.bridge.bridge-nf-call-ip6tables` 设为 `0`。配置 IPv4 接管时，确认模块加载、规则就绪后将前者持久化为 `1`。IPv6 需明确选择代理还是透传，不能仅打开开关便视为完成。ARP 过滤无需为此开启。
5. 配置 Passwall 节点和下游访问控制，检查桥接口/物理入口匹配、TCP 重定向、UDP TPROXY、策略路由及防火墙放行。`br-netfilter` 是必要依赖之一，不保证单独打开后所有代理模式即可在桥接拓扑正常工作。
6. 配置 DNS 接管/转发以配合域名分流，分别验证 TCP/UDP 53；普通 DNS 重定向不会自动接管 DoH/DoT。
7. 首次验证关闭软件/硬件流量加速、SFE 等可能绕过规则的功能；保留配置升级时尤其需要检查旧设置。

## 验证范围

先用一台下游电脑测试：从主路由获取地址、默认网关仍为主路由、直连和代理出口符合策略、DNS 分流和 UDP 正常；再检查 IPv6 策略、规则计数、Passwall 重启、防火墙重载与系统重启后的行为。只有实际经过业务网桥的流量受影响。

GitHub Actions 编译成功只确认构建，不能替代三网口设备上的实机验证。普通网卡断电不具备自动物理旁路能力。

## 检查 `make defconfig` 的结果

v3 在配置校验之前上传 `${VERSION}-before-verification` artifact，包含 `config.after-defconfig` 和 `config.after-defconfig.diff`。即使后续校验失败，也可下载此 artifact 查找 `CONFIG_PACKAGE_kmod-ipt-nat` 等选项的实际值。

手动运行并勾选 `debug_tmate` 时，v3 先从 Ubuntu 软件源安装 tmate，再进入 SSH 调试步骤；连接会话最长等待 20 分钟。调试会话只允许触发者 GitHub 账号中登记的 SSH 公钥连接。完成检查后，可在会话中执行 `touch continue` 继续工作流。
