class_name Distraction
extends Node3D
## Algo no cenário que chama a atenção da Mel: borboleta de feltro, botão brilhante, flor que canta…
## Ela vai até lá e brinca por um tempo. Se reveals_secret, a brincadeira revela um segredo
## (ex.: um botão-estrela escondido aparece) — a distração vira ajuda.

signal mel_started_playing
signal mel_stopped_playing

@export var descricao: String = "borboleta de feltro"
@export var play_duration: Vector2 = Vector2(3.0, 6.0)
@export var only_once: bool = false
@export var reveals_secret: bool = false
@export var secret_path: NodePath

var _claimed_by: MelController
var _used: bool = false


func _ready() -> void:
	add_to_group("distracao")


func is_available() -> bool:
	return _claimed_by == null and not (only_once and _used)


## Retorna quanto tempo ela vai brincar aqui.
func claim(mel: MelController) -> float:
	_claimed_by = mel
	_used = true
	mel_started_playing.emit()
	if reveals_secret and not secret_path.is_empty():
		var secret := get_node_or_null(secret_path) as Node3D
		if secret:
			secret.visible = true
	return randf_range(play_duration.x, play_duration.y)


func release() -> void:
	_claimed_by = null
	mel_stopped_playing.emit()
