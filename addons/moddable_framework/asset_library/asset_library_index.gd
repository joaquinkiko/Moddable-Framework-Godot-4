class_name AssetLibraryIndex extends Resource
## Stores a collection of asset paths

## Library's unique identifier
@export var index_name: StringName = "assets"
## Internal Directory path to load assets from
@export_dir var asset_dir: String = "res://"
## Will only add matching file extensions
@export var valid_extensions: PackedStringArray
## Directories to exclude from [member asset_dir]
@export var excluded_dirs: PackedStringArray
## If false, will only load internal assets, and no mod assets or executable directory assets
@export var allow_mod_assets: bool = true
## If false, [method get_asset_collection_md5] will return an empty array
@export var allow_unique_md5: bool = true
## If true, when searching asset by key, will check if asset with KEY_LOCALE exists--
## example: asset.key will check if asset.key_en exists, and return that instead if it does.
@export var check_for_locale_variants: bool = true

## Assets stored by [method path_to_id]:UID
var assets: Dictionary[int, int] = {}
var _temp_uids: PackedInt32Array = []

func _to_string() -> String: return "Library(%s)"%index_name

## Clears all [member assets] and unregisters any temporary UIDs
func clear_assets() -> void:
	assets.clear()
	for uid in _temp_uids:
		if ResourceUID.has_id(uid): ResourceUID.remove_id(uid)
	_temp_uids.clear()

## Add asset from [param path] which must be in [param source_dir]. May generate temporary UID for asset.
func add_asset(path: String, source_dir: String) -> void:
	assert(valid_extensions.has(path.get_extension()), "Invalid asset type for '%s': %s"%[self, path])
	assert(path.begins_with(source_dir), "Mismatched source directory '%s': %s"%[source_dir, path])
	var uid: int = -1
	if ResourceLoader.exists(path) and ResourceLoader.get_resource_uid(path) != -1:
		uid = ResourceLoader.get_resource_uid(path)
	else:
		uid = ResourceUID.create_id()
		ResourceUID.add_id(uid, path)
		_temp_uids.append(uid)
	assets[path_to_id(path, source_dir)] = uid

## Add all assets from [member asset_dir]
func add_all_from_dir() -> void:
	for file in _get_files_recursively(asset_dir):
		file = file.trim_suffix(".import")
		if not valid_extensions.has(file.get_extension()): continue
		add_asset(file, asset_dir)

## Add all assets from game's executable directory (Windows and Linux builds only)
func add_all_from_executable_dir() -> void:
	if not allow_mod_assets: return
	if OS.has_feature("editor"): return
	if not (OS.has_feature("windows") or OS.has_feature("linux")): return
	var expected_cfg: ConfigFile = Engine.get_main_loop().get_expected_resources_cfg()
	var path: String = OS.get_executable_path().get_base_dir() + "/%s"%asset_dir.trim_prefix("res://")
	for file in _get_files_recursively(path):
		if not valid_extensions.has(file.get_extension()): continue
		if not OS.has_feature("editor"):
			if expected_cfg.has_section("raw"):
				if not expected_cfg.get_section_keys("raw").has(file.trim_prefix(OS.get_executable_path().get_base_dir() + "/")):
					if not Engine.get_main_loop().third_party_extensions.has(file.get_extension()):
						Engine.get_main_loop().third_party_extensions.append(file.get_extension())
				elif not expected_cfg.get_value("raw", file.trim_prefix(OS.get_executable_path().get_base_dir() + "/")) == FileAccess.get_md5(file):
					if not Engine.get_main_loop().third_party_extensions.has(file.get_extension()):
						Engine.get_main_loop().third_party_extensions.append(file.get_extension())
			else:
				if not Engine.get_main_loop().third_party_extensions.has(file.get_extension()):
					Engine.get_main_loop().third_party_extensions.append(file.get_extension())
		add_asset(file, path)

## Add all assets from specified external directory (such as a mod)
func add_all_from_mod_dir(dir_path: String) -> void:
	if not allow_mod_assets: return
	assert(DirAccess.dir_exists_absolute(dir_path), "Mod directory doesn't exist to load assets: %s"%dir_path)
	dir_path += "/%s"%asset_dir.trim_prefix("res://")
	if not DirAccess.dir_exists_absolute(dir_path): return
	for file in _get_files_recursively(dir_path):
		if not valid_extensions.has(file.get_extension()): continue
		add_asset(file, dir_path)

## Recursively searches for files in a directory, skipping [member excluded_dirs]
func _get_files_recursively(dir: String) -> PackedStringArray:
	var output := PackedStringArray()
	if not DirAccess.dir_exists_absolute(dir): return []
	for sub_dir in DirAccess.get_directories_at(dir):
		if excluded_dirs.has(dir): continue
		output.append_array(_get_files_recursively("%s/%s"%[dir, sub_dir]))
	for file in DirAccess.get_files_at(dir):
		if file.begins_with("_"): continue
		output.append("%s/%s"%[dir,file])
	return output

## Converts asset path to lookup key
static func path_to_key(path: String, source_dir: String) -> StringName:
	path = path.trim_prefix(source_dir)
	path = path.trim_suffix(".%s"%path.get_extension())
	path = path.lstrip("/").rstrip("/")
	path = path.replace("/", ".")
	path = path.replace(" ", "_")
	return path

## Converts lookup key to unique index id
static func key_to_id(key: String) -> int:
	key = key.to_lower()
	var ui64 := PackedByteArray()
	ui64.resize(8)
	ui64.encode_u32(0, key.hash())
	key.reverse()
	ui64.encode_u32(4, key.hash())
	return ui64.decode_u64(0)

## Converts asset path to unique index id
static func path_to_id(path: String, source_dir: String) -> int:
	return key_to_id(path_to_key(path, source_dir))

## Gets path of an asset via lookup key. Returns empty if asset doesn't exist
func get_asset_path(key: String) -> String:
	if check_for_locale_variants and has_asset("%s_%s"%[key, TranslationServer.get_locale()]):
		key = "%s_%s"%[key, TranslationServer.get_locale()]
	var id := key_to_id(key)
	if not assets.has(id): 
		push_warning("Attempted to get non-existent asset from %s: %s"%[self, key])
		return ""
	assert(ResourceUID.has_id(assets[id]), "Unregistered asset UID: %s"%key)
	return ResourceUID.get_id_path(assets[id])

## Gets path of an asset via unique index id. Returns empty if it doesn't exist.
func get_asset_path_by_id(id: int) -> String:
	if not assets.has(id): 
		push_warning("Attempted to get non-existent asset from %s: id #%s"%[self, id])
		return ""
	assert(ResourceUID.has_id(assets[id]), "Unregistered asset UID: id #%s"%id)
	return ResourceUID.get_id_path(assets[id])

## Returns true if asset's path begins with "res://"
func is_asset_internal(key: String) -> bool:
	return get_asset_path(key).begins_with("res://") or get_asset_path(key).begins_with("uid://")

## Returns true if asset exists. Use [param check_locale_variant] to check both exact match and locale match.
func has_asset(key: String, check_locale_variant := true) -> bool:
	if check_locale_variant and has_asset("%s_%s"%[key, TranslationServer.get_locale()], false):
		return true
	var id := key_to_id(key)
	return assets.has(id)

## Returns all paths inside of library
func get_all_paths() -> PackedStringArray:
	var output := PackedStringArray()
	for uid in assets.values():
		output.append(ResourceUID.get_id_path(uid))
	return output

## Returns md5 of all asset paths. Useful for multiplayer, ensuring clients are running same libraries.
func get_asset_collection_md5() -> PackedByteArray:
	if not allow_unique_md5: return []
	var md5s: String = "0"
	for path in get_all_paths(): if FileAccess.file_exists(path):
		md5s = md5s + FileAccess.get_md5(path)
	return md5s.md5_buffer()

## Returns all keys inside library. Note: This is potentially slow-- don't call unless needed.
func get_all_keys(mod_dirs: PackedStringArray = []) -> PackedStringArray:
	var output := PackedStringArray()
	for file in _get_files_recursively(asset_dir):
		file = file.trim_suffix(".import")
		if not valid_extensions.has(file.get_extension()): continue
		output.append(path_to_key(file, asset_dir))
	if not OS.has_feature("editor") and (OS.has_feature("windows") or OS.has_feature("linux")):
		var path: String = OS.get_executable_path().get_base_dir() + "/%s"%asset_dir.trim_prefix("res://")
		for file in _get_files_recursively(path):
			if not valid_extensions.has(file.get_extension()): continue
			output.append(path_to_key(file, path))
	for mod_dir in mod_dirs:
		var path: String = "%s/%s"%[mod_dir, asset_dir.trim_prefix("res://")]
		for file in _get_files_recursively(path):
			if not valid_extensions.has(file.get_extension()): continue
			output.append(path_to_key(file, path))
	return output
