extends Node2D

# ----- 1. SETUP: DIE VERBINDUNG ZUR GRAFIK -----
@onready var dice_buttons = [
	$"W 1-3/W1", $"W 1-3/W2", $"W 1-3/W3",
	$"W 4-6/W4", $"W 4-6/W5", $"W 4-6/W6"
]
@onready var display = $FUNFACT
@onready var score_player_label = $"Score Player"
@onready var score_cpu_label = $"Score Cpu"
@onready var turn_display = $TurnLabel 

# ----- 2. VARIABLEN: DAS GEDÄCHTNIS -----
var dice_values = [0, 0, 0, 0, 0, 0]
var dice_selected = [false, false, false, false, false, false]
var dice_used = [false, false, false, false, false, false]
var has_rolled_this_turn = false

var current_turn_score = 0
var scores = [0, 0]
var active_player = 0
var target_score = 4000 

var funfacts = [
	"Quak! Frösche trinken kein Wasser, sie saugen es durch die Haut auf.",
	"Mofogga! Manche Frösche springen über 3 Meter weit.",
	"Wusstest du? Manche Frösche frieren im Winter ein.",
	"Quak! Frösche fressen oft ihre eigene alte Haut.",
	"Wusstest du? Goldbaumsteiger-Frösche sind extrem giftig!",
	"Füchse sind garkeine Rudeltiere.",
	"Manche Haie werden erst mit 30 Jahren geschlechtsreif.",
	"Wenn Fliegen hinter Fliegen fliegen fliegen Fliegen hinter Fliegen her."
]

# ----- 3. START -----
func _ready():
	randomize()
	update_ui()
	display.text = "Quak! Throw to start!"

# ----- 4. SPIEL-LOGIK -----

func roll_dice():
	has_rolled_this_turn = true 
	current_turn_score += calculate_score(get_selected_array())
	
	for i in range(6):
		if dice_selected[i]:
			dice_used[i] = true
			dice_selected[i] = false
	
	if dice_used.count(true) == 6:
		dice_used = [false, false, false, false, false, false]

	var freshly_rolled = []
	for i in range(6):
		if not dice_used[i]:
			dice_values[i] = randi_range(1, 6)
			freshly_rolled.append(dice_values[i])
	
	display.text = funfacts[randi() % funfacts.size()]
	update_ui()
	check_farkle(freshly_rolled)

func check_farkle(rolled_values):
	if calculate_score(rolled_values) == 0:
		trigger_bust()

func trigger_bust():
	display.text = "!!! FARKLE !!!\nQuak... Null Punkte für dich."
	current_turn_score = 0
	await get_tree().create_timer(2.0).timeout
	next_turn()

func next_turn():
	current_turn_score = 0
	has_rolled_this_turn = false
	dice_used = [false, false, false, false, false, false]
	dice_selected = [false, false, false, false, false, false]
	active_player = 1 if active_player == 0 else 0
	update_ui()
	if active_player == 1:
		cpu_logic()

# --- DER PUNKTRECHNER (Mathe-Regeln) ---
func calculate_score(values: Array) -> int:
	if values.size() == 0: return 0
	var s: int = 0
	# Ein Zähler: Wir speichern, wie oft jede Zahl (1 bis 6) gewürfelt wurde
	var c = {1:0, 2:0, 3:0, 4:0, 5:0, 6:0} 
	for v in values:
		c[v] += 1
	
	# Regel 1: Große Straße (1-6) = 1500 Punkte
	if c[1]>=1 and c[2]>=1 and c[3]>=1 and c[4]>=1 and c[5]>=1 and c[6]>=1:
		return 1500
	
	# Regel 2: Kleine Straße (1-5) = 500 Punkte
	if c[1]>=1 and c[2]>=1 and c[3]>=1 and c[4]>=1 and c[5]>=1:
		s += 500
		for i in range(1,6): c[i] -= 1 
	
	# Regel 3: Kleine Straße (2-6) = 750 Punkte
	elif c[2]>=1 and c[3]>=1 and c[4]>=1 and c[5]>=1 and c[6]>=1:
		s += 750
		for i in range(2,7): c[i] -= 1
	
	# Regel 4: Mehrlinge (3 gleiche oder mehr)
	for n in range(1, 7):
		if c[n] >= 3: # FIX: c[n] statt c
			var amount = c[n]
			var base = 1000 if n == 1 else n * 100
			s += base * int(pow(2, amount - 3)) 
			c[n] = 0
			
	# Regel 5: Einzelne 1er (100 Pkt) und 5er (50 Pkt)
	s += (c[1] * 100) + (c[5] * 50) #
	
	return s




# ----- 5. GUI --------

func update_ui():
	var hand_points = calculate_score(get_selected_array())
	var total_hand = current_turn_score + hand_points
	
	var p_name = "SPIELER" if active_player == 0 else "CPU"
	turn_display.text = p_name + " ist am Zug!"
	
	var current_fact = display.text.split("\n")[0]
	display.text = current_fact

	score_player_label.text = "Spieler: %d / %d\n(Hand: +%d)" % [scores[0], target_score, (total_hand if active_player == 0 else 0)]
	score_cpu_label.text = "CPU: %d / %d\n(Hand: +%d)" % [scores[1], target_score, (total_hand if active_player == 1 else 0)]
	
	for i in range(6):
		var btn = dice_buttons[i]
		btn.text = str(dice_values[i])
		if dice_used[i] or not has_rolled_this_turn:
			btn.disabled = true
			btn.modulate = Color(0.3, 0.3, 0.3)
		elif dice_selected[i]:
			btn.disabled = false
			btn.modulate = Color(1, 1, 0)
		else:
			btn.disabled = false
			btn.modulate = Color(1, 1, 1)

# ----- 6. CPU-LOGIK -----
func cpu_logic():
	if active_player == 0: return 
	await get_tree().create_timer(1.0).timeout
	roll_dice()
	if active_player == 0: return 

	await get_tree().create_timer(1.0).timeout
	for i in range(6):
		if not dice_used[i]: dice_selected[i] = true
	
	for i in range(6):
		if dice_selected[i]:
			var val = dice_values[i]
			dice_selected[i] = false
			if calculate_score(get_selected_array()) < calculate_score(get_selected_array() + [val]):
				dice_selected[i] = true
	
	update_ui()
	await get_tree().create_timer(1.0).timeout
	
	var total_p = current_turn_score + calculate_score(get_selected_array())
	var left = dice_used.count(false) - dice_selected.count(true)
	
	if total_p >= 500 or (total_p >= 300 and left <= 2):
		_on_bank_button_pressed()
	else:
		cpu_logic()

# ----- 7. KNÖPFE -----
func _on_throw_pressed():
	if active_player == 0 and (calculate_score(get_selected_array()) > 0 or not has_rolled_this_turn):
		roll_dice()

func _on_fold_pressed():
	_on_bank_button_pressed()

func _on_bank_button_pressed():
	var pts = current_turn_score + calculate_score(get_selected_array())
	if pts == 0: return
	scores[active_player] += pts
	if scores[active_player] >= target_score:
		display.text = "SIEG FÜR " + ("SPIELER" if active_player == 0 else "CPU")
		return
	next_turn()

func _on_dice_clicked_helper(index: int):
	if active_player == 0 and not dice_used[index] and has_rolled_this_turn:
		dice_selected[index] = !dice_selected[index]
		update_ui()

func _on_w_1_pressed(): _on_dice_clicked_helper(0)
func _on_w_2_pressed(): _on_dice_clicked_helper(1)
func _on_w_3_pressed(): _on_dice_clicked_helper(2)
func _on_w_4_pressed(): _on_dice_clicked_helper(3)
func _on_w_5_pressed(): _on_dice_clicked_helper(4)
func _on_w_6_pressed(): _on_dice_clicked_helper(5)

func _on_menü_exit_settings_pressed():
	get_tree().reload_current_scene()

func get_selected_array() -> Array:
	var a = []
	for i in range(6):
		if dice_selected[i]: a.append(dice_values[i])
	return a
