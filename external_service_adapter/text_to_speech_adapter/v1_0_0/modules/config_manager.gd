extends BasePluginConfigManager

var download_dir:
	get:
		return get_value("TTSServices","DownloadDir","")
	set(value):
		set_value("TTSServices","DownloadDir",value)


var last_model_list_update:
	get:
		return get_value("TTSServices","LastModelListUpdateTime", "0000-00-00")
	set(value):
		set_value("TTSServices","LastModelListUpdateTime", value)


var model_list_url:
	get:
		return get_value("TTSServices","ModelListURL", '{"default":"https://pub-120dfe5d44734d658b1a5a6e046fd9a9.r2.dev/SummerTTS.txt"}')
	set(value):
		set_value("TTSServices","ModelListURL",value)


var custom_model_list:
	get:
		# name,url,hash
		return get_value("TTSServices","CustomModelList", '')
	set(value):
		set_value("TTSServices","CustomModelList",value)

var model_list_info:
	get:
		if model_list_info == null:
			return {}
		return model_list_info
	set(value):
		model_list_info = value

var character_use_model_info:
	get:
		return get_value("TTSServices","CharacterUseModelInfo", '{}')
	set(value):
		set_value("TTSServices","CharacterUseModelInfo",value)

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

func download_model_list_file_finish_func(gid, adapter_plugin_name):
	var downloader_list = await PluginManager.get_plugin_instance_by_script_name("downloader_list")
	var cur_gid = await downloader_list.get_reverse_gid(adapter_plugin_name, gid)
	if cur_gid in download_gids:
		download_gids.erase(cur_gid)
	if download_gids.size()==0:
		downloader_list.disconnect("download_complete", download_model_list_file_finish_func)
		call_deferred("force_update_model_index_list_info")
		

func force_update_model_index_list_info():
	download_gids = []
	var cur_save_file = PluginManager.get_globalize_plugin_file_dir_path(plugin_name)

	var downloader_list = await PluginManager.get_plugin_instance_by_script_name("downloader_list")
	
	var cur_model_list_url_map = JSON.parse_string(model_list_url) 
	if cur_model_list_url_map == null:
		cur_model_list_url_map = {}
		
	var local_download_dir = download_dir
	if local_download_dir == "":
		local_download_dir = PluginManager.get_globalize_plugin_file_dir_path(plugin_name)
	
	downloader_list.connect("download_complete", download_model_index_list_file_finish_func)
	
	for model_list_name in cur_model_list_url_map:
		var cur_model_list_url = cur_model_list_url_map[model_list_name]
		var cur_string = FileAccess.get_file_as_string(cur_save_file.path_join(cur_model_list_url.get_file()))
		for one_model_info in cur_string.split("\n",false):
			var cur_model_info = one_model_info.split(",")
			var cur_model_index_list_url = cur_model_info[2]
			DirAccess.remove_absolute(cur_save_file.path_join(cur_model_index_list_url.get_file()))

			var cur_download_gid = await downloader_list.new_task([cur_model_index_list_url],{"dir":cur_save_file})
			download_gids.append(cur_download_gid)
	
	for one_model_info in custom_model_list.split("\n",false):
		var cur_model_info = one_model_info.split(",")
		if cur_model_info.size()>=4:
			var cur_model_index_list_url = cur_model_info[2]
			DirAccess.remove_absolute(cur_save_file.path_join(cur_model_index_list_url.get_file()))
			var cur_download_gid = await downloader_list.new_task([cur_model_index_list_url],{"dir":cur_save_file})
			download_gids.append(cur_download_gid)

	

func download_model_index_list_file_finish_func(gid, adapter_plugin_name):
	var downloader_list = await PluginManager.get_plugin_instance_by_script_name("downloader_list")
	var cur_gid = await downloader_list.get_reverse_gid(adapter_plugin_name, gid)
	if cur_gid in download_gids:
		download_gids.erase(cur_gid)
	if download_gids.size()==0:
		downloader_list.disconnect("download_complete", download_model_index_list_file_finish_func)
		last_model_list_update=Time.get_date_string_from_system()
		apply_all()


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
			if cur_model_info.size()>=4:
				cur_one_model_list_info["container_name"] = model_list_name
				cur_one_model_list_info["name"] = cur_model_info[0]
				cur_one_model_list_info["url"] = cur_model_info[1]
				
				var index_map_file = cur_save_file.path_join(cur_model_info[2].get_file())
				cur_one_model_list_info["index_map"] = get_index_map(index_map_file)
				cur_one_model_list_info["target_hash"] = cur_model_info[3]
				
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
		if cur_model_info.size()>=4:
			var cur_one_model_info = ModelInfo.new()
			var cur_one_model_list_info = {}
			cur_one_model_list_info["container_name"] = "custom"
			cur_one_model_list_info["name"] = cur_model_info[0]
			cur_one_model_list_info["url"] = cur_model_info[1]
			var index_map_file = cur_save_file.path_join(cur_model_info[2].get_file())
			cur_one_model_list_info["index_map"] = get_index_map(index_map_file)
			cur_one_model_list_info["target_hash"] = cur_model_info[3]
			cur_one_model_list_info["local_file_path"] = local_download_dir.path_join("custom").path_join(cur_model_info[0])
			if FileAccess.file_exists(cur_one_model_list_info["local_file_path"]):
				cur_one_model_list_info["local_hash"] = FileAccess.get_md5(cur_one_model_list_info["local_file_path"])
			else:
				cur_one_model_list_info["local_hash"] = ""
				
			cur_one_model_info.set_data(cur_one_model_list_info)
			cur_model_list_info["custom"].append(cur_one_model_info)

	return cur_model_list_info

func get_index_map(cur_index_map_file):
	var cur_string = FileAccess.get_file_as_string(cur_index_map_file)
	var cur_map = {}
	for one_model_index_info in cur_string.split("\n",false):
		var cur_one_model_index_array = one_model_index_info.split(",")
		cur_map[cur_one_model_index_array[0]] = cur_one_model_index_array[1]
	
	return cur_map


class ModelInfo:
	var name 
	var url 
	var target_hash
	var local_file_path
	var local_hash
	var container_name
	var index_map
	
	func set_data(cur_data):
		name = cur_data["name"]
		url = cur_data["url"]
		target_hash = cur_data["target_hash"]
		local_file_path = cur_data["local_file_path"]
		local_hash = cur_data["local_hash"]
		container_name = cur_data["container_name"]
		index_map = cur_data["index_map"]


