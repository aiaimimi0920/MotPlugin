extends PluginAPI

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

signal add_tts_adapter
signal finish_audio
signal generated_audio_buffer
signal model_list_update


func _on_init()->void:
	super._on_init()
	set_plugin_info(plugin_name,"tts_list","mimi",plugin_version,"Collection of tts methods",
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
	
var tts_adapter_name_list = []
var tts_adapter_name_map = {}

func sort_tts_adapter(a, b):
	if tts_adapter_name_map[a] < tts_adapter_name_map[b]:
		return true
	if tts_adapter_name_map[a] == tts_adapter_name_map[b]:
		if a<b:
			return true
		return false
	return false


func trigger_tts_adapter(adapter_plugin_name, target_index):
	tts_adapter_name_map[adapter_plugin_name] = target_index
	tts_adapter_name_list=tts_adapter_name_map.keys()
	tts_adapter_name_list.sort_custom(sort_tts_adapter)
	var tts_plugin_adapter = await PluginManager.get_plugin_instance_by_script_name(adapter_plugin_name)
	tts_plugin_adapter.connect("finish_audio",finish_audio_func.bind(adapter_plugin_name))
	tts_plugin_adapter.connect("generated_audio_buffer",generated_audio_buffer_func.bind(adapter_plugin_name))
	tts_plugin_adapter.connect("model_list_update",model_list_update_func.bind(adapter_plugin_name))
	emit_signal("add_tts_adapter",adapter_plugin_name)

var user_preferred_tts:
	get:
		return service_config_manager.preferred_tts


func finish_audio_func(utterance_id: int, finish_time:float, adapter_plugin_name:String):
	emit_signal("finish_audio", utterance_id, finish_time, adapter_plugin_name)

func generated_audio_buffer_func(utterance_id: int,audio_buffer:Array, file_path:String, adapter_plugin_name:String):
	emit_signal("generated_audio_buffer", utterance_id, audio_buffer, file_path, adapter_plugin_name)


func model_list_update_func(adapter_plugin_name):
	emit_signal("model_list_update", adapter_plugin_name)
	

func get_use_tts_plugin_name(tts_plugin_name, used_plugin_name):
	if tts_plugin_name!="":
		return tts_plugin_name
	var cur_user_preferred_tts = user_preferred_tts.split(",",false)
	if cur_user_preferred_tts.size()!=0:
		for value in cur_user_preferred_tts:
			if value not in used_plugin_name:
				return value
	for value in tts_adapter_name_list:
		if value not in used_plugin_name:
			return value
	return ""
	

func get_use_tts_plugin(tts_plugin_name, used_plugin_name):
	tts_plugin_name = get_use_tts_plugin_name(tts_plugin_name,used_plugin_name)
	if tts_plugin_name=="":
		return null
	var tts_plugin_adapter = await PluginManager.get_plugin_instance_by_script_name(tts_plugin_name)
	return tts_plugin_adapter
	
func get_ui_instance():
	var cur_node = load(get_absolute_path("ui/main.tscn")).instantiate()
	return cur_node


func get_models_info(tts_plugin_name,used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return false
	return await tts_plugin_adapter.get_model_list_info()
	

func get_all_models_info():
	var all_models_info = {}
	for tts_plugin_name in tts_adapter_name_list:
		var models_info = await get_models_info(tts_plugin_name)
		all_models_info[tts_plugin_name] = models_info
	return all_models_info

func force_update_model_list_info(tts_plugin_name,used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return false
	tts_plugin_adapter.force_update_model_list_info()

func download_model(cur_model_info):
	var downloader_list = await PluginManager.get_plugin_instance_by_script_name("downloader_list")
	var download_gid = await downloader_list.new_task([cur_model_info.url],{"dir":cur_model_info.local_file_path.get_base_dir(),"out":cur_model_info.local_file_path.get_file()})
	var is_finish = await downloader_list.wait_task(download_gid, 4)
	return true


func get_setup_model_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_setup_model_need_args()

func setup_model(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.setup_model(adapter_need_data)


func get_unsetup_model_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_unsetup_model_need_args()

func unsetup_model(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.unsetup_model(adapter_need_data)

func get_tts_is_speaking_from_vits_res_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_is_speaking_from_vits_res_need_args()

func tts_is_speaking_from_vits_res(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_is_speaking_from_vits_res(adapter_need_data)

func get_tts_is_speaking_from_vits_path_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_is_speaking_from_vits_path_need_args()

func tts_is_speaking_from_vits_path(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_is_speaking_from_vits_path(adapter_need_data)

func get_tts_is_speaking_from_speaker_uuid_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_is_speaking_from_speaker_uuid_need_args()

func tts_is_speaking_from_speaker_uuid(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_is_speaking_from_speaker_uuid(adapter_need_data)

func get_tts_is_paused_from_vits_res_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_is_paused_from_vits_res_need_args()

func tts_is_paused_from_vits_res(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_is_paused_from_vits_res(adapter_need_data)

func get_tts_is_paused_from_vits_path_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_is_paused_from_vits_path_need_args()

func tts_is_paused_from_vits_path(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_is_paused_from_vits_path(adapter_need_data)
		
func get_tts_is_paused_from_speaker_uuid_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_is_paused_from_speaker_uuid_need_args()

func tts_is_paused_from_speaker_uuid(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_is_paused_from_speaker_uuid(adapter_need_data)
		
func get_tts_get_voices_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_get_voices_need_args()

func tts_get_voices(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_get_voices(adapter_need_data)

func get_tts_get_voices_from_vits_res_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_get_voices_from_vits_res_need_args()

func tts_get_voices_from_vits_res(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_get_voices_from_vits_res(adapter_need_data)

func get_tts_get_voices_from_vits_path_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_get_voices_from_vits_path_need_args()

func tts_get_voices_from_vits_path(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_get_voices_from_vits_path(adapter_need_data)

func get_tts_infer_from_vits_res_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_infer_from_vits_res_need_args()

func tts_infer_from_vits_res(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_infer_from_vits_res(adapter_need_data)

func get_tts_infer_from_vits_path_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_infer_from_vits_path_need_args()

func tts_infer_from_vits_path(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_infer_from_vits_path(adapter_need_data)

func get_tts_infer_from_speaker_uuid_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_infer_from_speaker_uuid_need_args()

func tts_infer_from_speaker_uuid(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_infer_from_speaker_uuid(adapter_need_data)

func get_tts_pause_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_pause_need_args()

func tts_pause(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_pause(adapter_need_data)

func get_tts_pause_from_vits_res_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_pause_from_vits_res_need_args()

func tts_pause_from_vits_res(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_pause_from_vits_res(adapter_need_data)

func get_tts_pause_from_vits_path_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_pause_from_vits_path_need_args()

func tts_pause_from_vits_path(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_pause_from_vits_path(adapter_need_data)

func get_tts_pause_from_speaker_uuid_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_pause_from_speaker_uuid_need_args()

func tts_pause_from_speaker_uuid(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_pause_from_speaker_uuid(adapter_need_data)

func get_tts_resume_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_resume_need_args()

func tts_resume(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_resume(adapter_need_data)

func get_tts_resume_from_vits_res_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_resume_from_vits_res_need_args()

func tts_resume_from_vits_res(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_resume_from_vits_res(adapter_need_data)

func get_tts_resume_from_vits_path_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_resume_from_vits_path_need_args()

func tts_resume_from_vits_path(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_resume_from_vits_path(adapter_need_data)

func get_tts_resume_from_speaker_uuid_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_resume_from_speaker_uuid_need_args()

func tts_resume_from_speaker_uuid(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_resume_from_speaker_uuid(adapter_need_data)

func get_tts_play_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_play_need_args()

func tts_play(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_play(adapter_need_data)

func get_tts_play_from_utterance_id_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_play_from_utterance_id_need_args()

func tts_play_from_utterance_id(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_play_from_utterance_id(adapter_need_data)

func get_tts_play_from_vits_res_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_play_from_vits_res_need_args()

func tts_play_from_vits_res(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_play_from_vits_res(adapter_need_data)

func get_tts_play_from_vits_path_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_play_from_vits_path_need_args()

func tts_play_from_vits_path(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_play_from_vits_path(adapter_need_data)

func get_tts_play_from_speaker_uuid_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_play_from_speaker_uuid_need_args()

func tts_play_from_speaker_uuid(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_play_from_speaker_uuid(adapter_need_data)

func get_tts_stop_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_stop_need_args()

func tts_stop(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_stop(adapter_need_data)

func get_tts_stop_from_utterance_id_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_stop_from_utterance_id_need_args()

func tts_stop_from_utterance_id(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_stop_from_utterance_id(adapter_need_data)

func get_tts_stop_from_vits_res_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_stop_from_vits_res_need_args()

func tts_stop_from_vits_res(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_stop_from_vits_res(adapter_need_data)

func get_tts_stop_from_vits_path_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_stop_from_vits_path_need_args()

func tts_stop_from_vits_path(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_stop_from_vits_path(adapter_need_data)

func get_tts_stop_from_speaker_uuid_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_tts_stop_from_speaker_uuid_need_args()

func tts_stop_from_speaker_uuid(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.tts_stop_from_speaker_uuid(adapter_need_data)

func get_set_character_use_model_info_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_set_character_use_model_info_need_args()

func set_character_use_model_info(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.set_character_use_model_info(adapter_need_data)


func get_remove_character_use_model_info_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_remove_character_use_model_info_need_args()

func remove_character_use_model_info(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.remove_character_use_model_info(adapter_need_data)


func get_get_character_use_model_info_need_args(tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return tts_plugin_adapter.get_get_character_use_model_info_need_args()

func get_character_use_model_info(adapter_need_data, tts_plugin_name="", used_plugin_name=[]):
	var tts_plugin_adapter = await get_use_tts_plugin(tts_plugin_name, used_plugin_name)
	if tts_plugin_adapter==null:
		return null
	return await tts_plugin_adapter.get_character_use_model_info(adapter_need_data)


var character_name_map = {}

func add_character_name(cur_character_name):
	character_name_map[cur_character_name] = true
	pass
	
func remove_character_name(cur_character_name):
	character_name_map.erase(cur_character_name)
	pass
	
func get_character_map():
	if character_map==null:
		update_character_map()
	return character_map

var character_map = null
func update_character_map():
	var all_models_info = {}
	for tts_plugin_name in tts_adapter_name_list:
		var need_args = await get_get_character_use_model_info_need_args(tts_plugin_name)
		for key in character_name_map.keys():
			need_args["character_name"] = key
			need_args["use_default"] = false
			var character_info = await get_character_use_model_info(need_args, tts_plugin_name)
			if character_info == null:
				continue
			all_models_info[key] = character_info
	for key in character_name_map.keys():
		if key not in all_models_info:
			all_models_info[key] = {
				"character_name":key,
			}
	character_map = all_models_info
	return


func get_tts_is_speaking_from_character_need_args():
	return {"character_name":"",}

func tts_is_speaking_from_character(adapter_need_data):
	var character_name = adapter_need_data.get("character_name","")
	if character_name=="":
		return false
	var cur_character_map = get_character_map()
	if character_name not in cur_character_map:
		return false
	var character_info = cur_character_map[character_name]
	var cur_plugin_name = character_info["plugin_name"]
	var cur_model_path = character_info["model_path"]
	var cur_speaker_index = character_info["speaker_index"]
	
	var need_args = await get_tts_is_speaking_from_vits_path_need_args(cur_plugin_name)
	need_args["model_path"] = cur_model_path
	need_args["speaker_index"] = cur_speaker_index
	need_args.merge(adapter_need_data,true)
	var is_speaking = await tts_is_speaking_from_vits_path(need_args, cur_plugin_name)


func get_tts_is_paused_from_character_need_args():
	return {"character_name":"",}

func tts_is_paused_from_character(adapter_need_data):
	var character_name = adapter_need_data.get("character_name","")
	if character_name=="":
		return false
	var cur_character_map = get_character_map()
	if character_name not in cur_character_map:
		return false
	var character_info = cur_character_map[character_name]
	var cur_plugin_name = character_info["plugin_name"]
	var cur_model_path = character_info["model_path"]
	var cur_speaker_index = character_info["speaker_index"]
	
	var need_args = await get_tts_is_paused_from_vits_path_need_args(cur_plugin_name)
	need_args["model_path"] = cur_model_path
	need_args["speaker_index"] = cur_speaker_index
	need_args.merge(adapter_need_data,true)
	var is_speaking = await tts_is_paused_from_vits_path(need_args, cur_plugin_name)
	
func get_tts_infer_from_character_need_args():
	return {"character_name":"",}

func tts_infer_from_character(adapter_need_data):
	var character_name = adapter_need_data.get("character_name","")
	if character_name=="":
		return false
	var cur_character_map = get_character_map()
	if character_name not in cur_character_map:
		return false
	var character_info = cur_character_map[character_name]
	var cur_plugin_name = character_info["plugin_name"]
	var cur_model_path = character_info["model_path"]
	var cur_speaker_index = character_info["speaker_index"]
	
	var need_args = await get_tts_infer_from_vits_path_need_args(cur_plugin_name)
	need_args["model_path"] = cur_model_path
	need_args["speaker_index"] = cur_speaker_index
	need_args.merge(adapter_need_data,true)
	var is_speaking = await tts_infer_from_vits_path(need_args, cur_plugin_name)
	
func get_tts_pause_from_character_need_args():
	return {"character_name":"",}

func tts_pause_from_character(adapter_need_data):
	var character_name = adapter_need_data.get("character_name","")
	if character_name=="":
		return false
	var cur_character_map = get_character_map()
	if character_name not in cur_character_map:
		return false
	var character_info = cur_character_map[character_name]
	var cur_plugin_name = character_info["plugin_name"]
	var cur_model_path = character_info["model_path"]
	var cur_speaker_index = character_info["speaker_index"]
	
	var need_args = await get_tts_pause_from_vits_path_need_args(cur_plugin_name)
	need_args["model_path"] = cur_model_path
	need_args["speaker_index"] = cur_speaker_index
	need_args.merge(adapter_need_data,true)
	var is_speaking = await tts_pause_from_vits_path(need_args, cur_plugin_name)

func get_tts_resume_from_character_need_args():
	return {"character_name":"",}

func tts_resume_from_character(adapter_need_data):
	var character_name = adapter_need_data.get("character_name","")
	if character_name=="":
		return false
	var cur_character_map = get_character_map()
	if character_name not in cur_character_map:
		return false
	var character_info = cur_character_map[character_name]
	var cur_plugin_name = character_info["plugin_name"]
	var cur_model_path = character_info["model_path"]
	var cur_speaker_index = character_info["speaker_index"]
	
	var need_args = await get_tts_resume_from_vits_path_need_args(cur_plugin_name)
	need_args["model_path"] = cur_model_path
	need_args["speaker_index"] = cur_speaker_index
	need_args.merge(adapter_need_data,true)
	var is_speaking = await tts_resume_from_vits_path(need_args, cur_plugin_name)
	
func get_tts_play_from_character_need_args():
	return {"character_name":"",}

func tts_play_from_character(adapter_need_data):
	var character_name = adapter_need_data.get("character_name","")
	if character_name=="":
		return false
	var cur_character_map = get_character_map()
	if character_name not in cur_character_map:
		return false
	var character_info = cur_character_map[character_name]
	var cur_plugin_name = character_info["plugin_name"]
	var cur_model_path = character_info["model_path"]
	var cur_speaker_index = character_info["speaker_index"]
	
	var need_args = await get_tts_play_from_vits_path_need_args(cur_plugin_name)
	need_args["model_path"] = cur_model_path
	need_args["speaker_index"] = cur_speaker_index
	need_args.merge(adapter_need_data,true)
	var is_speaking = await tts_play_from_vits_path(need_args, cur_plugin_name)
	
func get_tts_stop_from_character_need_args():
	return {"character_name":"",}

func tts_stop_from_character(adapter_need_data):
	var character_name = adapter_need_data.get("character_name","")
	if character_name=="":
		return false
	var cur_character_map = get_character_map()
	if character_name not in cur_character_map:
		return false
	var character_info = cur_character_map[character_name]
	var cur_plugin_name = character_info["plugin_name"]
	var cur_model_path = character_info["model_path"]
	var cur_speaker_index = character_info["speaker_index"]
	
	var need_args = await get_tts_stop_from_vits_path_need_args(cur_plugin_name)
	need_args["model_path"] = cur_model_path
	need_args["speaker_index"] = cur_speaker_index
	need_args.merge(adapter_need_data,true)
	var is_speaking = await tts_stop_from_vits_path(need_args, cur_plugin_name)
