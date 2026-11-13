class_name MissionItem
extends Area3D
## Item de missão (ex.: botão-estrela). Ao tocar no Nino ou na Mel, conta para a missão ENCONTRAR.
## Se is_exit for true, funciona como saída do sonho (missão SAIR).

@export var is_exit: bool = false
@export var bob_height: float = 0.25
@export var spin_speed: float = 1.5

var _visual: Node3D
var _base_local: Vector3
var _time: float = 0.0


func _ready() -> void:
	_visual = get_node_or_null("Visual") as Node3D
	if _visual:
		_base_local = _visual.position
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _visual == null:
		return
	_time += delta
	_visual.position = _base_local + Vector3.UP * sin(_time * 2.5) * bob_height
	_visual.rotate_object_local(Vector3.UP, spin_speed * delta)


func _on_body_entered(body: Node3D) -> void:
	if not (body.is_in_group("sonhador") or body.is_in_group("mel")):
		return
	if is_exit:
		GameState.completar_missao()
	else:
		GameState.coletar_item()
	# TODO: partículas de fiapos/purpurina + som de "plim" de botão.
	queue_free()
