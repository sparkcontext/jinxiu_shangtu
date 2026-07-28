## 加載畫面:展示故事背景與序章引子,同時在背景線程中預載下一場景
extends Control

## 文字播完且場景預載完成後,點按任意處進入此場景
@export_file("*.tscn") var next_scene := "res://scenes/chapters/ch1_s1_parlor.tscn"

const TYPING_SPEED := 28.0 ## 打字機速度(字元/秒)

@onready var _character: TextureRect = $Character
@onready var _story: RichTextLabel = $TextPanel/Margin/VBox/StoryText
@onready var _bar: ProgressBar = $BottomBar/VBox/BarRow/ProgressBar
@onready var _load_label: Label = $BottomBar/VBox/BarRow/LoadLabel
@onready var _percent: Label = $BottomBar/VBox/BarRow/Percent
@onready var _hint: Label = $BottomBar/VBox/Hint
@onready var _fade: ColorRect = $FadeRect

var _typed := false      ## 引子是否打完
var _loaded := false     ## 場景是否預載完成
var _proceeding := false ## 是否正在切場景
var _shown := 0.0        ## 已顯示字元數(浮點累計)
var _total_chars := 0
var _progress := 0.0     ## 平滑後的進度條數值
var _blink := 0.0
var _last_tap_frame := -1 ## 去重:觸控與模擬滑鼠事件可能同幀成對送達

func _ready() -> void:
	_fade.modulate.a = 1.0
	_hint.modulate.a = 0.0
	_story.visible_characters = 0
	_total_chars = _story.get_parsed_text().length()
	_character.modulate.a = 0.0
	ResourceLoader.load_threaded_request(next_scene)
	var t := create_tween().set_parallel(true)
	t.tween_property(_fade, "modulate:a", 0.0, 0.8)
	t.tween_property(_character, "modulate:a", 1.0, 1.6).set_delay(0.4)

func _process(delta: float) -> void:
	# 打字機逐字顯示
	if not _typed:
		_shown += TYPING_SPEED * delta
		_story.visible_characters = int(_shown)
		if _shown >= _total_chars:
			_finish_typing()
	# 預載進度
	if not _loaded:
		var prog := []
		match ResourceLoader.load_threaded_get_status(next_scene, prog):
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				_progress = lerpf(_progress, prog[0] * 100.0, delta * 4.0)
			ResourceLoader.THREAD_LOAD_LOADED:
				_progress = 100.0
				_loaded = true
			ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				push_warning("加載畫面:預載失敗,切場景時改為同步載入")
				_progress = 100.0
				_loaded = true
		_bar.value = _progress
		_percent.text = "%d%%" % int(_progress)
	# 提示呼吸閃爍
	if _typed and _loaded and not _proceeding:
		_load_label.text = "備貨妥當"
		_blink += delta
		_hint.modulate.a = 0.55 + 0.45 * sin(_blink * 3.0)

func _input(event: InputEvent) -> void:
	## 用 _input 而非 _unhandled_input:全屏背景/遮罩會吃掉事件,
	## 這裡需要在 Control 消費之前攔截點按
	if _proceeding:
		return
	var pressed: bool = (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventKey and event.pressed and not event.echo)
	if not pressed:
		return
	## 行動裝置上一次點按可能同時送達觸控與模擬滑鼠事件,
	## 同一幀只處理一次,避免連跳「看完全文」和「進入遊戲」兩步
	var frame := Engine.get_process_frames()
	if frame == _last_tap_frame:
		return
	_last_tap_frame = frame
	if not _typed:
		_finish_typing() ## 第一次點按:直接看完全文
	elif _loaded:
		_proceed()       ## 第二次點按:進入遊戲

func _finish_typing() -> void:
	_typed = true
	_shown = _total_chars
	_story.visible_characters = -1 ## -1 表示顯示全部

func _proceed() -> void:
	_proceeding = true
	_hint.modulate.a = 1.0
	var t := create_tween()
	t.tween_property(_fade, "modulate:a", 1.0, 0.6)
	t.tween_callback(_go)

func _go() -> void:
	var packed := ResourceLoader.load_threaded_get(next_scene)
	if packed:
		get_tree().change_scene_to_packed(packed)
	else:
		get_tree().change_scene_to_file(next_scene)
