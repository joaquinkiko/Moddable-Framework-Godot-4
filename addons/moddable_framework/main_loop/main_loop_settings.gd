class_name ModdableFrameworkMainLoopSettings
## Project Settings Loader and Getter for [ModdableFrameworkMainLoop] related settings

const BASE_SETTING_PATH = "ModdableFramework/MainLoop"
const STATIC_FUNCTION_TYPES = ["Initialize", "Process", "Physics", "Finalize"]
const DEFAULT_SETTINGS = {
	"Library/ConfigPath":"res://asset_library.cfg",
	"Bootup/Verbose":true,
	"DLC/SearchForPacks":true,
	"DLC/SearchDir":"dlc",
	"DLC/ExpectedPackNames":[],
	"Static/InitializeFunction":"_initialize",
	"Static/InitializeClasses":[],
	"Static/ProcessFunction":"_process",
	"Static/ProcessClasses":[],
	"Static/PhysicsFunction":"_physics",
	"Static/PhysicsClasses":[],
	"Static/FinalizeFunction":"_finalize",
	"Static/FinalizeClasses":[],
	"Patches/SearchForPacks":true,
	"Patches/SearchDir":"patches"
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
	_add_setting("Bootup/Verbose", true, TYPE_BOOL)
	_add_setting("DLC/SearchForPacks", true, TYPE_BOOL)
	_add_setting("DLC/SearchDir", "dlc", TYPE_STRING, 0)
	_add_setting("Patches/SearchForPacks", true, TYPE_BOOL)
	_add_setting("Patches/SearchDir", "patches", TYPE_STRING, 0)
	for type in STATIC_FUNCTION_TYPES:
		_add_setting("Static/%sFunction"%type, "_%s"%type.to_lower(), TYPE_STRING, 0, "Function Name")
		_add_setting("Static/%sClasses"%type, [], TYPE_PACKED_STRING_ARRAY)

static func _remove_setting(key: String) -> void:
	if ProjectSettings.has_setting("%s/%s"%[BASE_SETTING_PATH, key]):
		ProjectSettings.set_setting("%s/%s"%[BASE_SETTING_PATH, key], null)

static func remove_all_settings() -> void:
	_remove_setting("Bootup/Verbose")
	_remove_setting("DLC/SearchForPacks")
	_remove_setting("DLC/SearchDir")
	_remove_setting("Patches/SearchForPacks")
	_remove_setting("Patches/SearchDir")
	for type in STATIC_FUNCTION_TYPES:
		_remove_setting("Bootup/%sFunction"%type)
		_remove_setting("Static/%sClasses"%type)

static func get_setting(key: String) -> Variant:
	return ProjectSettings.get_setting("%s/%s"%[BASE_SETTING_PATH, key], DEFAULT_SETTINGS.get(key))

static func get_function_classes(function: String) -> PackedStringArray:
	var output: PackedStringArray
	if ProjectSettings.has_setting("%s/Static/%sClasses"%[BASE_SETTING_PATH, function]):
		output = get_setting("Static/%sClasses"%function)
	return output

static func get_function_method(function: String) -> String:
	return get_setting("Static/%sFunction"%function)
