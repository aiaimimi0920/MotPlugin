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

	if model_info_node_tscn == null:
		model_info_node_tscn = load(cur_plugin_node.get_absolute_path("ui/model_node.tscn"))

	for cur_key in model_info_list:
		for cur_info in model_info_list[cur_key]:
			var cur_node = model_info_node_tscn.instantiate()
			%ModelList.add_child(cur_node)
			cur_node.update_ui(cur_info, adapter_plugin_name)
			cur_node.name = cur_info.name


func _on_update_button_pressed():
	var cur_plugin_node = await get_plugin_node()
	cur_plugin_node.force_update_model_list_info(adapter_plugin_name)


func _on_expand_button_toggled(toggled_on):
	for cur_node in %ModelList.get_children():
		cur_node.visible = toggled_on

