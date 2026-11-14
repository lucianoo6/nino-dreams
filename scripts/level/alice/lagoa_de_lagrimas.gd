extends Fase
## Alice, Capítulo 2 — A Lagoa de Lágrimas.
## A Alice gigante chorou tanto que virou uma lagoa (de TULE!). Ela continua chorando lá no horizonte,
## e lágrimas enormes caem do céu: uma sombra na água avisa onde, e o respingo empurra quem estiver perto.
## Caminho: ilha inicial → luvinhas brancas e o leque boiando → ilha do Rato → trecho a nado
## (garrafa BEBA-ME e xícara-barquinho para descansar) → ilha do lampião → botões gigantes →
## praia onde os bichos esperam; o Dodô é a saída ("uma Corrida em Comitê!").

const SHADER_AGUA := preload("res://shaders/lagoa_tule.gdshader")
const FONTE := preload("res://assets/fonts/Fredoka-Bold.woff2")
const M_GRAMA := preload("res://materials/pbr/feltro_verde.tres")
const M_AREIA := preload("res://materials/pbr/feltro_creme.tres")
const M_TERRA := preload("res://materials/pbr/cotele_marrom.tres")
const M_LUVA := preload("res://materials/pbr/la_trico_creme.tres")
const M_PAPEL := preload("res://materials/pbr/papel.tres")
const M_MADEIRA := preload("res://materials/pbr/madeira_verniz.tres")
const M_VIDRO := preload("res://materials/pbr/vidro_claro.tres")
const M_OURO := preload("res://materials/pbr/linha_dourada.tres")
const M_FITA := preload("res://materials/pbr/veludo_vermelho.tres")
const SOM_SPLASH := preload("res://assets/audio/sfx/pouso_feltro.mp3")

## Modelos opcionais (Hyper3D); se ainda não existirem, a fase funciona sem eles.
const CAMINHO_RATO := "res://assets/models/personagens/rato.glb"
const CAMINHO_ALICE := "res://assets/models/personagens/alice_gigante.glb"

## Onde as lágrimas podem cair (faixa do trecho a nado).
const LAGRIMAS_Z := Vector2(26.0, 70.0)

var _boiando: Array[Dictionary] = []  # {no, base, fase, amplitude}
var _tempo: float = 0.0
var _relogio_lagrima: float = 2.0


func _ready() -> void:
	_gravidade()
	_lagoa()
	_caminho()
	_praia()
	_alice_no_horizonte()
	super._ready()


func _physics_process(delta: float) -> void:
	_tempo += delta
	for b: Dictionary in _boiando:
		var n := b["no"] as Node3D
		var base: Vector3 = b["base"]
		var f: float = b["fase"]
		n.position = base + Vector3.UP * sin(_tempo * 1.3 + f) * float(b["amplitude"])
		n.rotation.z = sin(_tempo * 0.9 + f) * 0.04
	_relogio_lagrima -= delta
	if _relogio_lagrima <= 0.0:
		_relogio_lagrima = randf_range(1.2, 2.2)
		_lagrima()


# ---------------- base ----------------

func _gravidade() -> void:
	var a := Area3D.new()
	a.collision_layer = 0
	a.collision_mask = 6
	a.monitorable = false
	a.gravity_space_override = Area3D.SPACE_OVERRIDE_REPLACE
	a.gravity_direction = Vector3.DOWN
	a.gravity = 25.0
	a.position = Vector3(0, 20, 50)
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(220, 80, 260)
	c.shape = b
	a.add_child(c)
	add_child(a)


func _lagoa() -> void:
	var agua := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(220, 260)
	pm.subdivide_width = 110
	pm.subdivide_depth = 130
	agua.mesh = pm
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_AGUA
	agua.material_override = mat
	agua.position = Vector3(0, 0, 50)
	agua.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(agua)
	var zona := ZonaAgua.new()
	zona.tamanho = Vector3(220, 8, 260)
	zona.position = Vector3(0, -4, 50)
	add_child(zona)
	# fundo de feltro (para não "afundar" para sempre)
	_caixa_solida(Vector3(0, -7, 50), Vector3(220, 1, 260), M_AREIA)


func _caixa_solida(pos: Vector3, tamanho: Vector3, mat: Material) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.position = pos
	add_child(corpo)
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tamanho
	m.mesh = bm
	m.material_override = mat
	corpo.add_child(m)
	var c := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = tamanho
	c.shape = s
	corpo.add_child(c)
	return corpo


func _malha(pai: Node3D, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.position = pos
	m.material_override = mat
	pai.add_child(m)
	return m


## Ilhota de feltro: lateral de terra fofa, topo de grama, florzinhas.
func _ilha(pos: Vector3, raio: float, semente: int) -> StaticBody3D:
	var ilha := StaticBody3D.new()
	ilha.position = pos
	add_child(ilha)
	var lado := CylinderMesh.new()
	lado.top_radius = raio
	lado.bottom_radius = raio * 1.2
	lado.height = 4.0
	_malha(ilha, lado, Vector3(0, -2.0, 0), M_TERRA)
	var topo := CylinderMesh.new()
	topo.top_radius = raio - 0.05
	topo.bottom_radius = raio + 0.08
	topo.height = 0.25
	_malha(ilha, topo, Vector3(0, 0.0, 0), M_GRAMA)
	var c := CollisionShape3D.new()
	var s := CylinderShape3D.new()
	s.radius = raio
	s.height = 4.2
	c.shape = s
	c.position.y = -1.98
	ilha.add_child(c)
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	for i in int(raio * 2.5):
		var ang: float = rng.randf() * TAU
		var r: float = rng.randf_range(0.6, raio - 0.5)
		var flor := PropProcedural.new()
		flor.tipo = PropProcedural.Tipo.FLOR
		flor.tamanho = rng.randf_range(0.35, 0.6)
		flor.com_colisao = false
		flor.cor = [Color(1, 0.6, 0.7), Color(1, 0.9, 0.4), Color(0.75, 0.65, 1.0), Color(1, 1, 1)][i % 4]
		flor.semente = semente * 10 + i
		flor.position = Vector3(cos(ang) * r, 0.12, sin(ang) * r)
		ilha.add_child(flor)
	return ilha


## Coisa boiando onde dá para pisar (sobe e desce com a água).
func _boia(pos: Vector3, amplitude: float = 0.12) -> AnimatableBody3D:
	var corpo := AnimatableBody3D.new()
	corpo.position = pos
	corpo.sync_to_physics = true
	add_child(corpo)
	_boiando.append({"no": corpo, "base": pos, "fase": randf() * TAU, "amplitude": amplitude})
	return corpo


func _forma_caixa(corpo: CollisionObject3D, tamanho: Vector3, pos: Vector3 = Vector3.ZERO) -> void:
	var c := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = tamanho
	c.shape = s
	c.position = pos
	corpo.add_child(c)


# ---------------- o caminho ----------------

func _caminho() -> void:
	_ilha(Vector3(0, 0.55, 0), 5.0, 1)
	var pt: bool = MenuEstanteUI._pt()
	_placa("Atravesse a lagoa até a margem!" if pt else "Cross the pool to the shore!", Vector3(-2.5, 3.2, 3.5))
	# as luvinhas brancas que o Coelho deixou cair
	_luva(Vector3(2.0, 0.15, 9.0), 0.4)
	_luva(Vector3(-1.2, 0.15, 13.0), -0.5)
	# o leque (foi ele que fez a Alice encolher!)
	_leque(Vector3(1.8, 0.2, 18.0))
	# ilha do Rato
	_ilha(Vector3(-3.0, 0.7, 25.5), 4.0, 2)
	_rato(Vector3(-3.6, 0.82, 26.5))
	# trecho a nado, com lugares para descansar
	_garrafa(Vector3(3.5, 0.2, 35.0))
	_xicara_barco(Vector3(-2.5, -0.35, 42.5))
	_placa("Cuidado com as lágrimas! ☂" if pt else "Watch out for the tears! ☂", Vector3(-3.0, 3.6, 29.0))
	# ilha do lampião
	_ilha(Vector3(2.0, 0.7, 52.0), 4.5, 3)
	_lampiao(Vector3(3.2, 0.82, 53.0))
	# botões gigantes boiando como vitórias-régias
	var cores: Array[Color] = [Color(1, 0.8, 0.3), Color(0.95, 0.4, 0.45), Color(0.4, 0.65, 1.0)]
	for i in 3:
		var b := _boia(Vector3(-1.0 + i * 1.6, 0.05, 59.0 + i * 4.2), 0.08)
		var botao := PropProcedural.new()
		botao.tipo = PropProcedural.Tipo.BOTAO
		botao.tamanho = 1.5
		botao.cor = cores[i]
		botao.com_colisao = false
		b.add_child(botao)
		var c := CollisionShape3D.new()
		var cs := CylinderShape3D.new()
		cs.radius = 1.45
		cs.height = 0.3
		c.shape = cs
		b.add_child(c)


func _luva(pos: Vector3, giro: float) -> void:
	var b := _boia(pos)
	b.rotation.y = giro
	_forma_caixa(b, Vector3(2.0, 0.45, 2.6))
	var palma := BoxMesh.new()
	palma.size = Vector3(2.0, 0.4, 2.0)
	_malha(b, palma, Vector3(0, 0, 0.3), M_LUVA)
	for k in 4:
		var dedo := CapsuleMesh.new()
		dedo.radius = 0.22
		dedo.height = 1.2
		var d := _malha(b, dedo, Vector3(-0.72 + k * 0.48, 0, -1.15), M_LUVA)
		d.rotation.x = PI / 2.0
	var polegar := CapsuleMesh.new()
	polegar.radius = 0.24
	polegar.height = 1.0
	var p := _malha(b, polegar, Vector3(1.15, 0, 0.2), M_LUVA)
	p.rotation = Vector3(PI / 2.0, 0.6, 0)


func _leque(pos: Vector3) -> void:
	var b := _boia(pos, 0.1)
	_forma_caixa(b, Vector3(4.6, 0.35, 2.4), Vector3(0, 0, -0.6))
	for k in 11:
		var vareta := BoxMesh.new()
		vareta.size = Vector3(0.5, 0.06, 2.6)
		var v := _malha(b, vareta, Vector3.ZERO, M_PAPEL if k % 2 == 0 else M_FITA)
		var ang: float = lerpf(-1.25, 1.25, k / 10.0)
		v.rotation.y = ang
		v.position = Vector3(sin(ang), 0.02 * (k % 2), -cos(ang)) * 1.2 + Vector3(0, 0.1, 0.6)
	var pino := CylinderMesh.new()
	pino.top_radius = 0.12
	pino.bottom_radius = 0.12
	pino.height = 0.3
	_malha(b, pino, Vector3(0, 0.15, 0.6), M_OURO)


func _garrafa(pos: Vector3) -> void:
	var b := _boia(pos, 0.1)
	var c := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 0.75
	cs.height = 3.4
	c.shape = cs
	c.rotation.z = PI / 2.0
	b.add_child(c)
	var corpo := CylinderMesh.new()
	corpo.top_radius = 0.75
	corpo.bottom_radius = 0.75
	corpo.height = 3.0
	var m := _malha(b, corpo, Vector3.ZERO, M_VIDRO)
	m.rotation.z = PI / 2.0
	var gargalo := CylinderMesh.new()
	gargalo.top_radius = 0.28
	gargalo.bottom_radius = 0.5
	gargalo.height = 0.8
	var g := _malha(b, gargalo, Vector3(-1.85, 0, 0), M_VIDRO)
	g.rotation.z = PI / 2.0
	var rotulo := CylinderMesh.new()
	rotulo.top_radius = 0.77
	rotulo.bottom_radius = 0.77
	rotulo.height = 1.2
	var r := _malha(b, rotulo, Vector3(0.2, 0, 0), M_PAPEL)
	r.rotation.z = PI / 2.0
	var l := Label3D.new()
	l.text = "BEBA-ME" if MenuEstanteUI._pt() else "DRINK ME"
	l.font = FONTE
	l.font_size = 64
	l.pixel_size = 0.005
	l.modulate = Color(0.55, 0.15, 0.2)
	l.outline_size = 0
	l.position = Vector3(0.2, 0.0, -0.8)
	l.rotation.y = PI
	l.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
	b.add_child(l)


func _xicara_barco(pos: Vector3) -> void:
	var b := _boia(pos, 0.1)
	var x := PropProcedural.new()
	x.tipo = PropProcedural.Tipo.XICARA
	x.tamanho = 2.4
	x.cor = Color(1, 0.75, 0.85)
	x.com_colisao = false
	b.add_child(x)
	# chão dentro da xícara (para ficar em pé "dentro" dela)
	var c := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 1.3
	cs.height = 0.9
	c.shape = cs
	c.position.y = 0.55
	b.add_child(c)


func _lampiao(pos: Vector3) -> void:
	var poste := CylinderMesh.new()
	poste.top_radius = 0.08
	poste.bottom_radius = 0.1
	poste.height = 2.4
	var n := Node3D.new()
	n.position = pos
	add_child(n)
	_malha(n, poste, Vector3(0, 1.2, 0), M_MADEIRA)
	var luz := OmniLight3D.new()
	luz.light_color = Color(1.0, 0.75, 0.45)
	luz.light_energy = 2.0
	luz.omni_range = 7.0
	luz.position.y = 2.5
	n.add_child(luz)
	var bulbo := SphereMesh.new()
	bulbo.radius = 0.25
	bulbo.height = 0.5
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.78, 0.45)
	mat.emission_energy_multiplier = 3.0
	_malha(n, bulbo, Vector3(0, 2.5, 0), mat)


func _placa(texto: String, pos: Vector3) -> void:
	var l := Label3D.new()
	l.text = texto
	l.font = FONTE
	l.font_size = 64
	l.pixel_size = 0.006
	l.modulate = Color(1.0, 0.95, 0.82)
	l.outline_modulate = Color(0.3, 0.2, 0.45)
	l.outline_size = 16
	l.position = pos
	l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	l.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
	add_child(l)


# ---------------- personagens ----------------

func _rato(pos: Vector3) -> void:
	var p := Personagem.new()
	if ResourceLoader.exists(CAMINHO_RATO):
		p.modelo = load(CAMINHO_RATO)
	else:
		_bicho_feltro(p, Color(0.6, 0.6, 0.65), Color(1, 0.7, 0.75), 0.55, true)
	p.escala = 0.5
	p.altura_pes = 0.48
	p.altura_balao = 1.4
	p.anim_parado = &"human_000093"
	p.anim_falando = &"human_000041"
	var pt: bool = MenuEstanteUI._pt()
	p.falas = PackedStringArray([
		"Ó Rato! Você sabe como sair desta lagoa?" if pt else "O Mouse! Do you know the way out of this pool?",
		"Nada de falar em gatos, por favor!" if pt else "No talking about cats, please!",
		"Nade até a margem — os outros bichos estão lá." if pt else "Swim to the shore — the other animals are there."])
	p.tom_voz = 520.0
	p.raio_conversa = 6.0
	p.position = pos
	add_child(p)


## Bichinho feito de bolinhas de feltro (corpo, cabeça, olhos de botão, bico ou orelhas).
func _bicho_feltro(pai: Node3D, cor: Color, cor_detalhe: Color, tamanho: float, rato: bool) -> Node3D:
	var corpo := Node3D.new()
	pai.add_child(corpo)
	var feltro := StandardMaterial3D.new()
	feltro.albedo_color = cor
	feltro.roughness = 0.95
	feltro.rim_enabled = true
	feltro.rim = 0.5
	var detalhe := StandardMaterial3D.new()
	detalhe.albedo_color = cor_detalhe
	detalhe.roughness = 0.9
	var preto := StandardMaterial3D.new()
	preto.albedo_color = Color(0.05, 0.05, 0.07)
	preto.roughness = 0.2
	var esf := SphereMesh.new()
	esf.radius = tamanho
	esf.height = tamanho * 2.1
	_malha(corpo, esf, Vector3(0, tamanho, 0), feltro)
	var cabeca := SphereMesh.new()
	cabeca.radius = tamanho * 0.62
	cabeca.height = tamanho * 1.24
	_malha(corpo, cabeca, Vector3(0, tamanho * 2.15, -tamanho * 0.15), feltro)
	for x: float in [-0.25, 0.25]:
		var olho := SphereMesh.new()
		olho.radius = tamanho * 0.1
		olho.height = tamanho * 0.2
		_malha(corpo, olho, Vector3(x * tamanho, tamanho * 2.3, -tamanho * 0.7), preto)
	if rato:
		for x: float in [-0.45, 0.45]:
			var orelha := CylinderMesh.new()
			orelha.top_radius = tamanho * 0.32
			orelha.bottom_radius = tamanho * 0.32
			orelha.height = tamanho * 0.06
			var o := _malha(corpo, orelha, Vector3(x * tamanho, tamanho * 2.75, -tamanho * 0.1), detalhe)
			o.rotation.x = PI / 2.0
	else:
		var bico := CylinderMesh.new()
		bico.top_radius = 0.0
		bico.bottom_radius = tamanho * 0.18
		bico.height = tamanho * 0.55
		var b := _malha(corpo, bico, Vector3(0, tamanho * 2.05, -tamanho * 0.85), detalhe)
		b.rotation.x = -PI / 2.0
		for x: float in [-1.0, 1.0]:
			var asa := SphereMesh.new()
			asa.radius = tamanho * 0.45
			asa.height = tamanho * 1.3
			var a := _malha(corpo, asa, Vector3(x * tamanho * 0.85, tamanho * 1.0, 0), feltro)
			a.scale = Vector3(0.35, 1.0, 1.0)
			a.rotation.z = x * 0.3
	return corpo


func _praia() -> void:
	_caixa_solida(Vector3(0, -0.6, 86.0), Vector3(80, 2.4, 26), M_AREIA)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for i in 10:
		var moita := PropProcedural.new()
		moita.tipo = PropProcedural.Tipo.MORRINHO
		moita.tamanho = rng.randf_range(1.0, 2.0)
		moita.cor = Color(0.4, 0.62, 0.35)
		moita.semente = i
		moita.position = Vector3(rng.randf_range(-30, 30), 0.6, rng.randf_range(88, 98))
		add_child(moita)
	var pt: bool = MenuEstanteUI._pt()
	# os bichos molhados esperando, em roda
	var bichos: Array = [
		["Pato" if pt else "Duck", Color(1, 0.95, 0.85), Color(1, 0.65, 0.2), 0.42, Vector3(-3.5, 0.6, 79.0)],
		["Papagaio" if pt else "Lory", Color(0.9, 0.25, 0.25), Color(1, 0.85, 0.3), 0.36, Vector3(3.0, 0.6, 79.5)],
		["Aguiazinha" if pt else "Eaglet", Color(0.6, 0.45, 0.3), Color(1, 0.8, 0.3), 0.32, Vector3(-1.5, 0.6, 82.5)],
	]
	for b: Array in bichos:
		var p := Personagem.new()
		p.position = b[4]
		p.rotation.y = PI
		p.altura_balao = float(b[3]) * 3.6
		p.falas = PackedStringArray(["Estou ensopado!" if pt else "I'm soaking wet!"])
		p.tom_voz = 380.0 + randf() * 200.0
		p.raio_conversa = 5.0
		p.intervalo = 9.0
		add_child(p)
		_bicho_feltro(p, b[1], b[2], b[3], false)
	# o Dodô: é a saída
	var dodo := Personagem.new()
	dodo.position = Vector3(0.5, 0.6, 81.0)
	dodo.rotation.y = PI
	dodo.altura_balao = 2.4
	dodo.falas = PackedStringArray([
		"A melhor maneira de se secar é uma Corrida em Comitê!" if pt
			else "The best thing to get us dry would be a Caucus-race!",
		"Venha! Todo mundo ganha!" if pt else "Come on! Everybody has won!"])
	dodo.tom_voz = 220.0
	dodo.raio_conversa = 8.0
	add_child(dodo)
	_bicho_feltro(dodo, Color(0.55, 0.55, 0.65), Color(0.95, 0.85, 0.5), 0.65, false)
	var saida := MissionItem.new()
	saida.is_exit = true
	saida.bob_height = 0.0
	saida.spin_speed = 0.0
	saida.collision_layer = 0
	saida.collision_mask = 6
	saida.position = Vector3(0.5, 1.4, 79.5)
	_forma_caixa(saida, Vector3(4.0, 2.5, 3.0))
	add_child(saida)
	var brilho := OmniLight3D.new()
	brilho.light_color = Color(1.0, 0.85, 0.5)
	brilho.light_energy = 1.5
	brilho.omni_range = 5.0
	brilho.position = Vector3(0.5, 2.0, 80.0)
	add_child(brilho)


func _alice_no_horizonte() -> void:
	if not ResourceLoader.exists(CAMINHO_ALICE):
		return
	var alice := (load(CAMINHO_ALICE) as PackedScene).instantiate() as Node3D
	alice.scale = Vector3.ONE * 30.0
	alice.position = Vector3(14, 9.0, 128)
	alice.rotation.y = PI  # olhando para a lagoa
	add_child(alice)


# ---------------- lágrimas ----------------

func _lagrima() -> void:
	var nino := get_tree().get_first_node_in_group("sonhador") as Node3D
	if nino == null:
		return
	if nino.global_position.z < LAGRIMAS_Z.x - 4.0 or nino.global_position.z > LAGRIMAS_Z.y:
		return
	var alvo := Vector3(nino.global_position.x + randf_range(-5.0, 5.0), 0.0,
		clampf(nino.global_position.z + randf_range(-3.0, 7.0), LAGRIMAS_Z.x, LAGRIMAS_Z.y))
	# sombra de aviso
	var sombra := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = 2.4
	disco.bottom_radius = 2.4
	disco.height = 0.02
	sombra.mesh = disco
	var ms := StandardMaterial3D.new()
	ms.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ms.albedo_color = Color(0.1, 0.15, 0.35, 0.0)
	ms.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sombra.material_override = ms
	sombra.position = alvo + Vector3.UP * 0.18
	sombra.scale = Vector3(0.3, 1, 0.3)
	add_child(sombra)
	var gota := MeshInstance3D.new()
	var esf := SphereMesh.new()
	esf.radius = 1.1
	esf.height = 2.8
	gota.mesh = esf
	gota.material_override = M_VIDRO
	gota.position = alvo + Vector3.UP * 34.0
	add_child(gota)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(sombra, "scale", Vector3.ONE, 1.3)
	tw.tween_property(ms, "albedo_color:a", 0.45, 1.3)
	tw.tween_property(gota, "position:y", 0.0, 1.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func() -> void:
		_respingo(alvo)
		sombra.queue_free()
		gota.queue_free())


func _respingo(pos: Vector3) -> void:
	Efeitos.fiapos(self, pos + Vector3.UP * 0.2, Vector3.UP, Color(0.75, 0.88, 1.0))
	var anel := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.9
	t.outer_radius = 1.1
	anel.mesh = t
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.9, 0.95, 1.0, 0.8)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	anel.material_override = m
	anel.position = pos + Vector3.UP * 0.15
	add_child(anel)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(anel, "scale", Vector3(4, 1, 4), 0.9).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.9)
	tw.chain().tween_callback(anel.queue_free)
	var som := AudioStreamPlayer3D.new()
	som.stream = SOM_SPLASH
	som.bus = &"Efeitos"
	som.pitch_scale = 0.6
	som.position = pos
	add_child(som)
	som.play()
	som.finished.connect(som.queue_free)
	for grupo: StringName in [&"sonhador", &"mel"]:
		for n: Node in get_tree().get_nodes_in_group(grupo):
			var d := n as DreamerController
			if d and d.global_position.distance_to(pos) < 3.0:
				d.empurrar(pos, 7.0)
