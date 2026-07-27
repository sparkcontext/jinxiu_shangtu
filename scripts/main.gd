## 標題畫面
extends Control

@onready var _continue_btn: Button = $Center/VBox/Continue

func _ready() -> void:
	_continue_btn.visible = GameState.has_save()

func _on_start_pressed() -> void:
	AudioManager.play_sfx("click")
	GameState.clear_save() ## 新遊戲覆蓋舊進度
	GameState.reset()
	get_tree().change_scene_to_file("res://scenes/chapters/ch1_s1_parlor.tscn")

func _on_continue_pressed() -> void:
	AudioManager.play_sfx("click")
	var chapter := GameState.load_game()
	if chapter.is_empty():
		return
	get_tree().change_scene_to_file(chapter)

func _on_quit_pressed() -> void:
	get_tree().quit()
