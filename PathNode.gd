extends Node3D
class_name PathNode

var init_position
var root_node: Node3D = null
var connections: Array = []
var explored = 0
var dot_object

func _init(position: Vector3):
	init_position = position

func _ready():
	global_position = init_position
	root_node = get_tree().root.get_node("World")
	dot_object = root_node.create_dot(global_position, Color(0,0,1), "Paths")

func _to_string():
	return "PathNode" + str(global_position)

func connect_node(node: PathNode):
	connections.append(node)
	node.connections.append(self)
	root_node.draw_line(self.global_position, node.global_position)

func get_route(previous_node: PathNode, node: PathNode):
	var route = [self]
	if self == node:
		return route
	else:
		for con_node in connections:
			if con_node != previous_node:
				var child_route = con_node.get_route(self, node)
				if child_route != null:
					route.append_array(child_route)
	if node in route:
		return route
	else:
		return null

func mark_explored():
	dot_object.material.albedo_color = Color(1,1,0)
	explored = 1

func check_unexplored():
	for n in connections:
		if !n.explored:
			return n
	return null
