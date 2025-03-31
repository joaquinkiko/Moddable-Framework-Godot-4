class_name ModdableFrameworkMainLoop extends SceneTree
## Designed to replace Project Setting ("application/run/main_loop_type").
## Manages loading resource packs and extensions at bootup, 
## initializing the [AssetLibrary], and running various static classes at runtime.

## Any unexpected third party packs, extensions, or assets loaded at bootup
var third_party_paths := PackedStringArray([])
## All non-DLC directory loaded packs
var loaded_packs_paths := PackedStringArray([])
## All DLC directory loaded packs
var loaded_dlc_packs_paths := PackedStringArray([])
## All Patches directory loaded packs
var loaded_patch_packs_paths := PackedStringArray([])
## All loaded extensions
var loaded_extension_paths := PackedStringArray([])

func _initialize() -> void:
	_load_extensions()
	if ModdableFrameworkMainLoopSettings.get_setting("Bootup/Verbose"): 
		var third_party_extensions_count := 0
		for path in third_party_paths: if path.get_extension() == "dll" or path.get_extension() == "so":
			third_party_extensions_count += 1
			if third_party_extensions_count > 0:
				print("\tThird-Party Library Extension detected: %s"%third_party_extensions_count)
	_load_resource_packs()
	if ModdableFrameworkMainLoopSettings.get_setting("Bootup/Verbose"): 
		var third_party_pack_count := 0
		for path in third_party_paths: if path.get_extension() == "pck":
			third_party_pack_count += 1
			if third_party_pack_count > 0:
				print("\tThird-Party Resource Packs detected: %s"%third_party_pack_count)
	_initialize_asset_library()
	if ModdableFrameworkMainLoopSettings.get_setting("Bootup/Verbose"): 
		var third_party_asset_count := 0
		for path in third_party_paths: if not (path.get_extension() == "dll" or path.get_extension() == "so" or path.get_extension() == "pck"):
			third_party_asset_count += 1
			if third_party_asset_count > 0:
				print("\tThird-Party assets detected: %s"%third_party_asset_count)
	_call_static_function("Initialize")
	if ModdableFrameworkMainLoopSettings.get_setting("Bootup/Verbose"): 
		print("Main Loop Initialized in %sms\n"%Time.get_ticks_msec())

func _process(delta: float) -> bool:
	_call_static_function("Process", [delta])
	return false

func _physics_process(delta: float) -> bool:
	_call_static_function("Physics", [delta])
	return false

func _finalize() -> void:
	_call_static_function("Finalize")
	AssetLibrary.finalize()
	_editor_unload_extensions()

## (Exported builds only) returns ConfigFile of expected packs and extensions to load,
## along with hashes of their expected file contents. Useful for detecting third-party assets.
func get_expected_resources_cfg() -> ConfigFile:
	if OS.has_feature("editor"): return ConfigFile.new()
	var expected_cfg := ConfigFile.new()
	if not expected_cfg.load_encrypted_pass("res://expected_resources.cfg", "v%s"%ProjectSettings.get_setting("application/config/version")) == OK:
		push_error("Error loading 'res://expected_resources.cfg'")
	return expected_cfg

## (Exported builds only) Loads resource packs, DLC, and patch packs at bootup
func _load_resource_packs() -> void:
	if OS.has_feature("editor"): return
	var expected_cfg := get_expected_resources_cfg()
	var dir_to_check: String = ProjectSettings.globalize_path("%s/%s"%[OS.get_executable_path().get_base_dir(), ModdableFrameworkExportSettings.get_setting("ExportOptions/PackDir")])
	if not DirAccess.dir_exists_absolute(dir_to_check): return
	for file in DirAccess.get_files_at(dir_to_check):
		if file.get_extension() == "pck":
			if not OS.has_feature("editor"):
				if expected_cfg.has_section("packs"):
					if not expected_cfg.get_section_keys("packs").has(file):
						third_party_paths.append(file)
				else: third_party_paths.append(file)
			if ModdableFrameworkMainLoopSettings.get_setting("Bootup/Verbose"): print("Loading %s..."%file)
			ProjectSettings.load_resource_pack("%s/%s"%[dir_to_check, file], false)
			loaded_packs_paths.append("%s/%s"%[dir_to_check, file])
	if not ModdableFrameworkMainLoopSettings.get_setting("DLC/SearchForPacks"): return
	dir_to_check == ProjectSettings.globalize_path("%s/%s"%[OS.get_executable_path().get_base_dir(), ModdableFrameworkMainLoopSettings.get_setting("DLC/SearchDir")])
	if not DirAccess.dir_exists_absolute(dir_to_check): return
	for file in DirAccess.get_files_at(dir_to_check):
		if file.get_extension() == "pck":
			if ModdableFrameworkMainLoopSettings.get_setting("Bootup/Verbose"): print("Loading DLC %s..."%file)
			ProjectSettings.load_resource_pack("%s/%s"%[dir_to_check, file], false)
			loaded_dlc_packs_paths.append("%s/%s"%[dir_to_check, file])
	if not ModdableFrameworkMainLoopSettings.get_setting("Patches/SearchForPacks"): return
	dir_to_check == ProjectSettings.globalize_path("%s/%s"%[OS.get_executable_path().get_base_dir(), ModdableFrameworkMainLoopSettings.get_setting("Patches/SearchDir")])
	if not DirAccess.dir_exists_absolute(dir_to_check): return
	for file in DirAccess.get_files_at(dir_to_check):
		if file.get_extension() == "pck":
			if ModdableFrameworkMainLoopSettings.get_setting("Bootup/Verbose"): print("Loading Patch %s..."%file)
			ProjectSettings.load_resource_pack("%s/%s"%[dir_to_check, file], false)
			loaded_patch_packs_paths.append("%s/%s"%[dir_to_check, file])

## Loads Shared Library extensions at bootup (essentially generating .gdextension file at runtime)
func _load_extensions() -> void:
	var dir_to_check: String
	var expected_cfg := get_expected_resources_cfg()
	if OS.has_feature("editor"):
		if OS.has_feature("windows"): 
			if OS.has_feature("x86_64"): 
				dir_to_check = "%s/win64/debug"%ModdableFrameworkExportSettings.EDITOR_EXTENSIONS_DIR
				_editor_load_dependencies("%s/dependencies/win64"%ModdableFrameworkExportSettings.EDITOR_EXTENSIONS_DIR)
			elif OS.has_feature("x86_32"): 
				dir_to_check = "%s/win32/debug"%ModdableFrameworkExportSettings.EDITOR_EXTENSIONS_DIR
				_editor_load_dependencies("%s/dependencies/win32"%ModdableFrameworkExportSettings.EDITOR_EXTENSIONS_DIR)
		if OS.has_feature("linux"): 
			if OS.has_feature("x86_64"): 
				dir_to_check = "%s/linux64/debug"%ModdableFrameworkExportSettings.EDITOR_EXTENSIONS_DIR
				_editor_load_dependencies("%s/dependencies/linux64"%ModdableFrameworkExportSettings.EDITOR_EXTENSIONS_DIR)
			elif OS.has_feature("x86_32"): 
				dir_to_check = "%s/linux32/debug"%ModdableFrameworkExportSettings.EDITOR_EXTENSIONS_DIR
				_editor_load_dependencies("%s/dependencies/linux32"%ModdableFrameworkExportSettings.EDITOR_EXTENSIONS_DIR)
		var base_dir_to_check := dir_to_check
	else: dir_to_check = "%s/%s"%[OS.get_executable_path().get_base_dir(), ModdableFrameworkExportSettings.get_setting("ExportOptions/ExtensionDir")]
	if not DirAccess.dir_exists_absolute(dir_to_check): return
	for dir in DirAccess.get_directories_at(dir_to_check):
		if OS.has_feature(dir):
			for file in DirAccess.get_files_at("%s/%s"%[dir_to_check, dir]):
				_generate_gdextension("%s/%s"%[dir_to_check, file], expected_cfg)
	for file in DirAccess.get_files_at(dir_to_check):
		_generate_gdextension("%s/%s"%[dir_to_check, file], expected_cfg)
	

func _generate_gdextension(path: String, expected_cfg: ConfigFile = get_expected_resources_cfg()) -> void:
	if (OS.has_feature("windows") and not  path.get_extension() == "dll") or (OS.has_feature("linux") and not  path.get_extension() == "so"): return
	if OS.has_feature("ignore-%s"%path.get_basename()): return
	for extension in loaded_extension_paths: if extension.get_file() == path.get_file(): return
	if not OS.has_feature("editor"):
		if expected_cfg.has_section("extensions"):
			if not expected_cfg.get_section_keys("extensions").has(path.get_file()):
					third_party_paths.append(path.get_file())
			elif not expected_cfg.get_value("extensions", path.get_file()) == FileAccess.get_md5(path):
				third_party_paths.append(path.get_file())
		else:
			third_party_paths.append(path.get_file())
	if ModdableFrameworkMainLoopSettings.get_setting("Bootup/Verbose"): print("Loading %s..."%path.get_file())
	var gdextension := FileAccess.create_temp(FileAccess.WRITE_READ, path.get_file().get_basename(), "gdextension", false)
	var entry_symbol: String = "%s_init"%path.get_file().get_basename()
	gdextension.store_string('[configuration]\nentry_symbol = "%s"\n'%entry_symbol)
	gdextension.store_string('compatibility_minimum = 4.4\n\n[libraries]\n')
	if OS.has_feature("windows"):
		gdextension.store_string('windows = "%s"\n\n'%path)
	elif OS.has_feature("linux"):
		gdextension.store_string('linux = "%s"\n\n'%path)
	else: return
	gdextension.close()
	if GDExtensionManager.load_extension(gdextension.get_path()) == GDExtensionManager.LOAD_STATUS_OK:
		loaded_extension_paths.append(path)
	else: push_error("Error loading %s"%path.get_file())

## Initializes the [AssetLibrary]
func _initialize_asset_library() -> void:
	if FileAccess.file_exists(ModdableFrameworkLibrarySettings.get_setting("Library/ConfigPath")):
		var library_cfg := ConfigFile.new()
		library_cfg.load(ModdableFrameworkLibrarySettings.get_setting("Library/ConfigPath"))
		var indices: Array[AssetLibraryIndex]
		for section in library_cfg.get_sections():
			var index = AssetLibraryIndex.new()
			index.index_name = section
			index.asset_dir = library_cfg.get_value(section, "asset_dir", "res://")
			index.valid_extensions = library_cfg.get_value(section, "valid_extensions", [])
			index.excluded_dirs = library_cfg.get_value(section, "excluded_dirs", [])
			index.allow_mod_assets = library_cfg.get_value(section, "allow_mod_assets", true)
			index.check_for_locale_variants = library_cfg.get_value(section, "check_for_locale_variants", true)
			index.allow_unique_md5 = library_cfg.get_value(section, "allow_unique_md5", true)
			indices.append(index)
		AssetLibrary.libraries = indices
	AssetLibrary.initialize()

## (Editor only) Copies extension dependencies into Godot editor executable's directory
func _editor_load_dependencies(dir: String) -> void:
	if not OS.has_feature("editor"): return
	for sub_dir in DirAccess.get_directories_at(dir):
		if OS.has_feature(sub_dir):
			for file in DirAccess.get_files_at("%s/%s"%[dir, sub_dir]):
				if not (file.begins_with("dll") or file.begins_with("so")): continue
				var expected: String = "%s/%s"%[OS.get_executable_path().get_base_dir(), file]
				if FileAccess.file_exists(expected): continue
				DirAccess.copy_absolute("%s/%s/%s"%[dir, sub_dir, file], expected)
	for file in DirAccess.get_files_at(dir):
		if not (file.begins_with("dll") or file.begins_with("so")): continue
		var expected: String = "%s/%s"%[OS.get_executable_path().get_base_dir(), file]
		if FileAccess.file_exists(expected): continue
		DirAccess.copy_absolute("%s/%s"%[dir, file], expected)

## (Editor only) Calls [method _editor_unload_dependencies] for all extensions
func _editor_unload_extensions() -> void:
	if OS.has_feature("editor"):
		if OS.has_feature("windows"): 
			if OS.has_feature("x86_64"): 
				_editor_unload_dependencies("%s/dependencies/win64"%ModdableFrameworkExportSettings.EDITOR_EXTENSIONS_DIR)
			elif OS.has_feature("x86_32"): 
				_editor_unload_dependencies("%s/dependencies/win32"%ModdableFrameworkExportSettings.EDITOR_EXTENSIONS_DIR)
		if OS.has_feature("linux"): 
			if OS.has_feature("x86_64"): 
				_editor_unload_dependencies("%s/dependencies/linux64"%ModdableFrameworkExportSettings.EDITOR_EXTENSIONS_DIR)
			elif OS.has_feature("x86_32"): 
				_editor_unload_dependencies("%s/dependencies/linux32"%ModdableFrameworkExportSettings.EDITOR_EXTENSIONS_DIR)

## (Editor only) Cleans up extension dependencies created by [method _editor_load_dependencies]
func _editor_unload_dependencies(dir: String) -> void:
	if not OS.has_feature("editor"): return
	for file in DirAccess.get_files_at(dir):
		if not (file.begins_with("dll") or file.begins_with("so")): continue
		var expected: String = "%s/%s"%[OS.get_executable_path().get_base_dir(), file]
		if FileAccess.file_exists(expected):
			DirAccess.remove_absolute(file)
	if DirAccess.dir_exists_absolute("%s/editor"%dir):
		for file in DirAccess.get_files_at("%s/editor"%dir):
			if not (file.begins_with("dll") or file.begins_with("so")): continue
			var expected: String = "%s/%s"%[OS.get_executable_path().get_base_dir(), file]
			if FileAccess.file_exists(expected):
				DirAccess.remove_absolute(file)

## Calls specified function on all static classes defined in [ModdableFrameworkMainLoopSettings]
func _call_static_function(function: String, params := Array([])) -> void:
	var classes := ModdableFrameworkMainLoopSettings.get_function_classes(function)
	if classes.size() == 0: return
	for static_class in classes:
		var method := ModdableFrameworkMainLoopSettings.get_function_method(function)
		if method.is_empty(): continue
		if not ResourceLoader.exists(static_class): 
			push_warning("Couldn't find static class (%s) to call (%s) on"%[static_class, method])
			continue
		var gdscript := load(static_class).new() as GDScript
		if gdscript == null:
			push_warning("Couldn't find static class (%s) to call (%s) on"%[static_class, method])
			continue
		if not gdscript.has_meta(method): 
			push_warning("Couldn't find method (%s) in static class (%s)"%[method, static_class])
			continue
		if params.size() == 0:
			gdscript.call(method)
		else: gdscript.callv(method, params)

## Generated md5 of loaded resource packs (returns empty array if none detected or running from editor)
func get_md5_loaded_packs() -> PackedByteArray:
	if OS.has_feature("editor"): return []
	if loaded_packs_paths.size() == 0: return []
	var md5s: String = "0"
	for path in loaded_packs_paths:
		md5s = md5s + FileAccess.get_md5(path)
	return md5s.md5_buffer()

## Generated md5 of loaded DLC packs (returns empty array if none detected or running from editor)
func get_md5_loaded_dlc_packs() -> PackedByteArray:
	if OS.has_feature("editor"): return []
	if loaded_dlc_packs_paths.size() == 0: return []
	var md5s: String = "0"
	for path in loaded_dlc_packs_paths:
		md5s = md5s + FileAccess.get_md5(path)
	return md5s.md5_buffer()

## Generated md5 of loaded Patch packs (returns empty array if none detected or running from editor)
func get_md5_loaded_patches_packs() -> PackedByteArray:
	if OS.has_feature("editor"): return []
	if loaded_patch_packs_paths.size() == 0: return []
	var md5s: String = "0"
	for path in loaded_patch_packs_paths:
		md5s = md5s + FileAccess.get_md5(path)
	return md5s.md5_buffer()


## Generated md5 of extensions (returns empty array if none detected)
func get_md5_loaded_extensions() -> PackedByteArray:
	if loaded_extension_paths.size() == 0: return []
	var md5s: String = "0"
	for path in loaded_extension_paths:
		md5s = md5s + FileAccess.get_md5(path)
	return md5s.md5_buffer()

## Generated md5 of third party assets detected at bootup (returns empty array if none detected)
func get_md5_third_party_assets() -> PackedByteArray:
	if third_party_paths.size() == 0: return []
	var md5s: String = "0"
	for path in third_party_paths:
		if not (path.get_extension() == "dll" or path.get_extension() == "so" or path.get_extension() == "pck"):
			md5s = md5s + FileAccess.get_md5(path)
	return md5s.md5_buffer()

## Generated md5 of core executable plus bootup pack (returns empty array whilst running from editor)
func get_md5_bootup_pack() -> PackedByteArray:
	if OS.has_feature("editor"): return []
	var md5s: String = "0"
	if FileAccess.file_exists(OS.get_executable_path()):
		md5s = md5s + FileAccess.get_md5(OS.get_executable_path())
	var executable_name := OS.get_executable_path().get_basename()
	var executable_dir := OS.get_executable_path().get_base_dir()
	if FileAccess.file_exists("%s/%s.pck"%[executable_dir, executable_name]):
		md5s = md5s + FileAccess.get_md5("%s/%s.pck"%[executable_dir, executable_name])
	return md5s.md5_buffer()
