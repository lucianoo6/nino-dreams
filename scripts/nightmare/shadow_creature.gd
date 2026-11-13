class_name ShadowCreature
extends CharacterBody3D
## Criatura/vilão de pesadelo feita de lã escura e fios soltos.
## Persegue o Nino; sob a Luna desacelera, encolhe e por fim se desfaz em estrelinhas.
## A aura da Estrelinha (Mel) é zona segura: a sombra é empurrada para fora.

signal dissipated

@export var darkness: float = 3.0
@export var chase_speed: float = 3.5
@export var lit_slowdown: float = 0.2
@export var is_boss: bool = false

## Atualizados pela Estrelinha a cada frame físico.
var is_in_star_aura: bool = false
var repel_active: bool = false
var repel_from: Vector3 = Vector3.ZERO

var _max_darkness: float
var _lit_timer: float = 0.0
var _target: Node3D


func _ready() -> void:
	add_to_group("sombra")
	_max_darkness = darkness


func receive_light(amount: float) -> void:
	darkness -= amount
	_lit_timer = 0.15
	scale = Vector3.ONE * lerpf(0.4, 1.0, clampf(darkness / _max_darkness, 0.0, 1.0))
	if darkness <= 0.0:
		_dissipate()


func _physics_process(delta: float) -> void:
	_lit_timer -= delta
	if _target == null:
		_target = get_tree().get_first_node_in_group("sonhador") as Node3D

	var gravity: Vector3 = get_gravity()
	if gravity.length_squared() > 0.001:
		up_direction = -gravity.normalized()
	var up: Vector3 = up_direction

	var lateral := Vector3.ZERO
	if _target:
		var to: Vector3 = _target.global_position - global_position
		to -= up * to.dot(up)
		if to.length_squared() > 0.01:
			lateral = to.normalized() * chase_speed * (lit_slowdown if _lit_timer > 0.0 else 1.0)

	if repel_active:
		var away: Vector3 = global_position - repel_from
		away -= up * away.dot(up)
		if away.length_squared() > 0.001:
			lateral = away.normalized() * chase_speed * 1.2
	is_in_star_aura = false
	repel_active = false

	var vertical: float = velocity.dot(up) - gravity.length() * delta
	velocity = lateral + up * vertical
	move_and_slide()


func _dissipate() -> void:
	dissipated.emit()
	# TODO: explosão de estrelinhas de feltro + o mundo recupera a cor.
	if is_boss:
		GameState.completar_missao()
	queue_free()
