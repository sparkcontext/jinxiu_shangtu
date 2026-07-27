## 遊戲數值系統(Autoload 全域單例)
## 管理銀兩、聲望、好感、戒心、貨物品質與已獲得的情報
extends Node

signal stats_changed(changed_keys: Array)

const STAT_KEYS: Array[String] = ["銀兩", "聲望", "好感", "戒心", "貨物品質"]
const SAVE_PATH := "user://savegame.json"

## 各數值說明:
## 銀兩:資金,請客送禮會扣,成交會加
## 聲望:江湖地位,影響結局評價
## 好感:對方對你的信任,談判關鍵數值
## 戒心:對方的防備,過高容易破局
## 貨物品質:貨色水準,驗貨環節使用
var stats: Dictionary = {}
var flags: Array[String] = [] ## 情報列表

func _ready() -> void:
	reset()

func reset() -> void:
	stats = {
		"銀兩": 500,
		"聲望": 10,
		"好感": 0,
		"戒心": 50,
		"貨物品質": 60,
	}
	flags = []
	stats_changed.emit(STAT_KEYS)

## 套用對話選項的效果;回傳實際改動的說明文字(供 UI 提示)
func apply_effects(effects: Dictionary) -> Array[String]:
	var notes: Array[String] = []
	var changed: Array[String] = []
	for key in effects.keys():
		if key == "情報":
			var info: String = str(effects[key])
			if not flags.has(info):
				flags.append(info)
			notes.append("獲得情報:%s" % info)
			continue
		if not stats.has(key):
			continue
		var delta: int = int(effects[key])
		stats[key] += delta
		changed.append(key)
		var sign_str := "+" if delta >= 0 else ""
		notes.append("%s %s%d" % [key, sign_str, delta])
	if not changed.is_empty():
		stats_changed.emit(changed)
	return notes

## 第一幕結算評語
func get_verdict() -> String:
	var favor: int = stats["好感"]
	var guard: int = stats["戒心"]
	if favor >= 30:
		return "惺惺相惜——克劳迪對你刮目相看,明日驗貨十拿九穩。"
	if favor >= 15 and guard < 60:
		return "不卑不亢——第一印象尚可,明日碼頭還需小心應對。"
	if guard >= 70:
		return "暗流湧動——洋人心存戒備,明日驗貨恐有刁難。"
	return "平平而過——生意還有得談,但你沒佔到先機。"

## ---------- 存檔 / 讀檔 ----------
var current_chapter := ""

## 章節進入時自動存檔(記錄數值、情報與所在章節)
func save_chapter(chapter_path: String) -> void:
	current_chapter = chapter_path
	var data := {
		"stats": stats,
		"flags": flags,
		"chapter": chapter_path,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

## 讀檔,回傳應前往的章節路徑;失敗回傳空字串
func load_game() -> String:
	if not has_save():
		return ""
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return ""
	var loaded_stats: Dictionary = parsed.get("stats", {})
	for key in STAT_KEYS:
		if loaded_stats.has(key):
			stats[key] = int(loaded_stats[key])
	flags.clear()
	for f in parsed.get("flags", []):
		flags.append(str(f))
	current_chapter = str(parsed.get("chapter", ""))
	stats_changed.emit(STAT_KEYS)
	return current_chapter

## 通關後清除存檔
func clear_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
	current_chapter = ""
