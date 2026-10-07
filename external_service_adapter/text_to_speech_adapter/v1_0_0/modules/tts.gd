extends Node

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

var _text_speech_to_singleton:
	get:
		return Engine.get_singleton("TextToSpeech")


signal finish_audio(utterance_id: int, finish_time:float)
signal generated_audio_buffer(utterance_id: int,audio_buffer:Array, file_path:String)

func setup_model(cur_model_res:VITSResource):
	_text_speech_to_singleton.setup_model(cur_model_res)

func unsetup_model(cur_model_res:VITSResource):
	_text_speech_to_singleton.unsetup_model(cur_model_res)

func tts_is_speaking_from_vits_res(cur_model_res:VITSResource, cur_speaker_index:int):
	_text_speech_to_singleton.tts_is_speaking_from_vits_res(cur_model_res, cur_speaker_index)
	
func tts_is_speaking_from_vits_path(cur_vits_model_path:String, cur_speaker_index:int):
	_text_speech_to_singleton.tts_is_speaking_from_vits_path(cur_vits_model_path, cur_speaker_index)

func tts_is_speaking_from_speaker_uuid(cur_speaker_uuid:String):
	_text_speech_to_singleton.tts_is_speaking_from_speaker_uuid(cur_speaker_uuid)

func tts_is_paused_from_vits_res(cur_model_res:VITSResource, cur_speaker_index:int):
	_text_speech_to_singleton.tts_is_paused_from_vits_res(cur_model_res, cur_speaker_index)
	
func tts_is_paused_from_vits_path(cur_vits_model_path:String, cur_speaker_index:int):
	_text_speech_to_singleton.tts_is_paused_from_vits_path(cur_vits_model_path, cur_speaker_index)

func tts_is_paused_from_speaker_uuid(cur_speaker_uuid:String):
	_text_speech_to_singleton.tts_is_paused_from_speaker_uuid(cur_speaker_uuid)

func tts_get_voices():
	_text_speech_to_singleton.tts_get_voices()

func tts_get_voices_from_vits_res(cur_model_res:VITSResource):
	_text_speech_to_singleton.tts_get_voices_from_vits_res(cur_model_res)
	
func tts_get_voices_from_vits_path(cur_vits_model_path:String):
	_text_speech_to_singleton.tts_get_voices_from_vits_path(cur_vits_model_path)



func tts_infer_from_vits_res(cur_text:String, cur_model_res:VITSResource, cur_speaker_index:int, cur_volume:int, cur_pitch:float, cur_rate:float, cur_interrupt:bool, cur_auto_play:bool, cur_immediately:bool, cur_wait_utterance_id:int, cur_wait_event:int, cur_wait_time:float, cur_create_file:bool, cur_file_path:String):
	_text_speech_to_singleton.tts_infer_from_vits_res(cur_text, cur_model_res, cur_speaker_index, cur_volume, cur_pitch, cur_rate, cur_interrupt, cur_auto_play, cur_immediately, cur_wait_utterance_id, cur_wait_event, cur_wait_time, cur_create_file, cur_file_path)
	
func tts_infer_from_vits_path(cur_text:String, cur_vits_model_path:String, cur_speaker_index:int, cur_volume:int, cur_pitch:float, cur_rate:float, cur_interrupt:bool, cur_auto_play:bool, cur_immediately:bool, cur_wait_utterance_id:int, cur_wait_event:int, cur_wait_time:float, cur_create_file:bool, cur_file_path:String):
	_text_speech_to_singleton.tts_infer_from_vits_path(cur_text, cur_vits_model_path, cur_speaker_index, cur_volume, cur_pitch, cur_rate, cur_interrupt, cur_auto_play, cur_immediately, cur_wait_utterance_id, cur_wait_event, cur_wait_time, cur_create_file, cur_file_path)


func tts_infer_from_speaker_uuid(cur_text:String, cur_speaker_uuid:String, cur_volume:int, cur_pitch:float, cur_rate:float, cur_interrupt:bool, cur_auto_play:bool, cur_immediately:bool, cur_wait_utterance_id:int, cur_wait_event:int, cur_wait_time:float, cur_create_file:bool, cur_file_path:String):
	_text_speech_to_singleton.tts_infer_from_speaker_uuid(cur_text, cur_speaker_uuid, cur_volume, cur_pitch, cur_rate, cur_interrupt, cur_auto_play, cur_immediately, cur_wait_utterance_id, cur_wait_event, cur_wait_time, cur_create_file, cur_file_path)


func tts_pause():
	_text_speech_to_singleton.tts_pause()

func tts_pause_from_vits_res(cur_model_res:VITSResource, cur_speaker_index:int):
	_text_speech_to_singleton.tts_pause_from_vits_res(cur_model_res, cur_speaker_index)	
	
func tts_pause_from_vits_path(cur_vits_model_path:String, cur_speaker_index:int):
	_text_speech_to_singleton.tts_pause_from_vits_path(cur_vits_model_path, cur_speaker_index)	

func tts_pause_from_speaker_uuid(cur_speaker_uuid:String):
	_text_speech_to_singleton.tts_pause_from_speaker_uuid(cur_speaker_uuid)	

func tts_resume():
	_text_speech_to_singleton.tts_resume()	

func tts_resume_from_vits_res(cur_model_res:VITSResource, cur_speaker_index:int):
	_text_speech_to_singleton.tts_resume_from_vits_res(cur_model_res, cur_speaker_index)	

func tts_resume_from_vits_path(cur_vits_model_path:String, cur_speaker_index:int):
	_text_speech_to_singleton.tts_resume_from_vits_path(cur_vits_model_path, cur_speaker_index)

func tts_resume_from_speaker_uuid(cur_speaker_uuid:String):
	_text_speech_to_singleton.tts_resume_from_speaker_uuid(cur_speaker_uuid)

func tts_play():
	_text_speech_to_singleton.tts_play()

func tts_play_from_utterance_id(cur_utterance_id:int):
	_text_speech_to_singleton.tts_play_from_utterance_id(cur_utterance_id)

func tts_play_from_vits_res(cur_model_res:VITSResource, cur_speaker_index:int):
	_text_speech_to_singleton.tts_play_from_vits_res(cur_model_res, cur_speaker_index)
	
func tts_play_from_vits_path(cur_vits_model_path:String, cur_speaker_index:int):
	_text_speech_to_singleton.tts_play_from_vits_path(cur_vits_model_path, cur_speaker_index)

func tts_play_from_speaker_uuid(cur_speaker_uuid:String):
	_text_speech_to_singleton.tts_play_from_speaker_uuid(cur_speaker_uuid)

func tts_stop():
	_text_speech_to_singleton.tts_stop()

func tts_stop_from_utterance_id(cur_utterance_id:int):
	_text_speech_to_singleton.tts_stop_from_utterance_id(cur_utterance_id)

func tts_stop_from_vits_res(cur_model_res:VITSResource, cur_speaker_index:int):
	_text_speech_to_singleton.tts_stop_from_vits_res(cur_model_res, cur_speaker_index)
	
func tts_stop_from_vits_path(cur_vits_model_path:String, cur_speaker_index:int):
	_text_speech_to_singleton.tts_stop_from_vits_path(cur_vits_model_path, cur_speaker_index)

func tts_stop_from_speaker_uuid(cur_speaker_uuid:String):
	_text_speech_to_singleton.tts_stop_from_speaker_uuid(cur_speaker_uuid)


func _ready():
	_text_speech_to_singleton.connect("finish_audio", _finish_audio_func)
	_text_speech_to_singleton.connect("generated_audio_buffer", _generated_audio_buffer_func)


func _finish_audio_func(utterance_id: int, finish_time:float):
	emit_signal("finish_audio", utterance_id, finish_time)
	pass

func _generated_audio_buffer_func(utterance_id: int,audio_buffer:Array, file_path:String):
	emit_signal("generated_audio_buffer", utterance_id, audio_buffer,file_path)
	pass
