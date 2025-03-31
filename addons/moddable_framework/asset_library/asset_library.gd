class_name AssetLibrary
## Global for loading assets from [LibraryIndex] array, and managing mods

## Name of mod directory to look for mods in
const MOD_DIR = "user://mods"
## Path to mod settings [ConfigFile]
const MOD_SETTINGS_PATH = "user://mods/settings.cfg"
## Arg used to run in modless mod
const MODLESS_ARG = "--modless"
## Feature tag used to force modless
const MODLESS_FEATURE_TAG = "modless"

## [LibraryIndex] to manage
static var libraries: Array[AssetLibraryIndex]
## [LibraryIndex] by [member LibraryIndex.index_name]
static var _libraries_by_name: Dictionary[StringName, AssetLibraryIndex]
## List of enabled mods
static var enabled_mods: PackedStringArray = []
## Settings containing mod load order, and any other mod settings
static var mod_settings := ConfigFile.new()

static func initialize() -> void:
	reload_mod_list()
	if libraries.is_empty(): return
	var start_tick := Time.get_ticks_msec()
	var count: int = 0
	if ModdableFrameworkLibrarySettings.get_setting("Library/Verbose"): print("Initializing libraries...")
	for library in libraries:
		assert(!_libraries_by_name.has(library.index_name), "Duplicate Library Index: %s"%library)
		_libraries_by_name[library.index_name] = library
		library.add_all_from_dir()
		library.add_all_from_executable_dir()
		for mod in enabled_mods:
			library.add_all_from_mod_dir("%s/%s"%[MOD_DIR, enabled_mods])
		if ModdableFrameworkLibrarySettings.get_setting("Library/Verbose"): 
			print("\tLoaded %s: %s"%[library.index_name, library.assets.size()])
		count += library.assets.size()
	if ModdableFrameworkLibrarySettings.get_setting("Library/Verbose"): 
		print("Loaded %s assets in %sms"%[count, (Time.get_ticks_msec() - start_tick)])

static func finalize() -> void:
	save_mod_settings()
	for library in libraries:
		library.clear_assets()

## Reloads all [member libraries]
static func reload_libraries() -> void:
	if libraries.is_empty(): return
	var start_tick := Time.get_ticks_msec()
	var count: int = 0
	if ModdableFrameworkLibrarySettings.get_setting("Library/Verbose"): print("Reloading libraries...")
	for library in libraries:
		library.clear_assets()
		library.add_all_from_dir()
		library.add_all_from_executable_dir()
		for mod in enabled_mods:
			library.add_all_from_mod_dir("%s/%s"%[MOD_DIR, enabled_mods])
		if ModdableFrameworkLibrarySettings.get_setting("Library/Verbose"): 
			print("\tLoaded %s: %s"%[library.index_name, library.assets.size()])
	if ModdableFrameworkLibrarySettings.get_setting("Library/Verbose"): 
		print("Loaded %s assets in %sms"%[count, (Time.get_ticks_msec() - start_tick)])

## True if [member libraries] has [param index]
static func has_library(index: StringName) -> bool:
	return _libraries_by_name.has(index)

## Returns [LibraryIndex] from [member libraries]
static func get_library(index: StringName) -> AssetLibraryIndex:
	assert(_libraries_by_name.has(index), "Library does not exist: %s"%index)
	return _libraries_by_name[index]

## Identical to [method LibraryIndex.get_asset_path]
static func get_asset_path(index: StringName, key: String) -> String:
	assert(_libraries_by_name.has(index), "Library does not exist: %s"%index)
	return _libraries_by_name[index].get_asset_path(key)

## Identical to [method LibraryIndex.has_asset]
static func has_asset(index: StringName, key: String) -> bool:
	assert(_libraries_by_name.has(index), "Library does not exist: %s"%index)
	return _libraries_by_name[index].has_asset(key)

## Identical to [method LibraryIndex.is_asset_internal]
static func is_asset_internal(index: StringName, key: String) -> bool:
	assert(_libraries_by_name.has(index), "Library does not exist: %s"%index)
	return _libraries_by_name[index].is_asset_internal(key)

## Identical to [method LibraryIndex.get_all_paths]
static func get_all_paths(index: StringName) -> PackedStringArray:
	assert(_libraries_by_name.has(index), "Library does not exist: %s"%index)
	return _libraries_by_name[index].get_all_paths()

## Identical to [method LibraryIndex.get_all_keys], except with mods param filled out. Note, this is slow
static func get_all_keys(index: StringName) -> PackedStringArray:
	assert(_libraries_by_name.has(index), "Library does not exist: %s"%index)
	var mod_dirs := PackedStringArray()
	for mod in enabled_mods:
		mod_dirs.append(get_mod_directory(mod))
	return _libraries_by_name[index].get_all_keys(mod_dirs)

## Returns true if started with command line argument [member MODLESS_ARG]
static func run_modless() -> bool:
	if OS.has_feature(MODLESS_FEATURE_TAG): return true
	return OS.get_cmdline_user_args().has(MODLESS_ARG)

## Updates mod settings, adding new mods, and removing missing mods, and refreshing load order
static func reload_mod_list() -> void:
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(MOD_DIR)): return
	if DirAccess.get_directories_at(ProjectSettings.globalize_path(MOD_DIR)).size() == 0: return
	if FileAccess.file_exists(MOD_SETTINGS_PATH): mod_settings.load(MOD_SETTINGS_PATH)
	else: mod_settings.save(MOD_SETTINGS_PATH)
	if run_modless():
		if ModdableFrameworkLibrarySettings.get_setting("Library/Verbose"): 
			print("Running modless. Reload mod list skipped.")
		return
	if ModdableFrameworkLibrarySettings.get_setting("Library/Verbose"): 
		print("Loading mods...")
	var start_tick := Time.get_ticks_msec()
	enabled_mods.clear()
	var found_dirs: PackedStringArray = []
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(MOD_DIR)):
		found_dirs = DirAccess.get_directories_at(MOD_DIR)
		for dir in found_dirs:
			if mod_settings.get_value("LoadOrder", dir, null) == null:
				mod_settings.set_value("LoadOrder", dir, -1)
		if mod_settings.has_section("LoadOrder"):
			for dir in mod_settings.get_section_keys("LoadOrder"):
				if not found_dirs.has(dir): 
					mod_settings.erase_section_key("LoadOrder", dir)
					_clear_mod_settings(dir)
			var mods_to_load: Dictionary[int, String]
			for mod in mod_settings.get_section_keys("LoadOrder"):
				if mod_settings.get_value("LoadOrder", mod, -1) >= 0:
					mods_to_load[mod_settings.get_value("LoadOrder", mod, -1)] = mod
			var order: int = 0
			for n in range(0, mods_to_load.values().max() + 1):
				if not mods_to_load.has(n): continue
				mod_settings.set_value("LoadOrder", mods_to_load[n], order)
				enabled_mods.append(mods_to_load[n])
				order += 1
	for enabled_mod in enabled_mods:
		if not mod_dependencies_fulfilled(enabled_mod): 
			set_mod(enabled_mod, false)
	save_mod_settings()
	if ModdableFrameworkLibrarySettings.get_setting("Library/Verbose"): 
		print("Loaded %s mods in %sms"%[found_dirs.size(), (Time.get_ticks_msec() - start_tick)])

## Returns directory of specified mod if it exists
static func get_mod_directory(mod: String) -> String:
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("%s/%s"%[MOD_DIR, mod])):
		return "%s/%s"%[MOD_DIR, mod]
	else: return ""

## Returns list of both active and disabled mods
static func get_all_mods() -> PackedStringArray:
	if mod_settings.has_section("LoadOrder"): return mod_settings.get_section_keys("LoadOrder")
	else: return []

## Returns true if specified mod is active
static func is_mod_active(mod: String) -> bool:
	return enabled_mods.has(mod)

## Sets mod as [param enable], adding to end of load list
static func set_mod(mod: String, enable: bool) -> void:
	if run_modless():
		if ModdableFrameworkLibrarySettings.get_setting("Library/Verbose"): 
			print("Running modless. Set mod skipped.")
		return
	assert(mod_settings.has_section("LoadOrder"), "LoadOrder doesn't exist in mod settings")
	if enable:
		if enabled_mods.has(mod): return
		if not mod_dependencies_fulfilled(mod): return
		assert(mod_settings.get_value("LoadOrder", mod, null) != null, "Mod doesn't exist: %s"%mod)
		enabled_mods.append(mod)
		mod_settings.set_value("LoadOrder", mod, get_max_load_order())
		_initialize_mod_settings(mod)
	else:
		if not enabled_mods.has(mod): return
		assert(mod_settings.get_value("LoadOrder", mod, null) != null, "Mod doesn't exist: %s"%mod)
		enabled_mods.remove_at(enabled_mods.find(mod))
		mod_settings.set_value("LoadOrder", mod, -1)
		_clear_mod_settings(mod)
		for enabled_mod in enabled_mods:
			if not mod_dependencies_fulfilled(enabled_mod): 
				set_mod(enabled_mod, false)
	save_mod_settings()

## Returns max value in the mod load order
static func get_max_load_order() -> int:
	var max_value: int = 0
	for _mod in mod_settings.get_section_keys("LoadOrder"):
		if mod_settings.get_value("LoadOrder", _mod, -1) > max_value:
			max_value = mod_settings.get_value("LoadOrder", _mod, -1)
	return max_value

## Changes load order of active mod
static func set_mod_load_order(mod: String, order: int) -> void:
	assert(enabled_mods.has(mod), "Can't set load order of disabled mod")
	assert(mod_settings.has_section("LoadOrder"), "LoadOrder doesn't exist in mod settings")
	order = clampi(order, 0, get_max_load_order())
	var current_load_order: int = mod_settings.get_value("LoadOrder", mod, 0)
	if order == current_load_order: return
	for key in mod_settings.get_section_keys("LoadOrder"):
		if mod == mod: continue
		var key_order: int = mod_settings.get_value("LoadOrder", key, 0)
		if order > current_load_order:
			if key_order > current_load_order and key_order <= order:
				mod_settings.set_value("LoadOrder", key, key_order - 1)
		else:
			if key_order < current_load_order and key_order >= order:
				mod_settings.set_value("LoadOrder", key, key_order + 1)
	mod_settings.set_value("LoadOrder", mod, order)
	enabled_mods.clear()
	var mods_to_load: Dictionary[int, String]
	for _mod in mod_settings.get_section_keys("LoadOrder"):
		if mod_settings.get_value("LoadOrder", _mod, -1) >= 0:
			mods_to_load[mod_settings.get_value("LoadOrder", _mod, -1)] = mod
	var _order: int = 0
	for n in range(0, mods_to_load.values().max() + 1):
		if not mods_to_load.has(n): continue
		mod_settings.set_value("LoadOrder", mods_to_load[n], _order)
		enabled_mods.append(mods_to_load[n])
		_order += 1

## Saves current mod settings and load order
static func save_mod_settings() -> void:
	mod_settings.save(MOD_SETTINGS_PATH)

## Returns "manifest.cfg" from specified mod if it exists.
static func get_mod_manifest(mod: String) -> ConfigFile:
	if get_mod_directory(mod).is_empty(): return ConfigFile.new()
	if not FileAccess.file_exists("%s/manifest.cfg"%get_mod_directory(mod)): return ConfigFile.new()
	var output := ConfigFile.new()
	output.load("%s/manifest.cfg"%get_mod_directory(mod))
	return output

## Returns name of mod, either from manifest or directory name
static func get_mod_name(mod: String) -> String:
	return get_mod_manifest(mod).get_value("Info", "Name", mod).capitalize()

## Returns specified info about mod if manifest present
static func get_mod_info(mod: String, info: String) -> Variant:
	return get_mod_manifest(mod).get_value("Info", info, null)

## Returns mod version if it has manifest present
static func get_mod_version(mod: String) -> String:
	return get_mod_manifest(mod).get_value("Info", "Version", "1.0.0")

## Returns [Texture2D] from icon.png inside of mod directory. Note: Icon gets squared
static func get_mod_icon(mod: String) -> Texture2D:
	if not FileAccess.file_exists("%s/icon.png"%get_mod_directory(mod)):
		return PlaceholderTexture2D.new()
	var image := Image.new()
	if image.load_png_from_buffer(FileAccess.get_file_as_bytes("%s/icon.png"%get_mod_directory(mod))) != OK:
		return PlaceholderTexture2D.new()
	var long_side: int = image.get_width()
	if image.get_height() > image.get_width(): long_side = image.get_height()
	image.resize(long_side, long_side, Image.INTERPOLATE_BILINEAR)
	return ImageTexture.create_from_image(image)

## Returns a list of mod settings by Setting:{"Name","Default","Type"}
static func get_mod_settings_list(mod: String) -> Dictionary[StringName, Variant]:
	var output: Dictionary[StringName, Variant] = {}
	var mainfest := get_mod_manifest(mod)
	for section in mainfest.get_sections():
		if not section.begins_with("Setting_"): continue
		output[section.trim_prefix("Setting_")] = {
			"Name":mainfest.get_value(section,"Name", section.trim_prefix("Setting_").capitalize()),
			"Default":mainfest.get_value(section,"Default", 0),
			"Type":mainfest.get_value(section,"Default", TYPE_INT)
		}
	return output

## Get current value of mod setting
static func get_mod_setting(mod: String, setting: String) -> Variant:
	return mod_settings.get_value("Settings_%s"%mod, setting, 0)

## Set value of mod setting
static func set_mod_setting(mod: String, setting: String, value: Variant) -> void:
	mod_settings.set_value("Settings_%s"%mod, setting, value)

## Initializes mod settings in settings file
static func _initialize_mod_settings(mod: String) -> void:
	var settings := get_mod_settings_list(mod)
	for setting in settings.keys():
		mod_settings.set_value("Settings_%s"%mod, setting, settings[setting]["Default"])

## Removes mod settings from settings file
static func _clear_mod_settings(mod: String) -> void:
	var settings := get_mod_settings_list(mod)
	for setting in settings.keys():
		mod_settings.erase_section("Settings_%s"%mod)

## Gets list of mod "Dependencies" if present in mod manifest
static func get_mod_dependencies(mod: String) -> PackedStringArray:
	return get_mod_manifest(mod).get_value("Info", "Dependencies", [])

## Returns true if all mod Dependencies fulfilled
static func mod_dependencies_fulfilled(mod: String) -> bool:
	var enabled_mods_by_name := PackedStringArray()
	for enabled_mod in enabled_mods: enabled_mods_by_name.append(get_mod_name(enabled_mod))
	for dependency in get_mod_dependencies(mod):
		if not enabled_mods_by_name.has(dependency): return false
	return true

## Returns list of unfulfilled mod dependencies
static func get_mod_missing_dependencies(mod: String) -> PackedStringArray:
	var output := PackedStringArray()
	var enabled_mods_by_name := PackedStringArray()
	for enabled_mod in enabled_mods: enabled_mods_by_name.append(get_mod_name(enabled_mod))
	for dependency in get_mod_dependencies(mod):
		if not enabled_mods_by_name.has(dependency): output.append(dependency)
	return output

## Returns MD5s of all asset libraries, useful for multiplayer client authentication
static func get_md5s_of_all_libraries() -> PackedByteArray:
	var output := PackedByteArray()
	for library in libraries:
		output.append_array(library.get_asset_collection_md5())
	return output
