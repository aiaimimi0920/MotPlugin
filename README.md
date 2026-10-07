# MotPlugin

Mot 具体插件的独立开发仓库：https://github.com/aiaimimi0920/MotPlugin 。

| 目录 | 内容 |
| --- | --- |
| `plugin/` | 面向用户的功能插件 |
| `external_service_adapter/` | Godot 侧服务适配代码 |
| `external_service/` | Python 等外部服务源码 |

三个目录的 806 个文件已从客户端工程迁入，本仓库是它们的唯一维护源。后续逐插件拆分适配层与服务的内部组织方式，本轮不做。

- [开发状态、敏感配置与运行断点](docs/DEVELOPMENT.md)
- [旧插件分支的原许可声明](docs/LEGACY_PLUGIN_LICENSE)
- [迁移前的历史状态](docs/history/20261007-initial-layout.md)

**源码归属已独立，不等于运行解耦已经完成。** 旧 GDScript 依赖客户端资源和全局对象，Python 依赖环境未锁定；没有创建新的插件宿主或执行打包。

保留原仓库 LICENSE 和旧插件分支、组件的许可声明，不把迁移视为重新授权。
