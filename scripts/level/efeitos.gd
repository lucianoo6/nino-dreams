class_name Efeitos
extends RefCounted
## Partículas de um tiro só, criadas por código (sem cena): fiapos de feltro ao pousar,
## estrelinhas ao pegar um botão. Cada uma se apaga sozinha.

static func fiapos(pai: Node, pos: Vector3, normal: Vector3, cor: Color = Color(0.75, 0.9, 0.6)) -> void:
	var p := _base(18, 0.7, 0.9)
	var proc := p.process_material as ParticleProcessMaterial
	proc.direction = normal
	proc.spread = 70.0
	proc.initial_velocity_min = 1.0
	proc.initial_velocity_max = 2.2
	proc.gravity = -normal * 4.0
	proc.damping_min = 2.0
	proc.damping_max = 3.0
	proc.color = cor
	_soltar(pai, p, pos)


static func estrelinhas(pai: Node, pos: Vector3) -> void:
	var p := _base(40, 1.1, 1.0)
	var proc := p.process_material as ParticleProcessMaterial
	proc.direction = Vector3.UP
	proc.spread = 180.0
	proc.initial_velocity_min = 1.5
	proc.initial_velocity_max = 3.5
	proc.gravity = Vector3.ZERO
	proc.damping_min = 2.5
	proc.damping_max = 4.0
	proc.color = Color(1.0, 0.85, 0.4) * 2.0
	(p.material_override as StandardMaterial3D).blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_soltar(pai, p, pos)


static func _base(qtd: int, vida: float, explosao: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = qtd
	p.lifetime = vida
	p.one_shot = true
	p.explosiveness = explosao
	p.local_coords = false
	var proc := ParticleProcessMaterial.new()
	proc.scale_min = 0.5
	proc.scale_max = 1.2
	var curva := Curve.new()
	curva.add_point(Vector2(0, 1))
	curva.add_point(Vector2(1, 0))
	var tc := CurveTexture.new()
	tc.curve = curva
	proc.scale_curve = tc
	p.process_material = proc
	var quad := QuadMesh.new()
	quad.size = Vector2(0.08, 0.08)
	p.draw_pass_1 = quad
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	var ponto := GradientTexture2D.new()
	ponto.fill = GradientTexture2D.FILL_RADIAL
	ponto.fill_from = Vector2(0.5, 0.5)
	ponto.fill_to = Vector2(1.0, 0.5)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	ponto.gradient = g
	mat.albedo_texture = ponto
	p.material_override = mat
	return p


static func _soltar(pai: Node, p: GPUParticles3D, pos: Vector3) -> void:
	if pai == null:
		return
	pai.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)
