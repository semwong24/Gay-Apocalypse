extends Control
var scenes
var comics = {}
var current_comic = ""
var current_page = -1
@export var panelscale:float
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Dialogic.signal_event.connect(_on_dialogic_signal)
	load_comic("intro_comic")
	load_page_full("intro_comic",1)
	pass # Replace with function body.

func _on_dialogic_signal(argument:String):
	if argument == "nextpage":
		advance_page()
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
				panel.scale = Vector2(panelscale,panelscale)
				panel.position = Vector2(0,0)
				panel.visible = false
				page_panels.append(panel)
				add_child(panel)
		comic.append(page_panels)
	comics[name] = comic
	return comic
func load_page_full(comic_name:String,page:int):
	current_comic = comic_name
	current_page = page
	for panel in comics[comic_name][page]:
		panel.visible = true
func unload_page():
	for panel in comics[current_comic][current_page]:
		panel.visible = false
	
func advance_page():
	assert(current_comic.length() > 0)
	unload_page()
	current_page += 1
	if current_page >= len(comics[current_comic]):
		current_page = -1
		return
	load_page_full(current_comic,current_page)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
