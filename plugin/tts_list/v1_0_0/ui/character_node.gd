extends PanelContainer

var plugin_node = null
func get_plugin_node():
	if plugin_node and is_instance_valid(plugin_node):
		return plugin_node
	var _plugin_result = PluginManager.get_plugin_name(get_script())
	plugin_node = await PluginManager.get_plugin_instance_by_script_name(_plugin_result[0])
	return plugin_node


var character_info

func update_ui(cur_character_info):
	character_info = cur_character_info
	printt("character_info",character_info)
	%CharacterName.text = character_info.get("character_name","")
	update_plugin_option()
	update_plugin_container_option()
	update_model_option()
	update_model_index_option()
	target_adapter_plugin_name = character_info.get("plugin_name","")
	target_container_name = character_info.get("container_name","")
	target_model_path = character_info.get("model_path","")
	target_model_index = character_info.get("speaker_index",0)
	

func update_plugin_option():
	%PluginOptionButton.clear()
	var cur_plugin_node = await get_plugin_node()
	for key in cur_plugin_node.tts_adapter_name_list:
		%PluginOptionButton.add_item(key)

var target_adapter_plugin_name:
	get:
		var id = %PluginOptionButton.get_selected_id()
		if id==-1:
			return ""
		var index = %PluginOptionButton.get_item_index(id)
		if index == -1:
			return ""
		return %PluginOptionButton.get_item_text(index)
	set(val):
		for index in range(%PluginOptionButton.item_count):
			if %PluginOptionButton.get_item_text(index) == val:
				%PluginOptionButton.select(index)
				return

func update_plugin_container_option():
	%PluginContainerOptionButton.clear()
	if target_adapter_plugin_name=="":
		return 
	
	var target_plugin_node = await PluginManager.get_plugin_instance_by_script_name(target_adapter_plugin_name)
	
	for key in target_plugin_node.get_model_list_info().keys():
		%PluginContainerOptionButton.add_item(key)


var target_container_name:
	get:
		var id = %PluginContainerOptionButton.get_selected_id()
		if id==-1:
			return ""
		var index = %PluginContainerOptionButton.get_item_index(id)
		if index == -1:
			return ""
		return %PluginContainerOptionButton.get_item_text(index)
	set(val):
		for index in range(%PluginContainerOptionButton.item_count):
			if %PluginContainerOptionButton.get_item_text(index) == val:
				%PluginContainerOptionButton.select(index)
				return


func update_model_option():
	printt("update_model_option")
	%ModelOptionButton.clear()
	if target_adapter_plugin_name=="":
		return 

	if target_container_name == "":
		return 

	var target_plugin_node = await PluginManager.get_plugin_instance_by_script_name(target_adapter_plugin_name)
	
	var cur_model_list_info = target_plugin_node.get_model_list_info().get(target_container_name,{})
	if cur_model_list_info.is_empty():
		return 
	
	
	for cur_model_info in cur_model_list_info:
		%ModelOptionButton.add_item(cur_model_info.name)
		%ModelOptionButton.set_item_metadata(%ModelOptionButton.item_count-1, cur_model_info.local_file_path)
		
var target_model_path:
	get:
		var id = %ModelOptionButton.get_selected_id()
		if id==-1:
			return ""
		var index = %ModelOptionButton.get_item_index(id)
		if index == -1:
			return ""
		return %ModelOptionButton.get_item_metadata(index)
	set(val):
		for index in range(%ModelOptionButton.item_count):
			if %ModelOptionButton.get_item_metadata(index) == val:
				%ModelOptionButton.select(index)
				break

var target_model_name:
	get:
		var id = %ModelOptionButton.get_selected_id()
		if id==-1:
			return ""
		var index = %ModelOptionButton.get_item_index(id)
		if index == -1:
			return ""
		return %ModelOptionButton.get_item_text(index)


func update_model_index_option():
	%ModelIndexOptionButton.clear()
	if target_adapter_plugin_name=="":
		return 

	if target_container_name == "":
		return 
		
	if target_model_name == "":
		return 

	var target_plugin_node = await PluginManager.get_plugin_instance_by_script_name(target_adapter_plugin_name)
	
	var cur_model_list_info = target_plugin_node.get_model_list_info().get(target_container_name,{})
	if cur_model_list_info.is_empty():
		return 
	

	var cur_target_model_info = null
	for cur_model_info in cur_model_list_info:

		if cur_model_info.name == target_model_name:
			cur_target_model_info = cur_model_info
			break
			
	if cur_target_model_info == null:
		return 
	var keys = cur_target_model_info.index_map.keys()

	keys.sort()
	for key in keys:
		%ModelIndexOptionButton.add_item("{0}({1})".format([key,cur_target_model_info.index_map[key]]), int(key))

var target_model_index:
	get:
		var id = %ModelIndexOptionButton.get_selected_id()
		if id==-1:
			return ""
		return id
	set(val):
		for index in range(%ModelIndexOptionButton.item_count):
			if %ModelIndexOptionButton.get_item_id(index) == val:
				%ModelIndexOptionButton.select(index)
				return


var update_flag = false

func _on_plugin_option_button_item_selected(index):
	printt("111111111")
	update_plugin_container_option()
	update_model_option()
	update_model_index_option()
	update_flag = true


func _on_plugin_container_option_button_item_selected(index):
	printt("2222222222")
	update_model_option()
	update_model_index_option()
	update_flag = true


func _on_model_option_button_item_selected(index):
	printt("3333333333")
	update_model_index_option()
	update_flag = true
	

func _on_model_index_option_button_item_selected(index):
	printt("44444444")
	update_flag = true

func _process(delta):
	if update_flag:
		var cur_plugin_node = await get_plugin_node()
		
		for tts_plugin_name in cur_plugin_node.tts_adapter_name_list:
			if tts_plugin_name==target_adapter_plugin_name:
				continue
			var need_args = await cur_plugin_node.get_remove_character_use_model_info_need_args(tts_plugin_name)
			need_args["character_name"] = %CharacterName.text
			await cur_plugin_node.remove_character_use_model_info(need_args)
		
		var need_args = await cur_plugin_node.get_set_character_use_model_info_need_args(target_adapter_plugin_name)
		need_args["model_path"] = target_model_path
		need_args["container_name"] = target_container_name
		need_args["character_name"] = %CharacterName.text
		need_args["speaker_index"] = target_model_index
		need_args["plugin_name"] = target_adapter_plugin_name
		printt("55555555555")
		await cur_plugin_node.set_character_use_model_info(need_args)
		
		await cur_plugin_node.update_character_map()
		update_flag=false
