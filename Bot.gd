extends CSGSphere3D

var initialized: bool = false

var root_node: Node3D = null

var m_scale: float = 0.05
var rotation_speed: float = 1
var starting_rotation

var bot_state: int #0 IDLE 1 INSPECT 2 EXPLORE
var paths: Array = []
var current_pathnode: PathNode
var movement_path
var move_target

func _ready():
	await get_tree().root.ready
	root_node = get_tree().root.get_node("World")
	print("Ready")
	initialized = true

	starting_rotation = rotation_degrees.y
	bot_state = 1
	var init_path_node = new_path_node(global_position)
	current_pathnode = init_path_node

func _physics_process(_delta):
	if initialized:
		if bot_state == 1:
			inspect()
		elif bot_state == 2:
			check_opening()
		elif bot_state == 3:
			move_by_path()
		elif bot_state == 4:
			move_to_goal()

func new_path_node(position: Vector3) -> PathNode:
	var path_node: PathNode = load("res://PathNode.gd").new(position)
	paths.append(path_node)
	root_node.find_child("PathTree").add_child(path_node)
	path_node._ready()
	if path_node != current_pathnode and current_pathnode != null:
		path_node.connect_node(current_pathnode)
	return path_node

func move_xyz(location):
	global_position = global_position.move_toward(location, (1*m_scale))
	focus_camera()
	return global_position.distance_to(location)

func inspect():
	if rotation_degrees.y < starting_rotation + 360:
		spin_observe()
	else:
		current_pathnode.mark_explored()
		rotation.y = -PI+rotation_speed
		find_opening()
		reset_inspection()
		bot_state = 2

func spin_observe():
	rotation_degrees.y += rotation_speed
	var Ray: RayCast3D = get_node("RayCast3D")
	if Ray.is_colliding():
		show_wall(Ray)
		place_dot(Ray)

func show_wall(Ray: RayCast3D):
	var collision_object: StaticBody3D = Ray.get_collider()
	var wall_box: CSGBox3D = collision_object.get_node("CSGBox3D")
	wall_box.transparency = 0
	if wall_box.get_parent().get_name() == "Goal":
		move_target = wall_box.global_position
		bot_state = 4

func place_dot(Ray: RayCast3D):
	var collision_point: Vector3 = Ray.get_collision_point()
	var too_close: bool = false
	var CollisionCheckGroup: Node3D = root_node.get_node("CollisionCheckGroup")
	for dot in CollisionCheckGroup.get_children():
		if dot.global_position.distance_to(collision_point) < 0.5:
			too_close = true
	if !too_close:
		root_node.create_dot(collision_point, Color(1, 0, 0), "CollisionCheckGroup")

func find_opening():
	var CollisionCheckGroup: Node3D = root_node.get_node("CollisionCheckGroup")
	var group_children = CollisionCheckGroup.get_children()
	for i in range(0, group_children.size()):
		var previous_child
		if i == 0:
			previous_child = group_children[group_children.size()-1]
		else:
			previous_child = group_children[i-1]
		var children_distance: float = group_children[i].global_position.distance_to(previous_child.global_position)
		if children_distance > 2:
			var potential_opening_position = (group_children[i].global_position + previous_child.global_position) / 2
			add_opening(potential_opening_position)

func add_opening(potential_opening_position):
	var too_close = false
	for path in paths:
		if potential_opening_position.distance_to(path["position"]) < 1.5:
			too_close = true
	if !too_close:
		new_path_node(potential_opening_position)

func reset_inspection():
	var CollisionCheckGroup: Node3D = root_node.get_node("CollisionCheckGroup")
	for dot in CollisionCheckGroup.get_children():
		CollisionCheckGroup.remove_child(dot)
		dot.queue_free()

func check_opening():
	for path_node in paths:
		if path_node.explored == 0:
			movement_path = current_pathnode.get_route(current_pathnode, path_node)
			print(movement_path)
			bot_state = 3
			break

func move_by_path():
	if movement_path.size() != 0:
		var target_node = movement_path[0]
		if move_target == null:
			move_target = target_node.global_position
		else:
			var distance_to_target = move_xyz(move_target)
			
			var dir_vec = global_position.direction_to(move_target)
			var dir = Vector3(0.5, 0, 0.8)
			var axis = Vector3(0,0,1)
			var angle = axis.angle_to(dir_vec)
			rotation.y = angle
			
			if distance_to_target < 0.1:
				global_position = move_target
				current_pathnode = target_node
				move_target = null
				movement_path.erase(target_node)
	else:
		starting_rotation = rotation_degrees.y
		bot_state = 1
		
func focus_camera():
	root_node.get_node("WorldCamera").global_position.x = global_position.x
	root_node.get_node("WorldCamera").global_position.z = global_position.z

func move_to_goal():
	if move_xyz(move_target) < 0.1:
		var popup = AcceptDialog.new()
		root_node.add_child(popup)
		popup.dialog_text = "Complete"
		popup.show()
		get_tree().paused = true
