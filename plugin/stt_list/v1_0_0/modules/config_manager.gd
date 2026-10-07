extends BasePluginConfigManager

var preferred_stt:
	get:
		return get_value("General","PreferredSTT", "speech_to_text_adapter")
	set(value):
		set_value("General","PreferredSTT",value)
