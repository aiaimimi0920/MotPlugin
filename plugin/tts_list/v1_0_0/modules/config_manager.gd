extends BasePluginConfigManager

var preferred_tts:
	get:
		return get_value("General","PreferredTTS", "text_to_speech_adapter")
	set(value):
		set_value("General","PreferredTTS",value)
