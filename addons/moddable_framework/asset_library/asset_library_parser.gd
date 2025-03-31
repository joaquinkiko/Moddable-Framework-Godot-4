class_name AssetLibraryParser
## Utility class to assist [AssetLibraryLoader] with parsing

## Searches a multi-layered [Dictionary] using [param keys] in order of layered keys.
## If cannot find key at any step, returns [param default]
static func recursive(dict: Dictionary, default: Variant, keys: Array):
	var final_key: Variant = keys[keys.size() - 1]
	var search_dict: Dictionary = dict.duplicate(true)
	for key in keys:
		if search_dict.has(key):
			if key == final_key:
				return search_dict[key]
			elif search_dict[key] is Dictionary:
				search_dict = search_dict[key].duplicate(true)
			else: return default
		else: return default

## Get all keys from top row of csv file
static func get_csv_keys(contents : String) -> PackedStringArray:
	var output : PackedStringArray = []
	output = contents.split('\n')[0].split(',')
	for n in output.size():
		output[n] = output[n].strip_edges()
	return output

## Returns a csv column in the form of keys:value combo where keys are column 1, and value is specified cloumn key
static func get_csv_dictionary_by_key(contents : String, key : String) -> Dictionary[String, String]:
	var output : Dictionary = {}
	var keys : PackedStringArray = get_csv_keys(contents)
	if not keys.has(key): return {}
	var key_index : int = keys.find(key)
	var first_line : bool = true
	for row in contents.split('\n'):
		if first_line: 
			first_line = false
			continue
		output[row.split(',')[0].strip_edges()] = row.split(',')[key_index % row.split(',').size()].strip_edges()
	return output

## Returns csv as dictionary of dictionarys similar to [get_csv_dictionary_by_key]
static func get_csv_data(contents : String) -> Dictionary[String, Dictionary]:
	var output: Dictionary = {}
	var first_key: bool = true
	for key in get_csv_keys(contents):
		if first_key:
			first_key = false
			continue
		output[key] = get_csv_dictionary_by_key(contents, key)
	return output
