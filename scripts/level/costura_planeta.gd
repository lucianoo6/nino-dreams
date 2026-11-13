@tool
class_name CosturaPlaneta
extends MultiMeshInstance3D
## Costura em ponto cruz (X) dando a volta num Planetoid, como as emendas bordadas do conceito.
## Escolha o planeta e o eixo (normal do "equador" da costura).

const LINHA := preload("res://materials/pbr/linha_dourada.tres")

@export var planeta: NodePath:
	set(v):
		planeta = v
		_refazer()
@export var eixo: Vector3 = Vector3(0.3, 1, 0.1):
	set(v):
		eixo = v
		_refazer()
@export var pontos: int = 70:
	set(v):
		pontos = v
		_refazer()
## Fração da volta (1 = volta inteira).
@export_range(0.05, 1.0) var arco: float = 1.0:
	set(v):
		arco = v
		_refazer()
@export var cor: Color = Color(0.55, 0.35, 0.2):
	set(v):
		cor = v
		_refazer()


func _ready() -> void:
	_refazer()


func _refazer() -> void:
	if not is_inside_tree() or planeta.is_empty():
		return
	var p := get_node_or_null(planeta) as Planetoid
	if p == null:
		return
	top_level = true
	global_transform = Transform3D.IDENTITY
	var n: Vector3 = eixo.normalized()
	var a: Vector3 = (Vector3.FORWARD if absf(n.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).cross(n).normalized()
	var b: Vector3 = n.cross(a)
	var ponto := CapsuleMesh.new()
	ponto.radius = 0.035
	ponto.height = 0.42
	ponto.radial_segments = 8
	ponto.rings = 2
	var mat := LINHA.duplicate() as StandardMaterial3D
	mat.albedo_color = cor
	ponto.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = ponto
	mm.instance_count = pontos * 2
	for i in pontos:
		var t: float = TAU * arco * i / pontos
		var dir: Vector3 = (a * cos(t) + b * sin(t)).normalized()
		var pos: Vector3 = p.ponto_na_superficie(dir, 0.02)
		var tang: Vector3 = (-a * sin(t) + b * cos(t)).normalized()
		for k in 2:  # as duas pernas do X
			var giro: float = deg_to_rad(40.0) * (1 if k == 0 else -1)
			var eixo_ponto: Vector3 = tang.rotated(dir, giro)
			var base_y: Vector3 = eixo_ponto
			var base_x: Vector3 = dir.cross(base_y).normalized()
			var base_z: Vector3 = base_x.cross(base_y).normalized()
			mm.set_instance_transform(i * 2 + k, Transform3D(Basis(base_x, base_y, base_z), pos))
	multimesh = mm
