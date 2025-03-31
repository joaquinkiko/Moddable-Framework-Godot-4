class_name ModdableFrameworkRuntimeAuthentication
## Utility class for generating/comparing a unique [PackedByteArray] representing
## all currently loaded assets, packs, and extensions. This can
## be used for multiplayer authentication to ensure all peers are running similar clients.

## Generate unique [PackedByteArray] representing loaded [AssetLibrary] assets,
## loaded resource packs, dlc packs, extensions, and core executable
static func get_runtime_md5() -> PackedByteArray:
	var output := PackedByteArray([])
	output.append_array(Engine.get_main_loop().get_md5_bootup_pack())
	output.append_array(Engine.get_main_loop().get_md5_loaded_packs())
	output.append_array(Engine.get_main_loop().get_md5_loaded_dlc_packs())
	output.append_array(Engine.get_main_loop().get_md5_loaded_patches_packs())
	output.append_array(Engine.get_main_loop().get_md5_loaded_extensions())
	output.append_array(AssetLibrary.get_md5s_of_all_libraries())
	return output

## Takes a peer's [PackedByteArray] generated with [method get_runtime_md5] and
## compares against our own generated [PackedByteArray] from [method get_runtime_md5]
static func is_peer_runtime_md5_matched(peer_md5: PackedByteArray) -> bool:
	return peer_md5 == get_runtime_md5()
