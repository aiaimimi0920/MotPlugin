# 插件开发状态

三个源码目录按原样迁入，没有修改业务脚本，也没有与 MotGUI 保持源码副本。每个具体插件自己的后续说明应跟随该插件，通用开发约定保存在本目录。

## 尚未解决

- GDScript 仍依赖 MotGUI 的全局对象、`res://` 路径、加载器和打包流程，独立检出并不能直接运行。
- Python `.spec` 有旧机器绝对路径，至少一处旧 `VMe_Plugin/.../v1_0_0/free_ai` 位置已失效。
- 没有可复现的 requirements 或锁文件，模型缓存和历史环境不是仓库内依赖。
- 旧 BAT 可能安装浏览器并调用 PyInstaller，本轮没有执行。

插件宿主的编排、加载与权限机制由 MotCore/MotGUI 按职责承担；本仓库维护具体插件实现，不把协议或核心运行时一起塞入插件目录。

## 已处理的历史敏感配置

初始恢复时两处音乐插件 Python 源码已将历史硬编码值改成读取环境变量：

- `MOT_BAIDU_SPEECH_APP_ID`
- `MOT_BAIDU_SPEECH_API_KEY`
- `MOT_BAIDU_SPEECH_SECRET_KEY`
- `MOT_QIANQIAN_SIGNING_SECRET`

没有 `.env` 自动加载功能。调用对应功能而缺少变量时抛出 `KeyError`；显式传入 `baiduspeech_params` 的路径保留。不得把旧恢复镜像或凭据提交到本仓库。

## 历史文档

`history/20261007-initial-layout.md` 是插件仍在 GUI 内时的原始记录，旧路径和相对链接仅用于追溯，不是当前操作说明。完整多来源恢复记录保存在 MotGUI 的 `docs/recovery/`，本仓库不复制维护该历史报告。
