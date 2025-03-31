class_name AssetLibraryLoader

## Loads [Texture2D]
static func load_texture(index: StringName, key: String, mipmaps := true) -> Texture2D:
	var path := AssetLibrary.get_asset_path(index, key) as String
	if path.is_empty(): return PlaceholderTexture2D.new()
	if AssetLibrary.is_asset_internal(index, key):
		return ResourceLoader.load(path, "Texture2D")
	else:
		var image := Image.load_from_file(path)
		if image == null: return PlaceholderTexture2D.new()
		if mipmaps and not image.has_mipmaps(): image.generate_mipmaps()
		return ImageTexture.create_from_image(image)

## Loads an [AtlasTexture]
static func load_texture_atlas(index: StringName, key: String, region: Rect2, mipmaps := true) -> AtlasTexture:
	var path := AssetLibrary.get_asset_path(index, key) as String
	if path.is_empty(): 
		return AtlasTexture.new()
	if AssetLibrary.is_asset_internal(index, key):
		return ResourceLoader.load(path, "Texture2D")
	else:
		var image := Image.load_from_file(path)
		if image == null: return AtlasTexture.new()
		if mipmaps and not image.has_mipmaps(): image.generate_mipmaps()
		var atlas := AtlasTexture.new()
		atlas.atlas = ImageTexture.create_from_image(image)
		atlas.region = region
		return atlas

## Loads an array from a [AtlasTexture]
static func load_texture_array(index: StringName, key: String, size: Vector2i, start := 0, end := (1 << 32) - 1, mipmaps := true) -> Array[Texture2D]:
	var path := AssetLibrary.get_asset_path(index, key) as String
	if path.is_empty(): return [PlaceholderTexture2D.new()]
	size = size.clamp(Vector2i.ONE, Vector2i.ONE * ((1 << 32) - 1))
	var source := load_texture(index, key)
	var region_size := Vector2i(
		floori(float(source.get_width()) / size.x),
		floori(float(source.get_height()) / size.y)
	)
	var textures: Array[Texture2D] = []
	var position: int = -1
	for y in size.y: for x in size.x:
		position += 1
		if position < start: continue
		if position > end: break
		var rect := Rect2()
		rect.position.x = x * region_size.x
		rect.position.y = y * region_size.y
		rect.end.x = (x + 1) * region_size.x
		rect.end.y = (y + 1) * region_size.y
		textures.append(load_texture_atlas(index, key, rect, mipmaps))
	return textures

## Loads [StyleBoxTexture]
static func load_stylebox_texture(index: StringName, key: String, margins: int = 0) -> StyleBoxTexture:
	var path := AssetLibrary.get_asset_path(index, key) as String
	if path.is_empty(): return StyleBoxTexture.new()
	var stylebox := StyleBoxTexture.new()
	stylebox.texture = load_texture(index, key, false)
	if margins > 0:
		stylebox.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		stylebox.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		stylebox.set_texture_margin_all(margins)
	else:
		stylebox.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		stylebox.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return stylebox

## Loads [AudioStream]. Supports OGG, MP3, and WAV
static func load_audio(index: StringName, key: String, loop: bool = false) -> AudioStream:
	var path := AssetLibrary.get_asset_path(index, key) as String
	if path.is_empty(): return AudioStream.new()
	if AssetLibrary.is_asset_internal(index, key):
		var stream: AudioStream = ResourceLoader.load(path)
		if stream is AudioStreamOggVorbis:
			stream.loop = loop
		elif stream is AudioStreamWAV:
			if loop: stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			else: stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
		elif stream is AudioStreamMP3:
			stream.loop = loop
		return stream
	else:
		if path.get_extension() == "ogg":
			var stream := AudioStreamOggVorbis.load_from_file(path)
			stream.loop = loop
			return stream
		elif path.get_extension() == "wav":
			var stream := AudioStreamWAV.load_from_file(path)
			if loop: stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			else: stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
			return stream
		elif path.get_extension() == "mp3":
			var stream := AudioStreamMP3.load_from_file(path)
			stream.loop = loop
			return stream
		else: return AudioStream.new()

## Load [FontFile]
static func load_font(index: StringName, key: String) -> FontFile:
	var path := AssetLibrary.get_asset_path(index, key) as String
	if path.is_empty(): return FontFile.new()
	if AssetLibrary.is_asset_internal(index, key):
		return ResourceLoader.load(path, "FontFile")
	else: 
		var font : FontFile = FontFile.new()
		if path.ends_with('.ttf') or path.ends_with('.ttc') or path.ends_with('.otf') or path.ends_with('.otc'):
			if font.load_dynamic_font(path) == OK:
				return font
			else: return FontFile.new()
		elif path.ends_with('.woff') or path.ends_with('.woff2') or path.ends_with('.pfb') or path.ends_with('.pfm'):
			if font.load_dynamic_font(path) == OK:
				return font
			else: return FontFile.new()
		elif path.ends_with('.fnt') or path.ends_with('.font'):
			if font.load_bitmap_font(path) == OK:
				return font
			else: return FontFile.new()
		else: return FontFile.new()

## Load CSV as [Translation][Array]
static func load_translations(index: StringName, key: String) -> Array[Translation]:
	var path := AssetLibrary.get_asset_path(index, key) as String
	if path.is_empty(): return []
	if path.get_extension() == "csv":
		var data := AssetLibraryParser.get_csv_data(FileAccess.get_file_as_string(path))
		var _translations : Array[Translation] = []
		_translations.resize(data.keys().size())
		for n in _translations.size():
			_translations[n] = Translation.new()
			_translations[n].locale = data.keys()[n]
			for message_key: String in data[data.keys()[n]].keys():
				_translations[n].add_message(message_key, data[_translations[n].locale][message_key])
		return _translations
	elif path.get_extension() == "tres" or path.get_extension() == "res":
		if not is_resource_safe(index, key): return []
		var resource = ResourceLoader.load(path)
		if resource is Translation: return [resource]
		else: return []
	else: return []

## Load [Shader]
static func load_shader(index: StringName, key: String) -> Shader:
	var path := AssetLibrary.get_asset_path(index, key) as String
	if path.is_empty(): return Shader.new()
	if AssetLibrary.is_asset_internal(index, key):
		return ResourceLoader.load(path, "Shader")
	else:
		var shader : Shader = Shader.new()
		shader.code = FileAccess.get_file_as_string(path)
		return shader

## Load [ShaderMaterial] from [Shader] or resource
static func load_shader_material(index: StringName, key: String, properties: Dictionary[StringName, Variant] = {}) -> ShaderMaterial:
	var path := AssetLibrary.get_asset_path(index, key) as String
	if path.is_empty(): return ShaderMaterial.new()
	if path.get_extension() == "tres" or path.get_extension() == "res":
		if not is_resource_safe(index, key): return ShaderMaterial.new()
		var material = ResourceLoader.load(path)
		if not (material is ShaderMaterial or material is VisualShader): 
			return ShaderMaterial.new()
		return material
	else:
		var material := ShaderMaterial.new()
		material.shader = load_shader(index, key)
		for property in properties.keys():
			material.set_shader_parameter(property, properties[property])
		return material

## Load [Dictionary] from CFG or JSON
static func load_data_set(index: StringName, key: String) -> Dictionary[StringName, Variant]:
	var path := AssetLibrary.get_asset_path(index, key) as String
	if path.is_empty(): return {}
	if path.get_extension() == "cfg" or path.get_extension() == "ini":
		var config : ConfigFile = ConfigFile.new()
		config.load(path)
		var output : Dictionary[StringName, Variant] = {}
		for section in config.get_sections():
			output[section] = {}
			for config_key in config.get_section_keys(section):
				output[section][config_key] = config.get_value(section, config_key, null)
		return output
	elif path.get_extension() == "json":
		var json: JSON = JSON.new()
		if json.parse(FileAccess.get_file_as_string(path)) == OK:
			return json.data
		else: return {}
	elif path.get_extension() == "csv":
		var output: Dictionary = AssetLibraryParser.get_csv_data(load_file_string(index, key))
		return output
	else: return {}

## Load GLTF, GLB, or FBX as [Node3D]
static func load_model(index: StringName, key: String, textures: Array[Texture2D] = [], anim_fps: float = 30) -> Node3D:
	var path := AssetLibrary.get_asset_path(index, key) as String
	if path.is_empty(): return Node3D.new()
	if path.get_extension() == "gltf" or path.get_extension() == "glb":
		var gltf_doc := GLTFDocument.new()
		var gltf_state := GLTFState.new()
		if textures.size() > 0:
			gltf_state.set_images(textures)
		if gltf_doc.append_from_file(path, gltf_state) == OK:
			var output: Node3D = gltf_doc.generate_scene(gltf_state, anim_fps)
			return output
		else: return Node3D.new()
	elif path.get_extension() == "fbx":
		var fbx_doc := FBXDocument.new()
		var fbx_state := FBXState.new()
		if textures.size() > 0:
			fbx_state.set_images(textures)
		if fbx_doc.append_from_file(path, fbx_state) == OK:
			var output: Node3D = fbx_doc.generate_scene(fbx_state, anim_fps)
			return output
		else: return Node3D.new()
	#elif path.get_extension() == "obj":
	#	var node := MeshInstance3D.new()
	#	node.mesh = ObjParse.load_obj(path)
	#	return node
	else: return Node3D.new()

## Load only [Animation] resources from GLTF or GLB into an [AnimationLibrary].
static func load_animation_library(index: StringName, key: String, anim_fps: float = 30) -> AnimationLibrary:
	var path := AssetLibrary.get_asset_path(index, key) as String
	if path.is_empty(): return AnimationLibrary.new()
	if path.get_extension() == "gltf" or path.get_extension() == "glb":
		var gltf_doc := GLTFDocument.new()
		var gltf_state := GLTFState.new()
		if gltf_doc.append_from_file(path, gltf_state) == OK:
			var library := AnimationLibrary.new()
			var new_scene := gltf_doc.generate_scene(gltf_state, anim_fps)
			var animation_player : AnimationPlayer
			for node in new_scene.get_children():
				if node is AnimationPlayer:
					animation_player = node
					break
			if animation_player != null:
				for animation : String in animation_player.get_animation_list():
					library.add_animation(animation, animation_player.get_animation(animation))
			new_scene.queue_free()
			return library
		else: return AnimationLibrary.new()
	elif path.get_extension() == "fbx":
		var fbx_doc := FBXDocument.new()
		var fbx_state := FBXState.new()
		if fbx_doc.append_from_file(path, fbx_state) == OK:
			var library := AnimationLibrary.new()
			var new_scene := fbx_doc.generate_scene(fbx_state, anim_fps)
			var animation_player : AnimationPlayer
			for node in new_scene.get_children():
				if node is AnimationPlayer:
					animation_player = node
					break
			if animation_player != null:
				for animation : String in animation_player.get_animation_list():
					library.add_animation(animation, animation_player.get_animation(animation))
			new_scene.queue_free()
			return library
		else: return AnimationLibrary.new()
	else: return AnimationLibrary.new()

## Loads [Material] from [Shader] or resource
static func load_material(index: StringName, key: String, properties: Dictionary[StringName, Variant] = {}) -> Material:
	var path := AssetLibrary.get_asset_path(index, key) as String
	if path.is_empty(): return PlaceholderMaterial.new()
	if path.get_extension() == "tres" or path.get_extension() == "res":
		if not is_resource_safe(index, key): return PlaceholderMaterial.new()
		var material = ResourceLoader.load(path)
		if not material is Material: return PlaceholderMaterial.new()
		if material is ShaderMaterial:
			for property in properties:
				material.set_shader_parameter(property, properties[property])
		else:
			for property in properties:
				material.set(property, properties[property])
		return material
	else: 
		return load_shader_material(index, key, properties)

## Loads TRES, without knowing resource type
static func load_resource(index: StringName, key: String) -> Variant:
	var path := AssetLibrary.get_asset_path(index, key) as String
	if path.is_empty(): return PlaceholderMaterial.new()
	if not (path.get_extension() == "tres" or path.get_extension() == "res"): return null
	if not is_resource_safe(index, key): return null
	return ResourceLoader.load(path)

## Loads [PackedScene]
static func load_packed_scene(index: StringName, key: String) -> PackedScene:
	var path := AssetLibrary.get_asset_path(index, key) as String
	if path.is_empty(): return PackedScene.new()
	return ResourceLoader.load(path, "PackedScene")

## Loads [PanoramaSkyMaterial] from a texture
static func load_panorama_sky(index: StringName, key: String) -> PanoramaSkyMaterial:
	var sky := PanoramaSkyMaterial.new()
	sky.panorama = load_texture(index, key, false)
	return sky

## Loads a OGV [VideoStream]
static func load_video_stream(index: StringName, key: String) -> VideoStream:
	var path := AssetLibrary.get_asset_path(index, key) as String
	if path.is_empty(): return VideoStream.new()
	if AssetLibrary.is_asset_internal(index, key):
		return ResourceLoader.load(path, "VideoStream")
	elif path.get_extension() == "ogv":
		var video_stream := VideoStream.new()
		video_stream.file = path
		return video_stream
	else: return VideoStream.new()

## Loads asset as file bytes
static func load_file_bytes(index: StringName, key: String) -> PackedByteArray:
	var path := AssetLibrary.get_asset_path(index, key) as String
	if path.is_empty(): return []
	return FileAccess.get_file_as_bytes(path)

## Loads asset as file string
static func load_file_string(index: StringName, key: String) -> String:
	var path := AssetLibrary.get_asset_path(index, key) as String
	if path.is_empty(): return ""
	return FileAccess.get_file_as_string(path)

## Returns false if TRES resource has potentially malicous script contained in it.
## Always returns true of internal assets, regardless of contents.
static func is_resource_safe(index: StringName, key: String) -> bool:
	if AssetLibrary.is_asset_internal(index, key): return true
	var path := AssetLibrary.get_asset_path(index, key) as String
	if path.is_empty(): return true
	if path.get_extension() == "tres" or path.get_extension() == "res" or path.get_extension() == "theme":
		var contents := FileAccess.get_file_as_string(path)
		var regex := RegEx.new()
		regex.compile("type\\s*=\\s*\"GDScript\"\\s*")
		if regex.search(contents) != null:
			push_warning("Resource contains inline GDScript making it potentially malicous: %s"% AssetLibrary.get_asset_path(index,key))
			return false
		var extResourceRegex := RegEx.new()
		extResourceRegex.compile("\\[\\s*ext_resource\\s*.*?path\\s*=\\s*\"([^\"]*)\".*?\\]")
		var matches := extResourceRegex.search_all(contents)
		for match in matches:
			if not match.get_string(1).begins_with("res://"):
				push_warning("Resource contains exterior resource outside of res://, and cannot be verified as safe: %s"% AssetLibrary.get_asset_path(index,key))
				return false
	return true

## Loads [Theme] from resource, or from parsing CFG file, sorted as follows:
## [br][br]
## [ TYPE.NAME ]
## [br] THEME_TYPE=VALUE 
## [br]or for Font and Icon:[br] THEME_TYPE=ASSET_INDEX.ASSET_KEY
## [br]or for Stylebox:[br] THEME_TYPE=ASSET_INDEX.ASSET_KEY.MARGIN
## [br][br]
## Where type is color, constant, font, font_size (or fontSize), icon, or stylebox (or style).
static func load_theme(index: StringName, key: String) -> Theme:
	var path := AssetLibrary.get_asset_path(index, key) as String
	if path.is_empty(): return ThemeDB.get_project_theme()
	if path.get_extension() == "tres" or path.get_extension() == "res" or path.get_extension() == "theme":
		if not is_resource_safe(index, key): return ThemeDB.get_project_theme()
		var material = ResourceLoader.load(path)
		if not material is Theme: return ThemeDB.get_project_theme()
		return material
	elif path.get_extension() == "cfg":
		var data := ConfigFile.new()
		if data.load(path) != OK: return ThemeDB.get_project_theme()
		var theme := Theme.new()
		for section in data.get_sections(): for _key in data.get_section_keys(section):
			var section_data := section.split(".")
			if section_data.size() == 1: continue
			match section_data[0].to_lower():
				"color":
					theme.set_color(section[1], _key, data.get_value(section, key) as Color)
				"constant":
					theme.set_constant(section[1], _key, data.get_value(section, key) as int)
				"font":
					var key_data := (data.get_value(section, key) as String).split(".")
					if key_data.size() == 1: continue
					theme.set_font(section[1], _key, load_font(key_data[0], key_data[1]))
				"font_size":
					theme.set_font_size(section[1], _key, data.get_value(section, key) as int)
				"fontsize":
					theme.set_font_size(section[1], _key, data.get_value(section, key) as int)
				"icon":
					var key_data := (data.get_value(section, key) as String).split(".")
					if key_data.size() == 1: continue
					theme.set_icon(section[1], _key, load_texture(key_data[0], key_data[1], false))
				"stylebox":
					var key_data := (data.get_value(section, key) as String).split(".")
					if key_data.size() < 3: continue
					theme.set_stylebox(section[1], _key, load_stylebox_texture(key_data[0], key_data[1], key_data[2].to_int()))
				"style":
					var key_data := (data.get_value(section, key) as String).split(".")
					if key_data.size() < 3: continue
					theme.set_stylebox(section[1], _key, load_stylebox_texture(key_data[0], key_data[1], key_data[2].to_int()))
		return theme
	else: return ThemeDB.get_project_theme()

## Loads [Environment] from a resource, using the Project Setting 
## ("rendering/environment/defaults/default_environment") as fallback if error occurs
static func load_enviroment(index: StringName, key: String) -> Environment:
	var path := AssetLibrary.get_asset_path(index, key) as String
	if path.is_empty(): 
		if ProjectSettings.get_setting("rendering/environment/defaults/default_environment") != "":
			return ProjectSettings.get_setting("rendering/environment/defaults/default_environment")
		else: return Environment.new()
	if path.get_extension() == "tres" or path.get_extension() == "res":
		if not is_resource_safe(index, key): 
			if ProjectSettings.get_setting("rendering/environment/defaults/default_environment") != "":
				return ProjectSettings.get_setting("rendering/environment/defaults/default_environment")
			else: return Environment.new()
		var enviroment = ResourceLoader.load(path)
		if not enviroment is Environment: 
			if ProjectSettings.get_setting("rendering/environment/defaults/default_environment") != "":
				return ProjectSettings.get_setting("rendering/environment/defaults/default_environment")
			else: return Environment.new()
		return enviroment
	elif ProjectSettings.get_setting("rendering/environment/defaults/default_environment") != "":
		return ProjectSettings.get_setting("rendering/environment/defaults/default_environment")
	else: return Environment.new()
