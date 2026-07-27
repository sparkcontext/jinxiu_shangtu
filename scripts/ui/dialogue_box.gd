## 對話框 UI:打字機效果顯示台詞,支援選項按鈕
class_name DialogueBox
extends PanelContainer

signal advance_requested
signal choice_selected(index: int)

const TYPE_SPEED := 40.0 ## 每秒顯示字元數

@onready var _speaker: Label = $Margin/VBox/Speaker
@onready var _body: RichTextLabel = $Margin/VBox/Body
@onready var _hint: Label = $Margin/VBox/Hint
@onready var _choices_box: VBoxContainer = $Margin/VBox/Choices

var _typing := false
var _typed_chars := 0.0
var _pending_choices: Array = [] ## 打完字才顯示的選項

func _ready() -> void:
	_choices_box.visible = false
	_hint.visible = false

func _process(delta: float) -> void:
	if not _typing:
		return
	_typed_chars += TYPE_SPEED * delta
	_body.visible_characters = int(_typed_chars)
	if _body.visible_characters >= _body.text.length():
		_finish_typing()

## 顯示一般台詞
func show_line(speaker: String, text: String) -> void:
	_pending_choices = []
	_set_content(speaker, text)

## 顯示選項台詞(文字打完後才浮出按鈕)
func show_choices(speaker: String, text: String, choices: Array) -> void:
	_pending_choices = choices
	_set_content(speaker, text)

func _set_content(speaker: String, text: String) -> void:
	_speaker.text = speaker
	_body.text = text
	_body.visible_characters = 0
	_typed_chars = 0.0
	_typing = true
	_hint.visible = false
	_choices_box.visible = false
	for child in _choices_box.get_children():
		child.queue_free()

func _finish_typing() -> void:
	_typing = false
	_body.visible_characters = -1
	if _pending_choices.is_empty():
		_hint.visible = true
	else:
		_show_choice_buttons()

func _show_choice_buttons() -> void:
	for i in _pending_choices.size():
		var choice: Dictionary = _pending_choices[i]
		var btn := Button.new()
		btn.text = "%d. %s" % [i + 1, choice.get("text", "……")]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_choice_pressed.bind(i))
		_choices_box.add_child(btn)
	_choices_box.visible = true
	_pending_choices = []

func _on_choice_pressed(index: int) -> void:
	choice_selected.emit(index)

## 點擊或按鍵:打字中→直接顯示全文;已完成→推進劇情
func _on_tap() -> void:
	if _typing:
		_finish_typing()
	elif _choices_box.visible:
		pass ## 等玩家按選項
	else:
		advance_requested.emit()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_tap()
		accept_event()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		## 選項浮出時:數字鍵 1–4(含小鍵盤)直接選擇
		if _choices_box.visible:
			var idx := -1
			match event.keycode:
				KEY_1, KEY_KP_1: idx = 0
				KEY_2, KEY_KP_2: idx = 1
				KEY_3, KEY_KP_3: idx = 2
				KEY_4, KEY_KP_4: idx = 3
			if idx >= 0 and idx < _choices_box.get_child_count():
				_on_choice_pressed(idx)
				get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("ui_accept") or event.keycode == KEY_SPACE:
			_on_tap()
