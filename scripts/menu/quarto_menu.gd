extends Node3D
## Tela de escolha de história (estilo do conceito):
##   • esquerda: Nino lendo na cama, desfocado, com a luz quente do abajur e a janela virando bokeh;
##   • direita: estante alta e lotada, nítida, com um rastro de faíscas douradas;
##   • moldura de papelão kraft, título num remendo de jeans e etiqueta ‹ livro › embaixo.
## Escolher um livro: o foco passa para o Nino, o livro voa até ele, abre o sumário (capítulos),
## ele lê a última linha em balbucio, diz "continua…" ou "e FIM", e as nuvens levam ao sonho.

const PASTA_LIVROS := "res://data/livros/"

@export_group("Foco")
@export var foco_estante_distancia: float = 2.7
@export var foco_nino_distancia: float = 3.4
@export var duracao_rack_focus: float = 1.2

var _attrs: CameraAttributesPractical
var _livros: Array[ShelfBook] = []
var _indice: int = -1
var _ocupado: bool = false

@onready var _camera: Camera3D = $Camera3D
@onready var _nino: Node3D = $Nino
@onready var _maos: Marker3D = $Nino/MaosDoNino
@onready var _voz: BabbleVoice = $VozDoNino
@onready var _dialogo: BabbleDialog = $Dialogo
@onready var _sumario: ChapterPicker = $Sumario
@onready var _estante: Estante = $Estante
@onready var _ui: MenuEstanteUI = $Interface


func _ready() -> void:
	get_viewport().physics_object_picking = true
	GameState.cutscene = false
	_attrs = _camera.attributes as CameraAttributesPractical
	if _attrs == null:
		_attrs = CameraAttributesPractical.new()
		_camera.attributes = _attrs
	_camera.look_at($AlvoCamera.global_position)
	# Nino olha para o livro no colo, virado de 3/4 para a estante
	_nino.look_at(_nino.global_position + Vector3(0.9, 0.0, 1.0), Vector3.UP)

	_estante.construir(_carregar_livros())
	_livros = _estante.livros
	for livro: ShelfBook in _livros:
		livro.hovered.connect(_on_livro_hover)
		livro.clicked.connect(_escolher)
	_ui.anterior.connect(func() -> void: _mover(-1))
	_ui.proximo.connect(func() -> void: _mover(1))
	_ui.selecionar.connect(_on_selecionar)

	_foco_na_estante(0.0)
	_costurar_recompensas()
	Transicao.descobrir(1.2)
	var manha: String = GameState.consumir_manha()
	if not manha.is_empty():
		_amanhecer(manha)
	if not _livros.is_empty():
		_selecionar(0)


func _unhandled_input(event: InputEvent) -> void:
	if _ocupado or _livros.is_empty():
		return
	if event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		_mover(1)
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		_mover(-1)
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		_escolher(_livros[_indice])


# ---------------- Livros ----------------

func _carregar_livros() -> Array[BookData]:
	var lista: Array[BookData] = []
	for arquivo: String in ResourceLoader.list_directory(PASTA_LIVROS):
		if not arquivo.ends_with(".tres"):
			continue
		var livro := load(PASTA_LIVROS + arquivo) as BookData
		if livro and livro.em_dominio_publico_mundial():
			lista.append(livro)
	lista.sort_custom(func(a: BookData, b: BookData) -> bool: return a.ano_publicacao < b.ano_publicacao)
	return lista


func _on_selecionar() -> void:
	if not _livros.is_empty():
		_escolher(_livros[_indice])


func _mover(passo: int) -> void:
	if _ocupado or _livros.is_empty():
		return
	_selecionar(wrapi(_indice + passo, 0, _livros.size()))


func _on_livro_hover(livro: ShelfBook) -> void:
	if not _ocupado:
		_selecionar(_livros.find(livro))


func _selecionar(i: int) -> void:
	if i < 0:
		return
	if i == _indice:
		_livros[i].hop()
		return
	if _indice >= 0:
		_livros[_indice].set_selected(false)
	_indice = i
	var livro: ShelfBook = _livros[i]
	livro.set_selected(true)
	_estante.destacar(livro)
	_voz.blip(livro.data.titulo.substr(0, 1), 1.3)
	_ui.definir_livro(livro.data.titulo, livro.progresso_texto())


# ---------------- Escolha: ler, "e FIM", nuvens ----------------

func _escolher(livro: ShelfBook) -> void:
	if _ocupado:
		return
	if not GameState.livro_jogavel(livro.data):
		livro.hop()
		_ui.definir_livro(livro.data.titulo, "em breve — ainda sendo costurado 🧵")
		_voz.blip("e", 0.8)
		return
	_ocupado = true
	GameState.cutscene = true
	_ui.esconder()
	livro.hop()
	await get_tree().create_timer(0.25).timeout

	_foco_no_nino(duracao_rack_focus)
	await livro.voar_para(_maos.global_position, 1.0)
	_nino.get_node("LivroNoColo").visible = false  # o livro escolhido toma o lugar do que estava no colo

	# Sumário com o marcador de página (livros de um capítulo só pulam esta etapa).
	var numero: int = 1
	if livro.data.total_capitulos() > 1:
		numero = await _sumario.escolher(livro.data)
		if numero < 0:
			_foco_na_estante(duracao_rack_focus)
			_nino.get_node("LivroNoColo").visible = true
			await livro.voltar()
			_ui.mostrar()
			GameState.cutscene = false
			_ocupado = false
			return
	var capitulo: ChapterData = livro.data.lista_capitulos()[numero - 1]

	var linha: String = capitulo.ultima_linha if not capitulo.ultima_linha.is_empty() else capitulo.rotulo() + "…"
	var animador := _nino as CharacterAnimator
	if animador:
		animador.modo_fixo = &"ual/Sitting_Talking"  # lendo em voz alta
	await _dialogo.falar(linha, _voz)
	if animador:
		animador.modo_fixo = &"ual/Sitting_Idle"
	if livro.data.e_ultimo(capitulo):
		await _dialogo.dizer_fim(_voz)
	else:
		await _dialogo.dizer_continua(_voz)

	# A câmera se aproxima devagar e as nuvens tomam conta.
	var tw := create_tween()
	tw.tween_property(_camera, "fov", _camera.fov * 0.7, 1.6).set_trans(Tween.TRANS_SINE)
	await Transicao.cobrir(1.6).finished
	GameState.entrar_no_capitulo(livro.data, capitulo)


# ---------------- Manhã e recompensas ----------------

## Cada capítulo concluído vira um botão costurado na colcha da cama (o quarto guarda as conquistas).
func _costurar_recompensas() -> void:
	var colcha := get_node_or_null("Cama/Colcha") as Node3D
	if colcha == null:
		return
	var cores: Array[Color] = [Color(1, 0.8, 0.3), Color(0.35, 0.55, 0.95), Color(0.9, 0.3, 0.3), Color(0.45, 0.8, 0.5),
		Color(0.85, 0.6, 0.95)]
	for i in mini(GameState.total_concluidos(), 24):
		var b := PropProcedural.new()
		b.tipo = PropProcedural.Tipo.BOTAO
		b.tamanho = 0.07
		b.com_colisao = false
		b.cor = cores[i % cores.size()]
		b.position = Vector3(-0.5 + (i % 6) * 0.2, 0.052, 0.55 - floori(i / 6.0) * 0.2)
		colcha.add_child(b)


## Manhã depois de um sonho: luz do dia entrando, Nino conta o que sonhou e ganha um botão na colcha.
func _amanhecer(texto: String) -> void:
	_ocupado = true
	_ui.esconder(0.0)
	var env: Environment = ($WorldEnvironment as WorldEnvironment).environment
	var noite: Dictionary = {"cor": env.ambient_light_color, "energia": env.ambient_light_energy}
	var luar := $Luar as DirectionalLight3D
	var luar_cor: Color = luar.light_color
	var luar_e: float = luar.light_energy
	var tw := create_tween().set_parallel(true)
	tw.tween_property(env, "ambient_light_color", Color(1.0, 0.9, 0.75), 1.5)
	tw.tween_property(env, "ambient_light_energy", 1.1, 1.5)
	tw.tween_property(luar, "light_color", Color(1.0, 0.85, 0.6), 1.5)
	tw.tween_property(luar, "light_energy", 1.4, 1.5)
	await tw.finished
	var animador := _nino as CharacterAnimator
	if animador:
		animador.modo_fixo = &"ual/Sitting_Talking"
	var bom_dia: String = "Bom dia! Que sonho! " if MenuEstanteUI._pt() else "Good morning! What a dream! "
	await _dialogo.falar(bom_dia + texto, _voz)
	if animador:
		animador.modo_fixo = &"ual/Sitting_Idle"
	var volta := create_tween().set_parallel(true)
	volta.tween_property(env, "ambient_light_color", noite["cor"], 2.0)
	volta.tween_property(env, "ambient_light_energy", noite["energia"], 2.0)
	volta.tween_property(luar, "light_color", luar_cor, 2.0)
	volta.tween_property(luar, "light_energy", luar_e, 2.0)
	await volta.finished
	_ui.mostrar()
	_ocupado = false


# ---------------- Rack focus (desfoque) ----------------

func _foco_na_estante(duracao: float) -> void:
	_attrs.dof_blur_amount = 0.16
	_attrs.dof_blur_near_enabled = false
	_attrs.dof_blur_far_enabled = true
	_attrs.dof_blur_far_transition = 1.2
	if duracao <= 0.0:
		_attrs.dof_blur_far_distance = foco_estante_distancia
		return
	create_tween().tween_property(_attrs, "dof_blur_far_distance", foco_estante_distancia, duracao)


func _foco_no_nino(duracao: float) -> void:
	_attrs.dof_blur_near_enabled = true
	_attrs.dof_blur_near_distance = 0.01
	_attrs.dof_blur_near_transition = 1.4
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_attrs, "dof_blur_far_distance", 30.0, duracao)
	tw.tween_property(_attrs, "dof_blur_near_distance", foco_nino_distancia, duracao)
	tw.chain().tween_callback(func() -> void: _attrs.dof_blur_far_enabled = false)
