extends Node

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

var _speech_to_text_singleton:
	get:
		return Engine.get_singleton("SpeechToText")

var record_bus := "Record"
var audio_effect_capture_index := 0
@onready var _idx = AudioServer.get_bus_index(record_bus)
@onready var _effect_capture := AudioServer.get_bus_effect(_idx, audio_effect_capture_index) as AudioEffectCapture

signal update_transcribed_msg(index: int, is_partial:bool, text: String, process_time: int)
var _last_index = 0

var is_running = false

func _ready():
	_speech_to_text_singleton.connect("update_transcribed_msgs", _update_transcribed_msgs_func)
	_add_timer()

func _add_timer():
	var timer_node = Timer.new()
	timer_node.one_shot = false
	timer_node.autostart = true
	timer_node.wait_time = 1
	add_child(timer_node)
	timer_node.connect("timeout",self._on_timer_timeout)

func _on_timer_timeout():
	if Engine.is_editor_hint():
		return
	var cur_frames_available = _effect_capture.get_frames_available()
	var buffer: PackedVector2Array = []
	if cur_frames_available > 0:
		buffer = _effect_capture.get_buffer(cur_frames_available)

	if is_running:
		_speech_to_text_singleton.add_audio_buffer(buffer)
	else:
		_effect_capture.clear_buffer()


func _remove_special_characters(message: String, is_partial: bool):
	var special_characters = [ \
		{ "start": "[", "end": "]" }, \
		{ "start": "<", "end": ">" }]
	for special_character in special_characters:
		while(message.find(special_character["start"]) != -1):
			var begin_character := message.find(special_character["start"])
			var end_character := message.find(special_character["end"])
			if end_character != -1:
				message = message.substr(0, begin_character) + message.substr(end_character + 1)

	message = message.trim_suffix("{SPLIT}")
	
	var hallucinatory_character = [". you."]
	for special_character in hallucinatory_character:
		while(message.find(special_character) != -1):
			var begin_character := message.find(special_character)
			var end_character = begin_character + len(special_character)
			message = message.substr(0, begin_character) + message.substr(end_character + 1)
	return message
		

func _update_transcribed_msgs_func(process_time_ms: int, transcribed_msgs: Array):
	for transcribed_msg  in transcribed_msgs:
		var cur_text = _remove_special_characters(transcribed_msg["text"], transcribed_msg["is_partial"])
		if transcribed_msg["is_partial"]==false:
			if cur_text.ends_with("?") or cur_text.ends_with(",") or cur_text.ends_with("."):
				pass
			else:
				cur_text = cur_text + "."
		
		if(cur_text.length()<=1):
			cur_text = ""
		
		var split_character := cur_text.find("{SPLIT}")
		var first_text = ""
		var second_text = ""
		if split_character!=-1:
			first_text = cur_text.substr(0, split_character)
			second_text = cur_text.substr(split_character+7)
		else:
			first_text = cur_text
		
		if transcribed_msg["is_partial"]==false:
			if second_text!="":
				update_transcribed_msg.emit(_last_index, transcribed_msg["is_partial"], first_text, process_time_ms)
				update_transcribed_msg.emit(_last_index+1, true, second_text, process_time_ms)
			else:
				update_transcribed_msg.emit(_last_index, transcribed_msg["is_partial"], first_text, process_time_ms)
		else:
			update_transcribed_msg.emit(_last_index, transcribed_msg["is_partial"], first_text+second_text, process_time_ms)
		if transcribed_msg["is_partial"]==false:
			_last_index+=1


func start_listen(language_model=null, language=null, use_gpu=null):
	set_language(language)
	set_use_gpu(use_gpu)
	set_language_model(language_model)
	_speech_to_text_singleton.start_listen()
	is_running = true


func stop_listen():
	is_running = false
	_speech_to_text_singleton.stop_listen()
	var buffer: PackedVector2Array = _effect_capture.get_buffer(_effect_capture.get_frames_available())

## if val==null: set last language 
func set_language(val):
	var cur_val = ""
	if val == null:
		var last_use_model_info = JSON.parse_string(plugin_node.service_config_manager.last_use_model_info)
		if last_use_model_info==null:
			last_use_model_info = {}
		cur_val = last_use_model_info.get("language","auto")
	else:
		cur_val = val.to_lower()
	
	var target_index = 0
	if cur_val == "local":
		var local = OS.get_locale_language()
		cur_val = local.to_lower()
		if cur_val in plugin_node.service_config_manager.language_code_map:
			target_index = plugin_node.service_config_manager.language_code_map[cur_val]
			cur_val = plugin_node.service_config_manager.language_reverse_map[target_index]
		else:
			target_index = 0
			cur_val = "auto"

	else:
		if cur_val in plugin_node.service_config_manager.language_map:
			target_index = plugin_node.service_config_manager.language_map[cur_val]
		else:
			target_index = 0
			cur_val = "auto"
	
	var now_index = plugin_node.service_config_manager.language_map[get_language()]
	
	if now_index!=target_index:	
		var last_use_model_info = JSON.parse_string(plugin_node.service_config_manager.last_use_model_info)
		if last_use_model_info == null:
			last_use_model_info = {}
		if last_use_model_info.get("language","auto") != cur_val:
			last_use_model_info["language"] = cur_val
			plugin_node.service_config_manager.last_use_model_info = JSON.stringify(last_use_model_info)
	
		_speech_to_text_singleton.set_language(target_index)

func get_language():
	return plugin_node.service_config_manager.language_reverse_map[_speech_to_text_singleton.get_language()]


## if val==null: set last language model
func set_language_model(val):
	var cur_val = ""
	var cur_model:WhisperResource
	if val == null:
		var last_use_model_info = JSON.parse_string(plugin_node.service_config_manager.last_use_model_info)
		if last_use_model_info==null:
			last_use_model_info = {}
		cur_val = last_use_model_info.get("language_model","")
		if cur_val == "":
			return 
		cur_model = ResourceLoader.load(cur_val,"WhisperResource")
	else:
		if typeof(val) == TYPE_STRING:
			cur_model = ResourceLoader.load(val,"WhisperResource")
		else:
			cur_model = val

	if get_language_model() != cur_model:
		var last_use_model_info = JSON.parse_string(plugin_node.service_config_manager.last_use_model_info)
		if last_use_model_info==null:
			last_use_model_info = {}
		if last_use_model_info.get("language_model","") != cur_model.get_path():
			last_use_model_info["language_model"] = cur_model.get_path()
			plugin_node.service_config_manager.last_use_model_info = JSON.stringify(last_use_model_info)
		

		var now_language_model = get_language_model()
		
		_speech_to_text_singleton.set_language_model(cur_model)

func get_language_model():
	return _speech_to_text_singleton.get_language_model()


func set_use_gpu(val):
	var cur_val = false
	if val == null:
		var last_use_model_info = JSON.parse_string(plugin_node.service_config_manager.last_use_model_info)
		if last_use_model_info==null:
			last_use_model_info = {}
		cur_val = last_use_model_info.get("use_gpu",false)
	else:
		cur_val = val

	if get_use_gpu() != cur_val:
		var last_use_model_info = JSON.parse_string(plugin_node.service_config_manager.last_use_model_info)
		if last_use_model_info == null:
			last_use_model_info = {}
		if last_use_model_info.get("use_gpu",false) != cur_val:
			last_use_model_info["use_gpu"] = cur_val
			plugin_node.service_config_manager.last_use_model_info = JSON.stringify(last_use_model_info)

		_speech_to_text_singleton.set_use_gpu(cur_val)
	return true

func get_use_gpu():
	return _speech_to_text_singleton.is_use_gpu()
	
	
