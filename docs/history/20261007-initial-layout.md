# mot_plugin：具体插件开发入口

本目录的目标是按具体插件组织业务实现、适配层、外部服务、配置与资源。当前只建立职责和迁移入口，**没有把旧插件的物理位置迁到这里**。

## 当前唯一源码位置

| 类别 | 路径 |
| --- | --- |
| 面向用户的功能插件 | [`../mot_gui/plugin/`](../mot_gui/plugin/) |
| Godot 服务适配代码 | [`../mot_gui/external_service_adapter/`](../mot_gui/external_service_adapter/) |
| Python 等外部服务 | [`../mot_gui/external_service/`](../mot_gui/external_service/) |

旧工程通过 `res://plugin/...`、`res://external_service_adapter/...` 和 `res://external_service/...` 加载、引用和打包资源。Godot 的 `res://` 以 `mot_gui/project.godot` 所在目录为根；直接搬到仓库同级目录会破坏这一关系。

因此本轮保留单一源码，不创建双份插件、不使用机器专属软链接，也不引入未经验证的自动同步脚本。

## 后续迁移边界

物理拆分必须连同资源引用、插件发现、打包方式及本地/云端执行位置一起处理并验证，不能仅移动一个 `plugin/` 目录就认定完成。

插件业务实现与插件系统的加载、调用、权限机制分开：后者根据职责由智能核心或客户端负责。本目录不自动成为所有运行时机制的归属地，也不预先规定插件语言或协议。
