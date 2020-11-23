extends RigidBody


var prev_transform

func _ready():
    set_physics_process(false)


puppet func set_puppet_transform(transform):
    self.transform = transform


func _physics_process(_delta):
    
    # this code should *only* be called by the server (where the physics is executed)
    assert(GameState.mode == GameState.SERVER || GameState.mode == GameState.STANDALONE)
    if GameState.mode == GameState.SERVER:
        assert(is_network_master())
        
        # if the object has moved, update all the puppets
        if prev_transform != transform:
            rpc_unreliable("set_puppet_transform", transform)
            prev_transform = transform
