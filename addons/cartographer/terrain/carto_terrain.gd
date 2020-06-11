tool
extends MeshInstance
class_name CartoTerrain, "res://addons/cartographer/terrain_icon.svg"

export(float, 32, 1024, 32) var width: float = 256 setget _set_width
export(float, 32, 1024, 32) var depth: float = 256 setget _set_depth
export(float, 32, 1024, 32) var height: float = 64 setget _set_height
export(ImageTexture) var height_map: ImageTexture setget _set_height_map
export(Resource) var terrain_layers

var size: Vector3 = Vector3(256, 64, 256) setget _set_size
var sq_dim: float
var mesh_size: float
var terrain: MeshInstance = self
var bounds: CartoTerrainBounds
var mask_painter: TexturePainter setget , _get_mask_painter
var height_painter: TexturePainter setget , _get_height_painter
var _shader = preload("res://addons/cartographer/terrain/terrain.shader")
var brush: PaintBrush

func _set_width(w: float):
	width = w
	self.size = Vector3(w, size.y, size.z)

func _set_depth(d: float):
	depth = d
	self.size = Vector3(size.x, size.y, d)

func _set_height(h: float):
	height = h
	self.size = Vector3(size.x, h, size.z)

func _set_height_map(h: ImageTexture):
	height_map = h

func _set_size(s: Vector3):
	size = s
	sq_dim = max(s.x, s.z)
	bounds.reset(transform.origin - Vector3(size.x/2, 0, size.z/2), size)
	set_custom_aabb(bounds._aabb)
#	if terrain.mesh:
#		terrain.mesh.custom_aabb = bounds._aabb
#		terrain.mesh.size = Vector2(s.x, s.z)
	if terrain.mesh == null or sq_dim > mesh_size:
		print("PlaneMesh.new()")
		mesh_size = 256 if sq_dim <= 256 else 512 if sq_dim <= 512 else 1024
		var mesh = load("res://addons/cartographer/meshes/clipmap_%s.obj" % mesh_size)
		terrain.mesh = mesh
	if terrain.material_override:
		terrain.material_override.set_shader_param("terrain_size", size)
		terrain.material_override.set_shader_param("sq_dim", sq_dim)

func _get_mask_painter():
	if not mask_painter:
		if has_node("MaskPainter"):
			mask_painter = get_node("MaskPainter")
	return mask_painter

func _get_height_painter():
	if not height_painter:
		if has_node("HeightPainter"):
			height_painter = get_node("HeightPainter")
	return height_painter

func _init():
	bounds = CartoTerrainBounds.new(transform.origin - Vector3(size.x/2, 0, size.z/2), size)
	# A custom AABB is needed because vertices are offset by the GPU
	set_custom_aabb(bounds._aabb)
#	terrain_layers = CartoTerrainLayers.new()

func _enter_tree():
	if terrain_layers == null:
		terrain_layers = CartoTerrainLayers.new()
	terrain_layers.connect("changed", self, "_apply_terrain_layers")

	_init_mesh()
	_init_material()
	if Engine.is_editor_hint():
		_init_painters()

func _init_mesh():
	if terrain.mesh == null:
		_set_size(size)

func _init_material():
	if terrain.material_override == null:
		terrain.material_override = ShaderMaterial.new()
		terrain.material_override.shader = _shader
		_apply_terrain_layers()

func _apply_terrain_layers():
	prints("_apply_terrain_layers")
	terrain.material_override.set_shader_param("terrain_textures", terrain_layers.textures)
#	terrain.material_override.set_shader_param("terrain_masks", terrain_layers.masks)
	terrain.material_override.set_shader_param("use_triplanar", terrain_layers.use_triplanar)
	terrain.material_override.set_shader_param("uv1_scale", terrain_layers.uv1_scale)
#	if mask_painter:
#		mask_painter.texture = terrain_layers.masks

func _init_painters():
	_init_mask_painter()
	_init_height_painter()
	if terrain.material_override:
		terrain.material_override.set_shader_param("terrain_masks", mask_painter.get_texture())
		terrain.material_override.set_shader_param("terrain_height", height_painter.get_texture())

func _init_mask_painter():
	if not mask_painter:
		print("TexturePainter.new()")
		mask_painter = TexturePainter.new()
		mask_painter.name = "MaskPainter"
		terrain.add_child(mask_painter)
		mask_painter.texture = terrain_layers.masks

func _init_height_painter():
	if not height_painter:
		print("TexturePainter.new()")
		height_painter = TexturePainter.new()
#		height_painter.hdr = true
		height_painter.name = "HeightPainter"
		terrain.add_child(height_painter)
#		height_painter.texture = terrain_layers

func paint(action: int, pos: Vector2):
	height_painter.brush = brush
	mask_painter.brush = brush
	var on = action & Cartographer.Action.ON
	var just_changed = action & Cartographer.Action.JUST_CHANGED
	
	if not on and just_changed:
		var img = mask_painter.get_texture().get_data()
		terrain_layers.masks.create_from_image(img)
	
	if action & (Cartographer.Action.RAISE | Cartographer.Action.LOWER):
		height_painter.paint_height(action, pos)
	elif action & (Cartographer.Action.PAINT | Cartographer.Action.ERASE | Cartographer.Action.FILL):
		mask_painter.paint_masks(action, pos, terrain_layers.selected)

func intersect_ray(from: Vector3, dir: Vector3):
#	var hmap = ImageTexture.new()
#	var img = Image.new()
#	img.create(1024, 1024, Image.FORMAT_RGBA8, 0)
#	img.fill(Color(0, 0, 0, 1))
#	hmap.create_from_image(img)
	var hmap = height_painter.get_texture()
	from = transform.xform_inv(from)
	return bounds.intersect_ray(from, dir, hmap)
