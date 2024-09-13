extends HBoxContainer


@onready var btns = {GameState.Expressions.NEUTRAL: $happy,
			GameState.Expressions.HAPPY: $excited,
			GameState.Expressions.SAD: $sad,
			GameState.Expressions.ANGRY: $angry}
			
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

	var _err = $happy.connect("pressed", Callable(self, "toggle").bind(GameState.Expressions.NEUTRAL))
	_err = $sad.connect("pressed", Callable(self, "toggle").bind(GameState.Expressions.SAD))
	_err = $sad.connect("unpressed", Callable(btns[GameState.Expressions.NEUTRAL], "on_pressed"))
	_err = $angry.connect("pressed", Callable(self, "toggle").bind(GameState.Expressions.ANGRY))
	_err = $angry.connect("unpressed", Callable(btns[GameState.Expressions.NEUTRAL], "on_pressed"))
	_err = $excited.connect("pressed", Callable(self, "toggle").bind(GameState.Expressions.HAPPY))
	_err = $excited.connect("unpressed", Callable(btns[GameState.Expressions.NEUTRAL], "on_pressed"))

func toggle(btn):
	
	for b in btns:
		if b != btn:
			btns[b].stop()

func back_to_neutral():
	btns[GameState.Expressions.NEUTRAL].on_pressed()
