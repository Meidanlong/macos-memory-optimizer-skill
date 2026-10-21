# 常见内存大户速查表

| 大户 | 进程特征 | 典型占用 | 何时可安全释放 | 调小方法 |
|---|---|---|---|---|
| Colima / Lima VM | `com.apple.Virtualization.VirtualMachine` + `limactl hostagent` | 4~16 GiB | 不用 Docker 时 `colima stop` | `colima stop && colima start --memory 4` |
| Docker Desktop | `com.docker.backend` / `com.docker.virtualization` | 4~8 GiB | 退出 Docker Desktop | Settings → Resources → Memory 调小 |
| Chrome / Edge | 多个 `Renderer` / `GPU` / `Browser Helper` | 1~4 GiB | 关标签页、退出浏览器 | 开内存节省模式 |
| VSCode | `Code Helper (Renderer)` 多进程 | 0.5~2 GiB | 关不用的窗口/工作区 | 禁用不常用扩展 |
| JetBrains IDE | `<IDE>.app/Contents/MacOS/<IDE>` + `jetbrains-toolbox` | 0.5~2 GiB/个 | 关不用的项目窗口 | 调 `.vmoptions` 堆内存 |
| 微信 | `WeChat` | 0.5~1.5 GiB | 退出客户端（注意未保存消息） | - |
| 飞书 Lark | `Lark` / `Feishu` | 0.5~1.5 GiB | 退出客户端 | - |
| 钉钉 | `DingTalk` | 0.3~1 GiB | 退出客户端 | - |
| node 开发服务 | 多个 `node` 进程 | 0.2~1 GiB/个 | 关掉不用的 dev server | - |
| Android Emulator | `qemu-system-x86_64` / `emulator` | 2~8 GiB | 不调试安卓时退出 | AVD 编辑里调 RAM |
| Xcode | `Xcode` / `SourceKitService` | 1~4 GiB | 关掉不编译的项目 | - |
| 系统索引 | `mds_stores` / `mdworker_shared` | 0.1~1 GiB | 不要杀，等索引完 | - |
