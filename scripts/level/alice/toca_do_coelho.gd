extends Fase
## Alice, Capítulo 1 — Descendo pela Toca do Coelho.
## 1) Campinho no topo: o Coelho Branco passa correndo e some no buraco.
## 2) O poço: cair DEVAGARINHO (queda lenta), desviando e pousando em prateleiras cheias de livros,
##    armários e quadros; potes de laranjada, xícaras e relógios flutuam no meio.
## 3) Monte de gravetos e folhas de feltro no fundo → corredor baixo → salão das portas.
## 4) Mesinha de vidro com a chave dourada; pegar a chave levanta a cortina e destranca a portinha → saída.
## A fase é montada por código (geometria em CSG com colisão) para ser fácil de ajustar.

const M_TERRA := preload("res://materials/pbr/cotele_marrom.tres")
const M_SALAO := preload("res://materials/pbr/feltro_creme.tres")
const M_CHAO := preload("res://materials/pbr/assoalho.tres")
const M_GRAMA := preload("res://materials/pbr/feltro_verde.tres")
const M_MADEIRA := preload("res://materials/pbr/madeira_verniz.tres")
const M_MADEIRA_CRUA := preload("res://materials/pbr/madeira.tres")
const M_PAPEL := preload("res://materials/pbr/papel.tres")
const M_VIDRO := preload("res://materials/pbr/vidro_claro.tres")
const M_AMBAR := preload("res://materials/pbr/vidro_ambar.tres")
const M_OURO := preload("res://materials/pbr/linha_dourada.tres")
const M_CORTINA := preload("res://materials/pbr/veludo_vermelho.tres")
const M_TAPETE := preload("res://materials/pbr/veludo_azul.tres")
const M_PORTA := preload("res://materials/pbr/cotele_vinho.tres")
const FONTE := preload("res://assets/fonts/Fredoka-Bold.woff2")
const COELHO := preload("res://assets/models/personagens/coelho.glb")
const SOM_CHAVE := preload("res://assets/audio/sfx/botao_plim_b.mp3")

## Altura do topo do poço (o fundo fica em y = 0).
const TOPO: float = 92.0
const RAIO_POCO: float = 7.0
## Velocidade máxima de queda dentro do poço (m/s) — "ou o poço era muito fundo, ou ela caía muito devagar".
const QUEDA_LENTA: float = 4.5

var _flutuantes: Array[Node3D] = []
var _tempo: float = 0.0
var _chave: Node3D
var _cortina: Node3D
var _porta_luz: OmniLight3D
var _tem_chave: bool = false
var _dica_atual: Label
## Parede do poço: veludo cotelê marrom (terra fofa) em escala grande, para não dar moiré de longe.
var _m_parede: Material = _escalado(M_TERRA, 0.3)


func _ready() -> void:
	_gravidade_geral()
	_montar_toca()
	_campinho()
	_prateleiras()
	_coisas_flutuando()
	_luzes_do_poco()
	_fundo_de_folhas()
	_salao()
	_coelho()
	super._ready()


func _process(delta: float) -> void:
	_tempo += delta
	for i in _flutuantes.size():
		var n: Node3D = _flutuantes[i]
		n.rotate_y(delta * (0.3 + 0.1 * (i % 4)))
		n.rotate_x(delta * 0.17 * (1 if i % 2 == 0 else -1))
		n.position.y += sin(_tempo * 0.8 + i) * delta * 0.15
	if _chave and not _tem_chave:
		_chave.rotate_y(delta * 1.6)
	elif _chave:
		var nino := get_tree().get_first_node_in_group("sonhador") as Node3D
		if nino:
			var alvo: Vector3 = nino.global_position + Vector3.UP * 2.1
			_chave.global_position = _chave.global_position.lerp(alvo, 1.0 - exp(-8.0 * delta))
			_chave.rotate_y(delta * 3.0)


static func _escalado(base: Material, fator: float) -> Material:
	var m := base.duplicate() as StandardMaterial3D
	m.uv1_scale *= fator
	return m


# ---------------- gravidade ----------------

func _gravidade_geral() -> void:
	# Gravidade "para baixo" em toda a fase (o resto do jogo é de planetinhas, então é por área).
	var geral := _area_gravidade(Vector3(0, 45, 18), Vector3(80, 140, 90), 25.0, 0)
	geral.name = "GravidadeGeral"
	# Dentro do poço: a mesma gravidade, mas a queda é limitada (queda lenta, dá para ir guiando).
	var poco := _area_gravidade(Vector3(0, TOPO / 2.0 + 1.5, 0), Vector3(RAIO_POCO * 2.0, TOPO - 3.0, RAIO_POCO * 2.0),
		25.0, 1)
	poco.name = "QuedaLenta"
	poco.body_entered.connect(func(b: Node3D) -> void: _queda_lenta(b, true))
	poco.body_exited.connect(func(b: Node3D) -> void: _queda_lenta(b, false))
	# Câmera olhando bem para baixo no poço, para ver onde vai pousar.
	var zona := CameraZone.new()
	zona.comprimento = 9.5
	zona.inclinacao_graus = -68.0
	zona.position = poco.position
	_forma(zona, Vector3(RAIO_POCO * 2.0, TOPO - 6.0, RAIO_POCO * 2.0))
	add_child(zona)


func _area_gravidade(centro: Vector3, tamanho: Vector3, forca: float, prioridade: int) -> Area3D:
	var a := Area3D.new()
	a.position = centro
	a.collision_layer = 0
	a.collision_mask = 6
	a.monitorable = false
	a.priority = prioridade
	a.gravity_space_override = Area3D.SPACE_OVERRIDE_REPLACE
	a.gravity_direction = Vector3.DOWN
	a.gravity = forca
	_forma(a, tamanho)
	add_child(a)
	return a


func _forma(a: Area3D, tamanho: Vector3) -> void:
	var c := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = tamanho
	c.shape = s
	a.add_child(c)


func _queda_lenta(corpo: Node3D, dentro: bool) -> void:
	var d := corpo as DreamerController
	if d:
		d.queda_maxima = QUEDA_LENTA if dentro else 30.0


# ---------------- a toca (poço + corredor + salão) ----------------

func _montar_toca() -> void:
	var toca := CSGCombiner3D.new()
	toca.name = "Toca"
	toca.use_collision = true
	add_child(toca)
	# Casca externa
	_cilindro(toca, Vector3(0, TOPO / 2.0 - 1.0, 0), RAIO_POCO + 0.8, TOPO + 2.0, _m_parede, CSGShape3D.OPERATION_UNION)
	_caixa(toca, Vector3(0, 2.0, 14.0), Vector3(6.0, 5.0, 12.0), _m_parede, CSGShape3D.OPERATION_UNION)
	_caixa(toca, Vector3(0, 3.5, 32.0), Vector3(26.0, 9.0, 26.0), _m_parede, CSGShape3D.OPERATION_UNION)
	# Interior escavado (as faces de dentro levam o material destas formas)
	_cilindro(toca, Vector3(0, TOPO / 2.0 + 1.0, 0), RAIO_POCO, TOPO + 4.0, _m_parede, CSGShape3D.OPERATION_SUBTRACTION)
	_caixa(toca, Vector3(0, 1.75, 13.5), Vector3(4.0, 3.5, 13.0), _m_parede, CSGShape3D.OPERATION_SUBTRACTION)
	_caixa(toca, Vector3(0, 3.5, 32.0), Vector3(24.0, 7.0, 24.0), M_SALAO, CSGShape3D.OPERATION_SUBTRACTION)
	# Chão de assoalho por cima (o fundo do poço, o corredor e o salão)
	_solido(Vector3(0, -0.05, 0), Vector3(RAIO_POCO * 2.0, 0.2, RAIO_POCO * 2.0), M_CHAO)
	_solido(Vector3(0, -0.05, 13.5), Vector3(4.0, 0.2, 13.0), M_CHAO)
	_solido(Vector3(0, -0.05, 32.0), Vector3(24.0, 0.2, 24.0), M_CHAO)
	# lambri de madeira no salão
	for lado: float in [-1.0, 1.0]:
		_malha(self, _bm(Vector3(0.1, 1.3, 24.0)), Vector3(lado * 11.95, 0.65, 32.0), M_MADEIRA)
		# parede da frente tem a abertura do corredor (x entre -2 e 2)
		_malha(self, _bm(Vector3(10.0, 1.3, 0.1)), Vector3(lado * 7.0, 0.65, 20.05), M_MADEIRA)
	_malha(self, _bm(Vector3(24.0, 1.3, 0.06)), Vector3(0, 0.65, 43.97), M_MADEIRA)


func _cilindro(pai: Node, pos: Vector3, raio: float, altura: float, mat: Material, op: int) -> CSGCylinder3D:
	var c := CSGCylinder3D.new()
	c.radius = raio
	c.height = altura
	c.sides = 40
	c.position = pos
	c.material = mat
	c.operation = op
	pai.add_child(c)
	return c


func _caixa(pai: Node, pos: Vector3, tamanho: Vector3, mat: Material, op: int) -> CSGBox3D:
	var c := CSGBox3D.new()
	c.size = tamanho
	c.position = pos
	c.material = mat
	c.operation = op
	pai.add_child(c)
	return c


## Caixa com colisão (StaticBody + malha).
func _solido(pos: Vector3, tamanho: Vector3, mat: Material, pai: Node3D = null, rot_y: float = 0.0) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.position = pos
	corpo.rotation.y = rot_y
	(pai if pai else self as Node3D).add_child(corpo)
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


# ---------------- topo: campinho na beira do buraco ----------------

func _campinho() -> void:
	var anel := CSGCombiner3D.new()
	anel.name = "Campinho"
	anel.use_collision = true
	add_child(anel)
	_cilindro(anel, Vector3(0, TOPO - 0.6, 0), 22.0, 1.2, M_GRAMA, CSGShape3D.OPERATION_UNION)
	_cilindro(anel, Vector3(0, TOPO - 0.6, 0), RAIO_POCO, 2.0, _m_parede, CSGShape3D.OPERATION_SUBTRACTION)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 26:
		var ang: float = rng.randf() * TAU
		var r: float = rng.randf_range(RAIO_POCO + 1.5, 20.0)
		var p := PropProcedural.new()
		p.tipo = PropProcedural.Tipo.FLOR if i % 3 != 0 else PropProcedural.Tipo.MORRINHO
		p.tamanho = rng.randf_range(0.5, 0.9) if p.tipo == PropProcedural.Tipo.FLOR else rng.randf_range(1.0, 2.0)
		p.cor = [Color(1, 0.55, 0.65), Color(1, 0.85, 0.35), Color(0.7, 0.6, 1.0), Color(1, 1, 1)][i % 4]
		p.semente = i
		p.com_colisao = p.tipo == PropProcedural.Tipo.MORRINHO
		p.position = Vector3(cos(ang) * r, TOPO, sin(ang) * r)
		p.rotation.y = rng.randf() * TAU
		add_child(p)
	# borda da toca: um rolo de terra fofa e raízes de lã em volta do buraco
	var borda := TorusMesh.new()
	borda.inner_radius = RAIO_POCO - 0.2
	borda.outer_radius = RAIO_POCO + 0.9
	borda.rings = 48
	_malha(self, borda, Vector3(0, TOPO, 0), _m_parede)
	var pt: bool = MenuEstanteUI._pt()
	_placa("Siga o Coelho Branco!\nPule no buraco ↓" if pt else "Follow the White Rabbit!\nJump down the hole ↓",
		Vector3(-4.5, TOPO + 2.4, -RAIO_POCO - 1.5), 0.0)


# ---------------- o poço ----------------

## Prateleiras saindo da parede em espiral: dá para pousar, descansar e escolher o caminho.
func _prateleiras() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var ang: float = 0.6
	var y: float = TOPO - 9.0
	var i: int = 0
	while y > 6.0:
		var dir := Vector3(cos(ang), 0, sin(ang))
		var base := Node3D.new()
		base.name = "Prateleira%d" % i
		base.position = dir * (RAIO_POCO - 1.1) + Vector3.UP * y
		base.rotation.y = atan2(dir.x, dir.z)  # +Z local aponta para a parede
		add_child(base)
		_solido(Vector3.ZERO, Vector3(3.4, 0.25, 2.2), M_MADEIRA, base)
		# mão-francesa embaixo
		_malha(base, _bm(Vector3(0.18, 0.9, 0.18)), Vector3(-1.3, -0.55, 0.9), M_MADEIRA_CRUA)
		_malha(base, _bm(Vector3(0.18, 0.9, 0.18)), Vector3(1.3, -0.55, 0.9), M_MADEIRA_CRUA)
		match i % 3:
			0:
				_livros(base, rng)
			1:
				_armario(base)
			2:
				_quadro(base, rng)
		i += 1
		ang += deg_to_rad(rng.randf_range(95.0, 135.0))
		y -= rng.randf_range(6.0, 8.0)


func _bm(tamanho: Vector3) -> BoxMesh:
	var bm := BoxMesh.new()
	bm.size = tamanho
	return bm


func _livros(base: Node3D, rng: RandomNumberGenerator) -> void:
	var x: float = -1.4
	var k: int = 0
	while x < 1.3:
		var larg: float = rng.randf_range(0.14, 0.24)
		var alt: float = rng.randf_range(0.45, 0.75)
		var livro := Node3D.new()
		livro.position = Vector3(x + larg / 2.0, 0.125, 0.75)
		livro.rotation.y = PI
		base.add_child(livro)
		LivroVisual.montar(livro, "", Color.from_hsv(rng.randf(), 0.55, 0.75), larg, alt, 0.5, k)
		x += larg + 0.02
		k += 1


func _armario(base: Node3D) -> void:
	var a := _solido(Vector3(0.6, 0.125 + 0.8, 0.55), Vector3(1.5, 1.6, 0.9), M_MADEIRA, base)
	for lado: float in [-0.36, 0.36]:
		_malha(a, _bm(Vector3(0.68, 1.45, 0.05)), Vector3(lado, 0, -0.47), M_MADEIRA_CRUA)
		_malha(a, _bm(Vector3(0.08, 0.08, 0.08)), Vector3(lado * 0.2, 0, -0.52), M_OURO)
	# o pote de LARANJADA (vazio, que decepção!) em cima do armário
	_pote(a, Vector3(0, 0.95, 0), 0.6)


func _quadro(base: Node3D, rng: RandomNumberGenerator) -> void:
	var q := Node3D.new()
	q.position = Vector3(rng.randf_range(-0.6, 0.6), 1.6, 1.12)
	base.add_child(q)
	_malha(q, _bm(Vector3(1.6, 1.2, 0.08)), Vector3.ZERO, M_MADEIRA)
	_malha(q, _bm(Vector3(1.35, 0.95, 0.04)), Vector3(0, 0, -0.04), M_PAPEL)
	var l := Label3D.new()
	l.text = "MAPA" if rng.randf() < 0.5 else "✿"
	l.font = FONTE
	l.font_size = 64
	l.modulate = Color(0.45, 0.3, 0.2)
	l.outline_size = 0
	l.position = Vector3(0, 0, -0.07)
	l.rotation.y = PI
	l.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
	q.add_child(l)


func _pote(pai: Node3D, pos: Vector3, escala: float) -> Node3D:
	var pote := Node3D.new()
	pote.position = pos
	pote.scale = Vector3.ONE * escala
	pai.add_child(pote)
	var corpo := CylinderMesh.new()
	corpo.top_radius = 0.42
	corpo.bottom_radius = 0.45
	corpo.height = 0.9
	_malha(pote, corpo, Vector3(0, 0.45, 0), M_AMBAR)
	var tampa := CylinderMesh.new()
	tampa.top_radius = 0.46
	tampa.bottom_radius = 0.46
	tampa.height = 0.14
	_malha(pote, tampa, Vector3(0, 0.95, 0), M_TAPETE)
	var rot := CylinderMesh.new()
	rot.top_radius = 0.455
	rot.bottom_radius = 0.465
	rot.height = 0.32
	_malha(pote, rot, Vector3(0, 0.45, 0), M_PAPEL)
	var l := Label3D.new()
	l.text = "LARANJADA" if MenuEstanteUI._pt() else "ORANGE\nMARMALADE"
	l.font = FONTE
	l.font_size = 22
	l.modulate = Color(0.95, 0.5, 0.1)
	l.outline_size = 0
	l.position = Vector3(0, 0.45, -0.47)
	l.rotation.y = PI
	l.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
	pote.add_child(l)
	return pote


## Coisas caindo junto, girando devagar no meio do poço (sem colisão).
func _coisas_flutuando() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	for i in 16:
		var y: float = TOPO - 12.0 - i * 5.0
		var ang: float = rng.randf() * TAU
		var r: float = rng.randf_range(2.0, 4.2)
		var pos := Vector3(cos(ang) * r, y, sin(ang) * r)
		var n: Node3D
		match i % 4:
			0:
				n = _pote(self, pos, 0.8)
			1:
				var x := PropProcedural.new()
				x.tipo = PropProcedural.Tipo.XICARA
				x.tamanho = 0.7
				x.com_colisao = false
				x.cor = Color(1, 0.75, 0.85)
				x.position = pos
				add_child(x)
				n = x
			2:
				var rel := PropProcedural.new()
				rel.tipo = PropProcedural.Tipo.RELOGIO
				rel.tamanho = 0.6
				rel.com_colisao = false
				rel.position = pos
				add_child(rel)
				n = rel
			3:
				n = Node3D.new()
				n.position = pos
				add_child(n)
				LivroVisual.montar(n, "", Color.from_hsv(rng.randf(), 0.6, 0.8), 0.6, 0.85, 0.16, i)
		_flutuantes.append(n)


func _luzes_do_poco() -> void:
	# Lampiões quentinhos na parede, em espiral, e um varal de luzinhas descendo.
	var pontos: Array[NodePath] = []
	for i in 12:
		var y: float = TOPO - 4.0 - i * 7.5
		var ang: float = i * 2.1
		var dir := Vector3(cos(ang), 0, sin(ang))
		var luz := OmniLight3D.new()
		luz.light_color = Color(1.0, 0.72, 0.42)
		luz.light_energy = 2.2
		luz.omni_range = 11.0
		luz.position = dir * (RAIO_POCO - 0.6) + Vector3.UP * y
		add_child(luz)
		var bulbo := SphereMesh.new()
		bulbo.radius = 0.22
		bulbo.height = 0.44
		var mat := StandardMaterial3D.new()
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.75, 0.4)
		mat.emission_energy_multiplier = 4.0
		mat.albedo_color = Color(1.0, 0.85, 0.6)
		_malha(luz, bulbo, Vector3.ZERO, mat)
		var m := Marker3D.new()
		m.name = "PontoVaral%d" % i
		var a2: float = i * 0.9
		m.position = Vector3(cos(a2), 0, sin(a2)) * (RAIO_POCO - 0.15) + Vector3.UP * (TOPO - 1.0 - i * 7.6)
		add_child(m)
		pontos.append(m.get_path())
	var varal := FioEsticado.new()
	varal.curvatura = -0.04
	varal.luzinhas = true
	varal.espacamento_luzes = 1.6
	add_child(varal)
	varal.pontos = pontos


# ---------------- fundo: folhas e gravetos ----------------

func _fundo_de_folhas() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var cores: Array[Material] = [preload("res://materials/pbr/la_trico_laranja.tres"),
		preload("res://materials/pbr/feltro_vermelho.tres"), preload("res://materials/pbr/cotele_oliva.tres"),
		M_PORTA]
	var monte := PropProcedural.new()
	monte.tipo = PropProcedural.Tipo.MORRINHO
	monte.tamanho = 5.0
	monte.cor = Color(0.75, 0.45, 0.2)
	monte.position = Vector3(0, 0, 0)
	add_child(monte)
	for i in 90:
		var ang: float = rng.randf() * TAU
		var r: float = sqrt(rng.randf()) * (RAIO_POCO - 0.8)
		var folha := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.45, 0.7, 0.04)
		folha.mesh = pm
		folha.material_override = cores[i % cores.size()]
		folha.position = Vector3(cos(ang) * r, 0.05 + rng.randf() * 0.25 + maxf(0.0, 1.0 - r / 4.0) * 0.6, sin(ang) * r)
		folha.rotation = Vector3(-PI / 2.0 + rng.randf_range(-0.4, 0.4), rng.randf() * TAU, rng.randf_range(-0.3, 0.3))
		add_child(folha)
	for i in 18:
		var graveto := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.04
		cm.bottom_radius = 0.06
		cm.height = rng.randf_range(0.9, 1.8)
		graveto.mesh = cm
		graveto.material_override = M_MADEIRA_CRUA
		var ang2: float = rng.randf() * TAU
		var r2: float = rng.randf() * 5.0
		graveto.position = Vector3(cos(ang2) * r2, 0.15, sin(ang2) * r2)
		graveto.rotation = Vector3(PI / 2.0, rng.randf() * TAU, 0)
		add_child(graveto)


# ---------------- salão das portas ----------------

func _salao() -> void:
	var c := Vector3(0, 0, 32.0)
	# tapete comprido
	_malha(self, _bm(Vector3(3.6, 0.04, 20.0)), c + Vector3(0, 0.07, 0), M_TAPETE)
	# portas grandes (trancadas) dos dois lados
	for k in 4:
		for lado: float in [-1.0, 1.0]:
			var z: float = c.z - 8.0 + k * 5.0
			var porta := Node3D.new()
			porta.position = Vector3(lado * 11.85, 0, z)
			porta.rotation.y = -lado * PI / 2.0
			add_child(porta)
			_malha(porta, _bm(Vector3(2.2, 4.0, 0.2)), Vector3(0, 2.0, 0), M_PORTA)
			_malha(porta, _bm(Vector3(2.5, 4.2, 0.12)), Vector3(0, 2.1, -0.06), M_MADEIRA)
			var mac := SphereMesh.new()
			mac.radius = 0.12
			mac.height = 0.24
			_malha(porta, mac, Vector3(0.75, 1.9, 0.15), M_OURO)
	# lustres pendurados
	for z: float in [24.0, 32.0, 40.0]:
		var luz := OmniLight3D.new()
		luz.light_color = Color(1.0, 0.8, 0.55)
		luz.light_energy = 3.0
		luz.omni_range = 14.0
		luz.shadow_enabled = true
		luz.position = Vector3(0, 5.2, z)
		add_child(luz)
		var bulbo := SphereMesh.new()
		bulbo.radius = 0.35
		bulbo.height = 0.7
		var mat := StandardMaterial3D.new()
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.8, 0.5)
		mat.emission_energy_multiplier = 3.0
		_malha(luz, bulbo, Vector3.ZERO, mat)
		var fio := CylinderMesh.new()
		fio.top_radius = 0.02
		fio.bottom_radius = 0.02
		fio.height = 1.6
		_malha(luz, fio, Vector3(0, 1.0, 0), M_OURO)
	_mesinha(c + Vector3(0, 0, -1.0))
	_portinha(c + Vector3(0, 0, 11.9))
	_placa("O salão das portas", Vector3(0, 4.3, 21.0), PI)


func _mesinha(pos: Vector3) -> void:
	var mesa := StaticBody3D.new()
	mesa.name = "MesinhaDeVidro"
	mesa.position = pos
	add_child(mesa)
	var tampo := CylinderMesh.new()
	tampo.top_radius = 1.3
	tampo.bottom_radius = 1.3
	tampo.height = 0.1
	_malha(mesa, tampo, Vector3(0, 1.6, 0), M_VIDRO)
	var borda := TorusMesh.new()
	borda.inner_radius = 1.26
	borda.outer_radius = 1.36
	_malha(mesa, borda, Vector3(0, 1.6, 0), M_OURO)
	for k in 3:
		var a: float = k * TAU / 3.0
		var perna := CylinderMesh.new()
		perna.top_radius = 0.06
		perna.bottom_radius = 0.04
		perna.height = 1.6
		_malha(mesa, perna, Vector3(cos(a) * 0.9, 0.8, sin(a) * 0.9), M_VIDRO)
	var col := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 1.3
	cs.height = 0.12
	col.shape = cs
	col.position.y = 1.6
	mesa.add_child(col)
	# a chave dourada
	_chave = Node3D.new()
	_chave.name = "ChaveDourada"
	_chave.position = pos + Vector3(0, 2.25, 0)
	add_child(_chave)
	var haste := CylinderMesh.new()
	haste.top_radius = 0.05
	haste.bottom_radius = 0.05
	haste.height = 0.7
	var h := _malha(_chave, haste, Vector3.ZERO, M_OURO)
	h.rotation.z = PI / 2.0
	var argola := TorusMesh.new()
	argola.inner_radius = 0.1
	argola.outer_radius = 0.18
	var ar := _malha(_chave, argola, Vector3(-0.45, 0, 0), M_OURO)
	ar.rotation.x = PI / 2.0
	_malha(_chave, _bm(Vector3(0.08, 0.2, 0.06)), Vector3(0.28, -0.1, 0), M_OURO)
	_malha(_chave, _bm(Vector3(0.08, 0.14, 0.06)), Vector3(0.16, -0.07, 0), M_OURO)
	var brilho := OmniLight3D.new()
	brilho.light_color = Color(1.0, 0.85, 0.4)
	brilho.light_energy = 1.2
	brilho.omni_range = 2.5
	_chave.add_child(brilho)
	var pega := Area3D.new()
	pega.collision_layer = 0
	pega.collision_mask = 6
	_forma(pega, Vector3(1.0, 1.0, 1.0))
	_chave.add_child(pega)
	pega.body_entered.connect(_pegar_chave)


func _portinha(pos: Vector3) -> void:
	var porta := Node3D.new()
	porta.name = "Portinha"
	porta.position = pos
	porta.rotation.y = PI
	add_child(porta)
	_malha(porta, _bm(Vector3(1.0, 1.3, 0.12)), Vector3(0, 0.65, 0), M_GRAMA)
	_malha(porta, _bm(Vector3(1.2, 1.45, 0.08)), Vector3(0, 0.72, -0.05), M_OURO)
	var mac := SphereMesh.new()
	mac.radius = 0.07
	mac.height = 0.14
	_malha(porta, mac, Vector3(0.32, 0.65, 0.09), M_OURO)
	# cortina baixinha na frente
	_cortina = Node3D.new()
	_cortina.position = pos + Vector3(0, 0, -0.35)
	add_child(_cortina)
	for k in 7:
		var dobra := CylinderMesh.new()
		dobra.top_radius = 0.17
		dobra.bottom_radius = 0.2
		dobra.height = 2.0
		_malha(_cortina, dobra, Vector3(-1.0 + k * 0.33, 1.0, 0), M_CORTINA)
	_malha(_cortina, _bm(Vector3(2.6, 0.12, 0.12)), Vector3(0, 2.05, 0), M_OURO)
	_porta_luz = OmniLight3D.new()
	_porta_luz.light_color = Color(0.6, 1.0, 0.6)
	_porta_luz.light_energy = 0.0
	_porta_luz.omni_range = 4.0
	_porta_luz.position = pos + Vector3(0, 0.8, -0.8)
	add_child(_porta_luz)
	var trancada := Area3D.new()
	trancada.collision_layer = 0
	trancada.collision_mask = 2
	trancada.position = pos + Vector3(0, 0.8, -1.0)
	_forma(trancada, Vector3(2.6, 2.0, 1.2))
	add_child(trancada)
	trancada.body_entered.connect(func(b: Node3D) -> void:
		if b.is_in_group("sonhador") and not _tem_chave:
			_dica("Trancada… onde está a chave?" if MenuEstanteUI._pt() else "Locked… where's the key?"))


func _pegar_chave(corpo: Node3D) -> void:
	if _tem_chave or not (corpo.is_in_group("sonhador") or corpo.is_in_group("mel")):
		return
	_tem_chave = true
	var p := AudioStreamPlayer.new()
	p.stream = SOM_CHAVE
	p.bus = &"Efeitos"
	add_child(p)
	p.play()
	Efeitos.estrelinhas(self, _chave.global_position)
	_dica("A chave dourada! Agora, a portinha…" if MenuEstanteUI._pt() else "The golden key! Now, the little door…")
	# a cortina sobe e a portinha brilha
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_cortina, "position:y", 2.4, 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_cortina, "scale:y", 0.3, 1.2)
	tw.tween_property(_porta_luz, "light_energy", 2.5, 1.2)
	var saida := MissionItem.new()
	saida.is_exit = true
	saida.bob_height = 0.0
	saida.spin_speed = 0.0
	saida.collision_layer = 0
	saida.collision_mask = 6
	saida.position = _porta_luz.position + Vector3(0, -0.2, 0.5)
	_forma(saida, Vector3(1.4, 1.6, 0.8))
	add_child(saida)


func _placa(texto: String, pos: Vector3, rot_y: float) -> Label3D:
	var l := Label3D.new()
	l.text = texto
	l.font = FONTE
	l.font_size = 72
	l.pixel_size = 0.006
	l.modulate = Color(1.0, 0.95, 0.82)
	l.outline_modulate = Color(0.35, 0.2, 0.4)
	l.outline_size = 18
	l.position = pos
	l.rotation.y = rot_y
	l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	l.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
	add_child(l)
	return l


## Dica curtinha no rodapé da tela.
func _dica(texto: String) -> void:
	if _dica_atual and is_instance_valid(_dica_atual):
		_dica_atual.get_parent().queue_free()
	var camada := CanvasLayer.new()
	camada.layer = 45
	add_child(camada)
	_dica_atual = MenuEstanteUI._rotulo(texto, FONTE, 36, Color(1.0, 0.95, 0.82), Color(0.25, 0.15, 0.35), 12)
	_dica_atual.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_dica_atual.anchor_left = 0.0
	_dica_atual.anchor_right = 1.0
	_dica_atual.offset_top = -120
	_dica_atual.offset_bottom = -60
	camada.add_child(_dica_atual)
	var tw := create_tween()
	tw.tween_interval(3.0)
	tw.tween_property(_dica_atual, "modulate:a", 0.0, 0.8)
	tw.tween_callback(camada.queue_free)


# ---------------- Coelho Branco ----------------

func _coelho() -> void:
	# No topo, apressado na beira do buraco…
	var c1 := _npc_coelho(Vector3(2.5, TOPO, -RAIO_POCO - 1.2), PackedStringArray([
		"Ai, ai! Ai, ai! Vou chegar tarde!" if MenuEstanteUI._pt() else "Oh dear! Oh dear! I shall be late!",
		"Meu relógio! Que horas são?!" if MenuEstanteUI._pt() else "My watch! What time is it?!"]))
	c1.rotation.y = PI * 0.8
	# …e lá embaixo, no corredor, sumindo de vista.
	var c2 := _npc_coelho(Vector3(1.0, 0, 18.0), PackedStringArray([
		"Oh, minhas orelhas e bigodes, como está ficando tarde!" if MenuEstanteUI._pt()
			else "Oh my ears and whiskers, how late it's getting!"]))
	c2.rotation.y = PI


func _npc_coelho(pos: Vector3, falas: PackedStringArray) -> Personagem:
	var p := Personagem.new()
	p.modelo = COELHO
	p.escala = 0.72
	p.altura_pes = 0.68
	p.altura_balao = 1.85
	p.anim_parado = &"human_000063"
	p.anim_falando = &"human_000041"
	p.falas = falas
	p.tom_voz = 420.0
	p.raio_conversa = 6.0
	p.position = pos
	add_child(p)
	return p
