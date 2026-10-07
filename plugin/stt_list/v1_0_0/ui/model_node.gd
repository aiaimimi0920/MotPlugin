extends PanelContainer

var plugin_node = null
func get_plugin_node():
	if plugin_node and is_instance_valid(plugin_node):
		return plugin_node
	var _plugin_result = PluginManager.get_plugin_name(get_script())
	plugin_node = await PluginManager.get_plugin_instance_by_script_name(_plugin_result[0])
	return plugin_node


var model_info
var adapter_plugin_name
signal use_language_model

func _on_link_button_pressed():
	var url = model_info.url
	if url!="":
		DisplayServer.clipboard_set(url)
	return true

func _on_folder_button_pressed():
	if model_info.local_file_path.simplify_path()!="":
		OS.shell_show_in_file_manager(model_info.local_file_path.simplify_path())

func _on_delete_button_pressed():
	delete_model()

func _on_download_button_pressed():
	download_model()

func delete_model():
	FileManager.remove_file(model_info.local_file_path)

func download_model():
	var plugin_node = await get_plugin_node()
	await plugin_node.download_model(model_info)
	plugin_node.force_update_model_list_info(adapter_plugin_name)
	plugin_node.call_deferred("emit_signal","model_list_info_update")


func _on_update_button_pressed():
	if model_info.target_hash!=model_info.local_hash:
		delete_model()
		download_model()

func update_ui(cur_model_info,cur_adapter_plugin_name):
	model_info = cur_model_info
	adapter_plugin_name = cur_adapter_plugin_name
	
	%ModelName.text = model_info.container_name.path_join(model_info.name)
	%TargetHash.text = model_info.target_hash
	%LocalHash.text = model_info.local_hash
	if model_info.local_hash=="":
		%DeleteButton.visible = false
		%DownloadButton.visible = true
		%UpdateButton.visible = false
	else:
		%DeleteButton.visible = true
		%DownloadButton.visible = false
		%UpdateButton.visible = true
	
func _on_use_button_pressed():
	emit_signal("use_language_model",model_info)
	pass # Replace with function body.
