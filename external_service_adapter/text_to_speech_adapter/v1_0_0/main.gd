extends PluginAPI
var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

signal finish_audio(utterance_id: int, finish_time:float)
signal generated_audio_buffer(utterance_id: int,audio_buffer:Array, file_path:String)
signal model_list_update

func _on_init()->void:
	super._on_init()
	set_plugin_info(plugin_name,"text_to_speech_adapter","mimi",plugin_version,"It is possible to call the functions of summer.tts",
		"service",{"tts_list":["v1_0_0"]})
	Logger.add_file_appender_by_name_path(PluginManager.get_plugin_log_path(plugin_name), plugin_name)
	var cur_new_conversation = ConversationManager.get_conversation_by_plugin_name(plugin_name, true)
	
func _ready()->void:
	service_tts = load(get_absolute_path("modules/tts.gd")).new()
	service_config_manager = load(get_absolute_path("modules/config_manager.gd")).new()
	start()
	pass

var service_tts
var service_config_manager

func start()->void:
	service_config_manager.connect("config_loaded",_config_loaded)
	service_config_manager.name = "ConfigManager"
	service_tts.name = "tts"
	add_child(service_config_manager,true)
	add_child(service_tts,true)

	service_tts.connect("finish_audio",finish_audio_func)
	service_tts.connect("generated_audio_buffer",generated_audio_buffer_func)
	
	service_config_manager.init_config()
	

func finish_audio_func(utterance_id: int, finish_time:float):
	call_deferred("emit_signal", "finish_audio", utterance_id, finish_time)

func generated_audio_buffer_func(utterance_id: int,audio_buffer:Array, file_path:String):
	call_deferred("emit_signal", "generated_audio_buffer", utterance_id, audio_buffer,file_path)


func _config_loaded()->void:
	service_config_manager.apply_all()
	var tts_list = await PluginManager.get_plugin_instance_by_script_name("tts_list")
	tts_list.trigger_tts_adapter(plugin_name, 0)
	

func force_update_model_list_info():
	return await service_config_manager.force_update_model_list_info()


func get_model_list_info():
	return await service_config_manager.model_list_info


func get_set_character_use_model_info_need_args():
	return {"character_name":"","model_path":"","speaker_index":0,"container_name":"default"}

func set_character_use_model_info(adapter_need_data):
	var cur_character_use_model_info = await JSON.parse_string(service_config_manager.character_use_model_info)
	if cur_character_use_model_info == null:
		cur_character_use_model_info = {}
	var character_name = adapter_need_data.get("character_name", "")
	var cur_model_path = adapter_need_data.get("model_path", "")
	var cur_speaker_index = adapter_need_data.get("speaker_index", 0)
	var cur_container_name = adapter_need_data.get("container_name", "default")
	cur_character_use_model_info[character_name] = {
		"model_path":cur_model_path,
		"speaker_index":cur_speaker_index,
		"container_name":cur_container_name,
		"plugin_name":plugin_name,
		"character_name":character_name,
	}
	service_config_manager.character_use_model_info = JSON.stringify(cur_character_use_model_info)

func get_remove_character_use_model_info_need_args():
	return {"character_name":""}

func remove_character_use_model_info(adapter_need_data):
	var cur_character_use_model_info = await JSON.parse_string(service_config_manager.character_use_model_info)
	if cur_character_use_model_info == null:
		cur_character_use_model_info = {}
	var character_name = adapter_need_data.get("character_name", "")
	cur_character_use_model_info.erase(character_name)
	service_config_manager.character_use_model_info = JSON.stringify(cur_character_use_model_info)


func get_get_character_use_model_info_need_args():
	return {"character_name":"","use_default":true}

func get_character_use_model_info(adapter_need_data):
	var character_name = adapter_need_data.get("character_name", "")
	var use_default = adapter_need_data.get("use_default", true)
	var cur_character_use_model_info = await JSON.parse_string(service_config_manager.character_use_model_info)
	printt("get_character_use_model_info","cur_character_use_model_info",cur_character_use_model_info)
	if cur_character_use_model_info==null:
		cur_character_use_model_info = {}
	if character_name in cur_character_use_model_info:
		return cur_character_use_model_info[character_name]
	if use_default == false:
		return null
	if "default" in cur_character_use_model_info:
		return cur_character_use_model_info["default"]
	if not cur_character_use_model_info.is_empty():
		return cur_character_use_model_info.values[0]
	return {
		"model_path":"",
		"speaker_index":0,
		"plugin_name":plugin_name,
		"container_name":"default",
		"character_name":character_name,
	}

func get_setup_model_need_args():
	return {"model_res":null}

func setup_model(adapter_need_data):
	var cur_model_res = adapter_need_data.get("model_res", null)
	return await service_tts.setup_model(cur_model_res)

func get_unsetup_model_need_args():
	return {"model_res":null}

func unsetup_model(adapter_need_data):
	var cur_model_res = adapter_need_data.get("model_res", null)
	return await service_tts.unsetup_model(cur_model_res)

func get_tts_is_speaking_from_vits_res_need_args():
	return {"model_res":null, "speaker_index":0,}

func tts_is_speaking_from_vits_res(adapter_need_data):
	var cur_model_res = adapter_need_data.get("model_res", null)
	var cur_speaker_index = adapter_need_data.get("speaker_index", 0)
	return await service_tts.tts_is_speaking_from_vits_res(cur_model_res, cur_speaker_index)

func get_tts_is_speaking_from_vits_path_need_args():
	return {"model_path":"", "speaker_index":0,}

func tts_is_speaking_from_vits_path(adapter_need_data):
	var cur_vits_model_path = adapter_need_data.get("model_path", null)
	var cur_speaker_index = adapter_need_data.get("speaker_index", 0)
	return await service_tts.tts_is_speaking_from_vits_path(cur_vits_model_path, cur_speaker_index)


func get_tts_is_speaking_from_speaker_uuid_need_args():
	return {"speaker_uuid":"",}

func tts_is_speaking_from_speaker_uuid(adapter_need_data):
	var cur_speaker_uuid = adapter_need_data.get("speaker_uuid", "")
	return await service_tts.tts_is_speaking_from_speaker_uuid(cur_speaker_uuid)

func get_tts_is_paused_from_vits_res_need_args():
	return {"model_res":null, "speaker_index":0,}

func tts_is_paused_from_vits_res(adapter_need_data):
	var cur_model_res = adapter_need_data.get("model_res", null)
	var cur_speaker_index = adapter_need_data.get("speaker_index", 0)
	return await service_tts.tts_is_paused_from_vits_res(cur_model_res, cur_speaker_index)

func get_tts_is_paused_from_vits_path_need_args():
	return {"model_path":"", "speaker_index":0,}

func tts_is_paused_from_vits_path(adapter_need_data):
	var cur_vits_model_path = adapter_need_data.get("model_path", null)
	var cur_speaker_index = adapter_need_data.get("speaker_index", 0)
	return await service_tts.tts_is_paused_from_vits_path(cur_vits_model_path, cur_speaker_index)

func get_tts_is_paused_from_speaker_uuid_need_args():
	return {"speaker_uuid":"",}

func tts_is_paused_from_speaker_uuid(adapter_need_data):
	var cur_speaker_uuid = adapter_need_data.get("speaker_uuid", "")
	return await service_tts.tts_is_paused_from_speaker_uuid(cur_speaker_uuid)

func get_tts_get_voices_need_args():
	return {}

func tts_get_voices(adapter_need_data):
	return await service_tts.tts_get_voices()

func get_tts_get_voices_from_vits_res_need_args():
	return {"model_res":null,}

func tts_get_voices_from_vits_res(adapter_need_data):
	var cur_model_res = adapter_need_data.get("model_res", null)
	return await service_tts.tts_get_voices_from_vits_res(cur_model_res)

func get_tts_get_voices_from_vits_path_need_args():
	return {"model_path":"",}

func tts_get_voices_from_vits_path(adapter_need_data):
	var cur_vits_model_path = adapter_need_data.get("model_path", null)
	return await service_tts.tts_get_voices_from_vits_path(cur_vits_model_path)

func get_tts_infer_from_vits_res_need_args():
	return {"text":"", "model_res":null, "speaker_index":0,"volume":100,"pitch":1.0,"rate":1.0,"interrupt":false,"auto_play":true,"immediately":false,"wait_utterance_id":-1,"wait_event":0,"wait_time":0.0,"create_file":false,"file_path":""}

func tts_infer_from_vits_res(adapter_need_data):
	var cur_text = adapter_need_data.get("text","")
	var cur_model_res = adapter_need_data.get("model_res", null)
	var cur_speaker_index = adapter_need_data.get("speaker_index", 0)
	var cur_volume = adapter_need_data.get("volume", 100)
	var cur_pitch = adapter_need_data.get("pitch", 1.0)
	var cur_rate = adapter_need_data.get("rate", 1.0)
	var cur_interrupt = adapter_need_data.get("interrupt", false)
	var cur_auto_play = adapter_need_data.get("auto_play", true)
	var cur_immediately = adapter_need_data.get("immediately", false)
	var cur_wait_utterance_id = adapter_need_data.get("wait_utterance_id", -1)
	var cur_wait_event = adapter_need_data.get("wait_event", 0)
	var cur_wait_time = adapter_need_data.get("wait_time", 0.0)
	var cur_create_file = adapter_need_data.get("create_file", false)
	var cur_file_path = adapter_need_data.get("file_path", "")
	
	return await service_tts.tts_infer_from_vits_res(cur_text, cur_model_res, cur_speaker_index, cur_volume, cur_pitch, cur_rate, cur_interrupt, cur_auto_play, cur_immediately, cur_wait_utterance_id, cur_wait_event, cur_wait_time, cur_create_file, cur_file_path)

func get_tts_infer_from_vits_path_need_args():
	return {"text":"", "model_path":"", "speaker_index":0,"volume":100,"pitch":1.0,"rate":1.0,"interrupt":false,"auto_play":true,"immediately":false,"wait_utterance_id":-1,"wait_event":0,"wait_time":0.0,"create_file":false,"file_path":""}

func tts_infer_from_vits_path(adapter_need_data):
	var cur_text = adapter_need_data.get("text","")
	var cur_vits_model_path = adapter_need_data.get("model_path", null)
	var cur_speaker_index = adapter_need_data.get("speaker_index", 0)
	var cur_volume = adapter_need_data.get("volume", 100)
	var cur_pitch = adapter_need_data.get("pitch", 1.0)
	var cur_rate = adapter_need_data.get("rate", 1.0)
	var cur_interrupt = adapter_need_data.get("interrupt", false)
	var cur_auto_play = adapter_need_data.get("auto_play", true)
	var cur_immediately = adapter_need_data.get("immediately", false)
	var cur_wait_utterance_id = adapter_need_data.get("wait_utterance_id", -1)
	var cur_wait_event = adapter_need_data.get("wait_event", 0)
	var cur_wait_time = adapter_need_data.get("wait_time", 0.0)
	var cur_create_file = adapter_need_data.get("create_file", false)
	var cur_file_path = adapter_need_data.get("file_path", "")
	return await service_tts.tts_infer_from_vits_path(cur_text, cur_vits_model_path, cur_speaker_index, cur_volume, cur_pitch, cur_rate, cur_interrupt, cur_auto_play, cur_immediately, cur_wait_utterance_id, cur_wait_event, cur_wait_time, cur_create_file, cur_file_path)

func get_tts_infer_from_speaker_uuid_need_args():
	return {"text":"", "speaker_uuid":"", "volume":100,"pitch":1.0,"rate":1.0,"interrupt":false,"auto_play":true,"immediately":false,"wait_utterance_id":-1,"wait_event":0,"wait_time":0.0,"create_file":false,"file_path":""}

func tts_infer_from_speaker_uuid(adapter_need_data):
	var cur_text = adapter_need_data.get("text","")
	var cur_speaker_uuid = adapter_need_data.get("speaker_uuid", "")
	var cur_volume = adapter_need_data.get("volume", 100)
	var cur_pitch = adapter_need_data.get("pitch", 1.0)
	var cur_rate = adapter_need_data.get("rate", 1.0)
	var cur_interrupt = adapter_need_data.get("interrupt", false)
	var cur_auto_play = adapter_need_data.get("auto_play", true)
	var cur_immediately = adapter_need_data.get("immediately", false)
	var cur_wait_utterance_id = adapter_need_data.get("wait_utterance_id", -1)
	var cur_wait_event = adapter_need_data.get("wait_event", 0)
	var cur_wait_time = adapter_need_data.get("wait_time", 0.0)
	var cur_create_file = adapter_need_data.get("create_file", false)
	var cur_file_path = adapter_need_data.get("file_path", "")
	
	return await service_tts.tts_infer_from_speaker_uuid(cur_text, cur_speaker_uuid, cur_volume, cur_pitch, cur_rate, cur_interrupt, cur_auto_play, cur_immediately, cur_wait_utterance_id, cur_wait_event, cur_wait_time, cur_create_file, cur_file_path)

func get_tts_pause_need_args():
	return {}

func tts_pause(adapter_need_data):
	return await service_tts.tts_pause()

func get_tts_pause_from_vits_res_need_args():
	return {"model_res":null, "speaker_index":0,}

func tts_pause_from_vits_res(adapter_need_data):
	var cur_model_res = adapter_need_data.get("model_res", null)
	var cur_speaker_index = adapter_need_data.get("speaker_index", 0)
	return await service_tts.tts_pause_from_vits_res(cur_model_res, cur_speaker_index)

func get_tts_pause_from_vits_path_need_args():
	return {"model_path":"", "speaker_index":0,}

func tts_pause_from_vits_path(adapter_need_data):
	var cur_vits_model_path = adapter_need_data.get("model_path", null)
	var cur_speaker_index = adapter_need_data.get("speaker_index", 0)
	return await service_tts.tts_pause_from_vits_path(cur_vits_model_path, cur_speaker_index)

func get_tts_pause_from_speaker_uuid_need_args():
	return {"speaker_uuid":"",}

func tts_pause_from_speaker_uuid(adapter_need_data):
	var cur_speaker_uuid = adapter_need_data.get("speaker_uuid", "")
	return await service_tts.tts_pause_from_speaker_uuid(cur_speaker_uuid)

func get_tts_resume_need_args():
	return {}

func tts_resume(adapter_need_data):
	return await service_tts.tts_resume()
	
func get_tts_resume_from_vits_res_need_args():
	return {"model_res":null, "speaker_index":0,}

func tts_resume_from_vits_res(adapter_need_data):
	var cur_model_res = adapter_need_data.get("model_res", null)
	var cur_speaker_index = adapter_need_data.get("speaker_index", 0)
	return await service_tts.tts_resume_from_vits_res(cur_model_res, cur_speaker_index)

func get_tts_resume_from_vits_path_need_args():
	return {"model_path":"", "speaker_index":0,}

func tts_resume_from_vits_path(adapter_need_data):
	var cur_vits_model_path = adapter_need_data.get("model_path", null)
	var cur_speaker_index = adapter_need_data.get("speaker_index", 0)
	return await service_tts.tts_resume_from_vits_path(cur_vits_model_path, cur_speaker_index)

func get_tts_resume_from_speaker_uuid_need_args():
	return {"speaker_uuid":"",}

func tts_resume_from_speaker_uuid(adapter_need_data):
	var cur_speaker_uuid = adapter_need_data.get("speaker_uuid", "")
	return await service_tts.tts_resume_from_speaker_uuid(cur_speaker_uuid)

func get_tts_play_need_args():
	return {}

func tts_play(adapter_need_data):
	return await service_tts.tts_play()

func get_tts_play_from_utterance_id_need_args():
	return {"utterance_id":0,}

func tts_play_from_utterance_id(adapter_need_data):
	var cur_utterance_id = adapter_need_data.get("utterance_id", 0)
	return await service_tts.tts_play_from_utterance_id(cur_utterance_id)

func get_tts_play_from_vits_res_need_args():
	return {"model_res":null, "speaker_index":0,}

func tts_play_from_vits_res(adapter_need_data):
	var cur_model_res = adapter_need_data.get("model_res", null)
	var cur_speaker_index = adapter_need_data.get("speaker_index", 0)
	return await service_tts.tts_play_from_vits_res(cur_model_res, cur_speaker_index)

func get_tts_play_from_vits_path_need_args():
	return {"model_path":null, "speaker_index":0,}

func tts_play_from_vits_path(adapter_need_data):
	var cur_vits_model_path = adapter_need_data.get("model_path", null)
	var cur_speaker_index = adapter_need_data.get("speaker_index", 0)
	return await service_tts.tts_play_from_vits_path(cur_vits_model_path, cur_speaker_index)
	
func get_tts_play_from_speaker_uuid_need_args():
	return {"speaker_uuid":"",}

func tts_play_from_speaker_uuid(adapter_need_data):
	var cur_speaker_uuid = adapter_need_data.get("speaker_uuid", "")
	return await service_tts.tts_play_from_speaker_uuid(cur_speaker_uuid)

func get_tts_stop_need_args():
	return {}

func tts_stop(adapter_need_data):
	return await service_tts.tts_stop()

func get_tts_stop_from_utterance_id_need_args():
	return {"utterance_id":0,}

func tts_stop_from_utterance_id(adapter_need_data):
	var cur_utterance_id = adapter_need_data.get("utterance_id", 0)
	return await service_tts.tts_stop_from_utterance_id(cur_utterance_id)

func get_tts_stop_from_vits_res_need_args():
	return {"model_res":null, "speaker_index":0,}

func tts_stop_from_vits_res(adapter_need_data):
	var cur_model_res = adapter_need_data.get("model_res", null)
	var cur_speaker_index = adapter_need_data.get("speaker_index", 0)
	return await service_tts.tts_stop_from_vits_res(cur_model_res, cur_speaker_index)

func get_tts_stop_from_vits_path_need_args():
	return {"model_path":"", "speaker_index":0,}

func tts_stop_from_vits_path(adapter_need_data):
	var cur_vits_model_path = adapter_need_data.get("model_path", null)
	var cur_speaker_index = adapter_need_data.get("speaker_index", 0)
	return await service_tts.tts_stop_from_vits_path(cur_vits_model_path, cur_speaker_index)

func get_tts_stop_from_speaker_uuid_need_args():
	return {"speaker_uuid":"",}

func tts_stop_from_speaker_uuid(adapter_need_data):
	var cur_speaker_uuid = adapter_need_data.get("speaker_uuid", "")
	return await service_tts.tts_stop_from_speaker_uuid(cur_speaker_uuid)

