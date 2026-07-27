## 第二幕·碼頭驗貨:章節控制器(含驗貨找茬小遊戲)
extends Control

const DIALOGUE_PATH := "res://data/dialogues/zh_TW/ch1_s2_dock.json"
const NEXT_SCENE := "res://scenes/chapters/ch1_s3_banquet.tscn"

@onready var _dialogue_box: DialogueBox = $UI/DialogueBox
@onready var _toast: Label = $UI/Toast
@onready var _inspection: InspectionGame = $UI/Inspection

@onready var _panels: Dictionary = {
	"沈雲錦": $Stage/ShenPanel,
	"趙掌櫃": $Stage/ZhaoPanel,
	"克劳迪": $Stage/KePanel,
}

var _engine := DialogueEngine.new()
var _pending_results: Dictionary = {}

func _ready() -> void:
	GameState.save_chapter("res://scenes/chapters/ch1_s2_dock.tscn")
	AudioManager.play_ambience("dock")
	_toast.visible = false
	if not _engine.load_from_json(DIALOGUE_PATH):
		return
	_engine.line_ready.connect(_on_line_ready)
	_engine.choices_ready.connect(_on_choices_ready)
	_engine.minigame_requested.connect(_on_minigame)
	_engine.effect_applied.connect(_show_toast)
	_engine.finished.connect(_on_finished)
	_dialogue_box.advance_requested.connect(_engine.advance)
	_dialogue_box.choice_selected.connect(_engine.choose)
	_inspection.completed.connect(_on_minigame_completed)
	_engine.start()

func _on_line_ready(speaker: String, text: String) -> void:
	_highlight_speaker(speaker)
	_dialogue_box.show_line(speaker, text)

func _on_choices_ready(speaker: String, text: String, choices: Array) -> void:
	_highlight_speaker(speaker)
	_dialogue_box.show_choices(speaker, text, choices)

func _on_minigame(node: Dictionary) -> void:
	_highlight_speaker(node.get("speaker", ""))
	_dialogue_box.show_line(node.get("speaker", ""), node.get("text", ""))
	_pending_results = node.get("results", {})
	_inspection.start()

func _on_minigame_completed(result_key: String, notes: Array) -> void:
	if not notes.is_empty():
		_show_toast(notes)
	var next_id: String = _pending_results.get(result_key, "")
	_engine.jump_to(next_id)

func _highlight_speaker(speaker: String) -> void:
	for name in _panels.keys():
		var panel: PanelContainer = _panels[name]
		panel.modulate = Color.WHITE if name == speaker else Color(0.45, 0.45, 0.45)

func _show_toast(notes: Array) -> void:
	_toast.text = "\n".join(notes)
	_toast.visible = true
	_toast.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.6)
	tween.tween_property(_toast, "modulate:a", 0.0, 0.6)
	tween.tween_callback(func(): _toast.visible = false)

## 本章結束,稍作停頓後自動進入下一幕
func _on_finished() -> void:
	var tween := create_tween()
	tween.tween_interval(1.8)
	tween.tween_callback(func(): get_tree().change_scene_to_file(NEXT_SCENE))
