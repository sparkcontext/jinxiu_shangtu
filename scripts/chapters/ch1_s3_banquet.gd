## 第三幕·酒宴談判:章節控制器(含議價小遊戲與最終結局)
extends Control

const DIALOGUE_PATH := "res://data/dialogues/zh_TW/ch1_s3_banquet.json"

## 議價結果 -> (結局標題, 結局評語)
const ENDINGS := {
	"deal_high": ["結局一 · 大單成交", "高價簽下三千擔大單!錦記的名字,從今晚起響徹上海滩。"],
	"deal_mid": ["結局二 · 穩健成交", "公道的價,長遠的路。這單生意,為錦記打開了洋行的大門。"],
	"deal_low": ["結局三 · 微利開張", "價雖低,局已開。先站穩腳跟,來日方長。"],
	"deal_small": ["結局四 · 保本小單", "一百擔試水單。小生意,也是生意——留得青山在。"],
	"fail": ["結局五 · 談判破局", "宴席終有散時。這一次沒談成,但上海滩的故事,不會只有這一篇。"],
}

@onready var _dialogue_box: DialogueBox = $UI/DialogueBox
@onready var _toast: Label = $UI/Toast
@onready var _bidding: BiddingGame = $UI/Bidding
@onready var _settlement: PanelContainer = $UI/Settlement
@onready var _settle_title: Label = $UI/Settlement/Margin/VBox/Title
@onready var _settle_stats: Label = $UI/Settlement/Margin/VBox/Stats
@onready var _settle_verdict: Label = $UI/Settlement/Margin/VBox/Verdict

@onready var _panels: Dictionary = {
	"沈雲錦": $Stage/ShenPanel,
	"趙掌櫃": $Stage/ZhaoPanel,
	"克劳迪": $Stage/KePanel,
}

var _engine := DialogueEngine.new()
var _pending_results: Dictionary = {}
var _last_result := ""

func _ready() -> void:
	_toast.visible = false
	_settlement.visible = false
	if not _engine.load_from_json(DIALOGUE_PATH):
		return
	_engine.line_ready.connect(_on_line_ready)
	_engine.choices_ready.connect(_on_choices_ready)
	_engine.minigame_requested.connect(_on_minigame)
	_engine.effect_applied.connect(_show_toast)
	_engine.finished.connect(_on_finished)
	_dialogue_box.advance_requested.connect(_engine.advance)
	_dialogue_box.choice_selected.connect(_engine.choose)
	_bidding.completed.connect(_on_minigame_completed)
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
	_bidding.start()

func _on_minigame_completed(result_key: String, notes: Array) -> void:
	_last_result = result_key
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

func _on_finished() -> void:
	var ending: Array = ENDINGS.get(_last_result, ["第一章 · 完", "錦記的故事,才剛剛開始。"])
	_settle_title.text = ending[0]
	var lines: Array[String] = []
	for key in GameState.STAT_KEYS:
		lines.append("%s:%d" % [key, GameState.stats[key]])
	if not GameState.flags.is_empty():
		lines.append("")
		for info in GameState.flags:
			lines.append("◆ " + info)
	_settle_stats.text = "\n".join(lines)
	_settle_verdict.text = ending[1]
	_settlement.visible = true

func _on_restart_pressed() -> void:
	GameState.reset()
	get_tree().change_scene_to_file("res://scenes/chapters/ch1_s1_parlor.tscn")

func _on_back_title_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
