## 小遊戲:宴席議價(出價拉桿)
## 你是賣方:出價越高賺越多,但超過對方心理價位他會還價甚至翻臉
## 對方心理價位受「好感」與情報影響。三輪之內談成,否則只剩小單或破局
## 結果:deal_high / deal_mid / deal_low / deal_small / fail
class_name BiddingGame
extends PanelContainer

signal completed(result_key: String, notes: Array)

const MAX_ROUNDS := 3
const PRICE_MIN := 100
const PRICE_MAX := 180

@onready var _round_label: Label = $Margin/VBox/RoundLabel
@onready var _hint_label: Label = $Margin/VBox/HintLabel
@onready var _his_offer_label: Label = $Margin/VBox/HisOfferLabel
@onready var _price_label: Label = $Margin/VBox/PriceLabel
@onready var _slider: HSlider = $Margin/VBox/Slider
@onready var _offer_btn: Button = $Margin/VBox/Buttons/Offer
@onready var _accept_btn: Button = $Margin/VBox/Buttons/Accept

var _willingness := 0 ## 對方心理價位(每擔可接受最高價)
var _round := 1
var _counter_price := 0 ## 對方還價
var _has_intel := false

func _ready() -> void:
	visible = false
	_slider.min_value = PRICE_MIN
	_slider.max_value = PRICE_MAX
	_slider.step = 1
	_slider.value_changed.connect(func(v: float): _price_label.text = "你的出價:每擔 %d 兩" % int(v))
	_offer_btn.pressed.connect(_on_offer)
	_accept_btn.pressed.connect(_on_accept)

func start() -> void:
	visible = true
	_round = 1
	_counter_price = 0
	_has_intel = GameState.flags.any(func(f: String): return f.contains("三千擔"))
	var favor: int = mini(GameState.stats["好感"], 40)
	_willingness = 118 + favor / 2 + (10 if _has_intel else 0)
	_slider.value = 130
	_price_label.text = "你的出價:每擔 130 兩"
	_his_offer_label.visible = false
	_accept_btn.visible = false
	_update_round_ui()

func _update_round_ui() -> void:
	_round_label.text = "第 %d / %d 輪" % [_round, MAX_ROUNDS]
	var hints: Array[String] = []
	if _has_intel:
		hints.append("◆ 情報:他急需三千擔頭等絲,你可以適當堅持。")
	if GameState.stats["好感"] >= 25:
		hints.append("◆ 席間氣氛融洽,他對你頗為信任。")
	elif GameState.stats["戒心"] >= 65:
		hints.append("◆ 他心存戒備,出價宜穩不宜狠。")
	_hint_label.text = "\n".join(hints) if not hints.is_empty() else "◆ 底細不明,謹慎出價。"

func _on_offer() -> void:
	var ask := int(_slider.value)
	if ask <= _willingness:
		_deal(ask)
		return
	## 出價超出心理價位:他還價,戒心上升
	GameState.apply_effects({"戒心": 8})
	_counter_price = maxi(_willingness - 10 - randi() % 6, PRICE_MIN)
	_his_offer_label.text = "克劳迪搖搖頭,伸出手指比了個價:「每擔 %d 兩,這是我的底線。」" % _counter_price
	_his_offer_label.visible = true
	_accept_btn.visible = true
	_round += 1
	if _round > MAX_ROUNDS:
		_end_of_rounds()
	else:
		_update_round_ui()

func _on_accept() -> void:
	_deal(_counter_price)

func _end_of_rounds() -> void:
	visible = false
	if GameState.stats["好感"] >= 20:
		var notes := GameState.apply_effects({"銀兩": 110 * 1, "聲望": 1})
		completed.emit("deal_small", notes)
	else:
		var notes := GameState.apply_effects({"聲望": -3})
		completed.emit("fail", notes)

func _deal(price: int) -> void:
	visible = false
	## 訂金入賬:每擔價 × 3(代表首批訂金)
	var notes := GameState.apply_effects({"銀兩": price * 3, "聲望": 2})
	var result: String
	if price >= 140:
		result = "deal_high"
	elif price >= 125:
		result = "deal_mid"
	else:
		result = "deal_low"
	completed.emit(result, notes)
