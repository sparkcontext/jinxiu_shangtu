## 第一幕·客廳會談:章節控制器
## 負責載入對話、切換發言者立牌、顯示數值變動提示與結算畫面
extends Control

const DIALOGUE_PATH := "res://data/dialogues/zh_TW/ch1_s1_parlor.json"
const NEXT_SCENE := "res://scenes/chapters/ch1_s2_dock.tscn"

@onready var _dialogue_box: DialogueBox = $UI/DialogueBox
@onready var _settlement: PanelContainer = $UI/Settlement
@onready var _settle_stats: Label = $UI/Settlement/Margin/VBox/Stats
@onready var _settle_verdict: Label = $UI/Settlement/Margin/VBox/Verdict
@onready var _toast: Label = $UI/Toast

## 發言者 -> 立牌節點
@onready var _panels: Dictionary = {
	"沈雲錦": $Stage/ShenPanel,
	"趙掌櫃": $Stage/ZhaoPanel,
	"克劳迪": $Stage/KePanel,
}

var _engine := DialogueEngine.new()

func _ready() -> void:
	_settlement.visible = false
	_toast.visible = false

	if not _engine.load_from_json(DIALOGUE_PATH):
		return
	_engine.line_ready.connect(_on_line_ready)
	_engine.choices_ready.connect(_on_choices_ready)
	_engine.effect_applied.connect(_on_effect_applied)
	_engine.finished.connect(_on_finished)
	_dialogue_box.advance_requested.connect(_engine.advance)
	_dialogue_box.choice_selected.connect(_engine.choose)
	_engine.start()

func _on_line_ready(speaker: String, text: String) -> void:
	_highlight_speaker(speaker)
	_dialogue_box.show_line(speaker, text)

func _on_choices_ready(speaker: String, text: String, choices: Array) -> void:
	_highlight_speaker(speaker)
	_dialogue_box.show_choices(speaker, text, choices)

## 說話的人立牌亮起,其餘變暗;旁白則全部變暗
func _highlight_speaker(speaker: String) -> void:
	for name in _panels.keys():
		var panel: PanelContainer = _panels[name]
		panel.modulate = Color.WHITE if name == speaker else Color(0.45, 0.45, 0.45)

## 數值變動提示(浮水印式短訊)
func _on_effect_applied(notes: Array) -> void:
	_toast.text = "\n".join(notes)
	_toast.visible = true
	_toast.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.6)
	tween.tween_property(_toast, "modulate:a", 0.0, 0.6)
	tween.tween_callback(func(): _toast.visible = false)

func _on_finished() -> void:
	var lines: Array[String] = []
	for key in GameState.STAT_KEYS:
		lines.append("%s:%d" % [key, GameState.stats[key]])
	if not GameState.flags.is_empty():
		lines.append("")
		for info in GameState.flags:
			lines.append("◆ " + info)
	_settle_stats.text = "\n".join(lines)
	_settle_verdict.text = GameState.get_verdict()
	_settlement.visible = true

func _on_next_chapter_pressed() -> void:
	get_tree().change_scene_to_file(NEXT_SCENE)

func _on_restart_pressed() -> void:
	GameState.reset()
	get_tree().reload_current_scene()

func _on_back_title_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
