class_name LivroNasMaos
extends Node3D
## Mantém um livro aberto entre as mãos do personagem, com as páginas viradas para o rosto dele.
## Funciona com qualquer animação (sentado, lendo em voz alta...): segue os ossos das mãos e da cabeça.
## Coloque como filho do personagem; os ossos são procurados no Skeleton3D dele.

@export var osso_mao_esq: StringName = &"LeftHand"
@export var osso_mao_dir: StringName = &"RightHand"
@export var osso_cabeca: StringName = &"Head"
## Deslocamento para cima (m) a partir do ponto entre as mãos.
@export var elevacao: float = 0.07
## 0 = livro deitado no colo; 1 = livro em pé. Valores no meio = como se segura para ler.
@export_range(0.0, 1.0) var inclinacao: float = 0.65

var _esq: Skeleton3D
var _i_esq: int = -1
var _i_dir: int = -1
var _i_cab: int = -1


func _ready() -> void:
	for n: Node in get_parent().find_children("*", "Skeleton3D", true, false):
		_esq = n as Skeleton3D
		break
	if _esq:
		_i_esq = _esq.find_bone(osso_mao_esq)
		_i_dir = _esq.find_bone(osso_mao_dir)
		_i_cab = _esq.find_bone(osso_cabeca)
	top_level = true


func _process(_delta: float) -> void:
	if _esq == null or _i_esq < 0 or _i_dir < 0 or _i_cab < 0:
		return
	var t: Transform3D = _esq.global_transform
	var mao_e: Vector3 = t * _esq.get_bone_global_pose(_i_esq).origin
	var mao_d: Vector3 = t * _esq.get_bone_global_pose(_i_dir).origin
	var cabeca: Vector3 = t * _esq.get_bone_global_pose(_i_cab).origin
	var meio: Vector3 = (mao_e + mao_d) / 2.0 + Vector3.UP * elevacao
	var para_rosto: Vector3 = (cabeca - meio).normalized()
	var horizontal: Vector3 = Vector3(para_rosto.x, 0.0, para_rosto.z).normalized()
	var normal: Vector3 = para_rosto.lerp(horizontal, inclinacao).normalized()  # páginas viradas para o rosto
	var lado: Vector3 = (mao_d - mao_e)
	lado = (lado - normal * lado.dot(normal)).normalized()
	if lado.length_squared() < 0.001:
		return
	var frente: Vector3 = lado.cross(normal).normalized()
	global_transform = Transform3D(Basis(lado, normal, frente), meio)
