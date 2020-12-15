extends Panel

signal timeout

var duration = 0.0
var elapsed = 0.0

var running : bool = false

func _ready():
    pass

func reset():
    running = false
    elapsed = 0.0
    material.set_shader_param("value", 100);

func start(d=5):
    
    reset()
    
    duration = d
    
    running = true
    
func _process(delta):
    
    if !running:
        return
        
    if duration > 0 and elapsed < duration:
        elapsed += delta
        
        material.set_shader_param("value", 100 * (1- elapsed / duration));
    
    else:
        emit_signal("timeout")
        running = false
        
        
