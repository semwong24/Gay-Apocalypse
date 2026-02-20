@tool
extends Area3D
# THIS SHIZ DOES NOT WORK DONT USE IT UGH
func _ready():
	print("Script ready")

# This creates a button in the Inspector
func _get_tool_buttons():
	return [{
		"name": "Combine Collisions",
		"icon": preload("res://icon.svg"),
		"callback": combine_collision_shapes
	}]

func combine_collision_shapes():
	print("Starting combine function")
	var collision_shapes = []
	
	print("Area: ", self)
	print("Children: ", get_children())
	
	for child in get_children():
		print("Checking child: ", child, " Type: ", child.get_class())
		if child is CollisionShape3D:
			collision_shapes.append(child)
			print("Found collision shape: ", child.name)
	
	print("Total collision shapes found: ", collision_shapes.size())
	
	if collision_shapes.size() == 0:
		print("ERROR: No collision shapes found!")
		return
	
	# Create meshes from collision shapes
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for col_shape in collision_shapes:
		if col_shape.shape is BoxShape3D:
			var box = col_shape.shape
			var box_mesh = BoxMesh.new()
			box_mesh.size = box.size
			
			surface_tool.append_from(box_mesh, 0, col_shape.transform)
			print("Added box to combined mesh")
	
	var combined_mesh = surface_tool.commit()
	print("Combined mesh created")
	
	# Create collision from combined mesh
	var new_col_shape = CollisionShape3D.new()
	var concave_shape = combined_mesh.create_trimesh_shape()
	new_col_shape.shape = concave_shape
	new_col_shape.name = "CombinedCollision"
	
	add_child(new_col_shape)
	new_col_shape.owner = get_tree().edited_scene_root
	
	print("Combined collision created! Look for 'CombinedCollision' node")
