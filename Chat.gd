extends Control

signal on_chat_msg

onready var textinput = $VBoxContainer/HBoxContainer/TextInput

var chatmsg = preload("res://ChatMsg.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
    textinput.connect("text_entered", self, "on_chat_msg_entered")
    $VBoxContainer/HBoxContainer/SendBtn.connect("button_up", self, "on_chat_msg_entered")
    
    for i in range(10):
        var msg
        if i % 3 == 1:
            msg = add_msg("Msg " + str(i), "User " + str(i))
            
        else:
            msg = add_msg("Hello " + str(i))
            
        msg.set_own_msg(i%2==1)
        yield(get_tree().create_timer(.5), "timeout")


func on_chat_msg_entered(_msg=null):
    var msg = textinput.text
    if not msg:
        return
        
    emit_signal("on_chat_msg", msg)
    var chatmsg = add_msg(msg)
    chatmsg.set_own_msg(true)
    textinput.text = ""

func set_list_players_in_range(players):
    # (connected to player's signal in Game.gd)

    for n in $VBoxContainer/ListPlayersInRange.get_children():
        $VBoxContainer/ListPlayersInRange.remove_child(n)
        n.queue_free()
        
    for p in players:
        var lbl = Label.new()
        lbl.text += "[b]" + p.name + "[/b] can hear you\n"
        $VBoxContainer/ListPlayersInRange.add_child(lbl)

func add_msg(text, author=null):

    var msg = chatmsg.instance()
    msg.set_text(text, author)
    $VBoxContainer/ScrollContainer/Msgs.add_child(msg)
    
    # not very pretty, but the only way I could find to force the scroll container to
    # scroll to the bottom of the msg list
    get_tree().create_timer(.1).connect("timeout", self, "scroll_down")
    
        
    return msg

func scroll_down():
    $VBoxContainer/ScrollContainer.scroll_vertical = $VBoxContainer/ScrollContainer.scroll_vertical + 1000
