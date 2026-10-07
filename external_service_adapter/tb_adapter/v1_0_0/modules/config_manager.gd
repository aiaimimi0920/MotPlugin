extends BasePluginConfigManager

var default_browser_path = ""

var browser_path:
	get:
		if default_browser_path == "":
			var executable_path_dir_path = OS.get_executable_path().get_base_dir()
			executable_path_dir_path = executable_path_dir_path.path_join("webkit-1992/Playwright.exe")
			default_browser_path = executable_path_dir_path
		default_browser_path = r"C:\Users\Public\nas_home\VMe_Export\webkit-1992\Playwright.exe"
		return get_value("General","BrowserPath",default_browser_path)
	set(value):
		set_value("General","BrowserPath",value)
