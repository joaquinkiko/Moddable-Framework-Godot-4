@tool
extends EditorPlugin

var export_plugin: EditorExportPlugin = preload("res://addons/moddable_framework/export/export_manager.gd").new()

func _enter_tree() -> void:
	ModdableFrameworkLibrarySettings.add_all_settings()
	ProjectSettings.set_setting("application/run/main_loop_type", "ModdableFrameworkMainLoop")
	ModdableFrameworkExportSettings.add_all_settings()
	ModdableFrameworkMainLoopSettings.add_all_settings()
	ModdableFrameworkExportSettings.generate_default_files()
	ModdableFrameworkLibrarySettings.generate_default_files()
	add_export_plugin(export_plugin)

func _exit_tree() -> void:
	remove_export_plugin(export_plugin)

func _disable_plugin() -> void:
	ProjectSettings.set_setting("application/run/main_loop_type", "SceneTree")
	ModdableFrameworkExportSettings.remove_all_settings()
	ModdableFrameworkLibrarySettings.remove_all_settings()
	ModdableFrameworkMainLoopSettings.remove_all_settings()
