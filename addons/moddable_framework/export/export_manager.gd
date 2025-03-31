extends EditorExportPlugin

var _colored_folders: Dictionary[String, String] = {}
var _colored_folders_keys: PackedStringArray
var _dependency_files: PackedStringArray
var _features: PackedStringArray
var _is_debug: bool
var _export_dir: StringName
var _resource_dir: StringName
var _extensions_dir: StringName
var _files_to_pack: Array[PackedStringArray]
var _debug_files_to_pack: PackedStringArray
var _files_to_export_unpacked: PackedStringArray
var _exported_extensions: PackedStringArray
var _count_export_normal: int
var _count_ignored: int
var _build_start_time: int

func _get_name() -> String:
	return "ModdableFrameworkExport"

func _supports_platform(platform: EditorExportPlatform) -> bool:
	match platform.get_os_name():
		'Windows': return true
		'Linux': return true
		_: return false

func _platform_supports_external_files(platform: EditorExportPlatform) -> bool:
	match platform.get_os_name():
		'Windows': return true
		'Linux': return true
		_: return false

func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	if not _supports_platform(get_export_platform()): return
	_build_start_time = Time.get_ticks_msec()
	_clean_up()
	if not ProjectSettings.get("file_customization/folder_colors") == null:
		_colored_folders.assign(ProjectSettings.get("file_customization/folder_colors"))
		_colored_folders_keys = _colored_folders.keys().duplicate()
		_colored_folders_keys.sort()
		_colored_folders_keys.reverse()
	else:
		_colored_folders.clear()
	_is_debug = is_debug
	_features = features
	_export_dir = path.get_base_dir()
	_resource_dir = "%s/%s"%[_export_dir, ModdableFrameworkExportSettings.get_setting("ExportOptions/PackDir")]
	_extensions_dir = "%s/%s"%[_export_dir, ModdableFrameworkExportSettings.get_setting("ExportOptions/ExtensionDir")]
	_files_to_pack.resize(5)
	_dependency_files.append(ProjectSettings.get_setting("application/run/main_scene"))
	if _dependency_files[-1].begins_with("uid://"): _dependency_files[-1] = ResourceUID.get_id_path(ResourceUID.text_to_id(_dependency_files[-1]))
	_dependency_files.append(ProjectSettings.get_setting("application/boot_splash/image"))
	if _dependency_files[-1].begins_with("uid://"): _dependency_files[-1] = ResourceUID.get_id_path(ResourceUID.text_to_id(_dependency_files[-1]))
	_dependency_files.append(ProjectSettings.get_setting("display/mouse_cursor/custom_image"))
	if _dependency_files[-1].begins_with("uid://"): _dependency_files[-1] = ResourceUID.get_id_path(ResourceUID.text_to_id(_dependency_files[-1]))
	_dependency_files.append(ProjectSettings.get_setting("gui/theme/custom"))
	if _dependency_files[-1].begins_with("uid://"): _dependency_files[-1] = ResourceUID.get_id_path(ResourceUID.text_to_id(_dependency_files[-1]))
	_dependency_files.append(ProjectSettings.get_setting("gui/theme/custom_font"))
	if _dependency_files[-1].begins_with("uid://"): _dependency_files[-1] = ResourceUID.get_id_path(ResourceUID.text_to_id(_dependency_files[-1]))
	_dependency_files.append(ProjectSettings.get_setting("audio/buses/default_bus_layout"))
	if _dependency_files[-1].begins_with("uid://"): _dependency_files[-1] = ResourceUID.get_id_path(ResourceUID.text_to_id(_dependency_files[-1]))
	_dependency_files.append(ProjectSettings.get_setting("rendering/environment/defaults/default_environment"))
	if _dependency_files[-1].begins_with("uid://"): _dependency_files[-1] = ResourceUID.get_id_path(ResourceUID.text_to_id(_dependency_files[-1]))
	_dependency_files.append(ProjectSettings.get_setting("rendering/vrs/texture"))
	if _dependency_files[-1].begins_with("uid://"): _dependency_files[-1] = ResourceUID.get_id_path(ResourceUID.text_to_id(_dependency_files[-1]))
	_dependency_files.append(ProjectSettings.get_setting("xr/openxr/default_action_map"))
	if _dependency_files[-1].begins_with("uid://"): _dependency_files[-1] = ResourceUID.get_id_path(ResourceUID.text_to_id(_dependency_files[-1]))
	_dependency_files.append(ProjectSettings.get_setting("application/config/icon"))
	if _dependency_files[-1].begins_with("uid://"): _dependency_files[-1] = ResourceUID.get_id_path(ResourceUID.text_to_id(_dependency_files[-1]))
	_dependency_files.append(ProjectSettings.get_setting("application/config/macos_native_icon"))
	if _dependency_files[-1].begins_with("uid://"): _dependency_files[-1] = ResourceUID.get_id_path(ResourceUID.text_to_id(_dependency_files[-1]))
	_dependency_files.append(ProjectSettings.get_setting("application/config/windows_native_icon"))
	if _dependency_files[-1].begins_with("uid://"): _dependency_files[-1] = ResourceUID.get_id_path(ResourceUID.text_to_id(_dependency_files[-1]))
	for global in ProjectSettings.get_global_class_list():
		_dependency_files.append(global["path"])
		if _dependency_files[-1].begins_with("uid://"): _dependency_files[-1] = ResourceUID.get_id_path(ResourceUID.text_to_id(_dependency_files[-1]))
	_export_expected_resources()
	if FileAccess.file_exists(ModdableFrameworkLibrarySettings.get_setting("Library/ConfigPath")):
		add_file(ModdableFrameworkLibrarySettings.get_setting("Library/ConfigPath"), FileAccess.get_file_as_bytes(ModdableFrameworkLibrarySettings.get_setting("Library/ConfigPath")), false)
		_count_export_normal += 1

func _export_file(path: String, type: String, features: PackedStringArray) -> void:
	if not _supports_platform(get_export_platform()): return
	if path == ModdableFrameworkLibrarySettings.get_setting("Library/ConfigPath"): return
	if _dependency_files.has(path):
		_count_export_normal += 1
		return
	for key in _colored_folders_keys: if path.get_base_dir().begins_with(key.trim_suffix('/')):
		match ModdableFrameworkExportSettings.get_setting("ExportOptions/DirColorAction%s"%_colored_folders[key].capitalize()):
			ModdableFrameworkExportSettings.DirColorActions.DEFAULT_EXPORT:
				_count_export_normal += 1
			ModdableFrameworkExportSettings.DirColorActions.IGNORE_ON_EXPORT:
				skip_file(path)
			ModdableFrameworkExportSettings.DirColorActions.DEBUG_EXPORT_ONLY:
				if _is_debug: export_debug_file(path)
				else: skip_file(path)
			ModdableFrameworkExportSettings.DirColorActions.EXPORT_UNPACKED:
				export_file_unpacked(path)
			ModdableFrameworkExportSettings.DirColorActions.EXPORT_TO_PCK_1:
				export_to_pck(path, 0)
			ModdableFrameworkExportSettings.DirColorActions.EXPORT_TO_PCK_2:
				export_to_pck(path, 1)
			ModdableFrameworkExportSettings.DirColorActions.EXPORT_TO_PCK_3:
				export_to_pck(path, 2)
			ModdableFrameworkExportSettings.DirColorActions.EXPORT_TO_PCK_4:
				export_to_pck(path, 3)
			ModdableFrameworkExportSettings.DirColorActions.EXPORT_TO_PCK_5:
				export_to_pck(path, 4)
		return
	_count_export_normal += 1

func _export_end() -> void:
	if not _supports_platform(get_export_platform()): return
	print("Files Exported normally: %s"%_count_export_normal)
	_export_unpacked_files()
	if _files_to_export_unpacked.size() > 0:
		print("Files Exported raw: %s"%_files_to_export_unpacked.size())
	_export_resource_packs()
	for n in _files_to_pack.size(): if _files_to_pack[n].size() > 0:
		print("Files Exported to %s.pck: %s"%[ModdableFrameworkExportSettings.get_setting("ExportOptions/Pack%sName"%(n + 1)), _files_to_pack[n].size()])
		break
	_export_debug_pack()
	if _debug_files_to_pack.size() > 0:
		print("Files Exported to debug.pck: %s"%_debug_files_to_pack.size())
	if _count_ignored > 0:
		print("Files ignored: %s"%_count_ignored)
	_export_extensions()
	if _exported_extensions.size() > 0:
		print("Extensions Exported:")
		for file in _exported_extensions:
			print("\t%s"%file)
			break
	_export_license_file()
	print("Exported in %s seconds"%ceili((float(Time.get_ticks_msec() - _build_start_time) / 1000)))
	print("Final export size: %s\n"%String.humanize_size(_get_build_size()))
	_clean_up()

func _clean_up() -> void:
	_dependency_files.clear()
	_exported_extensions.clear()
	_debug_files_to_pack.clear()
	_colored_folders.clear()
	_files_to_pack.clear()
	_files_to_export_unpacked.clear()
	_features.clear()
	_export_dir = ""
	_resource_dir = ""
	_count_export_normal = 0
	_count_ignored = 0

func get_all_file_paths(path: String) -> PackedStringArray:
	if path == "res://.godot": return []
	if DirAccess.get_files_at(path).has(".gdignore"): return []
	var file_paths: PackedStringArray = []
	var dir = DirAccess.open(path)
	if dir == null: return []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		var file_path = path + file_name
		if dir.current_is_dir():
			file_paths += get_all_file_paths(file_path + '/')
		else:
			file_paths.append(file_path)
		file_name = dir.get_next()
	file_paths.reverse()
	return file_paths

func skip_file(path: String) -> void:
	if path.get_extension() == "gdextension":
		_count_export_normal += 1
		return
	skip()
	_count_ignored += 1

func export_file_unpacked(path: String) -> void:
	if not _platform_supports_external_files(get_export_platform()) or path.get_extension() == "gdextension":
		_count_export_normal += 1
		return
	skip()
	_files_to_export_unpacked.append(path)

func export_to_pck(path: String, pck_index: int) -> void:
	if not _platform_supports_external_files(get_export_platform()) or path.get_extension() == "gdextension":
		_count_export_normal += 1
		return
	skip()
	_files_to_pack[pck_index].append(path)

func export_debug_file(path: String) -> void:
	if not _platform_supports_external_files(get_export_platform()) or path.get_extension() == "gdextension":
		_count_export_normal += 1
		return
	skip()
	_debug_files_to_pack.append(path)

func _export_license_file() -> void:
	if ModdableFrameworkExportSettings.get_setting("ExportOptions/GameCopyrightFilename") != "":
		var license_file : FileAccess = FileAccess.open("%s/%s"%[_export_dir, ModdableFrameworkExportSettings.get_setting("ExportOptions/GameCopyrightFilename").replace("{game_name}", ProjectSettings.get_setting("application/config/name").replace(" ", "_").to_lower())], FileAccess.WRITE)
		if license_file != null:
			if FileAccess.file_exists(ModdableFrameworkExportSettings.get_setting("ExportOptions/MainLicenseFile")):
				license_file.store_string(FileAccess.get_file_as_string(ModdableFrameworkExportSettings.get_setting("ExportOptions/MainLicenseFile")))
				license_file.store_string("\n------------------------------------------------------\n")
			for file in get_all_file_paths("res://"):
				if file.get_file().to_lower().begins_with("license"):
					if file == ModdableFrameworkExportSettings.get_setting("ExportOptions/MainLicenseFile"): continue
					license_file.store_string(FileAccess.get_file_as_string(file))
					license_file.store_string("\n------------------------------------------------------\n")
			license_file.store_string("This game uses Godot Engine, available under the following license (https://godotengine.org/license):\n\n%s\n"%Engine.get_license_text())
			license_file.close()
			print("Exported %s"%ModdableFrameworkExportSettings.get_setting("ExportOptions/GameCopyrightFilename").replace("{game_name}", ProjectSettings.get_setting("application/config/name").replace(" ", "_").to_lower()))
	if ModdableFrameworkExportSettings.get_setting("ExportOptions/GodotCopyrightFilename") != "":
		var godot_license_file : FileAccess = FileAccess.open("%s/%s"%[_export_dir, ModdableFrameworkExportSettings.get_setting("ExportOptions/GodotCopyrightFilename")], FileAccess.WRITE)
		if godot_license_file != null:
			for n in Engine.get_copyright_info().size():
				if n > 0: godot_license_file.store_string("\n------------------------------------------------------\n")
				godot_license_file.store_string(Engine.get_copyright_info()[n]["name"] + "\n\n")
				for component in Engine.get_copyright_info()[n]["parts"]:
					for copyright in component["copyright"]:
						godot_license_file.store_string("Copyright (c) " + copyright + "\n")
					for license in component["license"].split(" and "):
						if Engine.get_license_info().has(license):
							godot_license_file.store_string("\n" + Engine.get_license_info()[license])
						else:
							if license.split(" or ").has("Apache-2.0"):
								godot_license_file.store_string("\n" + Engine.get_license_info()["Apache-2.0"])
							elif license.split(" or ").has("Apache-2.0"):
								godot_license_file.store_string("\n" + Engine.get_license_info()["Expat"])
			godot_license_file.close()
			print("Exported %s"%ModdableFrameworkExportSettings.get_setting("ExportOptions/GodotCopyrightFilename"))

func _export_resource_packs() -> void:
	var total_files_to_pack: int = 0
	for array in _files_to_pack: total_files_to_pack += array.size()
	if total_files_to_pack > 0:
		if _resource_dir != _export_dir and not DirAccess.dir_exists_absolute(_resource_dir):
			DirAccess.make_dir_recursive_absolute(_resource_dir)
	else: return
	for n in _files_to_pack.size():
		if _files_to_pack[n].size() == 0: continue
		var pck_name: String = ModdableFrameworkExportSettings.get_setting("ExportOptions/Pack%sName"%(n + 1))
		if pck_name == "": continue
		var resource_packer := PCKPacker.new()
		resource_packer.pck_start("%s/%s.pck"%[_resource_dir,pck_name])
		for file in _files_to_pack[n]:
			if FileAccess.file_exists("%s.%s"%[file,"import"]):
				resource_packer.add_file("%s.%s"%[file,"import"], "%s.%s"%[file,"import"])
				var import_file : ConfigFile = ConfigFile.new()
				import_file.load("%s.%s"%[file,"import"])
				var path_key : String = "path"
				for key in import_file.get_section_keys('remap'):
					if not key.begins_with("path"): continue
					path_key = key
					break
				var export_path : String = import_file.get_value('remap', path_key, file)
				resource_packer.add_file(export_path, export_path)
			else:
				resource_packer.add_file(file, file)
		resource_packer.flush()

func _export_debug_pack() -> void:
	if _debug_files_to_pack.size() > 0: 
		if _resource_dir != _export_dir and not DirAccess.dir_exists_absolute(_resource_dir):
			DirAccess.make_dir_recursive_absolute(_resource_dir)
	else: return
	var resource_packer := PCKPacker.new()
	resource_packer.pck_start("%s/debug.pck"%_resource_dir)
	for file in _debug_files_to_pack:
		if FileAccess.file_exists("%s.%s"%[file,"import"]):
			resource_packer.add_file("%s.%s"%[file,"import"], "%s.%s"%[file,"import"])
			var import_file : ConfigFile = ConfigFile.new()
			import_file.load("%s.%s"%[file,"import"])
			var path_key : String = "path"
			for key in import_file.get_section_keys('remap'):
				if not key.begins_with("path"): continue
				path_key = key
				break
			var export_path : String = import_file.get_value('remap', path_key, file)
			resource_packer.add_file(export_path, export_path)
		else:
			resource_packer.add_file(file, file)
	resource_packer.flush()

func _export_unpacked_files() -> void:
	if _files_to_export_unpacked.size() > 0: for file in _files_to_export_unpacked:
		if not DirAccess.dir_exists_absolute(("%s/%s"%[_export_dir, file.trim_prefix("res://")]).get_base_dir()):
			DirAccess.make_dir_recursive_absolute(("%s/%s"%[_export_dir, file.trim_prefix("res://")]).get_base_dir())
		DirAccess.copy_absolute(ProjectSettings.globalize_path(file), "%s/%s"%[_export_dir, file.trim_prefix("res://")])

func _export_extensions() -> void:
	var extensions_path: String = "%s/"%ModdableFrameworkExportSettings.EDITOR_EXTENSIONS_DIR
	var dependencies_path: String = "%s/dependencies/"%ModdableFrameworkExportSettings.EDITOR_EXTENSIONS_DIR
	extensions_path = ProjectSettings.globalize_path(extensions_path)
	dependencies_path = ProjectSettings.globalize_path(dependencies_path)
	if _features.has("windows"):
		if _features.has("x86_32"):
			extensions_path = extensions_path + "win32"
			dependencies_path = dependencies_path + "win32"
		elif _features.has("x86_64"):
			extensions_path = extensions_path + "win64"
			dependencies_path = dependencies_path + "win64"
	elif _features.has("linux"):
		if _features.has("x86_32"):
			extensions_path = extensions_path + "linux32"
			dependencies_path = dependencies_path + "linux32"
		elif _features.has("x86_64"):
			extensions_path = extensions_path + "linux64"
			dependencies_path = dependencies_path + "linux64"
	if _is_debug:
		extensions_path = extensions_path + "/debug"
	else:
		extensions_path = extensions_path + "/release"
	var base_extensions_path := extensions_path
	var base_dependencies_path := dependencies_path
	for feature in _features:
		extensions_path = "%s/%s"%[base_extensions_path, feature]
		dependencies_path = "%s/%s"%[base_dependencies_path, feature]
		if DirAccess.dir_exists_absolute(extensions_path):
			if DirAccess.get_files_at(extensions_path).size() > 0:
				if not DirAccess.dir_exists_absolute(_extensions_dir):
					DirAccess.make_dir_recursive_absolute(_extensions_dir)
			for file in DirAccess.get_files_at(extensions_path):
				if _features.has("ignore-%s"%file. get_basename()): continue
				for extension in _exported_extensions: if extension.get_file() == extension.get_file(): continue
				_exported_extensions.append(file)
				DirAccess.copy_absolute("%s/%s"%[extensions_path, file], "%s/%s"%[_extensions_dir, file])
		if DirAccess.dir_exists_absolute(dependencies_path):
			for file in DirAccess.get_files_at(dependencies_path):
				if _features.has("ignore-%s"%file.get_basename()): continue
				for extension in _exported_extensions: if extension.get_file() == extension.get_file(): continue
				_exported_extensions.append(file)
				DirAccess.copy_absolute("%s/%s"%[dependencies_path, file], "%s/%s"%[_export_dir, file])
	if DirAccess.dir_exists_absolute(base_extensions_path):
		if DirAccess.get_files_at(base_extensions_path).size() > 0:
			if not DirAccess.dir_exists_absolute(_extensions_dir):
				DirAccess.make_dir_recursive_absolute(_extensions_dir)
		for file in DirAccess.get_files_at(base_extensions_path):
			if _features.has("ignore-%s"%file.get_basename()): continue
			for extension in _exported_extensions: if extension.get_file() == extension.get_file(): continue
			_exported_extensions.append(file)
			DirAccess.copy_absolute("%s/%s"%[base_extensions_path, file], "%s/%s"%[_extensions_dir, file])
	if DirAccess.dir_exists_absolute(base_dependencies_path):
		for file in DirAccess.get_files_at(base_dependencies_path):
			if _features.has("ignore-%s"%file.get_basename()): continue
			for extension in _exported_extensions: if extension.get_file() == extension.get_file(): continue
			_exported_extensions.append(file)
			DirAccess.copy_absolute("%s/%s"%[base_dependencies_path, file], "%s/%s"%[_export_dir, file])

func _export_expected_resources() -> void:
	var cfg := ConfigFile.new()
	for n in range(1,6):
		var pck_name: String = ModdableFrameworkExportSettings.get_setting("ExportOptions/Pack%sName"%n)
		if pck_name == "": continue
		cfg.set_value("packs", "%s.pck"%pck_name, 1)
	if _is_debug:
		cfg.set_value("packs", "debug.pck", 1)
	
	var extensions_path: String = "%s/"%ModdableFrameworkExportSettings.EDITOR_EXTENSIONS_DIR
	extensions_path = ProjectSettings.globalize_path(extensions_path)
	if _features.has("windows"):
		if _features.has("x86_32"):
			extensions_path = extensions_path + "win32"
		elif _features.has("x86_64"):
			extensions_path = extensions_path + "win64"
	elif _features.has("linux"):
		if _features.has("x86_32"):
			extensions_path = extensions_path + "linux32"
		elif _features.has("x86_64"):
			extensions_path = extensions_path + "linux64"
	if _is_debug:
		extensions_path = extensions_path + "/debug"
	else:
		extensions_path = extensions_path + "/release"
	var base_extensions_path := extensions_path
	for feature in _features:
		extensions_path = "%s/%s"%[base_extensions_path, feature]
		if DirAccess.dir_exists_absolute(extensions_path):
			for file in DirAccess.get_files_at(extensions_path):
				if _features.has("ignore-%s"%file.get_basename()): continue
				cfg.set_value("extensions", file, FileAccess.get_md5("%s/%s"%[extensions_path,file]))
	if DirAccess.dir_exists_absolute(base_extensions_path):
		for file in DirAccess.get_files_at(base_extensions_path):
			if _features.has("ignore-%s"%file.get_basename()): continue
			cfg.set_value("extensions", file, FileAccess.get_md5("%s/%s"%[base_extensions_path,file]))
	
	for key in _colored_folders_keys:
		if ModdableFrameworkExportSettings.get_setting("ExportOptions/DirColorAction%s"%_colored_folders[key].capitalize()) == ModdableFrameworkExportSettings.DirColorActions.EXPORT_UNPACKED:
			for file in get_all_file_paths(key):
				if file.get_extension() == "uid" or file.get_extension() == "import": continue
				if _dependency_files.has(file): continue
				cfg.set_value("raw", file.trim_prefix("res://"), FileAccess.get_md5(file))
	
	var tmp := FileAccess.create_temp(FileAccess.WRITE, "expected-resources", "cfg", false)
	tmp.close()
	cfg.save_encrypted_pass(tmp.get_path(), "v%s"%ProjectSettings.get_setting("application/config/version"))
	add_file("res://expected_resources.cfg", FileAccess.get_file_as_bytes(tmp.get_path()), false)

func _get_build_size() -> int:
	var size : int = 0
	for path in get_all_file_paths(_export_dir + '/'):
		size += FileAccess.get_file_as_bytes(path).size()
	return size
