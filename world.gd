extends Node3D

func _ready():
	print("Ready world")

func draw_line(pos1: Vector3, pos2: Vector3):
	var mesh_instance = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	var mesh_material = StandardMaterial3D.new()
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = false
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, mesh_material)
	immediate_mesh.surface_add_vertex(pos1)
	immediate_mesh.surface_add_vertex(pos2)
	immediate_mesh.surface_end()
	mesh_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_material.albedo_color = Color(0,0,1)
	add_child(mesh_instance)

func create_dot(position: Vector3, color: Color, group: String) -> Node3D:
	var new_dot: CSGSphere3D = CSGSphere3D.new()
	new_dot.set_material(StandardMaterial3D.new())
	new_dot.material.albedo_color = color
	new_dot.radius = 0.1
	var Group: Node3D = get_node(group)
	Group.add_child(new_dot)
	new_dot.global_position = position
	return new_dot
