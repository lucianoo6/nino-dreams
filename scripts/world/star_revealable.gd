class_name StarRevealable
extends Node3D
## Algo que só existe sob a luz quente da Estrelinha (fio-ponte, plataforma de tule, botão secreto).
## Continua visível um pouquinho depois que a luz sai (linger_time) para não ser frustrante.
## Colisões filhas (CollisionShape3D) são ligadas/desligadas junto.

@export var linger_time: float = 1.5
@export var stay_revealed: bool = false

var _linger: float = 0.0
var _shown: bool = true


func _ready() -> void:
	add_to_group("revelavel_estrela")
	_apply(false)


func set_lit(lit: bool) -> void:
	if lit:
		_linger = linger_time


func _physics_process(delta: float) -> void:
	if _shown and stay_revealed:
		return
	_linger -= delta
	_apply(_linger > 0.0)


func _apply(revealed: bool) -> void:
	if revealed == _shown:
		return
	_shown = revealed
	visible = revealed
	for child: Node in find_children("*", "CollisionShape3D", true, false):
		(child as CollisionShape3D).set_deferred("disabled", not revealed)
