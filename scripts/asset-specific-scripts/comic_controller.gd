extends Control
var scenes
var comics = {}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_comic("intro_comic")
	load_page_full("intro_comic",0)
	pass # Replace with function body.

func load_comic(name:String):
	var path = DirAccess.open("res://assets/comic/"+name+"/")
	assert(path)
	var comic = []
	for page in path.get_directories():
		var page_panels = []
		for file_name in DirAccess.get_files_at("res://assets/comic/"+name+"/"+page+"/"):
			if (file_name.get_extension() == "import"):
				file_name = file_name.replace('.import', '')
				var panel = Sprite2D.new()
				var texture = ResourceLoader.load("res://assets/comic/"+name+"/"+page+"/"+file_name) as Texture2D
				panel.texture = texture
				panel.centered = false
				panel.position = Vector2(0,0)
				panel.scale = Vector2(0.281,0.281)
				panel.visible = false
				page_panels.append(panel)
				add_child(panel)
		comic.append(page_panels)
	comics[name] = comic
	return comic
func load_page_full(comic_name:String,page:int):
	for panel in comics[comic_name][page]:
		panel.visible = true
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
