class_name HudSonho
extends CanvasLayer
## Interface durante o sonho, no estilo artesanal da estante:
##   • canto superior esquerdo: botões da missão (desenhados como botões de costura, cheios ao pegar);
##   • canto superior direito (pesadelos): a Luna em fases da lua conforme o brilho que resta;
##   • ao completar: faixa "Capítulo concluído!" num remendo de jeans, com o nome do capítulo.

const FONTE_B := preload("res://assets/fonts/Fredoka-Bold.woff2")
const FONTE_SB := preload("res://assets/fonts/Fredoka-SemiBold.woff2")
const REMENDO := preload("res://assets/ui/remendo_jeans.png")
const CREME := Color(1.0, 0.95, 0.82)

var _botoes: BotoesMissao
var _lua: LuaFase
var _faixa: Control
var _chefe_caixa: VBoxContainer
var _chefe_barra: ProgressBar


func _ready() -> void:
	add_to_group("hud_sonho")
	layer = 40
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(raiz)

	_botoes = BotoesMissao.new()
	_botoes.position = Vector2(36, 30)
	_botoes.total = GameState.itens_necessarios
	var cap: ChapterData = GameState.capitulo_atual
	_botoes.visible = cap == null or cap.missao == BookData.MissionKind.ENCONTRAR
	raiz.add_child(_botoes)

	_lua = LuaFase.new()
	_lua.anchor_left = 1.0
	_lua.anchor_right = 1.0
	_lua.position = Vector2(-110, 28)
	_lua.visible = GameState.e_pesadelo()
	raiz.add_child(_lua)

	_faixa = _criar_faixa()
	raiz.add_child(_faixa)

	GameState.mission_progress.connect(func(atual: int, total: int) -> void:
		_botoes.total = total
		_botoes.pegar(atual))
	GameState.mission_completed.connect(_comemorar)
	_ligar_luna.call_deferred()


func _ligar_luna() -> void:
	for n: Node in get_tree().get_nodes_in_group("luna"):
		var luna := n as MoonLamp
		if luna:
			luna.glow_changed.connect(func(v: float) -> void: _lua.brilho = v)
			_lua.visible = true if GameState.e_pesadelo() else _lua.visible
			return


func _criar_faixa() -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.visible = false
	var remendo := NinePatchRect.new()
	remendo.texture = REMENDO
	for m: String in ["patch_margin_left", "patch_margin_right", "patch_margin_top", "patch_margin_bottom"]:
		remendo.set(m, 40)
	remendo.anchor_left = 0.5
	remendo.anchor_right = 0.5
	remendo.anchor_top = 0.38
	remendo.anchor_bottom = 0.38
	remendo.offset_left = -330
	remendo.offset_right = 330
	remendo.offset_top = -70
	remendo.offset_bottom = 70
	c.add_child(remendo)
	var coluna := VBoxContainer.new()
	coluna.set_anchors_preset(Control.PRESET_FULL_RECT)
	coluna.alignment = BoxContainer.ALIGNMENT_CENTER
	remendo.add_child(coluna)
	coluna.add_child(MenuEstanteUI._rotulo("Capítulo concluído!" if MenuEstanteUI._pt() else "Chapter complete!",
		FONTE_B, 48, CREME, Color(0.1, 0.1, 0.25), 8))
	var nome: String = GameState.capitulo_atual.rotulo() if GameState.capitulo_atual else ""
	coluna.add_child(MenuEstanteUI._rotulo(nome, FONTE_SB, 26, CREME, Color(0.1, 0.1, 0.25), 6))
	return c


func _comemorar() -> void:
	_faixa.visible = true
	_faixa.pivot_offset = get_viewport().get_visible_rect().size * Vector2(0.5, 0.38)
	_faixa.scale = Vector2(0.3, 0.3)
	_faixa.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_faixa, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_faixa, "modulate:a", 1.0, 0.25)
	var nino := get_tree().get_first_node_in_group("sonhador") as Node3D
	if nino:
		for k in 3:
			Efeitos.estrelinhas(get_tree().current_scene, nino.global_position + nino.global_basis.y * (1.0 + k * 0.5))


## Barra do chefe (ex.: Rainha de Copas): um coração de feltro que esvazia conforme a Luna a acalma.
func mostrar_chefe(chefe: ShadowCreature) -> void:
	if _chefe_caixa == null:
		_chefe_caixa = VBoxContainer.new()
		_chefe_caixa.anchor_left = 0.5
		_chefe_caixa.anchor_right = 0.5
		_chefe_caixa.anchor_top = 1.0
		_chefe_caixa.anchor_bottom = 1.0
		_chefe_caixa.offset_left = -260
		_chefe_caixa.offset_right = 260
		_chefe_caixa.offset_top = -96
		_chefe_caixa.offset_bottom = -30
		_chefe_caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_chefe_caixa)
		_chefe_caixa.add_child(MenuEstanteUI._rotulo("", FONTE_B, 28, CREME, Color(0.3, 0.05, 0.12), 8))
		_chefe_barra = ProgressBar.new()
		_chefe_barra.show_percentage = false
		_chefe_barra.custom_minimum_size = Vector2(520, 22)
		_chefe_barra.max_value = 1.0
		var fundo := StyleBoxFlat.new()
		fundo.bg_color = Color(0.12, 0.08, 0.2, 0.85)
		fundo.set_corner_radius_all(11)
		fundo.set_border_width_all(2)
		fundo.border_color = CREME
		var cheio := StyleBoxFlat.new()
		cheio.bg_color = Color(0.85, 0.15, 0.3)
		cheio.set_corner_radius_all(11)
		_chefe_barra.add_theme_stylebox_override("background", fundo)
		_chefe_barra.add_theme_stylebox_override("fill", cheio)
		_chefe_caixa.add_child(_chefe_barra)
	(_chefe_caixa.get_child(0) as Label).text = "♥ " + chefe.nome_chefe + " ♥"
	_chefe_barra.value = chefe.fracao()
	_chefe_caixa.visible = true
	_chefe_caixa.modulate.a = 0.0
	create_tween().tween_property(_chefe_caixa, "modulate:a", 1.0, 0.6)
	chefe.escuridao_mudou.connect(func(f: float) -> void: _chefe_barra.value = f)
	chefe.dissipated.connect(func() -> void: _chefe_caixa.visible = false)


## Escudo do chefe ligado: a barra fica acinzentada.
func chefe_protegido(sim: bool) -> void:
	if _chefe_barra:
		_chefe_barra.modulate = Color(0.6, 0.6, 0.7) if sim else Color.WHITE


## Fileira de botões de costura desenhados (vazios = contorno, pegos = amarelos com furinhos).
class BotoesMissao:
	extends Control
	var total: int = 3:
		set(v):
			total = v
			queue_redraw()
	var pegos: int = 0
	var _pulo: float = 0.0

	func pegar(n: int) -> void:
		pegos = n
		_pulo = 1.0
		queue_redraw()

	func _process(delta: float) -> void:
		if _pulo > 0.0:
			_pulo = maxf(0.0, _pulo - delta * 2.5)
			queue_redraw()

	func _draw() -> void:
		var fundo := StyleBoxFlat.new()
		fundo.bg_color = Color(0.97, 0.93, 0.85, 0.92)
		fundo.border_color = Color(0.55, 0.42, 0.3)
		fundo.set_border_width_all(2)
		fundo.set_corner_radius_all(28)
		draw_style_box(fundo, Rect2(0, 0, 30 + total * 52, 64))
		for i in total:
			var c := Vector2(40 + i * 52, 32)
			var r: float = 19.0 + (6.0 * _pulo if i == pegos - 1 else 0.0)
			if i < pegos:
				draw_circle(c, r, Color(1.0, 0.8, 0.28))
				draw_arc(c, r, 0, TAU, 32, Color(0.7, 0.5, 0.15), 3.0)
				draw_arc(c, r * 0.72, 0, TAU, 32, Color(0.8, 0.58, 0.2), 2.0)
				for o: Vector2 in [Vector2(-5, -5), Vector2(5, -5), Vector2(-5, 5), Vector2(5, 5)]:
					draw_circle(c + o, 2.6, Color(0.35, 0.22, 0.1))
				draw_line(c + Vector2(-5, -5), c + Vector2(5, 5), Color(0.85, 0.2, 0.25), 2.0)
				draw_line(c + Vector2(5, -5), c + Vector2(-5, 5), Color(0.85, 0.2, 0.25), 2.0)
			else:
				draw_arc(c, r, 0, TAU, 32, Color(0.55, 0.42, 0.3, 0.8), 3.0)
				for o: Vector2 in [Vector2(-5, -5), Vector2(5, -5), Vector2(-5, 5), Vector2(5, 5)]:
					draw_circle(c + o, 2.2, Color(0.55, 0.42, 0.3, 0.6))


## A Luna como lua que vai minguando conforme o brilho acaba (cheia → crescente → nova).
class LuaFase:
	extends Control
	var brilho: float = 1.0:
		set(v):
			brilho = clampf(v, 0.0, 1.0)
			queue_redraw()

	func _draw() -> void:
		var c := Vector2(40, 40)
		var r: float = 30.0
		draw_circle(c, 36, Color(0.12, 0.12, 0.25, 0.75))
		draw_circle(c, r, Color(0.25, 0.25, 0.4))  # parte apagada
		# parte acesa = lua menos o disco de sombra que avança da esquerda (polígono do crescente)
		var sc: Vector2 = c + Vector2(-lerpf(0.0, 2.2 * r, brilho), 0)
		var rs: float = r + 1.0
		var pontos := PackedVector2Array()
		for i in 64:
			var a: float = PI + i * TAU / 64.0
			var p: Vector2 = c + Vector2(cos(a), sin(a)) * r
			if p.distance_to(sc) >= rs:
				pontos.append(p)
		for i in 33:
			var a: float = PI / 2.0 - i * PI / 32.0
			var q: Vector2 = sc + Vector2(cos(a), sin(a)) * rs
			if q.distance_to(c) <= r:
				pontos.append(q)
		if pontos.size() >= 3:
			draw_colored_polygon(pontos, Color(1.0, 0.95, 0.75))
		draw_arc(c, r + 1.0, 0, TAU, 48, Color(0.75, 0.8, 1.0, 0.6), 2.0)
