class_name ModdableFrameworkExportSettings
## Project Settings Loader and Getter for export related settings

enum DirColorActions {
	DEFAULT_EXPORT,
	IGNORE_ON_EXPORT,
	DEBUG_EXPORT_ONLY,
	EXPORT_UNPACKED,
	EXPORT_TO_PCK_1,
	EXPORT_TO_PCK_2,
	EXPORT_TO_PCK_3,
	EXPORT_TO_PCK_4,
	EXPORT_TO_PCK_5}
const DIR_COLOR_ACTIONS_HINTS = [
	"Default Export",
	"Ignore on Export",
	"Debug-Only Resource Pack",
	"Raw Asset Export",
	"Pack 1 Export",
	"Pack 2 Export",
	"Pack 3 Export",
	"Pack 4 Export",
	"Pack 5 Export"]
const DIR_COLORS = ["red", "orange", "yellow", "green", "teal", "blue", "purple", "pink", "gray"]
const BASE_SETTING_PATH = "ModdableFramework/export"
const EDITOR_EXTENSIONS_DIR = "res://.extensions"
const DEFAULT_SETTINGS = {
	"ExportOptions/ExtensionDir":"data",
	"ExportOptions/PackDir":"data",
	"ExportOptions/MainLicenseFile":"res://license.md",
	"ExportOptions/GodotCopyrightFilename":"copyright_godot",
	"ExportOptions/GameCopyrightFilename":"copyright_{game_name}",
	"ExportOptions/Pack1Name":"",
	"ExportOptions/Pack2Name":"",
	"ExportOptions/Pack3Name":"",
	"ExportOptions/Pack4Name":"",
	"ExportOptions/Pack5Name":"",
	"ExportOptions/DirColorActionRed":DirColorActions.DEFAULT_EXPORT,
	"ExportOptions/DirColorActionOrange":DirColorActions.DEFAULT_EXPORT,
	"ExportOptions/DirColorActionYellow":DirColorActions.DEFAULT_EXPORT,
	"ExportOptions/DirColorActionGreen":DirColorActions.DEFAULT_EXPORT,
	"ExportOptions/DirColorActionTeal":DirColorActions.DEFAULT_EXPORT,
	"ExportOptions/DirColorActionBlue":DirColorActions.DEFAULT_EXPORT,
	"ExportOptions/DirColorActionPurple":DirColorActions.DEFAULT_EXPORT,
	"ExportOptions/DirColorActionPink":DirColorActions.DEFAULT_EXPORT,
	"ExportOptions/DirColorActionGray":DirColorActions.DEFAULT_EXPORT,
	}

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
	var color_hint_string: String
	for hint in DIR_COLOR_ACTIONS_HINTS: color_hint_string += "%s,"%hint
	color_hint_string = color_hint_string.trim_suffix(",")
	for color in DIR_COLORS:
		_add_setting("ExportOptions/DirColorAction%s"%color.capitalize(), DirColorActions.DEFAULT_EXPORT, TYPE_INT, PROPERTY_HINT_ENUM, color_hint_string)
	for n in range(1,6):
		_add_setting("ExportOptions/Pack%sName"%n, "", TYPE_STRING, 0, "Will not generate if empty")
	_add_setting("ExportOptions/GameCopyrightFilename", "copyright_{game_name}", TYPE_STRING, 0, "Will not generate if empty")
	_add_setting("ExportOptions/GodotCopyrightFilename", "copyright_godot", TYPE_STRING, 0, "Will not generate if empty")
	_add_setting("ExportOptions/MainLicenseFile", "res://license.md", TYPE_STRING, PROPERTY_HINT_FILE, "*")
	_add_setting("ExportOptions/PackDir", "data", TYPE_STRING, 0)
	_add_setting("ExportOptions/ExtensionDir", "data", TYPE_STRING, 0)

static func _remove_setting(key: String) -> void:
	if ProjectSettings.has_setting("%s/%s"%[BASE_SETTING_PATH, key]):
		ProjectSettings.set_setting("%s/%s"%[BASE_SETTING_PATH, key], null)

static func remove_all_settings() -> void:
	for color in DIR_COLORS:
		_remove_setting("ExportOptions/DirColorAction%s"%color.capitalize())
	for n in range(1,6):
		_remove_setting("ExportOptions/Pack%sName"%n)
	_remove_setting("ExportOptions/GameCopyrightFilename")
	_remove_setting("ExportOptions/GodotCopyrightFilename")
	_remove_setting("ExportOptions/MainLicenseFile")
	_remove_setting("ExportOptions/PackDir")
	_remove_setting("ExportOptions/ExtensionDir")

static func get_setting(key: String) -> Variant:
	return ProjectSettings.get_setting("%s/%s"%[BASE_SETTING_PATH, key], DEFAULT_SETTINGS.get(key))

static func generate_default_files() -> void:
	if not FileAccess.file_exists(get_setting("ExportOptions/MainLicenseFile")):
		print("Generating Default License File: %s"%get_setting("ExportOptions/MainLicenseFile"))
		var main_license := FileAccess.open(get_setting("ExportOptions/MainLicenseFile"), FileAccess.WRITE)
		if main_license == null:
			printerr("Error occured creating file: %s"%FileAccess.get_open_error())
		else:
			main_license.store_string(ProjectSettings.get_setting("application/config/name"))
			main_license.store_string("\n\nCopyright (c) %s.\n\nAll rights reserved."%Time.get_datetime_dict_from_system()["year"])
			main_license.close()
	if not DirAccess.dir_exists_absolute(EDITOR_EXTENSIONS_DIR): 
		DirAccess.make_dir_recursive_absolute(EDITOR_EXTENSIONS_DIR)
		print("Generating extensions folder: %s"%EDITOR_EXTENSIONS_DIR)
	if not DirAccess.dir_exists_absolute("%s/dependencies/win64"%EDITOR_EXTENSIONS_DIR):
		DirAccess.make_dir_recursive_absolute("%s/dependencies/win64"%EDITOR_EXTENSIONS_DIR)
	if not DirAccess.dir_exists_absolute("%s/dependencies/win32"%EDITOR_EXTENSIONS_DIR):
		DirAccess.make_dir_recursive_absolute("%s/dependencies/win32"%EDITOR_EXTENSIONS_DIR)
	if not DirAccess.dir_exists_absolute("%s/dependencies/linux64"%EDITOR_EXTENSIONS_DIR):
		DirAccess.make_dir_recursive_absolute("%s/dependencies/linux64"%EDITOR_EXTENSIONS_DIR)
	if not DirAccess.dir_exists_absolute("%s/dependencies/linux32"%EDITOR_EXTENSIONS_DIR):
		DirAccess.make_dir_recursive_absolute("%s/dependencies/linux32"%EDITOR_EXTENSIONS_DIR)
	if not DirAccess.dir_exists_absolute("%s/win64/release"%EDITOR_EXTENSIONS_DIR):
		DirAccess.make_dir_recursive_absolute("%s/win64/release"%EDITOR_EXTENSIONS_DIR)
	if not DirAccess.dir_exists_absolute("%s/win64/debug"%EDITOR_EXTENSIONS_DIR):
		DirAccess.make_dir_recursive_absolute("%s/win64/debug"%EDITOR_EXTENSIONS_DIR)
	if not DirAccess.dir_exists_absolute("%s/win32/release"%EDITOR_EXTENSIONS_DIR):
		DirAccess.make_dir_recursive_absolute("%s/win32/release"%EDITOR_EXTENSIONS_DIR)
	if not DirAccess.dir_exists_absolute("%s/win32/debug"%EDITOR_EXTENSIONS_DIR):
		DirAccess.make_dir_recursive_absolute("%s/win32/debug"%EDITOR_EXTENSIONS_DIR)
	if not DirAccess.dir_exists_absolute("%s/linux64/release"%EDITOR_EXTENSIONS_DIR):
		DirAccess.make_dir_recursive_absolute("%s/linux64/release"%EDITOR_EXTENSIONS_DIR)
	if not DirAccess.dir_exists_absolute("%s/linux64/debug"%EDITOR_EXTENSIONS_DIR):
		DirAccess.make_dir_recursive_absolute("%s/linux64/debug"%EDITOR_EXTENSIONS_DIR)
	if not DirAccess.dir_exists_absolute("%s/linux32/release"%EDITOR_EXTENSIONS_DIR):
		DirAccess.make_dir_recursive_absolute("%s/linux32/release"%EDITOR_EXTENSIONS_DIR)
	if not DirAccess.dir_exists_absolute("%s/linux32/debug"%EDITOR_EXTENSIONS_DIR):
		DirAccess.make_dir_recursive_absolute("%s/linux32/debug"%EDITOR_EXTENSIONS_DIR)
