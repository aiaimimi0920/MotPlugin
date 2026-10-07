extends VBoxContainer

var plugin_node = null
func get_plugin_node():
	if plugin_node and is_instance_valid(plugin_node):
		return plugin_node
	var _plugin_result = PluginManager.get_plugin_name(get_script())
	plugin_node = await PluginManager.get_plugin_instance_by_script_name(_plugin_result[0])
	return plugin_node

var model_info_list
var adapter_plugin_name

var model_info_node_tscn = null

func update_ui(cur_model_info_list,cur_adapter_plugin_name):
	var cur_plugin_node = await get_plugin_node()
	model_info_list = cur_model_info_list
	adapter_plugin_name = cur_adapter_plugin_name
	
	%PluginName.text = cur_adapter_plugin_name
	%ModelName.text = ""
	if model_info_node_tscn == null:
		model_info_node_tscn = load(cur_plugin_node.get_absolute_path("ui/model_node.tscn"))

	for cur_key in model_info_list:
		for cur_info in model_info_list[cur_key]:
			var cur_node = model_info_node_tscn.instantiate()
			%ModelList.add_child(cur_node)
			cur_node.update_ui(cur_info, adapter_plugin_name)
			cur_node.connect("use_language_model",self.set_language_model)
			cur_node.name = cur_info.name

	update_language_option_list()

	var last_use_model_info = await cur_plugin_node.get_last_use_model_info(cur_adapter_plugin_name)
	if last_use_model_info==null:
		last_use_model_info = {}
	%UseGpu.button_pressed = last_use_model_info.get("use_gpu",false)
	var target_language = last_use_model_info.get("language","auto")
	for i in range(%Language.item_count):
		if %Language.get_item_text(i) == target_language:
			%Language.selected = i
			break
	var target_language_model = last_use_model_info.get("language_model","")
	if target_language_model!="":
		%ModelName.text = target_language_model.get_base_dir().get_file().path_join(target_language_model.get_file())


func update_language_option_list():
	%Language.clear()

	var cur_plugin_node = await get_plugin_node()
	var cur_language_list = await cur_plugin_node.get_language_list(adapter_plugin_name)
	cur_language_list.insert(1,"local")
	var id = 0
	for key in cur_language_list:
		%Language.add_item(key, id)
		id += 1


func _on_update_button_pressed():
	var cur_plugin_node = await get_plugin_node()
	cur_plugin_node.force_update_model_list_info(adapter_plugin_name)


func _on_expand_button_toggled(toggled_on):
	for cur_node in %ModelList.get_children():
		cur_node.visible = toggled_on


func _on_use_gpu_toggled(toggled_on):
	if adapter_plugin_name:
		var cur_plugin_node = await get_plugin_node()
		cur_plugin_node.set_use_gpu(toggled_on, adapter_plugin_name)


func _on_language_item_selected(index):
	if adapter_plugin_name:
		var cur_plugin_node = await get_plugin_node()
		cur_plugin_node.set_language(%Language.get_item_text(index))


func set_language_model(model_info):
	if adapter_plugin_name:
		var cur_plugin_node = await get_plugin_node()
		await cur_plugin_node.set_language_model(model_info.local_file_path)
