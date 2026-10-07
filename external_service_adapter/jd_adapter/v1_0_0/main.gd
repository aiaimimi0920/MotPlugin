extends PluginAPI

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

func _on_init()->void:
	super._on_init()
	set_plugin_info(plugin_name,"jd_adapter","mimi",plugin_version,
		"Provide jd ware search and info get","service",{})
	Logger.add_file_appender_by_name_path(PluginManager.get_plugin_log_path(plugin_name), plugin_name)
	var cur_new_conversation = ConversationManager.get_conversation_by_plugin_name(plugin_name, true)

func _ready()->void:
	service_client = load(get_absolute_path("modules/client.gd")).new()
	service_loader = load(get_absolute_path("modules/loader.gd")).new()
	service_config_manager = load(get_absolute_path("modules/config_manager.gd")).new()
	service_protocol_handle = load(get_absolute_path("modules/protocol_handle.gd")).new()
	ware_script = load(get_absolute_path("api/ware/ware.gd"))
	init_all_node()
	start()
	pass

var ware_script
var ware_node

func init_all_node():
	ware_node = ware_script.new()
	add_child(ware_node)

func get_search_ware_need_args():
	return {"keyword":"","max_result":-1}

func search_ware(adapter_need_data):
	var keyword = adapter_need_data["keyword"]
	var max_result = adapter_need_data.get("max_result",-1)
	var ware_info_list = await ware_node.search_ware(keyword, max_result)
	var result_ware_info = create_ware_info_nodes(ware_info_list["ware_infos"])
	return result_ware_info

func get_get_ware_info_need_args():
	return {"sku_id":0}

func get_ware_info(adapter_need_data):
	var sku_id = adapter_need_data["sku_id"]
	var ware_info = await ware_node.get_ware_info(sku_id)
	var result_ware_info = create_ware_info_nodes([ware_info])
	return result_ware_info


func create_ware_info_nodes(data):
	var result_ware_info = []
	for ware_info in data:
		var cur_data = {
			"specs":ware_info["specs"],
			"images":ware_info["images"],
			"sku_id":ware_info["sku_id"],
			"comments":ware_info["comments"],
			"comments_info":ware_info["comments_info"],
			"price":ware_info["price"],
			"parameters":ware_info["parameters"],
			"url":ware_info["url"],
		}
		if cur_data["sku_id"]!="" and cur_data["price"]!="" and cur_data["url"]!="":
			var cur_ware_info = WareInfo.new(cur_data)
			result_ware_info.append(cur_ware_info)
	return result_ware_info

func _on_unload()->void:
	service_client.disconnect_to_service()
	service_loader.kill_service()
	pass


var service_client
var service_loader
var service_config_manager
var service_protocol_handle


func start()->void:
	service_config_manager.connect("config_loaded",_config_loaded)
	service_config_manager.name = "ConfigManager"
	service_client.name = "Client"
	service_loader.name = "Loader"
	add_child(service_config_manager,true)
	add_child(service_client,true)
	add_child(service_loader,true)
	service_config_manager.init_config()

func _config_loaded()->void:
	if await service_loader.load_service() == OK:
		Logger.info("Waiting for {plugin_name} backend to complete initialization steps, please wait".format({"plugin_name":plugin_name}))

		if OS.has_feature("editor") and service_loader.test_mode == service_loader.TEST_MODE.TEST_SCRIPT:
			await get_tree().create_timer(10).timeout
		else:
			await service_loader.service_ready

		service_client.connect_to_service(get_ws_url())


func get_ws_url()->String:
	return service_config_manager.service_address_port


func is_service_connected()->bool:
	return service_client.is_service_connected()

func is_ready()->bool:
	if is_service_connected():
		return true
	await service_client.client_connected
	return true

func send_service_request(server_syncId, content:Dictionary, caller:Callable,_timeout:float=-INF)->Dictionary:
	if _timeout <= -INF and service_config_manager.request_timeout > 0.0:
		_timeout=service_config_manager.request_timeout
	return await service_client.send_service_request(server_syncId, content, caller, _timeout)


class WareInfo:
	var sku_id = ""
	var specs = {}
	var images = []
	var comments = []
	var comments_info = {}
	var price = ""
	var url = ""
	var parameters = {}
	
	func _init(data) -> void:
		specs = data["specs"]
		parameters = data["parameters"]
		images = data["images"]
		sku_id = data["sku_id"]
		comments = data["comments"]
		comments_info = data["comments_info"]
		price = data["price"]
		url = data["url"]

	func get_structured_output():
		var cur_data = {
			"唯一id":sku_id,
			"商品图片链接":images,
			"商品相关评论":comments,
			"商品评论总结":comments_info,
			"规格":parameters,
			"介绍":specs,
			"价格":price,
			"购买链接":url,
			"商品来源":"京东",
		}
		return cur_data
		
	func get_structured_json_output():
		var cur_data = get_structured_output()
		var json_string = JSON.stringify(cur_data)
		return json_string
		
