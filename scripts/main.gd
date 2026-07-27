## 標題畫面
extends Control

func _on_start_pressed() -> void:
	GameState.reset() ## 新遊戲從這裡重置數值,章節間由 autoload 延續
	get_tree().change_scene_to_file("res://scenes/chapters/ch1_s1_parlor.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
