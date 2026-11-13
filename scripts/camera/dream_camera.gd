class_name DreamCamera
extends Node3D
## Câmera que segue o sonhador e se alinha suavemente com o "para cima" dele,
## mantendo o yaw controlado pelo jogador (Q/E, analógico direito ou mouse).
## Filhos esperados: SpringArm3D -> Camera3D.

@export var follow_speed: float = 10.0
@export var align_speed: float = 4.0
@export var yaw_speed: float = 2.5
@export var mouse_sensitivity: float = 0.004

var _target: CharacterBody3D
var _mouse_yaw: float = 0.0


func _ready() -> void:
	_target = get_parent() as CharacterBody3D
	add_to_group("camera_sonho")
	top_level = true
	global_transform = _target.global_transform


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

	global_basis = b
