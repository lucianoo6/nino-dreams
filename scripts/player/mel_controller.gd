class_name MelController
extends DreamerController
## MEL — a irmãzinha do Nino. Sozinha (IA) ela segue o irmão, mas é TODA distraída: para para brincar
## com o cenário (borboletas de feltro, botões soltos, poças de lantejoula…) e fica para trás.
## Às vezes a distração dela revela segredos. Nunca morre e nunca trava o progresso: se ficar longe
## demais, aparece de novo perto do Nino. No coop (drop-in), o jogador 2 assume o controle.

signal mood_changed(mood: Mood)

enum Mood { SEGUINDO, DISTRAIDA, VOLTANDO, COOP }

@export_group("IA")
@export var follow_distance: float = 2.2
@export var catch_up_distance: float = 7.0
@export var teleport_distance: float = 28.0
@export var distraction_search_radius: float = 9.0
@export var distraction_cooldown: Vector2 = Vector2(6.0, 15.0)
## Distância do Nino a partir da qual ela "se dá conta" e volta sozinha.
@export var snap_out_distance: float = 18.0

var estado: Mood = Mood.SEGUINDO
var player_controlled: bool:
	get:
		return estado == Mood.COOP

var _nino: DreamerController
var _distraction: Distraction
var _distraction_timer: float = 0.0
var _cooldown: float = 0.0
var _ai_jump: bool = false
var _ai_jump_held: bool = false


func _ready() -> void:
	super()
	remove_from_group("sonhador") # itens e sombras miram o Nino; a Mel tem grupo próprio
	add_to_group("mel")
	action_prefix = "p2_"
	_cooldown = randf_range(distraction_cooldown.x, distraction_cooldown.y)


func _physics_process(delta: float) -> void:
	if _nino == null:
		_nino = get_tree().get_first_node_in_group("sonhador") as DreamerController
	if not player_controlled and GameState.player_two_joined:
		_set_mood(Mood.COOP)
	elif player_controlled and not GameState.player_two_joined:
		_set_mood(Mood.SEGUINDO)

	if not player_controlled and _nino != null:
		_think_ai(delta)
	super(delta)
	_ai_jump = false


## Nino chama a Mel (C / Y): ela larga a brincadeira e corre até ele.
func chamar() -> void:
	if player_controlled:
		return
	_release_distraction()
	_set_mood(Mood.VOLTANDO)


func _think_ai(delta: float) -> void:
	var dist: float = global_position.distance_to(_nino.global_position)

	if dist > teleport_distance and not _nino.is_launching() and _nino.is_on_floor():
		# Ela "aparece" perto do irmão (TODO: puf de fiapos + risadinha).
		global_position = _nino.global_position + _nino.global_basis.z * 1.5 + _nino.up_direction * 0.5
		velocity = Vector3.ZERO
		_release_distraction()
		_set_mood(Mood.SEGUINDO)
		return

	match estado:
		Mood.SEGUINDO:
			_cooldown -= delta
			if _cooldown <= 0.0 and _try_find_distraction():
				_set_mood(Mood.DISTRAIDA)
		Mood.DISTRAIDA:
			if not is_instance_valid(_distraction):
				_distraction = null
				_set_mood(Mood.VOLTANDO)
			else:
				if global_position.distance_to(_distraction.global_position) < 1.2:
					_distraction_timer -= delta
				if _distraction_timer <= 0.0 or dist > snap_out_distance:
					_release_distraction()
					_set_mood(Mood.VOLTANDO)
		Mood.VOLTANDO:
			if dist < follow_distance * 1.5:
				_set_mood(Mood.SEGUINDO)

	# Pula junto quando o irmão pula (imitando ele — fofo e ajuda a atravessar).
	if estado != Mood.DISTRAIDA and not _nino.is_on_floor() and is_on_floor() and dist < 6.0 \
			and _nino.velocity.dot(_nino.up_direction) > 2.0:
		_ai_jump = true
	_ai_jump_held = not is_on_floor() and velocity.dot(up_direction) > 0.0


func _try_find_distraction() -> bool:
	var best: Distraction = null
	var best_dist: float = distraction_search_radius
	for n: Node in get_tree().get_nodes_in_group("distracao"):
		var dz := n as Distraction
		if dz == null or not dz.is_available():
			continue
		var dd: float = global_position.distance_to(dz.global_position)
		if dd < best_dist:
			best = dz
			best_dist = dd
	_cooldown = randf_range(distraction_cooldown.x, distraction_cooldown.y)
	if best == null:
		return false
	_distraction = best
	_distraction_timer = best.claim(self)
	return true


func _release_distraction() -> void:
	if is_instance_valid(_distraction):
		_distraction.release()
	_distraction = null


func _set_mood(m: Mood) -> void:
	if estado == m:
		return
	estado = m
	mood_changed.emit(m)


func _compute_wish(up: Vector3) -> Vector3:
	if player_controlled:
		return super(up)
	if _nino == null or GameState.cutscene:
		return Vector3.ZERO

	var distracted: bool = estado == Mood.DISTRAIDA and is_instance_valid(_distraction)
	var target: Vector3 = _distraction.global_position if distracted else _nino.global_position
	var to: Vector3 = target - global_position
	to -= up * to.dot(up)
	var dist: float = to.length()

	var stop_at: float = 0.8 if distracted else follow_distance
	if dist < stop_at:
		return Vector3.ZERO
	var speed01: float = 1.0 if (estado == Mood.VOLTANDO or dist > catch_up_distance) else 0.7
	return to / dist * speed01


## Brincando com a distração: pulinhos de alegria.
func get_animation_override() -> StringName:
	var base: StringName = super()
	if base != &"":
		return base
	if estado == Mood.DISTRAIDA and is_instance_valid(_distraction) \
			and global_position.distance_to(_distraction.global_position) < 1.5:
		return &"human_000030"
	return &""


func _read_jump_pressed() -> bool:
	return super() if player_controlled else _ai_jump


func _read_jump_held() -> bool:
	return super() if player_controlled else _ai_jump_held


func _read_spin_pressed() -> bool:
	return player_controlled and super()
