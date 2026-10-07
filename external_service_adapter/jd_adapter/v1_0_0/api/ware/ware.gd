extends Node

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

var sub_protocol = preload("./sub_protocol.gd")

func _ready():
	register_all_protocol()

func register_all_protocol():
	## 注册所有的服务端调用协议
	var service_protocol_handle = plugin_node.service_protocol_handle
	service_protocol_handle.register_protocol_format_with_object(sub_protocol, self)
	
func search_ware(keyword, max_result=10):
	if max_result == -1:
		max_result = 10
	var data = {}
	data["keyword"] = keyword
	data["max_result"] = max_result
	var result = await C_S_SEARCH_WARE(-1, data)
	return result


func get_ware_info(sku_id):
	var data = {}
	data["sku_id"] = sku_id
	var result = await C_S_GET_WARE_INFO(-1, data)
	return result


## The method name has the same name as the sub protocol
func C_S_SEARCH_WARE(server_syncId, content):
	## C_S_TEST为当前调用的方法的字符串，暂时没有找到可以直接获得当前方法名字的方法
	return await plugin_node.send_service_request(server_syncId, content, Callable(self, "C_S_SEARCH_WARE"), 600)

## The method name has the same name as the sub protocol
func S_C_SEARCH_WARE(server_syncId, content):
	pass


## The method name has the same name as the sub protocol
func C_S_GET_WARE_INFO(server_syncId, content):
	## C_S_TEST为当前调用的方法的字符串，暂时没有找到可以直接获得当前方法名字的方法
	return await plugin_node.send_service_request(server_syncId, content, Callable(self, "C_S_GET_WARE_INFO"), 600)
	
## The method name has the same name as the sub protocol
func S_C_GET_WARE_INFO(server_syncId, content):
	pass

