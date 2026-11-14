@tool
class_name CenarioRecortes
extends Node3D
## Fundo de TEATRINHO: anéis de morros recortados em feltro, em camadas (como cenário de papelão de
## teatro de bonecos), com contorno costurado, pontinhos de costura e arvorezinhas-pirulito de recorte.
## As camadas de trás ficam mais claras e azuladas (perspectiva aérea). Tira o "horizonte vazio de engine".

const TEXTURA := preload("res://assets/materiais/feltro/albedo.png")
const NORMAL := preload("res://assets/materiais/feltro/normal.png")

@export var raios: PackedFloat32Array = PackedFloat32Array([60.0, 85.0, 115.0]):
	set(v):
		raios = v
		_refazer()
@export var alturas: PackedFloat32Array = PackedFloat32Array([9.0, 16.0, 26.0]):
	set(v):
		alturas = v
		_refazer()
@export var cores: PackedColorArray = PackedColorArray([Color(0.42, 0.66, 0.38), Color(0.5, 0.66, 0.62),
		Color(0.68, 0.72, 0.85)]):
	set(v):
		cores = v
		_refazer()
## Altura da base (onde os recortes "entram no chão").
@export var base_y: float = -12.0:
	set(v):
		base_y = v
		_refazer()
@export var semente: int = 3:
	set(v):
		semente = v
		_refazer()
@export var arvores: bool = true:
	set(v):
		arvores = v
		_refazer()


func _ready() -> void:
	_refazer()


func _refazer() -> void:
	if not is_inside_tree():
		return
	for f: Node in get_children():
		f.queue_free()
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	for i in raios.size():
		var cor: Color = cores[mini(i, cores.size() - 1)]
		var fase: float = rng.randf() * 100.0
		var r: float = raios[i]
		var h: float = alturas[mini(i, alturas.size() - 1)]
		_anel(r + 0.35, h, fase, cor.darkened(0.35), 0.45)  # contorno (fica atrás, um pouco mais alto)
		_anel(r, h, fase, cor, 0.0)
		_costura(r - 0.05, h, fase, cor.lightened(0.55))
		if arvores and i < 2:
			_arvorezinhas(r - 0.4, h, fase, cor, rng)


## Altura do morro num ângulo (soma de senos irregulares = colinas fofas).
func _morro(ang: float, h: float, fase: float) -> float:
	return h * (0.55 + 0.25 * sin(ang * 3.0 + fase) + 0.15 * sin(ang * 7.0 + fase * 1.7)
		+ 0.08 * sin(ang * 13.0 + fase * 0.3))


func _material(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.albedo_texture = TEXTURA
	m.normal_enabled = true
	m.normal_texture = NORMAL
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.12, 0.12, 0.12)
	m.roughness = 0.95
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.rim_enabled = true
	m.rim = 0.4
	return m


func _anel(r: float, h: float, fase: float, cor: Color, extra: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = 220
	for i in n:
		var a0: float = TAU * i / n
		var a1: float = TAU * (i + 1) / n
		var p0 := Vector3(cos(a0) * r, base_y, sin(a0) * r)
		var p1 := Vector3(cos(a1) * r, base_y, sin(a1) * r)
		var t0 := Vector3(p0.x, _morro(a0, h, fase) + extra, p0.z)
		var t1 := Vector3(p1.x, _morro(a1, h, fase) + extra, p1.z)
		var normal := -Vector3(cos(a0), 0, sin(a0))
		for v: Vector3 in [p0, t0, p1, p1, t0, t1]:
			st.set_normal(normal)
			st.add_vertex(v)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _material(cor)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## Pontinhos de costura acompanhando a borda de cima.
func _costura(r: float, h: float, fase: float, cor: Color) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var ponto := BoxMesh.new()
	ponto.size = Vector3(0.9, 0.18, 0.1)
	mm.mesh = ponto
	var n: int = int(TAU * r / 1.6)
	mm.instance_count = n
	for i in n:
		var a: float = TAU * i / n
		var y: float = _morro(a, h, fase) - 0.45
		var a2: float = a + 0.004
		var dy: float = _morro(a2, h, fase) - 0.45 - y
		var tang := Vector3(-sin(a), 0, cos(a)) * (r * 0.004)
		tang.y = dy
		var x: Vector3 = tang.normalized()
		var z: Vector3 = -Vector3(cos(a), 0, sin(a))
		var y_ax: Vector3 = z.cross(x).normalized()
		mm.set_instance_transform(i, Transform3D(Basis(x, y_ax, z), Vector3(cos(a) * r, y, sin(a) * r)))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.9
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## Arvorezinhas-pirulito de recorte (copa redonda de feltro num palito) em cima dos morros.
func _arvorezinhas(r: float, h: float, fase: float, cor: Color, rng: RandomNumberGenerator) -> void:
	var tronco := _material(Color(0.45, 0.3, 0.2))
	for i in 26:
		var a: float = rng.randf() * TAU
		var y: float = _morro(a, h, fase)
		var arv := Node3D.new()
		arv.position = Vector3(cos(a) * r, y - 0.5, sin(a) * r)
		arv.rotation.y = -a + PI / 2.0
		add_child(arv)
		var alt: float = rng.randf_range(2.0, 4.5)
		var palito := BoxMesh.new()
		palito.size = Vector3(0.35, alt, 0.12)
		var p := MeshInstance3D.new()
		p.mesh = palito
		p.position.y = alt / 2.0
		p.material_override = tronco
		arv.add_child(p)
		var copa := CylinderMesh.new()
		var rc: float = rng.randf_range(1.3, 2.4)
		copa.top_radius = rc
		copa.bottom_radius = rc
		copa.height = 0.15
		var c := MeshInstance3D.new()
		c.mesh = copa
		c.rotation.x = PI / 2.0
		c.position.y = alt + rc * 0.8
		c.material_override = _material(cor.lerp(Color(0.3, 0.5, 0.25), rng.randf() * 0.6).lightened(rng.randf() * 0.15))
		arv.add_child(c)
