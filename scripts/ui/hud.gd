## HUD:頂部數值條,即時顯示五項數值,變動時閃爍提示
class_name HUD
extends PanelContainer

@onready var _box: HBoxContainer = $Margin/HBox

var _labels: Dictionary = {} ## 數值名稱 -> Label

func _ready() -> void:
	for key in GameState.STAT_KEYS:
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color(0.91, 0.86, 0.72))
		_box.add_child(label)
		_labels[key] = label
	refresh()
	GameState.stats_changed.connect(_on_stats_changed)

func refresh() -> void:
	for key in _labels.keys():
		_labels[key].text = "%s %d" % [key, GameState.stats.get(key, 0)]

func _on_stats_changed(changed_keys: Array) -> void:
	refresh()
	for key in changed_keys:
		var label: Label = _labels.get(key)
		if label == null:
			continue
		var tween := create_tween()
		label.modulate = Color(1.0, 0.85, 0.3)
		tween.tween_property(label, "modulate", Color.WHITE, 0.8)
