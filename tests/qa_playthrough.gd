## QA 自動化驗證:無頭模式全流程走查
## 執行:godot --headless --path . res://tests/qa_playthrough.tscn
## 全部通過 exit 0,否則 exit 1
extends Node

var _pass := 0
var _fail := 0

## 引擎驅動狀態
var _pending := ""
var _choices := []
var _minigame_node := {}
var _finished := false

func _check(label: String, actual: Variant, expected: Variant) -> void:
	if str(actual) == str(expected):
		_pass += 1
		print("  PASS  %s = %s" % [label, actual])
	else:
		_fail += 1
		print("  FAIL  %s → 預期 %s,實際 %s" % [label, expected, actual])

func _make_engine(path: String) -> DialogueEngine:
	var e := DialogueEngine.new()
	e.line_ready.connect(func(_s, _t): _pending = "line")
	e.choices_ready.connect(func(_s, _t, c): _pending = "choices"; _choices = c)
	e.minigame_requested.connect(func(n): _pending = "minigame"; _minigame_node = n)
	e.finished.connect(func(): _pending = "done"; _finished = true)
	assert(e.load_from_json(path))
	return e

## 依選項索引序列走完整個對話樹;遇到小遊戲節點用 jump_result 跳過
func _drive(e: DialogueEngine, choice_queue: Array, jump_result := "") -> void:
	e.start()
	var steps := 0
	while _pending != "done" and steps < 300:
		steps += 1
		match _pending:
			"line":
				e.advance()
			"choices":
				var idx: int = choice_queue.pop_front()
				e.choose(idx)
			"minigame":
				e.jump_to(_minigame_node["results"][jump_result])
	if steps >= 300:
		print("  FAIL  對話走查超過 300 步,疑似死循環")
		_fail += 1

func _ready() -> void:
	await get_tree().process_frame
	print("====== QA 開始 ======")
	_test_chapter1()
	_test_inspection()
	_test_bidding()
	_test_chapter3_flow()
	_test_save_load()
	_test_verdict()
	print("====== QA 結果:%d 通過,%d 失敗 ======" % [_pass, _fail])
	get_tree().quit(0 if _fail == 0 else 1)

## 第一幕:情報路線走查 + 數值斷言
func _test_chapter1() -> void:
	print("--- 第一幕·客廳會談(情報路線)---")
	GameState.reset()
	var e := _make_engine("res://data/dialogues/zh_TW/ch1_s1_parlor.json")
	# c0=0 打聽底細, c1=1 以茶待客, c2=2 試探問數量, c3=0 情報認錯, c4=0 任驗
	_drive(e, [0, 1, 2, 0, 0])
	_check("第一幕走完", _finished, true)
	_check("銀兩", GameState.stats["銀兩"], 470)       # 500-10(茶)-20(換貨)
	_check("好感", GameState.stats["好感"], 28)       # 5+18+5
	_check("聲望", GameState.stats["聲望"], 13)       # 10+3
	_check("戒心", GameState.stats["戒心"], 50)       # 50-5+5
	_check("情報·信用", GameState.flags.any(func(f): return f.contains("信用")), true)
	_check("情報·三千擔", GameState.flags.any(func(f): return f.contains("三千擔")), true)

## 驗貨小遊戲:perfect 與 poor 兩條路
func _test_inspection() -> void:
	print("--- 驗貨小遊戲 ---")
	var scene: PackedScene = load("res://scenes/minigames/inspection.tscn")
	# 全對 → perfect
	var game: InspectionGame = scene.instantiate()
	add_child(game)
	var got := {}
	game.completed.connect(func(r, _n): got["result"] = r)
	game.start()
	for i in game._flawed:
		game._grid.get_children()[i].button_pressed = true
	game._finish()
	_check("全對結果", got.get("result"), "perfect")
	_check("品質+15", GameState.stats["貨物品質"], 75)
	_check("好感+10", GameState.stats["好感"], 38)
	game.queue_free()
	# 標錯兩包好的 → poor
	var game2: InspectionGame = scene.instantiate()
	add_child(game2)
	var got2 := {}
	game2.completed.connect(func(r, _n): got2["result"] = r)
	game2.start()
	var marked := 0
	for i in 8:
		if not game2._flawed.has(i) and marked < 2:
			game2._grid.get_children()[i].button_pressed = true
			marked += 1
	game2._finish()
	_check("標錯結果", got2.get("result"), "poor")
	game2.queue_free()

## 議價小遊戲:高價成交與破局兩條路
func _test_bidding() -> void:
	print("--- 議價小遊戲 ---")
	var scene: PackedScene = load("res://scenes/minigames/bidding.tscn")
	# 好感38 + 情報三千擔 → 心理價位 147,出 145 成交 deal_high
	var before: int = GameState.stats["銀兩"]
	var game: BiddingGame = scene.instantiate()
	add_child(game)
	var got := {}
	game.completed.connect(func(r, _n): got["result"] = r)
	game.start()
	_check("心理價位", game._willingness, 147)
	game._slider.value = 145
	game._on_offer()
	_check("成交結果", got.get("result"), "deal_high")
	_check("訂金入賬", GameState.stats["銀兩"] - before, 435)
	game.queue_free()
	# 好感歸零無情報,連出三次 180 → fail
	GameState.stats["好感"] = 0
	GameState.flags.clear()
	var game2: BiddingGame = scene.instantiate()
	add_child(game2)
	var got2 := {}
	game2.completed.connect(func(r, _n): got2["result"] = r)
	game2.start()
	game2._slider.value = 180
	for i in 3:
		game2._on_offer()
	_check("破局結果", got2.get("result"), "fail")
	game2.queue_free()

## 第三幕:選項 + 小遊戲節點 jump_to 流程
func _test_chapter3_flow() -> void:
	print("--- 第三幕·酒宴談判(流程)---")
	GameState.reset()
	var e := _make_engine("res://data/dialogues/zh_TW/ch1_s3_banquet.json")
	_drive(e, [0], "deal_high")
	_check("第三幕走完", _finished, true)
	_check("發難選項生效", GameState.stats["好感"], 10)

## 存檔/讀檔
func _test_save_load() -> void:
	print("--- 存檔讀檔 ---")
	GameState.reset()
	GameState.stats["銀兩"] = 777
	GameState.flags.append("測試情報")
	GameState.save_chapter("res://scenes/chapters/ch1_s2_dock.tscn")
	GameState.reset()
	_check("存檔存在", GameState.has_save(), true)
	var chapter := GameState.load_game()
	_check("讀檔章節", chapter, "res://scenes/chapters/ch1_s2_dock.tscn")
	_check("讀檔銀兩", GameState.stats["銀兩"], 777)
	_check("讀檔情報", GameState.flags.has("測試情報"), true)
	GameState.clear_save()
	_check("清除存檔", GameState.has_save(), false)

## 評語邏輯
func _test_verdict() -> void:
	print("--- 結算評語 ---")
	GameState.reset()
	GameState.stats["好感"] = 35
	_check("高好感評語", GameState.get_verdict().contains("惺惺相惜"), true)
	GameState.stats["好感"] = 0
	GameState.stats["戒心"] = 75
	_check("高戒心評語", GameState.get_verdict().contains("戒備"), true)
