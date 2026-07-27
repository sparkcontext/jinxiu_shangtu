## 小遊戲:碼頭驗貨(找茬)
## 8 包絲綢中混有 3 包瑕疵品,30 秒內點出,按「驗完了」結算
## 結果:perfect / good / poor,由章節控制器決定後續劇情
class_name InspectionGame
extends PanelContainer

signal completed(result_key: String, notes: Array)

const BALE_COUNT := 8
const FLAW_COUNT := 3
const TIME_LIMIT := 30.0

@onready var _timer_bar: ProgressBar = $Margin/VBox/TimerBar
@onready var _grid: GridContainer = $Margin/VBox/Grid
@onready var _confirm: Button = $Margin/VBox/Confirm

var _flawed: Array[int] = []
var _time_left := TIME_LIMIT
var _running := false

func _ready() -> void:
	visible = false
	_confirm.pressed.connect(_finish)

func start() -> void:
	visible = true
	_running = true
	_time_left = TIME_LIMIT
	_timer_bar.max_value = TIME_LIMIT
	_timer_bar.value = TIME_LIMIT
	_build_bales()

func _process(delta: float) -> void:
	if not _running:
		return
	_time_left -= delta
	_timer_bar.value = maxf(_time_left, 0.0)
	if _time_left <= 0.0:
		_finish()

func _build_bales() -> void:
	for child in _grid.get_children():
		child.queue_free()
	_flawed.clear()
	while _flawed.size() < FLAW_COUNT:
		var i := randi() % BALE_COUNT
		if not _flawed.has(i):
			_flawed.append(i)
	for i in BALE_COUNT:
		var bale := Button.new()
		bale.custom_minimum_size = Vector2(150, 84)
		bale.toggle_mode = true
		bale.text = "絲綢"
		var normal := StyleBoxFlat.new()
		if _flawed.has(i):
			## 瑕疵包:色澤微微泛黃發暗,仔細看才分得出
			normal.bg_color = Color(0.78, 0.72, 0.55)
		else:
			normal.bg_color = Color(0.90, 0.87, 0.78)
		normal.set_corner_radius_all(8)
		var marked := normal.duplicate()
		marked.border_color = Color(0.85, 0.25, 0.2)
		marked.set_border_width_all(3)
		bale.add_theme_stylebox_override("normal", normal)
		bale.add_theme_stylebox_override("hover", normal)
		bale.add_theme_stylebox_override("pressed", marked)
		bale.toggled.connect(func(on: bool): bale.text = "✗ 可疑" if on else "絲綢")
		_grid.add_child(bale)

func _finish() -> void:
	if not _running:
		return
	_running = false
	var bales := _grid.get_children()
	var correct := 0
	var false_alarm := 0
	for i in bales.size():
		var marked: bool = bales[i].button_pressed
		var is_flawed: bool = _flawed.has(i)
		if marked and is_flawed:
			correct += 1
		elif marked and not is_flawed:
			false_alarm += 1
	var result: String
	var notes: Array[String] = []
	if correct == FLAW_COUNT and false_alarm == 0:
		result = "perfect"
		notes = GameState.apply_effects({"貨物品質": 15, "好感": 10})
	elif correct >= 2:
		result = "good"
		notes = GameState.apply_effects({"貨物品質": 8})
	else:
		result = "poor"
		notes = GameState.apply_effects({"貨物品質": -10, "戒心": 10})
	visible = false
	completed.emit(result, notes)
