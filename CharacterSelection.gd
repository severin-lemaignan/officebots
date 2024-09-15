extends Control

signal on_character_created

var NB_CHARACTERS = 5

# Called when the node enters the scene tree for the first time.
func _ready():
	for v in $Viewports.get_children():
		v.get_child(0).portrait_mode(true)
		
	for c in $CenterContainer/VBoxContainer/PortraitsContainer.get_children():
		c.pressed.connect(self.on_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	for i in range(NB_CHARACTERS):
		var tex = $Viewports.get_child(i).get_texture()
		$CenterContainer/VBoxContainer/PortraitsContainer.get_child(i).texture_normal = tex

func on_pressed():
	var character_name = $CenterContainer/VBoxContainer/Name.text
	
	if character_name == "":
		$CenterContainer/VBoxContainer/Name.placeholder_text = "You must set your name!"
		return
		
	var texture
	
	for i in range(NB_CHARACTERS):
		var c = $CenterContainer/VBoxContainer/PortraitsContainer.get_child(i)
		if c.button_pressed:
			texture = $Viewports.get_child(i).get_child(0).neutral_skin
		
	print("Created character " + name + " with skin " + texture.resource_path)

	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	await tween.finished
	
	visible = false
	
	on_character_created.emit([name, texture.resource_path])
	
