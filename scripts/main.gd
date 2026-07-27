## 標題畫面:與加載畫面同風格的開場
extends Control

@onready var _fade: ColorRect = $FadeRect
@onready var _character: TextureRect = $Character

func _ready() -> void:
	_fade.modulate.a = 1.0
	_character.modulate.a = 0.0
	var t := create_tween().set_parallel(true)
	t.tween_property(_fade, "modulate:a", 0.0, 0.8)
	t.tween_property(_character, "modulate:a", 1.0, 1.4).set_delay(0.3)

func _on_start_pressed() -> void:
	GameState.reset() ## 新遊戲從這裡重置數值,章節間由 autoload 延續
	var t := create_tween()
	t.tween_property(_fade, "modulate:a", 1.0, 0.4)
	t.tween_callback(_go_loading)

## 先進加載畫面(故事背景 + 序章引子),由它預載並切入第一幕
func _go_loading() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/loading_screen.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
