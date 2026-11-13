class_name DreamCamera
extends Node3D
## Câmera que segue o sonhador e se alinha suavemente com o "para cima" dele,
## mantendo o yaw controlado pelo jogador (Q/E, analógico direito ou mouse).
## Filhos esperados: SpringArm3D -> Camera3D.

@export var follow_speed: float = 10.0
@export var align_speed: float = 4.0
@export var yaw_speed: float = 2.5
@export var mouse_sensitivity: float = 0.004

@export_group("Intro das nuvens")
## Ao chegar da estante, a câmera começa lá no alto, entre as nuvens, e desce até o Nino.
@export var intro_distancia: float = 42.0
@export var intro_inclinacao_graus: float = -72.0
@export var intro_duracao: float = 3.5

var _target: CharacterBody3D
var _mouse_yaw: float = 0.0
var _arm: SpringArm3D
var _comprimento_padrao: float = 6.5
var _inclinacao_padrao: float = -0.436
var _zona: CameraZone
var _arm_tween: Tween


func _ready() -> void:
	_target = get_parent() as CharacterBody3D
	add_to_group("camera_sonho")
	top_level = true
	global_transform = _target.global_transform
	_arm = get_node_or_null("SpringArm3D") as SpringArm3D
	if _arm:
		_comprimento_padrao = _arm.spring_length
		_inclinacao_padrao = _arm.rotation.x
	if GameState.consumir_intro_das_nuvens():
		_intro_das_nuvens()


func _intro_das_nuvens() -> void:
	var arm := get_node_or_null("SpringArm3D") as SpringArm3D
	if arm == null:
		Transicao.descobrir()
		return
	GameState.cutscene = true
	var comprimento_final: float = arm.spring_length
	var inclinacao_final: float = arm.rotation.x
	arm.spring_length = intro_distancia
	arm.rotation.x = deg_to_rad(intro_inclinacao_graus)
	Transicao.definir(1.0)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(arm, "spring_length", comprimento_final, intro_duracao) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(arm, "rotation:x", inclinacao_final, intro_duracao) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	Transicao.descobrir(intro_duracao * 0.75)
	tw.finished.connect(func() -> void: GameState.cutscene = false)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse_yaw -= (event as InputEventMouseMotion).relative.x * mouse_sensitivity
	elif event is InputEventMouseButton and event.is_pressed() \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	global_position = global_position.lerp(_target.global_position, 1.0 - exp(-follow_speed * delta))

	# Alinha o eixo Y da câmera com o up do sonhador pelo menor arco (preserva o yaw).
	var b: Basis = global_basis.orthonormalized()
	var up: Vector3 = _target.up_direction
	if b.y.dot(up) > -0.999:
		var arc := Quaternion(b.y.normalized(), up.normalized())
		var aligned: Basis = (Basis(arc) * b).orthonormalized()
		b = b.slerp(aligned, 1.0 - exp(-align_speed * delta)).orthonormalized()

	var yaw: float = Input.get_axis("camera_right", "camera_left") * yaw_speed * delta + _mouse_yaw
	_mouse_yaw = 0.0
	if absf(yaw) > 0.00001:
		b = (Basis(b.y.normalized(), yaw) * b).orthonormalized()

	# Zona guiada: gira devagar para mostrar o caminho (o jogador ainda pode girar por cima).
	var alvo: Node3D = _zona.alvo() if _zona else null
	if alvo:
		var desejado: Vector3 = DreamerController.project_on_plane(alvo.global_position - _target.global_position, up)
		var atual: Vector3 = DreamerController.project_on_plane(-b.z, up)
		if desejado != Vector3.ZERO and atual != Vector3.ZERO:
			var ang: float = atual.signed_angle_to(desejado, up)
			b = (Basis(up.normalized(), ang * (1.0 - exp(-_zona.forca_giro * delta))) * b).orthonormalized()

	global_basis = b


func aplicar_zona(zona: CameraZone) -> void:
	_zona = zona
	_animar_braco(zona.comprimento, deg_to_rad(zona.inclinacao_graus))


func limpar_zona(zona: CameraZone) -> void:
	if _zona != zona:
		return
	_zona = null
	_animar_braco(_comprimento_padrao, _inclinacao_padrao)


func _animar_braco(comprimento: float, inclinacao: float) -> void:
	if _arm == null or GameState.cutscene:
		return
	if _arm_tween:
		_arm_tween.kill()
	_arm_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_arm_tween.tween_property(_arm, "spring_length", comprimento, 1.0)
	_arm_tween.tween_property(_arm, "rotation:x", inclinacao, 1.0)
