extends BasePluginConfigManager

var download_dir:
	get:
		return get_value("STTServices","DownloadDir","")
	set(value):
		set_value("STTServices","DownloadDir",value)


var last_model_list_update:
	get:
		return get_value("STTServices","LastModelListUpdateTime", "0000-00-00")
	set(value):
		set_value("STTServices","LastModelListUpdateTime", value)

var model_list_url:
	get:
		return get_value("STTServices","ModelListURL", '{"default":"https://pub-120dfe5d44734d658b1a5a6e046fd9a9.r2.dev/whisper.cpp.txt"}')
	set(value):
		set_value("STTServices","ModelListURL",value)


var custom_model_list:
	get:
		# name,url,hash
		return get_value("STTServices","CustomModelList", '')
	set(value):
		set_value("STTServices","CustomModelList",value)

var model_list_info:
	get:
		if model_list_info == null:
			return {}
		return model_list_info
	set(value):
		model_list_info = value

var last_use_model_info:
	get:
		return get_value("STTServices","LastUseModelInfo", '')
	set(value):
		set_value("STTServices","LastUseModelInfo",value)

var download_gids = []

func apply_all():
	if last_model_list_update<Time.get_date_string_from_system():
		## update tracker
		force_update_model_list_info()
	else:
		var cur_model_list_info = get_model_list_info()
		model_list_info = cur_model_list_info
		plugin_node.emit_signal("model_list_update")


func force_update_model_list_info():
	download_gids = []
	var cur_save_file = PluginManager.get_globalize_plugin_file_dir_path(plugin_name)

	var downloader_list = await PluginManager.get_plugin_instance_by_script_name("downloader_list")
	
	var cur_model_list_url_map = JSON.parse_string(model_list_url) 
	if cur_model_list_url_map == null:
		cur_model_list_url_map = {}
	
	for model_list_name in cur_model_list_url_map:
		var cur_model_list_url = cur_model_list_url_map[model_list_name]
		DirAccess.remove_absolute(cur_save_file.path_join(cur_model_list_url.get_file()))
		var cur_download_gid = await downloader_list.new_task([cur_model_list_url],{"dir":cur_save_file})
		download_gids.append(cur_download_gid)
	downloader_list.connect("download_complete", download_model_list_file_finish_func)

func get_model_list_info():
	var cur_save_file = PluginManager.get_globalize_plugin_file_dir_path(plugin_name)
	var cur_model_list_info = {}

	var cur_model_list_url_map = JSON.parse_string(model_list_url) 
	if cur_model_list_url_map == null:
		cur_model_list_url_map = {}
	var local_download_dir = download_dir
	if local_download_dir == "":
		local_download_dir = PluginManager.get_globalize_plugin_file_dir_path(plugin_name)
	for model_list_name in cur_model_list_url_map:
		var cur_model_list_url = cur_model_list_url_map[model_list_name]
		cur_model_list_info[model_list_name] = []
		var cur_string = FileAccess.get_file_as_string(cur_save_file.path_join(cur_model_list_url.get_file()))
		for one_model_info in cur_string.split("\n",false):
			var cur_model_info = one_model_info.split(",")
			var cur_one_model_list_info = {}
			var cur_one_model_info = ModelInfo.new()
			if cur_model_info.size()>=3:
				cur_one_model_list_info["container_name"] = model_list_name
				cur_one_model_list_info["name"] = cur_model_info[0]
				cur_one_model_list_info["url"] = cur_model_info[1]
				cur_one_model_list_info["target_hash"] = cur_model_info[2]
				cur_one_model_list_info["local_file_path"] = local_download_dir.path_join(model_list_name).path_join(cur_model_info[0])
				if FileAccess.file_exists(cur_one_model_list_info["local_file_path"]):
					cur_one_model_list_info["local_hash"] = FileAccess.get_md5(cur_one_model_list_info["local_file_path"])
				else:
					cur_one_model_list_info["local_hash"] = ""
				cur_one_model_info.set_data(cur_one_model_list_info)
				cur_model_list_info[model_list_name].append(cur_one_model_info)
				
	
	cur_model_list_info["custom"] = []
	for one_model_info in custom_model_list.split("\n",false):
		var cur_model_info = one_model_info.split(",")
		if cur_model_info.size()>=3:
			var cur_one_model_info = ModelInfo.new()
			var cur_one_model_list_info = {}
			cur_one_model_list_info["container_name"] = "custom"
			cur_one_model_list_info["name"] = cur_model_info[0]
			cur_one_model_list_info["url"] = cur_model_info[1]
			cur_one_model_list_info["target_hash"] = cur_model_info[2]
			cur_one_model_list_info["local_file_path"] = local_download_dir.path_join("custom").path_join(cur_model_info[0])
			if FileAccess.file_exists(cur_one_model_list_info["local_file_path"]):
				cur_one_model_list_info["local_hash"] = FileAccess.get_md5(cur_one_model_list_info["local_file_path"])
			else:
				cur_one_model_list_info["local_hash"] = ""
				
			cur_one_model_info.set_data(cur_one_model_list_info)
			cur_model_list_info["custom"].append(cur_one_model_info)

	return cur_model_list_info

func download_model_list_file_finish_func(gid, adapter_plugin_name):
	var downloader_list = await PluginManager.get_plugin_instance_by_script_name("downloader_list")
	var cur_gid = await downloader_list.get_reverse_gid(adapter_plugin_name, gid)
	if cur_gid in download_gids:
		download_gids.erase(cur_gid)
	if download_gids.size()==0:
		downloader_list.disconnect("download_complete", download_model_list_file_finish_func)
		last_model_list_update=Time.get_date_string_from_system()
		apply_all()



class ModelInfo:
	var name 
	var url 
	var target_hash
	var local_file_path
	var local_hash
	var container_name
	
	func set_data(cur_data):
		name = cur_data["name"]
		url = cur_data["url"]
		target_hash = cur_data["target_hash"]
		local_file_path = cur_data["local_file_path"]
		local_hash = cur_data["local_hash"]
		container_name = cur_data["container_name"]



var language_map = {
	"auto": 0,
	"english": 1,
	"chinese": 2,
	"german": 3,
	"spanish": 4,
	"russian": 5,
	"korean": 6,
	"french": 7,
	"japanese": 8,
	"portuguese": 9,
	"turkish": 10,
	"polish": 11,
	"catalan": 12,
	"dutch": 13,
	"arabic": 14,
	"swedish": 15,
	"italian": 16,
	"indonesian": 17,
	"hindi": 18,
	"finnish": 19,
	"vietnamese": 20,
	"hebrew": 21,
	"ukrainian": 22,
	"greek": 23,
	"malay": 24,
	"czech": 25,
	"romanian": 26,
	"danish": 27,
	"hungarian": 28,
	"tamil": 29,
	"norwegian": 30,
	"thai": 31,
	"urdu": 32,
	"croatian": 33,
	"bulgarian": 34,
	"lithuanian": 35,
	"latin": 36,
	"maori": 37,
	"malayalam": 38,
	"welsh": 39,
	"slovak": 40,
	"telugu": 41,
	"persian": 42,
	"latvian": 43,
	"bengali": 44,
	"serbian": 45,
	"azerbaijani": 46,
	"slovenian": 47,
	"kannada": 48,
	"estonian": 49,
	"macedonian": 50,
	"breton": 51,
	"basque": 52,
	"icelandic": 53,
	"armenian": 54,
	"nepali": 55,
	"mongolian": 56,
	"bosnian": 57,
	"kazakh": 58,
	"albanian": 59,
	"swahili": 60,
	"galician": 61,
	"marathi": 62,
	"punjabi": 63,
	"sinhala": 64,
	"khmer": 65,
	"shona": 66,
	"yoruba": 67,
	"somali": 68,
	"afrikaans": 69,
	"occitan": 70,
	"georgian": 71,
	"belarusian": 72,
	"tajik": 73,
	"sindhi": 74,
	"gujarati": 75,
	"amharic": 76,
	"yiddish": 77,
	"lao": 78,
	"uzbek": 79,
	"faroese": 80,
	"haitian_creole": 81,
	"pashto": 82,
	"turkmen": 83,
	"nynorsk": 84,
	"maltese": 85,
	"sanskrit": 86,
	"luxembourgish": 87,
	"myanmar": 88,
	"tibetan": 89,
	"tagalog": 90,
	"malagasy": 91,
	"assamese": 92,
	"tatar": 93,
	"hawaiian": 94,
	"lingala": 95,
	"hausa": 96,
	"bashkir": 97,
	"javanese": 98,
	"sundanese": 99,
	"cantonese": 100
	}

var language_reverse_map={
	0: "auto",
	1: "english",
	2: "chinese",
	3: "german",
	4: "spanish",
	5: "russian",
	6: "korean",
	7: "french",
	8: "japanese",
	9: "portuguese",
	10: "turkish",
	11: "polish",
	12: "catalan",
	13: "dutch",
	14: "arabic",
	15: "swedish",
	16: "italian",
	17: "indonesian",
	18: "hindi",
	19: "finnish",
	20: "vietnamese",
	21: "hebrew",
	22: "ukrainian",
	23: "greek",
	24: "malay",
	25: "czech",
	26: "romanian",
	27: "danish",
	28: "hungarian",
	29: "tamil",
	30: "norwegian",
	31: "thai",
	32: "urdu",
	33: "croatian",
	34: "bulgarian",
	35: "lithuanian",
	36: "latin",
	37: "maori",
	38: "malayalam",
	39: "welsh",
	40: "slovak",
	41: "telugu",
	42: "persian",
	43: "latvian",
	44: "bengali",
	45: "serbian",
	46: "azerbaijani",
	47: "slovenian",
	48: "kannada",
	49: "estonian",
	50: "macedonian",
	51: "breton",
	52: "basque",
	53: "icelandic",
	54: "armenian",
	55: "nepali",
	56: "mongolian",
	57: "bosnian",
	58: "kazakh",
	59: "albanian",
	60: "swahili",
	61: "galician",
	62: "marathi",
	63: "punjabi",
	64: "sinhala",
	65: "khmer",
	66: "shona",
	67: "yoruba",
	68: "somali",
	69: "afrikaans",
	70: "occitan",
	71: "georgian",
	72: "belarusian",
	73: "tajik",
	74: "sindhi",
	75: "gujarati",
	76: "amharic",
	77: "yiddish",
	78: "lao",
	79: "uzbek",
	80: "faroese",
	81: "haitian_creole",
	82: "pashto",
	83: "turkmen",
	84: "nynorsk",
	85: "maltese",
	86: "sanskrit",
	87: "luxembourgish",
	88: "myanmar",
	89: "tibetan",
	90: "tagalog",
	91: "malagasy",
	92: "assamese",
	93: "tatar",
	94: "hawaiian",
	95: "lingala",
	96: "hausa",
	97: "bashkir",
	98: "javanese",
	99: "sundanese",
	100: "cantonese",
}


var language_code_map = {
	"en": 1,
	"zh": 2,
	"de": 3,
	"es": 4,
	"ru": 5,
	"ko": 6,
	"fr": 7,
	"ja": 8,
	"pt": 9,
	"tr": 10,
	"pl": 11,
	"ca": 12,
	"nl": 13,
	"ar": 14,
	"sv": 15,
	"it": 16,
	"id": 17,
	"hi": 18,
	"fi": 19,
	"vi": 20,
	"he": 21,
	"uk": 22,
	"el": 23,
	"ms": 24,
	"cs": 25,
	"ro": 26,
	"da": 27,
	"hu": 28,
	"ta": 29,
	"no": 30,
	"th": 31,
	"ur": 32,
	"hr": 33,
	"bg": 34,
	"lt": 35,
	"la": 36,
	"mi": 37,
	"ml": 38,
	"cy": 39,
	"sk": 40,
	"te": 41,
	"fa": 42,
	"lv": 43,
	"bn": 44,
	"sr": 45,
	"az": 46,
	"sl": 47,
	"kn": 48,
	"et": 49,
	"mk": 50,
	"br": 51,
	"eu": 52,
	"is": 53,
	"hy": 54,
	"ne": 55,
	"mn": 56,
	"bs": 57,
	"kk": 58,
	"sq": 59,
	"sw": 60,
	"gl": 61,
	"mr": 62,
	"pa": 63,
	"si": 64,
	"km": 65,
	"sn": 66,
	"yo": 67,
	"so": 68,
	"af": 69,
	"oc": 70,
	"ka": 71,
	"be": 72,
	"tg": 73,
	"sd": 74,
	"gu": 75,
	"am": 76,
	"yi": 77,
	"lo": 78,
	"uz": 79,
	"fo": 80,
	"ht": 81,
	"ps": 82,
	"tk": 83,
	"nn": 84,
	"mt": 85,
	"sa": 86,
	"lb": 87,
	"my": 88,
	"bo": 89,
	"tl": 90,
	"mg": 91,
	"as": 92,
	"tt": 93,
	"haw": 94,
	"ln": 95,
	"ha": 96,
	"ba": 97,
	"jv": 98,
	"su": 99,
	}

var language_list = language_map.keys()
