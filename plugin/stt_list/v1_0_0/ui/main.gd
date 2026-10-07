extends Control

var plugin_node = null

func get_plugin_node():
	if plugin_node and is_instance_valid(plugin_node):
		return plugin_node
	var _plugin_result = PluginManager.get_plugin_name(get_script())
	plugin_node = await PluginManager.get_plugin_instance_by_script_name(_plugin_result[0])
	return plugin_node


func _ready():
	await init_ui()
	await init_signal()

func init_signal():
	var cur_plugin_node = await get_plugin_node()	
	cur_plugin_node.connect("add_stt_adapter", add_stt_adapter_func)
	cur_plugin_node.connect("model_list_update", model_list_update_func)

func add_stt_adapter_func(adapter_plugin_name):
	await update_model_list()

func model_list_update_func(adapter_plugin_name):
	await update_model_list()

func init_ui():
	await update_model_list()


var model_container_tscn = null

func update_model_list():
	var cur_plugin_node = await get_plugin_node()
	
	var all_models_info = await cur_plugin_node.get_all_models_info()
	
	if model_container_tscn == null:
		model_container_tscn = load(cur_plugin_node.get_absolute_path("ui/model_container.tscn"))
	
	for child in %ModelNodeContainer.get_children():
		%ModelNodeContainer.remove_child(child)
	
	
	for key in all_models_info:
		var cur_node = model_container_tscn.instantiate()
		%ModelNodeContainer.add_child(cur_node)
		cur_node.update_ui(all_models_info[key], key)
	
