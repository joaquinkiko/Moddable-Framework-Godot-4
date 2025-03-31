class_name ModdableFrameworkLibrarySettings
## Project Settings Loader and Getter for [AssetLibrary] related settings

const BASE_SETTING_PATH = "ModdableFramework/AssetLibrary"
const DEFAULT_SETTINGS = {
	"Library/ConfigPath":"res://asset_library.cfg",
	"Library/Verbose":true}

static func _add_setting(key: String, default: Variant, type: int, hint: int = 0, hint_string := "") -> void:
	if not ProjectSettings.has_setting("%s/%s"%[BASE_SETTING_PATH, key]):
		ProjectSettings.set_setting("%s/%s"%[BASE_SETTING_PATH, key], default)
	ProjectSettings.add_property_info({
		"name": "%s/%s"%[BASE_SETTING_PATH, key], 
		"type": type, 
		"hint": hint,
		"hint_string": hint_string})
	ProjectSettings.set_initial_value("%s/%s"%[BASE_SETTING_PATH, key], default)

static func add_all_settings() -> void:
	_add_setting("Library/ConfigPath", "res://asset_library.cfg", TYPE_STRING, PROPERTY_HINT_FILE, "*.cfg")
	_add_setting("Library/Verbose", true, TYPE_BOOL)

static func _remove_setting(key: String) -> void:
	if ProjectSettings.has_setting("%s/%s"%[BASE_SETTING_PATH, key]):
		ProjectSettings.set_setting("%s/%s"%[BASE_SETTING_PATH, key], null)

static func remove_all_settings() -> void:
	_remove_setting("Library/ConfigPath")
	_remove_setting("Library/Verbose")

static func get_setting(key: String) -> Variant:
	return ProjectSettings.get_setting("%s/%s"%[BASE_SETTING_PATH, key], DEFAULT_SETTINGS.get(key))

static func generate_default_files() -> void:
	if not FileAccess.file_exists(get_setting("Library/ConfigPath")):
		print("Generating Default Asset Library Config: %s"%get_setting("Library/ConfigPath"))
		var library_cfg := FileAccess.open(get_setting("Library/ConfigPath"), FileAccess.WRITE)
		library_cfg.store_string("[LibraryName]\n")
		library_cfg.store_string('asset_dir="res://"\n')
		library_cfg.store_string('valid_extensions=["extension"]\n')
		library_cfg.store_string('excluded_dirs=["dir_to_exclude"]\n')
		library_cfg.store_string('allow_mod_assets=true\n')
		library_cfg.store_string('allow_unique_md5=true\n')
		library_cfg.store_string('check_for_locale_variants=true\n')
		library_cfg.close()
