extends Node3D
@onready var camera = $Player3D
@onready var visibility = $Sketchfab_Scene/Sketchfab_model/VisibleOnScreenNotifier3D
@onready var model = $"Sketchfab_Scene/Sketchfab_model/Collada visual scene group"
func get_all_children(node) -> Array:
	var nodes : Array = []
	for N in node.get_children():
		if N.get_child_count() > 0:
			nodes.append(N)
			nodes.append_array(get_all_children(N))
		else:
			nodes.append(N)
	return nodes

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for node in self.get_children():
		if typeof(node) == typeof(SpotLight3D):
			if camera.position.distance_to(node.position)<100:
				node.visible = true
			else:
				node.visible = false
