@tool
class_name AncoraPlaneta
extends Node3D
## Gruda os filhos na superfície de um Planetoid, em pé e virados para fora.
## Para posicionar coisas no level: escolha o planeta e a direção — sem calcular transform na mão.

@export var planeta: NodePath:
	set(v):
		planeta = v
		_aplicar()
## Direção (no mundo) a partir do centro do planeta. Não precisa estar normalizada.
@export var direcao: Vector3 = Vector3.UP:
	set(v):
		direcao = v
		_aplicar()
@export var elevacao: float = 0.0:
	set(v):
		elevacao = v
		_aplicar()
## Giro em torno do "para cima" local, em graus.
@export_range(-180.0, 180.0) var giro: float = 0.0:
	set(v):
		giro = v
		_aplicar()


func _ready() -> void:
	_aplicar()


func _aplicar() -> void:
	if not is_inside_tree() or planeta.is_empty() or direcao.length_squared() < 0.0001:
		return
	var p := get_node_or_null(planeta) as Planetoid
	if p == null:
		return
	var up: Vector3 = direcao.normalized()
	var ref: Vector3 = Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT
	var x: Vector3 = ref.cross(up).normalized()
	var z: Vector3 = x.cross(up).normalized()
	var b := Basis(x, up, z).orthonormalized()
	b = Basis(up, deg_to_rad(giro)) * b
	global_transform = Transform3D(b, p.ponto_na_superficie(up, elevacao))
