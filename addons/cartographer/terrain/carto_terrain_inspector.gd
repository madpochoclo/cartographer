extends EditorInspectorPlugin
class_name CartoTerrainInspector

# const LayersEditor = preload("res://addons/cartographer/terrain/carto_terrain_material_editor/layers_editor.gd")
const MultiTextureEditor = preload("res://addons/cartographer/terrain/carto_multi_texture_editor/editor.gd")
const skip_props = ["selected", "use_triplanar", "shader"]

func can_handle(object):
	return object is CartoMultiTexture

func parse_property(object, type, path, hint, hint_text, usage):
#	prints(path, object, object.get(path), type, hint, hint_text, usage)
	if object == null:
		return false
	
	if object is CartoMultiTexture and path == "flags":
		var mted = MultiTextureEditor.new()
		add_property_editor_for_multiple_properties("Layers", PoolStringArray(["data"]), mted)
	elif path in skip_props:
		return true
	
	# TODO: Cache the editor
