## 對話引擎:讀取外置 JSON 對話樹,驅動整個劇情流程
## 節點格式:
##   一般台詞: { "speaker": "...", "text": "...", "next": "節點ID" }
##   選項節點: { "speaker": "...", "text": "...", "choices": [ { "text", "next", "effects" } ] }
##   結束節點: { "speaker": "...", "text": "...", "end": true }
class_name DialogueEngine
extends RefCounted

signal line_ready(speaker: String, text: String)
signal choices_ready(speaker: String, text: String, choices: Array)
signal minigame_requested(node: Dictionary) ## 節點含 "minigame" 時觸發,由場景控制器執行後用 jump_to 回傳結果
signal effect_applied(notes: Array)
signal finished

var _nodes: Dictionary = {}
var _start_id: String = ""
var _current_id: String = ""
var _is_finished: bool = false

## 載入對話 JSON,成功回傳 true
func load_from_json(path: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("DialogueEngine: 找不到對話檔 " + path)
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("DialogueEngine: JSON 格式錯誤 " + path)
		return false
	_nodes = parsed.get("nodes", {})
	_start_id = parsed.get("start", "")
	if _start_id.is_empty() or not _nodes.has(_start_id):
		push_error("DialogueEngine: 起始節點無效 " + path)
		return false
	return true

func start() -> void:
	_is_finished = false
	_goto(_start_id)

## 玩家推進一般台詞
func advance() -> void:
	if _is_finished:
		return
	var node: Dictionary = _nodes.get(_current_id, {})
	if node.has("choices"):
		return ## 選項節點必須用 choose()
	if node.get("end", false):
		_is_finished = true
		finished.emit()
		return
	var next_id: String = node.get("next", "")
	if next_id.is_empty() or not _nodes.has(next_id):
		push_warning("DialogueEngine: 節點 %s 沒有有效後繼,直接結束" % _current_id)
		_is_finished = true
		finished.emit()
		return
	_goto(next_id)

## 玩家選擇選項
func choose(index: int) -> void:
	if _is_finished:
		return
	var node: Dictionary = _nodes.get(_current_id, {})
	var choices: Array = node.get("choices", [])
	if index < 0 or index >= choices.size():
		return
	var choice: Dictionary = choices[index]
	if choice.has("effects"):
		var notes: Array = GameState.apply_effects(choice["effects"])
		if not notes.is_empty():
			effect_applied.emit(notes)
	var next_id: String = choice.get("next", "")
	if next_id.is_empty() or not _nodes.has(next_id):
		_is_finished = true
		finished.emit()
		return
	_goto(next_id)

## 小遊戲結果回傳:跳到指定節點繼續劇情
func jump_to(node_id: String) -> void:
	if _is_finished or not _nodes.has(node_id):
		return
	_goto(node_id)

func _goto(node_id: String) -> void:
	_current_id = node_id
	var node: Dictionary = _nodes[node_id]
	var speaker: String = node.get("speaker", "")
	var text: String = node.get("text", "")
	if node.has("minigame"):
		minigame_requested.emit(node)
	elif node.has("choices"):
		choices_ready.emit(speaker, text, node["choices"])
	else:
		line_ready.emit(speaker, text)
