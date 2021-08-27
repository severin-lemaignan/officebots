extends ColorRect

var INTRO = [
["""Hello Colleagues.

As you know,
an investor is coming to the office in few minutes
and will decide if he wants to invest in our company! 
It is a great day for the team and for the company.
But as you will see, the office is a mess. 
I will give each of you some missions to clean the place.  
You will need to talk to your colleagues to be sure you know them well.
Every mission will give you some points. 
""", "Next"],
["""
When the timer runs out,
the player with more points will win!
All missions do not worth the same amount of points.
""", "Next"],

["""
You can navigate the arena using the arrow keys.

When you approach a character, 
you may have a discussion with them through the chat.
You can use the emojis to show 
your emotions and expressions""", "Next"],
["""
You can interact with some objects: either bump into it or pick the object 
by clicking on the highlighted yellow circle on the object 
Some missions are using the objects: be careful to select the good object 
and not a similar one. 
""", "Next"],

["""
If you get stuck during the game,
 you can change your mission 
but it will cost you 3 points in your total.  

Good luck !""", "Let's start!"]]

#Topolewska-Siedzik, Ewa & Skimina, Ewa & Strus, Włodzimierz & Cieciuch, Jan & Rowiński, Tomasz. (2014). The short IPIP-BFM-20 questionnaire for measuring the big five. Roczniki Psychologiczne // Annals of Psychology. 17. 385-402. 

var BIG5 = [
    "1. Have frequent mood swings",
    "2. Worry about things",
    "3. Seldom feel blue",
    "4. Am relaxed most of the time",
    "5. Am quiet around strangers",
    "6. Am the life of the party",
    "7. Keep in the background",
    "8. Talk to a lot of different people at parties",
    "9. Feel little concern for others",
    "10. Am not interested in other people’s problems",
    "11. Sympathize with others’ feelings",
    "12. Take time out for others",
    "13. Please answer Completely disagree",
    "14. Get chores done right away",
    "15. Leave my belongings around",
    "16. Often forget to put things back in their proper place",
    "17. Follow a schedule",
    "18. Do not have a good imagination",
    "19. Am full of ideas",
    "20. Please answer Completely agree",
    "21. Have a rich vocabulary",
    "22. Have difficulty understanding abstract ideas"
   ]

onready var textzone = $Textzone
onready var textzone_btn = $TextzoneBtn

const LIKERT_ITEM = preload("res://LikertItem.tscn")

signal intro_complete

# emitted once the questionaire is complete; Prolific ID, age and gender are passed as parameters
signal questionaire_complete

signal big5_complete

signal final_complete

signal consent_given

signal player_guess

signal consent_pressed

var prolific_id
var result_big5
# Called when the node enters the scene tree for the first time.
func _ready():
    
#    showIntro()
#    preHocQuestionnaire()
#    big5()
    pass

func validate():
    var id = $PreQuestionaire/ProlificId.text
    if id.length() != 24:
        $PreQuestionaire/ValidationLabel.text = """Invalid ID: should be 24 characters long
and only include alphanumeric characters."""
        return false
    
    $PreQuestionaire/ValidationLabel.text = ""
    return true
    
func showIntro():
    
    $PreQuestionaire.hide()
    $Big5.hide()
    $FinalScreen.hide()
    
    textzone.show()
    textzone.text = ""
    textzone.percent_visible = 0
    textzone_btn.hide()
    
    self.modulate.a = 0
    show()
    
    $Tween.interpolate_property(self, "modulate:a", 0, 1, 1)
    $Tween.start()
    yield($Tween, "tween_all_completed")
    
    for text_btn in INTRO:
        textzone_btn.hide()
        $Tween.interpolate_property(textzone, "percent_visible", 0, 1, 5)
        textzone.text = text_btn[0]
        $Tween.start()
        yield($Tween,"tween_all_completed")
        textzone_btn.text = text_btn[1]
        textzone_btn.show()
        
        yield(textzone_btn, "pressed")

    
    $Tween.interpolate_property(self, "modulate:a", 1,0, 2)
    $Tween.start()
    yield($Tween, "tween_all_completed")
    
    hide()
    self.modulate.a = 1
    emit_signal("intro_complete")


func preHocQuestionnaire():
    $PreQuestionaire/ValidationLabel.text = ""
    textzone.hide()
    $Big5.hide()
    $PreQuestionaire.show()
    $FinalScreen.hide()

    while true:
        yield(textzone_btn, "button_up")
        if validate():
            break
        
    
    prolific_id = $PreQuestionaire/ProlificId.text
    
    
    $Tween.interpolate_property(self, "modulate:a", 1, 0, 0.5)
    $Tween.start()
    
    
    yield($Tween, "tween_all_completed")


    hide()
    self.modulate.a = 1
    
    emit_signal("questionaire_complete", prolific_id)

func consent():
#    $PreQuestionaire.hide()
    $Big5.hide()
    $FinalScreen.hide()
    
    textzone.show()
    textzone.text = ""
    textzone.percent_visible = 0
#    textzone_btn.hide()
    
    self.modulate.a = 0
    show()
    
    $PreQuestionaire/WelcomeLabel.hide()
    $PreQuestionaire/ProlificIdLabel.hide()
    $PreQuestionaire/ProlificId.hide()
    $PreQuestionaire/ValidationLabel.hide()
    $PreQuestionaire/NextLabel.hide()
    $TextzoneBtn.hide()
    
    $PreQuestionaire/NoConsentButton.show()
    $PreQuestionaire/YesConsentButton.show()
    $PreQuestionaire/ConsentLabel.show()
    $PreQuestionaire/ConsentTextLabel.show()
    
    
    $Tween.interpolate_property(self, "modulate:a", 0, 1, 1)
    $Tween.start()
    yield($Tween, "tween_all_completed")
    
#    yield($PreQuestionaire/ConsentCheckBox, "pressed")

    
    var button = yield(self, "consent_pressed")
    print(button)
    
    if button == "no":
        $PreQuestionaire/NoConsentButton.hide()
        $PreQuestionaire/YesConsentButton.hide()
        $PreQuestionaire/ConsentLabel.hide()
        $PreQuestionaire/ConsentTextLabel.hide()
        $PreQuestionaire/NoConsentLabel.show()
        return
        
    $PreQuestionaire/ConsentTextLabel.hide()
    $PreQuestionaire/NoConsentButton.hide()
    $PreQuestionaire/YesConsentButton.hide()
    $PreQuestionaire/ConsentLabel.hide()
    $PreQuestionaire/NextLabel.show()
    $TextzoneBtn.show()
    
    
    yield(textzone_btn, "button_up")


    $Tween.interpolate_property(self, "modulate:a", 1, 0, 0.5)
    $Tween.start()

    yield($Tween, "tween_all_completed")

    hide()
    self.modulate.a = 1

    emit_signal("consent_given")

func big5():
    
    $Textzone.hide()
    $PreQuestionaire.hide()
    $TextzoneBtn.hide()
    $Big5.show()
    $FinalScreen.hide()
    
    self.modulate.a = 0
    show()
    
    $Tween.interpolate_property(self, "modulate:a", 0, 1, 0.5)
    $Tween.start()
    yield($Tween, "tween_all_completed")
    
    var idx = 0

    $TextzoneBtn.disabled = false
    
    while idx < BIG5.size():
        $TextzoneBtn.hide()
        for c in $Big5/Items.get_children():
            c.hide()
            
        for _i in range(5):
            var question = BIG5[idx]
            var item = LIKERT_ITEM.instance()
            item.set_question(question)
            $Big5/Items.add_child(item)
            
            yield(item, "selected")
            idx += 1
             
            if idx == BIG5.size():
                break
        
        if idx != BIG5.size():
            $TextzoneBtn.text = "Continue"
            $TextzoneBtn.show()
            yield($TextzoneBtn, "button_up")

    var results = []
    for c in $Big5/Items.get_children():
        results.push_back(c.get_answer())
    print(results)
    result_big5=results
    
    $TextzoneBtn.text = "Well done! Let's get started!"
    $TextzoneBtn.show()
    $TextzoneBtn.disabled = false
    
    yield($TextzoneBtn, "button_up")
    
    $Tween.interpolate_property(self, "modulate:a", 1, 0, 0.5)
    $Tween.start()
    yield($Tween, "tween_all_completed")
    
    hide()
    self.modulate.a = 1
    
    emit_signal("big5_complete", results)


func final():
    
    $Textzone.hide()
    $PreQuestionaire.hide()
    $TextzoneBtn.show()
    $Big5.hide()
    $FinalScreen.show()

    $FinalScreen/WelcomeLabel.show()
    $FinalScreen/NPCs.show()
    $FinalScreen/ThankYou.hide()
    $FinalScreen/ByeLabel.hide()
    
    $TextzoneBtn.text = "Confirm"
    self.modulate.a = 0
    show()
    
    $Tween.interpolate_property(self, "modulate:a", 0, 1, 0.5)
    $Tween.start()
    yield($Tween, "tween_all_completed")
    
    $TextzoneBtn.disabled = false
    
    var murderer
    
    while true:
        murderer = $FinalScreen/NPCs/option1.group.get_pressed_button()
        yield($TextzoneBtn, "button_up")
        if murderer:
            emit_signal("player_guess", murderer.name)
            break
    

    #get selected 'killer'
    if murderer.name == "option1":
        $FinalScreen/Selection.text = "Congrats! You caught the killer!"
    else:
        $FinalScreen/Selection.text = "Ah you made the wrong choice!"
    
    $FinalScreen/WelcomeLabel.hide()
    $FinalScreen/NPCs.hide()
    
    $TextzoneBtn.hide()
    
    
    $FinalScreen/Selection.show()
    $FinalScreen/ThankYou.show()
    
    yield($FinalScreen/ThankYou,"link_followed")
    $FinalScreen/ThankYou.hide()
    $FinalScreen/Selection.hide()
    $FinalScreen/ByeLabel.show()
    
    emit_signal("final_complete")
            

    


func _on_YesConsentButton_pressed():
    emit_signal("consent_pressed", "yes")


func _on_NoConsentButton_pressed():
    emit_signal("consent_pressed", "no")
