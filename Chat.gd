extends Control


onready var textinput = $VBoxContainer/HBoxContainer/TextInput

signal on_chat_msg
signal typing
signal not_typing_anymore

var is_typing = false

var chatmsg = preload("res://ChatMsg.tscn")
var presencelabel = preload("res://PresenceLabel.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
    textinput.connect("text_entered", self, "on_chat_msg_entered")
    $VBoxContainer/HBoxContainer/SendBtn.connect("button_up", self, "on_chat_msg_entered")
    
    textinput.connect("text_changed", self, "on_is_typing")
    $VBoxContainer/HBoxContainer/is_typing_timer.wait_time = 2 # after this time without typing, the player is 'not typing anymore'
    $VBoxContainer/HBoxContainer/is_typing_timer.connect("timeout", self, "on_is_typing_expired")
    

    for btn in $VBoxContainer/ReactionsContainer.get_children():
        btn.connect("reaction", self, "on_chat_msg_entered")
        
#    for i in range(10):
#        var msg
#        if i % 3 == 1:
#            msg = add_msg("Msg " + str(i), "User " + str(i))
#
#        else:
#            msg = add_msg("Hello " + str(i))
#        msg.set_own_msg(i%2==1)
#        yield(get_tree().create_timer(.5), "timeout")





            

















func on_chat_msg_entered(_msg=null):
    var msg = _msg
    if not msg:
        msg = textinput.text
    if not msg:
        return
        
    emit_signal("on_chat_msg", msg)
    var chatmsg = add_msg(msg)
    chatmsg.set_own_msg(true)
    textinput.text = ""
    textinput.release_focus()

func on_is_typing(_msg):
    $VBoxContainer/HBoxContainer/is_typing_timer.start()
    
    if not is_typing:
        is_typing = true
        print("typing")
        emit_signal("typing")

func on_is_typing_expired():
    
    if is_typing:
        is_typing = false
        print("not typing")
        emit_signal("not_typing_anymore")
    
func set_list_players_in_range(players):
    # (connected to player's signal in Game.gd)

    for n in $VBoxContainer/ListPlayersInRange.get_children():
        $VBoxContainer/ListPlayersInRange.remove_child(n)
        n.queue_free()
    
    if not players:
        var lbl = presencelabel.instance() # default label ("No-one nearby")
        $VBoxContainer/ListPlayersInRange.add_child(lbl)
    else:
        for p in players:
            var lbl = presencelabel.instance()
            lbl.bbcode_text = "[i][b]" + p.username + "[/b] is nearby[/i]"
            $VBoxContainer/ListPlayersInRange.add_child(lbl)

func add_msg(text, author=null, own=null):
    # own controls the msg alignment: own=True -> right aligned, False: left aligned, null: full width

    var msg = chatmsg.instance()
    msg.set_text(text, author)
    $VBoxContainer/ScrollContainer/Msgs.add_child(msg)
    
    if own != null:
        msg.set_own_msg(own)
    
    # not very pretty, but the only way I could find to force the scroll container to
    # scroll to the bottom of the msg list
    get_tree().create_timer(.1).connect("timeout", self, "scroll_down")
    
        
    return msg

func scroll_down():
    $VBoxContainer/ScrollContainer.scroll_vertical = $VBoxContainer/ScrollContainer.scroll_vertical + 1000
