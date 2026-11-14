class_name ShadowCreature
extends CharacterBody3D
## Criatura/vilão de pesadelo feita de lã escura e fios soltos.
## Persegue o Nino; sob a Luna desacelera, encolhe e por fim se desfaz em estrelinhas.
## A aura da Estrelinha (Mel) é zona segura: a sombra é empurrada para fora.

signal dissipated
## Fração de escuridão que resta (1 = cheia, 0 = desfeita) — usada na barra do chefe.
signal escuridao_mudou(fracao: float)

@export var darkness: float = 3.0
@export var chase_speed: float = 3.5
@export var lit_slowdown: float = 0.2
@export var is_boss: bool = false
## Nome mostrado na barra do chefe.
@export var nome_chefe: String = ""
## Distância em que a sombra "encosta" no Nino (dá um susto e empurra).
@export var alcance_toque: float = 1.1

## Protegida por uma bolha de escuridão: a luz não faz efeito (ex.: chefe enquanto há soldados).
var escudo: bool = false

## Atualizados pela Estrelinha a cada frame físico.
var is_in_star_aura: bool = false
var repel_active: bool = false
var repel_from: Vector3 = Vector3.ZERO

var _max_darkness: float
var _lit_timer: float = 0.0
var _target: Node3D


func _ready() -> void:
	add_to_group("sombra")
	if is_boss:
		add_to_group("chefe")
	_max_darkness = darkness


func receive_light(amount: float) -> void:
	if is_queued_for_deletion():
		return
	if escudo:
		_lit_timer = 0.15
		return
	darkness -= amount
	escuridao_mudou.emit(clampf(darkness / _max_darkness, 0.0, 1.0))
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
	_orientar(up, lateral, delta)

	if _target and global_position.distance_to(_target.global_position) < alcance_toque * maxf(scale.x, 0.6):
		var d := _target as DreamerController
		if d:
			d.levar_susto(global_position)


## Fica em pé no planeta e virada para onde anda (o visual "olha" para -Z).
func _orientar(up: Vector3, lateral: Vector3, delta: float) -> void:
	var frente: Vector3 = -global_basis.z
	if lateral.length_squared() > 0.01:
		frente = lateral.normalized()
	frente -= up * frente.dot(up)
	if frente.length_squared() < 0.0001:
		return
	var alvo := Basis.looking_at(frente.normalized(), up)
	var s: Vector3 = global_basis.get_scale()
	var atual := global_basis.orthonormalized()
	global_basis = atual.slerp(alvo, 1.0 - exp(-8.0 * delta)).orthonormalized().scaled(s)


func fracao() -> float:
	return clampf(darkness / _max_darkness, 0.0, 1.0)


func _dissipate() -> void:
	dissipated.emit()
	Efeitos.estrelinhas(get_parent(), global_position + up_direction * 0.6)
	if is_boss:
		GameState.completar_missao()
	queue_free()
