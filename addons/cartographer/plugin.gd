tool
extends EditorPlugin

var dock
var editor = get_editor_interface()
var terrain: CartoTerrain
var brush: CartoBrush
var do_paint: bool = false

func _enter_tree():
	dock = preload("res://addons/cartographer/cartographer.tscn").instance()
	#add_control_to_dock(DOCK_SLOT_LEFT_UL, dock)
	#add_control_to_bottom_panel(dock, "Cartographer")
	#dock.hide()
	#editor.get_selection().connect("selection_changed", self, "_on_selection_changed", [dock])

func _on_selection_changed(dock):
	var selected = editor.get_selection().get_selected_nodes()
	
	if len(selected) == 1:
		var node = selected[0]
		if node.get("isCartoTerrain"):
#			make_bottom_panel_item_visible(dock)
			node.update_layer_data()
#		elif node.get("isCartoLayer"):
#			make_bottom_panel_item_visible(dock)
		else:
			hide_bottom_panel()
		

func _exit_tree():
	#remove_control_from_docks(dock)
	#remove_control_from_bottom_panel(dock)
	dock.free()

func handles(obj: Object):
	if obj is CartoBrush or obj is CartoTerrain:
		return true
	return false

func get_terrain_from(obj: Object):
	if obj is CartoBrush:
		obj = obj.get_parent()
	if obj is CartoTerrain:
		return obj
	return null

func get_brush_from(obj: Object):
	if obj is CartoBrush:
		return obj
	return null

func edit(obj: Object):
	terrain = get_terrain_from(obj)
	brush = get_brush_from(obj)

func make_visible(visible):
	if not visible:
		edit(null)

func forward_spatial_gui_input(camera, event):
	if terrain == null:
		return false
	var capture_event = false
	
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT \
	and not event.control and not event.alt:
		capture_event = true
		do_paint = event.pressed
	elif event is InputEventMouseMotion and do_paint:
		capture_event = true
		var viewport = camera.get_viewport()
		var viewport_container = viewport.get_parent()
		var screen_pos = viewport.get_mouse_position() * viewport.size / viewport_container.rect_size
		#var screen_pos = event.position * viewport.size / viewport_container.rect_size
		
		var org = camera.project_ray_origin(screen_pos)
		var dir = camera.project_ray_normal(screen_pos)
		var pos = camera.project_position(screen_pos, 100)
		var aabb = terrain.get_aabb()
		
		var i = 0
		while i < 800:
			i += 1
			print(i)
			pos = camera.project_position(screen_pos, i)
			if pos.x >= aabb.position.x and pos.x <= aabb.end.x and pos.z >= aabb.position.z and pos.z <= aabb.end.z \
			and pos.y < 0:
				print("INSIDE", pos)
				break
		
		var tex_pos = (aabb.size/2 + pos) * 512/20
		tex_pos = Vector3(tex_pos.x, tex_pos.z, 0)
		print(tex_pos)
		terrain.material.set_shader_param("brush_tip", tex_pos)
			
	
	return capture_event