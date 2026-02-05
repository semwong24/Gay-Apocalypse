extends Control
var scenes
var comics = {}
var current_comic = ""
var current_page = -1
var current_panel = -1
@export var panelscale:float
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Dialogic.signal_event.connect(_on_dialogic_signal)
	#load_comic("intro_comic")
	#load_page_full("intro_comic",0)

func _on_dialogic_signal(argument:Dictionary):
	if argument["purpose"] == "start":
		if argument["comic_name"] != "":
			start_comic(argument["comic_name"])
		else:
			start_comic()
		return
	if argument["purpose"] == "next_panel":
		next_panel()
		return
	if argument["purpose"] == "load_curr_panel":
		load_panel(current_panel)
func load_comic(name:String):
	if name in comics.keys():
		return comics[name]
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
func sync_dialogic():
	Dialogic.VAR.set_variable("panel",current_panel)
	Dialogic.VAR.set_variable("page",current_page)
	Dialogic.VAR.set_variable("comic",current_comic)
func start_comic(comic_name:String = ""):
	self.visible = true
	load_comic(comic_name)
	current_comic = comic_name
	if current_page == -1:
		current_page = 0
		current_panel = 0
	
func next_panel():
	if current_panel+1 < len(comics[current_comic][current_page]):
		current_panel = current_panel + 1
		load_panel(current_panel)
		return {"page":current_page,"panel":current_panel}
	elif current_page + 1 < len(comics[current_comic]):
		unload_page()
		current_panel = 0
		current_page = current_page + 1
		load_panel(current_panel)
		return {"page":current_page,"panel":current_panel}
	unload_page()
	Dialogic.VAR.set_variable("comic_complete",true)
	print("ended comic or error occurred")
	current_page = -1
	current_panel = -1
	sync_dialogic()
	self.visible = false
	return {}
		
	current_page = current_page +1	
func load_panel(panel:int):
	assert (comics[current_comic])
	comics[current_comic][current_page][panel].visible = true
	current_panel = panel
	sync_dialogic()
	
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
