@tool
class_name FioEsticado
extends Node3D
## Linha de costura esticada entre pontos (com barriga/arco), opcionalmente com luzinhas penduradas.
## Usos: a linha do carretel até o destino do lançamento; varal de luzinhas na trilha de cartas.

const LINHA := preload("res://materials/pbr/linha_vermelha.tres")

@export var pontos: Array[NodePath] = []:
	set(v):
		pontos = v
		_refazer()
## Quanto a linha "pende" (negativo) ou arqueia para cima (positivo), em fração do comprimento de cada trecho.
@export var curvatura: float = -0.08:
	set(v):
		curvatura = v
		_refazer()
@export var raio: float = 0.04:
	set(v):
		raio = v
		_refazer()
@export var material: Material = LINHA:
	set(v):
		material = v
		_refazer()
@export var luzinhas: bool = false:
	set(v):
		luzinhas = v
		_refazer()
@export var espacamento_luzes: float = 1.2:
	set(v):
		espacamento_luzes = v
		_refazer()
@export var cor_luz: Color = Color(1.0, 0.8, 0.45):
	set(v):
		cor_luz = v
		_refazer()

var _gerado: Node3D


func _ready() -> void:
	_refazer.call_deferred()


func _refazer() -> void:
	if not is_inside_tree():
		return
	if _gerado:
		_gerado.queue_free()
	_gerado = Node3D.new()
	add_child(_gerado, false, Node.INTERNAL_MODE_FRONT)
	_gerado.top_level = true
	_gerado.global_transform = Transform3D.IDENTITY
	var nos: Array[Vector3] = []
	for np: NodePath in pontos:
		var n := get_node_or_null(np) as Node3D
		if n:
			nos.append(n.global_position)
	if nos.size() < 2:
		return
	var amostras: Array[Vector3] = []
	for i in nos.size() - 1:
		var a: Vector3 = nos[i]
		var b: Vector3 = nos[i + 1]
		var comp: float = a.distance_to(b)
		for k in 16:
			var t: float = k / 16.0
			amostras.append(a.lerp(b, t) + Vector3.UP * curvatura * comp * 4.0 * t * (1.0 - t))
	amostras.append(nos[nos.size() - 1])
	var raios: Array[float] = []
	for _p in amostras:
		raios.append(raio)
	var mi := MeshInstance3D.new()
	mi.mesh = PropProcedural._tubo(amostras, raios, 1.0, 6, 1)
	mi.material_override = material
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_gerado.add_child(mi)
	if luzinhas:
		_pendurar_luzes(amostras)


func _pendurar_luzes(amostras: Array[Vector3]) -> void:
	var lampada := SphereMesh.new()
	lampada.radius = 0.09
	lampada.height = 0.16
	var mat := StandardMaterial3D.new()
	mat.albedo_color = cor_luz
	mat.emission_enabled = true
	mat.emission = cor_luz
	mat.emission_energy_multiplier = 4.0
	lampada.material = mat
	var andado: float = 0.0
	var proxima: float = espacamento_luzes * 0.5
	for i in amostras.size() - 1:
		var seg: float = amostras[i].distance_to(amostras[i + 1])
		while proxima <= andado + seg:
			var t: float = (proxima - andado) / seg
			var m := MeshInstance3D.new()
			m.mesh = lampada
			m.position = amostras[i].lerp(amostras[i + 1], t) + Vector3.DOWN * 0.12
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_gerado.add_child(m)
			proxima += espacamento_luzes
		andado += seg
