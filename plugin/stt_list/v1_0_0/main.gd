extends PluginAPI

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

signal add_stt_adapter
signal update_transcribed_msg
signal model_list_update

func _on_init()->void:
	super._on_init()
	set_plugin_info(plugin_name,"stt_list","mimi",plugin_version,"Collection of stt methods",
		"plugin", {})
	Logger.add_file_appender_by_name_path(PluginManager.get_plugin_log_path(plugin_name), plugin_name)
	var cur_new_conversation = ConversationManager.get_conversation_by_plugin_name(plugin_name, true)


var service_config_manager

func start()->void:
	service_config_manager.connect("config_loaded",_config_loaded)
	service_config_manager.name = "ConfigManager"
	add_child(service_config_manager,true)
	service_config_manager.init_config()

func _config_loaded()->void:
	pass

func _ready()->void:
	service_config_manager = load(get_absolute_path("modules/config_manager.gd")).new()
	start()
	
var stt_adapter_name_list = []
var stt_adapter_name_map = {}

func sort_stt_adapter(a, b):
	if stt_adapter_name_map[a] < stt_adapter_name_map[b]:
		return true
	if stt_adapter_name_map[a] == stt_adapter_name_map[b]:
		if a<b:
			return true
		return false
	return false

func trigger_stt_adapter(adapter_plugin_name, target_index):
	stt_adapter_name_map[adapter_plugin_name] = target_index
	stt_adapter_name_list=stt_adapter_name_map.keys()
	stt_adapter_name_list.sort_custom(sort_stt_adapter)
	var stt_plugin_adapter = await PluginManager.get_plugin_instance_by_script_name(adapter_plugin_name)
	stt_plugin_adapter.connect("update_transcribed_msg",update_transcribed_msg_func.bind(adapter_plugin_name))
	stt_plugin_adapter.connect("model_list_update",model_list_update_func.bind(adapter_plugin_name))
	emit_signal("add_stt_adapter",adapter_plugin_name)

var user_preferred_stt:
	get:
		return service_config_manager.preferred_stt

func update_transcribed_msg_func(index, is_partial, new_text, process_time, adapter_plugin_name):
	emit_signal("update_transcribed_msg", index, is_partial, new_text, process_time, adapter_plugin_name)

func model_list_update_func(adapter_plugin_name):
	emit_signal("model_list_update", adapter_plugin_name)
	

func get_use_stt_plugin_name(stt_plugin_name, used_plugin_name):
	if stt_plugin_name!="":
		return stt_plugin_name
	var cur_user_preferred_stt = user_preferred_stt.split(",",false)
	if cur_user_preferred_stt.size()!=0:
		for value in cur_user_preferred_stt:
			if value not in used_plugin_name:
				return value
	for value in stt_adapter_name_list:
		if value not in used_plugin_name:
			return value
	return ""
	

func get_use_stt_plugin(stt_plugin_name, used_plugin_name):
	stt_plugin_name = get_use_stt_plugin_name(stt_plugin_name,used_plugin_name)
	if stt_plugin_name=="":
		return null
	var stt_plugin_adapter = await PluginManager.get_plugin_instance_by_script_name(stt_plugin_name)
	return stt_plugin_adapter
	
func get_ui_instance():
	var cur_node = load(get_absolute_path("ui/main.tscn")).instantiate()
	return cur_node


func start_listen(language_model=null, language=null, use_gpu=null, stt_plugin_name="", used_plugin_name=[]):
	var stt_plugin_adapter = await get_use_stt_plugin(stt_plugin_name, used_plugin_name)
	if stt_plugin_adapter==null:
		return false
	await stt_plugin_adapter.start_listen(language_model, language, use_gpu)

func stop_listen(stt_plugin_name="", used_plugin_name=[]):
	var stt_plugin_adapter = await get_use_stt_plugin(stt_plugin_name, used_plugin_name)
	if stt_plugin_adapter==null:
		return false
	await stt_plugin_adapter.stop_listen()

func set_language(language=null, stt_plugin_name="", used_plugin_name=[]):
	var stt_plugin_adapter = await get_use_stt_plugin(stt_plugin_name, used_plugin_name)
	if stt_plugin_adapter==null:
		return false
	await stt_plugin_adapter.set_language(language)

func get_language(stt_plugin_name="", used_plugin_name=[]):
	var stt_plugin_adapter = await get_use_stt_plugin(stt_plugin_name, used_plugin_name)
	if stt_plugin_adapter==null:
		return false
	return await stt_plugin_adapter.get_language()

func set_language_model(language_model=null, stt_plugin_name="", used_plugin_name=[]):
	var stt_plugin_adapter = await get_use_stt_plugin(stt_plugin_name, used_plugin_name)
	if stt_plugin_adapter==null:
		return false
	return await stt_plugin_adapter.set_language_model(language_model)

func get_language_model(stt_plugin_name="", used_plugin_name=[]):
	var stt_plugin_adapter = await get_use_stt_plugin(stt_plugin_name, used_plugin_name)
	if stt_plugin_adapter==null:
		return false
	return await stt_plugin_adapter.get_language_model()

func set_use_gpu(use_gpu=null, stt_plugin_name="", used_plugin_name=[]):
	var stt_plugin_adapter = await get_use_stt_plugin(stt_plugin_name, used_plugin_name)
	if stt_plugin_adapter==null:
		return false
	return await stt_plugin_adapter.set_use_gpu(use_gpu)

func get_use_gpu(stt_plugin_name="", used_plugin_name=[]):
	var stt_plugin_adapter = await get_use_stt_plugin(stt_plugin_name, used_plugin_name)
	if stt_plugin_adapter==null:
		return false
	return await stt_plugin_adapter.get_use_gpu()
	

func get_models_info(stt_plugin_name,used_plugin_name=[]):
	var stt_plugin_adapter = await get_use_stt_plugin(stt_plugin_name, used_plugin_name)
	if stt_plugin_adapter==null:
		return false
	return await stt_plugin_adapter.get_model_list_info()

func get_language_list(stt_plugin_name,used_plugin_name=[]):
	var stt_plugin_adapter = await get_use_stt_plugin(stt_plugin_name, used_plugin_name)
	if stt_plugin_adapter==null:
		return false
	return await stt_plugin_adapter.get_language_list()
	

func get_all_models_info():
	var all_models_info = {}
	for stt_plugin_name in stt_adapter_name_list:
		var models_info = await get_models_info(stt_plugin_name)
		all_models_info[stt_plugin_name] = models_info
	return all_models_info

func force_update_model_list_info(stt_plugin_name,used_plugin_name=[]):
	var stt_plugin_adapter = await get_use_stt_plugin(stt_plugin_name, used_plugin_name)
	if stt_plugin_adapter==null:
		return false
	stt_plugin_adapter.force_update_model_list_info()

func get_last_use_model_info(stt_plugin_name,used_plugin_name=[]):
	var stt_plugin_adapter = await get_use_stt_plugin(stt_plugin_name, used_plugin_name)
	if stt_plugin_adapter==null:
		return false
	return await stt_plugin_adapter.get_last_use_model_info()

func download_model(cur_model_info):
	var downloader_list = await PluginManager.get_plugin_instance_by_script_name("downloader_list")
	var download_gid = await downloader_list.new_task([cur_model_info.url],{"dir":cur_model_info.local_file_path.get_base_dir(),"out":cur_model_info.local_file_path.get_file()})
	var is_finish = await downloader_list.wait_task(download_gid, 4)
	return true
