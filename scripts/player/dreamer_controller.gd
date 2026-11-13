class_name DreamerController
extends CharacterBody3D
## O sonhador (Nino). Movimento estilo "planetinhas": a gravidade vem das Area3D (gravity point)
## de cada planeta, e o personagem alinha o "para cima" com o oposto da gravidade.
## O mesmo controlador serve de base para a Mel (jogador 2 ou IA) — ver MelController.

@export_group("Movimento")
@export var move_speed: float = 7.0
@export var ground_accel: float = 45.0
@export var air_accel: float = 18.0
@export var turn_speed: float = 12.0

@export_group("Pulo")
@export var jump_velocity: float = 11.0
@export var low_jump_multiplier: float = 2.2
@export var coyote_time: float = 0.12
@export var jump_buffer: float = 0.12

@export_group("Rodopio")
## Giro no ar: um impulsinho para cima, uma vez por pulo. Deixa o controle "dançante".
@export var spin_boost: float = 5.0

@export_group("Gravidade")
@export var up_align_speed: float = 10.0

@export_group("Input")
## Câmera usada como referência de direção. Vazio = procura no grupo "camera_sonho".
@export var camera_rig_path: NodePath = ^"CameraRig"
## Prefixo das ações: "" = jogador 1 (Nino), "p2_" = jogador 2 (Mel).
@export var action_prefix: String = ""

var is_spinning: bool:
	get:
		return _spin_timer > 0.0

var _camera: DreamCamera
var _coyote: float = 0.0
var _jump_buffer_t: float = 0.0
var _spin_available: bool = true
var _spin_timer: float = 0.0


func _ready() -> void:
	add_to_group("sonhador")
	floor_snap_length = 0.4


func get_dream_camera() -> DreamCamera:
	if _camera == null:
		if not camera_rig_path.is_empty():
			_camera = get_node_or_null(camera_rig_path) as DreamCamera
		if _camera == null:
			_camera = get_tree().get_first_node_in_group("camera_sonho") as DreamCamera
	return _camera


func _physics_process(delta: float) -> void:
	var gravity: Vector3 = get_gravity()
	var g_len: float = gravity.length()

	# 1) Alinhar "para cima" com o oposto da gravidade do planeta atual.
	if g_len > 0.001:
		var target_up: Vector3 = -gravity / g_len
		var t: float = 1.0 - exp(-up_align_speed * delta)
		var new_up: Vector3 = up_direction.slerp(target_up, t)
		up_direction = new_up.normalized() if new_up.length_squared() > 0.0001 else target_up
	var up: Vector3 = up_direction

	# 2) Separar velocidade em vertical (ao longo do up) e lateral (no plano tangente).
	var vertical: float = velocity.dot(up)
	var lateral: Vector3 = velocity - up * vertical

	# 3) Direção desejada no plano tangente.
	var wish: Vector3 = _compute_wish(up)
	if wish.length_squared() > 1.0:
		wish = wish.normalized()

	var on_floor: bool = is_on_floor()
	lateral = lateral.move_toward(wish * move_speed, (ground_accel if on_floor else air_accel) * delta)

	# 4) Pulo com coyote time + buffer, e pulo curto ao soltar o botão.
	if on_floor:
		_coyote = coyote_time
		_spin_available = true
	else:
		_coyote -= delta

	if _read_jump_pressed():
		_jump_buffer_t = jump_buffer
	else:
		_jump_buffer_t -= delta

	if _jump_buffer_t > 0.0 and _coyote > 0.0:
		vertical = jump_velocity
		_jump_buffer_t = 0.0
		_coyote = 0.0
	else:
		var cut_jump: bool = vertical > 0.0 and not _read_jump_held()
		vertical -= g_len * delta * (low_jump_multiplier if cut_jump else 1.0)

	# 5) Rodopio.
	_spin_timer -= delta
	if _read_spin_pressed() and _spin_timer <= 0.0:
		_spin_timer = 0.35
		if not on_floor and _spin_available:
			vertical = maxf(vertical, spin_boost)
			_spin_available = false

	velocity = lateral + up * vertical
	move_and_slide()

	# 6) Orientar o corpo: em pé no planeta e virado para onde anda.
	_orient_body(up, wish, delta)


# ---- Input virtual: a Mel sobrescreve isto quando é controlada pela IA. ----

## Direção desejada no mundo (plano tangente). Padrão: analógico relativo à câmera.
func _compute_wish(up: Vector3) -> Vector3:
	var cam := get_dream_camera()
	if cam == null:
		return Vector3.ZERO
	var input: Vector2 = Input.get_vector(
		action_prefix + "move_left", action_prefix + "move_right",
		action_prefix + "move_forward", action_prefix + "move_back")
	var cb: Basis = cam.global_basis
	var cam_f: Vector3 = project_on_plane(-cb.z, up)
	var cam_r: Vector3 = project_on_plane(cb.x, up)
	return cam_r * input.x + cam_f * -input.y


func _read_jump_pressed() -> bool:
	return Input.is_action_just_pressed(action_prefix + "jump")


func _read_jump_held() -> bool:
	return Input.is_action_pressed(action_prefix + "jump")


func _read_spin_pressed() -> bool:
	return Input.is_action_just_pressed(action_prefix + "spin")


func _orient_body(up: Vector3, wish: Vector3, delta: float) -> void:
	var current: Basis = global_basis.orthonormalized()
	var target: Basis
	if wish.length_squared() > 0.01:
		target = Basis.looking_at(wish.normalized(), up)
	else:
		var fwd: Vector3 = project_on_plane(-current.z, up)
		if fwd.length_squared() < 0.001:
			fwd = project_on_plane(current.y, up)
		if fwd.length_squared() < 0.001:
			return
		target = Basis.looking_at(fwd, up)
	var t: float = 1.0 - exp(-turn_speed * delta)
	global_basis = current.slerp(target, t).orthonormalized()


static func project_on_plane(v: Vector3, normal: Vector3) -> Vector3:
	var p: Vector3 = v - normal * v.dot(normal)
	return p.normalized() if p.length_squared() > 0.0001 else Vector3.ZERO
