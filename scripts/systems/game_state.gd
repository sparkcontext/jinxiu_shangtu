## 遊戲數值系統(Autoload 全域單例)
## 管理銀兩、聲望、好感、戒心、貨物品質與已獲得的情報
extends Node

signal stats_changed(changed_keys: Array)

const STAT_KEYS: Array[String] = ["銀兩", "聲望", "好感", "戒心", "貨物品質"]

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
