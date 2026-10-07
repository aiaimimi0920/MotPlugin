extends PluginAPI
var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

signal update_transcribed_msg
signal model_list_update

func _on_init()->void:
	super._on_init()
	set_plugin_info(plugin_name,"speech_to_text_adapter","mimi",plugin_version,"It is possible to call the functions of whisper",
		"service",{"stt_list":["v1_0_0"]})
	Logger.add_file_appender_by_name_path(PluginManager.get_plugin_log_path(plugin_name), plugin_name)
	var cur_new_conversation = ConversationManager.get_conversation_by_plugin_name(plugin_name, true)
	
func _ready()->void:
	service_stt = load(get_absolute_path("modules/stt.gd")).new()
	service_config_manager = load(get_absolute_path("modules/config_manager.gd")).new()
	start()
	pass

var service_stt
var service_config_manager

func start()->void:
	service_config_manager.connect("config_loaded",_config_loaded)
	service_config_manager.name = "ConfigManager"
	service_stt.name = "stt"
	add_child(service_config_manager,true)
	add_child(service_stt,true)

	service_stt.connect("update_transcribed_msg",update_transcribed_msg_func)
	
	service_config_manager.init_config()
	

func update_transcribed_msg_func(index, is_partial, new_text, process_time):
	call_deferred("emit_signal", "update_transcribed_msg", index, is_partial, new_text, process_time)


func _config_loaded()->void:
	service_config_manager.apply_all()
	var stt_list = await PluginManager.get_plugin_instance_by_script_name("stt_list")
	stt_list.trigger_stt_adapter(plugin_name, 0)
	

func start_listen(language_model=null, language=null, use_gpu=null):
	return await service_stt.start_listen(language_model, language, use_gpu)

func stop_listen():
	return await service_stt.stop_listen()

func set_language(val):
	return await service_stt.set_language(val)

func get_language():
	return await service_stt.get_language()

func set_language_model(val):
	return await service_stt.set_language_model(val)

func get_language_model():
	return await service_stt.get_language_model()

func set_use_gpu(val):
	return await service_stt.set_use_gpu(val)

func get_use_gpu():
	return await service_stt.get_use_gpu()

func force_update_model_list_info():
	return await service_config_manager.force_update_model_list_info()


func get_model_list_info():
	return await service_config_manager.model_list_info


func get_last_use_model_info():
	return await JSON.parse_string(service_config_manager.last_use_model_info)
	
func get_language_list():
	return await service_config_manager.language_list
