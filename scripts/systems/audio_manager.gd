## 音頻管理(Autoload):BGM、場景環境音、UI 音效
extends Node

const AUDIO_DIR := "res://assets/audio/"
const BGM_PATH := AUDIO_DIR + "bgm_guzheng.wav"

var _bgm: AudioStreamPlayer
var _amb: AudioStreamPlayer
var _sfx: AudioStreamPlayer

func _ready() -> void:
	_bgm = _make_player(-14.0)
	_amb = _make_player(-16.0)
	_sfx = _make_player(-6.0)
	play_bgm()

func _make_player(volume_db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.volume_db = volume_db
	add_child(p)
	return p

func _load_loop(path: String) -> AudioStreamWAV:
	var stream: AudioStreamWAV = load(path)
	if stream:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = stream.get_length() * stream.mix_rate
	return stream

func play_bgm() -> void:
	var stream := _load_loop(BGM_PATH)
	if stream and _bgm.stream != stream:
		_bgm.stream = stream
		_bgm.play()

## 場景環境音:parlor / dock / banquet
func play_ambience(key: String) -> void:
	var path := AUDIO_DIR + "amb_%s.wav" % key
	if not ResourceLoader.exists(path):
		_amb.stop()
		return
	var stream := _load_loop(path)
	if stream:
		_amb.stream = stream
		_amb.play()

## UI 音效:page(翻頁)/ click(選項)/ coin(入賬)
func play_sfx(key: String) -> void:
	var path := AUDIO_DIR + "sfx_%s.wav" % key
	if not ResourceLoader.exists(path):
		return
	_sfx.stream = load(path)
	_sfx.play()
