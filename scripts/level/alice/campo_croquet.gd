extends Fase
## Alice, Capítulo 8 — O Campo de Croquet da Rainha (PESADELO).
## Um planetinha-campo de croquet à noite: arcos, roseiras meio pintadas de vermelho, ouriços-bola.
## Fase 1: soldados-carta de lã escura perseguem o Nino; a Rainha grita do trono, protegida por uma bolha.
## Fase 2: sem soldados, a bolha some e a Rainha desce — a Luna (e a Estrelinha da Mel) a acalmam.
##         Na metade, ela chama mais soldados e se protege de novo.
## Fim: a Rainha se desfaz em estrelinhas, o céu amanhece e ela, já calminha, deixa todo mundo jogar.

const SOMBRA := preload("res://scenes/nightmare/SombraDeLa.tscn")
const RAINHA := preload("res://assets/models/personagens/rainha.glb")
const FONTE := preload("res://assets/fonts/Fredoka-Bold.woff2")
const M_GRAMA := preload("res://materials/pbr/feltro_verde.tres")
const M_ARCO := preload("res://materials/pbr/feltro_creme.tres")
const M_CARTA := preload("res://materials/pbr/feltro_roxo.tres")
const M_TRONO := preload("res://materials/pbr/veludo_vermelho.tres")
const M_OURO := preload("res://materials/pbr/linha_dourada.tres")
const M_OURICO := preload("res://materials/pbr/cotele_marrom.tres")
const M_PEDRA := preload("res://materials/pbr/la_trico_creme.tres")

const RAIO: float = 13.0
const DIR_TRONO := Vector3(0.0, 0.15, 1.0)

var _planeta: Planetoid
var _rainha: ShadowCreature
var _visual_rainha: Personagem
var _bolha: MeshInstance3D
var _etapa: int = 0
var _soldados_vivos: int = 0
var _musica: AudioStreamPlayer


func _ready() -> void:
	_planeta = Planetoid.new()
	_planeta.name = "Campo"
	_planeta.raio = RAIO
	_planeta.alcance_gravidade = 12.0
	_planeta.material_superficie = M_GRAMA
	add_child(_planeta)
	_enfeites()
	_castelo()
	_trono_e_rainha()
	super._ready()
	for filho: Node in get_children():
		if filho is AudioStreamPlayer:
			_musica = filho as AudioStreamPlayer
			_musica.pitch_scale = 0.82  # a música do chá, mais lenta e sombria
	_comecar.call_deferred()


func _comecar() -> void:
	# soldados espalhados pelo campo
	var dirs: Array[Vector3] = [Vector3(1, 0.4, 0.3), Vector3(-1, 0.3, 0.5), Vector3(0.6, 0.1, -1),
		Vector3(-0.7, 0.0, -0.8), Vector3(0.2, -0.3, 1.0)]
	for i in dirs.size():
		_soldado(dirs[i], i)


# ---------------- posicionamento no planeta ----------------

func _no_planeta(n: Node3D, dir: Vector3, elevacao: float = 0.0, giro: float = 0.0) -> Node3D:
	var up: Vector3 = dir.normalized()
	var frente: Vector3 = up.cross(Vector3.RIGHT if absf(up.x) < 0.9 else Vector3.FORWARD).normalized()
	n.global_basis = Basis.looking_at(frente, up).rotated(up, giro)
	n.global_position = _planeta.ponto_na_superficie(up, elevacao)
	return n


func _malha(pai: Node3D, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.position = pos
	m.material_override = mat
	pai.add_child(m)
	return m


# ---------------- cenário ----------------

func _enfeites() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8
	# arcos de croquet (meio enterrados)
	for i in 9:
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.8, 1), rng.randf_range(-1, 1))
		if dir.normalized().dot(DIR_TRONO.normalized()) > 0.85:
			continue
		var arco := Node3D.new()
		add_child(arco)
		_no_planeta(arco, dir, 0.0, rng.randf() * TAU)
		var t := TorusMesh.new()
		t.inner_radius = 0.75
		t.outer_radius = 0.95
		var m := _malha(arco, t, Vector3.ZERO, M_ARCO)
		m.rotation.x = PI / 2.0
	# roseiras: as rosas brancas que os soldados pintaram de vermelho (pela metade!)
	for i in 14:
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.6, 1), rng.randf_range(-1, 1))
		var moita := PropProcedural.new()
		moita.tipo = PropProcedural.Tipo.MORRINHO
		moita.tamanho = rng.randf_range(1.0, 1.6)
		moita.cor = Color(0.2, 0.42, 0.25)
		moita.semente = i
		add_child(moita)
		_no_planeta(moita, dir, -0.1)
		for k in 3:
			var flor := PropProcedural.new()
			flor.tipo = PropProcedural.Tipo.FLOR
			flor.tamanho = 0.5
			flor.com_colisao = false
			flor.cor = Color(0.9, 0.12, 0.2) if (i + k) % 2 == 0 else Color(1, 1, 1)
			flor.semente = i * 3 + k
			flor.position = Vector3(rng.randf_range(-0.5, 0.5), moita.tamanho * 0.45, rng.randf_range(-0.5, 0.5))
			moita.add_child(flor)
	# ouriços-bola, encolhidinhos de medo
	for i in 6:
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.5, 1), rng.randf_range(-1, 1))
		var ourico := Node3D.new()
		add_child(ourico)
		_no_planeta(ourico, dir, 0.0, rng.randf() * TAU)
		var esf := SphereMesh.new()
		esf.radius = 0.35
		esf.height = 0.6
		_malha(ourico, esf, Vector3(0, 0.3, 0), M_OURICO)
		var focinho := SphereMesh.new()
		focinho.radius = 0.08
		focinho.height = 0.16
		_malha(ourico, focinho, Vector3(0, 0.25, -0.36), M_PEDRA)
	# cartas gigantes flutuando no céu
	for i in 10:
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
		var carta := Node3D.new()
		add_child(carta)
		carta.global_position = dir * rng.randf_range(32.0, 48.0)
		carta.rotation = Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)
		var b := BoxMesh.new()
		b.size = Vector3(3.0, 4.2, 0.1)
		_malha(carta, b, Vector3.ZERO, M_ARCO)
		_rotulo3d(carta, "♥" if i % 2 == 0 else "♠", Color(0.85, 0.1, 0.2) if i % 2 == 0 else Color(0.1, 0.1, 0.2),
			220, Vector3(0, 0, -0.06))


func _castelo() -> void:
	# o castelo da Rainha, longe, recortado contra o céu
	var c := Node3D.new()
	c.position = Vector3(-30, 6, 40)
	add_child(c)
	var b := BoxMesh.new()
	b.size = Vector3(12, 8, 4)
	_malha(c, b, Vector3.ZERO, M_TRONO)
	for x: float in [-6.0, -2.0, 2.0, 6.0]:
		var torre := CylinderMesh.new()
		torre.top_radius = 1.1
		torre.bottom_radius = 1.1
		torre.height = 11.0 + absf(x)
		_malha(c, torre, Vector3(x, (11.0 + absf(x)) / 2.0 - 4.0, 0), M_TRONO)
		var teto := CylinderMesh.new()
		teto.top_radius = 0.0
		teto.bottom_radius = 1.5
		teto.height = 2.6
		_malha(c, teto, Vector3(x, 11.0 + absf(x) - 4.0 + 1.3, 0), M_OURO)
		var janela := OmniLight3D.new()
		janela.light_color = Color(1.0, 0.6, 0.3)
		janela.light_energy = 2.0
		janela.omni_range = 5.0
		janela.position = Vector3(x, 4, -2.2)
		c.add_child(janela)


func _rotulo3d(pai: Node3D, texto: String, cor: Color, tamanho: int, pos: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = texto
	l.font = FONTE
	l.font_size = tamanho
	l.modulate = cor
	l.outline_size = 0
	l.position = pos
	l.rotation.y = PI
	l.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
	pai.add_child(l)
	return l


# ---------------- soldados-carta ----------------

func _soldado(dir: Vector3, i: int) -> ShadowCreature:
	var s := SOMBRA.instantiate() as ShadowCreature
	s.darkness = 2.2
	s.chase_speed = 2.3
	add_child(s)
	_no_planeta(s, dir, 0.2)
	(s.get_node("Visual") as Node3D).visible = false
	var corpo := Node3D.new()
	corpo.position.y = 0.75
	s.add_child(corpo)
	var carta := BoxMesh.new()
	carta.size = Vector3(0.85, 1.2, 0.07)
	_malha(corpo, carta, Vector3.ZERO, M_CARTA)
	var naipe: String = ["♠", "♣", "♠", "♣", "♠"][i % 5]
	_rotulo3d(corpo, naipe, Color(0.85, 0.85, 1.0), 120, Vector3(0, -0.1, -0.045))
	# olhinhos brilhando
	var olho_mat := StandardMaterial3D.new()
	olho_mat.emission_enabled = true
	olho_mat.emission = Color(1.0, 0.9, 0.5)
	olho_mat.emission_energy_multiplier = 3.0
	olho_mat.albedo_color = Color(1, 1, 0.8)
	for x: float in [-0.15, 0.15]:
		var olho := SphereMesh.new()
		olho.radius = 0.055
		olho.height = 0.11
		_malha(corpo, olho, Vector3(x, 0.32, -0.05), olho_mat)
	# perninhas e bracinhos de linha
	for x: float in [-0.2, 0.2]:
		var perna := BoxMesh.new()
		perna.size = Vector3(0.06, 0.4, 0.06)
		_malha(corpo, perna, Vector3(x, -0.78, 0), M_CARTA)
		var braco := BoxMesh.new()
		braco.size = Vector3(0.35, 0.06, 0.06)
		_malha(corpo, braco, Vector3(x * 3.0, 0.05, 0), M_CARTA)
	# balança andando
	var tw := s.create_tween().set_loops()
	tw.tween_property(corpo, "rotation:z", 0.18, 0.3).set_trans(Tween.TRANS_SINE)
	tw.tween_property(corpo, "rotation:z", -0.18, 0.3).set_trans(Tween.TRANS_SINE)
	_soldados_vivos += 1
	s.dissipated.connect(_soldado_acalmado)
	return s


func _soldado_acalmado() -> void:
	_soldados_vivos -= 1
	if _soldados_vivos > 0:
		return
	if _etapa == 0:
		_etapa = 1
		_rainha_desce()
	elif _etapa == 2:
		_etapa = 3
		_proteger(false)
		_gritar("Ora essa! Então eu mesma vou!" if MenuEstanteUI._pt() else "Very well! I'll do it myself!")


# ---------------- a Rainha ----------------

func _trono_e_rainha() -> void:
	var trono := Node3D.new()
	trono.name = "Trono"
	add_child(trono)
	_no_planeta(trono, DIR_TRONO, 0.0)
	var assento := BoxMesh.new()
	assento.size = Vector3(1.8, 0.7, 1.4)
	_malha(trono, assento, Vector3(0, 0.35, 0.3), M_TRONO)
	var encosto := BoxMesh.new()
	encosto.size = Vector3(1.8, 2.4, 0.3)
	_malha(trono, encosto, Vector3(0, 1.2, 1.0), M_TRONO)
	_rotulo3d(trono, "♥", Color(1.0, 0.85, 0.3), 300, Vector3(0, 1.8, 0.84))

	_rainha = SOMBRA.instantiate() as ShadowCreature
	_rainha.is_boss = true
	_rainha.nome_chefe = "Rainha de Copas" if MenuEstanteUI._pt() else "Queen of Hearts"
	_rainha.darkness = 14.0
	_rainha.chase_speed = 0.0
	_rainha.alcance_toque = 1.3
	add_child(_rainha)
	_no_planeta(_rainha, DIR_TRONO, 0.3)
	(_rainha.get_node("Visual") as Node3D).visible = false
	_visual_rainha = Personagem.new()
	_visual_rainha.modelo = RAINHA
	_visual_rainha.escala = 0.95
	_visual_rainha.altura_pes = 0.0
	_visual_rainha.altura_balao = 2.6
	_visual_rainha.anim_parado = &"human_000093"
	_visual_rainha.anim_falando = &"human_000041"
	_visual_rainha.falas = PackedStringArray([
		"Cortem-lhe a cabeça!" if MenuEstanteUI._pt() else "Off with his head!",
		"Soldados! Peguem aquele menino!" if MenuEstanteUI._pt() else "Soldiers! Seize that boy!",
		"Quem pintou estas rosas de BRANCO?!" if MenuEstanteUI._pt() else "Who painted these roses WHITE?!"])
	_visual_rainha.tom_voz = 340.0
	_visual_rainha.raio_conversa = 40.0
	_visual_rainha.intervalo = 5.0
	_rainha.add_child(_visual_rainha)
	_rainha.dissipated.connect(_rainha_acalmada)
	# bolha de escuridão (escudo)
	_bolha = MeshInstance3D.new()
	var esf := SphereMesh.new()
	esf.radius = 1.6
	esf.height = 3.2
	_bolha.mesh = esf
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.2, 0.08, 0.3, 0.55)
	mat.rim_enabled = true
	mat.rim = 1.0
	mat.emission_enabled = true
	mat.emission = Color(0.35, 0.1, 0.45)
	mat.emission_energy_multiplier = 0.8
	_bolha.material_override = mat
	_bolha.position.y = 1.2
	_rainha.add_child(_bolha)
	_proteger(true)


func _proteger(sim: bool) -> void:
	_rainha.escudo = sim
	var tw := create_tween()
	if sim:
		_bolha.visible = true
		_bolha.scale = Vector3.ONE * 0.2
		tw.tween_property(_bolha, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	else:
		tw.tween_property(_bolha, "scale", Vector3.ONE * 0.05, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_callback(func() -> void: _bolha.visible = false)
	get_tree().call_group("hud_sonho", "chefe_protegido", sim)


func _rainha_desce() -> void:
	_proteger(false)
	_gritar("Hmpf! Ninguém mais obedece?! Cortem-lhe a cabeça!" if MenuEstanteUI._pt()
		else "Hmph! Does nobody obey?! Off with his head!")
	_rainha.chase_speed = 2.0
	_visual_rainha.anim_parado = &"human_000088"  # andar elegante (e bravo)
	_visual_rainha._tocar(_visual_rainha.anim_parado)
	get_tree().call_group("hud_sonho", "mostrar_chefe", _rainha)
	_rainha.escuridao_mudou.connect(_rainha_enfraquece)


func _rainha_enfraquece(fracao: float) -> void:
	if _etapa == 1 and fracao < 0.5:
		_etapa = 2
		_proteger(true)
		_gritar("SOLDADOS!!" if MenuEstanteUI._pt() else "SOLDIERS!!")
		var up: Vector3 = (_rainha.global_position - _planeta.global_position).normalized()
		var lado: Vector3 = up.cross(Vector3.UP if absf(up.y) < 0.9 else Vector3.RIGHT).normalized()
		for k in 3:
			_soldado(up + lado.rotated(up, k * TAU / 3.0) * 0.5, k)


func _gritar(frase: String) -> void:
	_visual_rainha._falar(frase)


func _rainha_acalmada() -> void:
	# O céu amanhece e a Rainha, já calminha, fica no lugar onde se desfez.
	var pos: Vector3 = _rainha.global_position
	var base: Basis = _rainha.global_basis.orthonormalized()
	var calma := Personagem.new()
	calma.modelo = RAINHA
	calma.escala = 0.95
	calma.altura_pes = 0.0
	calma.altura_balao = 2.6
	calma.anim_parado = &"human_000050"
	calma.falas = PackedStringArray(["Hmpf… está bem. Podem jogar." if MenuEstanteUI._pt()
		else "Hmph… very well. You may play."])
	calma.tom_voz = 340.0
	calma.raio_conversa = 12.0
	add_child(calma)
	calma.global_transform = Transform3D(base, pos)
	_amanhecer()


func _amanhecer() -> void:
	var we := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we:
		var env: Environment = we.environment
		var tw := create_tween().set_parallel(true)
		tw.tween_property(env, "ambient_light_energy", 1.0, 3.0)
		tw.tween_property(env, "ambient_light_color", Color(1.0, 0.85, 0.75), 3.0)
		var ceu := (env.sky.sky_material as ProceduralSkyMaterial) if env.sky else null
		if ceu:
			tw.tween_property(ceu, "sky_top_color", Color(0.45, 0.6, 0.95), 3.0)
			tw.tween_property(ceu, "sky_horizon_color", Color(1.0, 0.75, 0.55), 3.0)
	var lua := get_node_or_null("Lua") as DirectionalLight3D
	if lua:
		create_tween().tween_property(lua, "light_color", Color(1.0, 0.8, 0.6), 3.0)
	if _musica:
		create_tween().tween_property(_musica, "pitch_scale", 1.0, 3.0)
