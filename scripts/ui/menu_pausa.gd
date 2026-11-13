extends CanvasLayer
## Autoload "Pausa": Esc / Start abre o menu (no sonho e na estante).
## Continuar · Configurações (música, efeitos, tela cheia, idioma) · Voltar para a estante · Sair do jogo.
## Configurações ficam em user://configuracoes.cfg.

const FONTE_B := preload("res://assets/fonts/Fredoka-Bold.woff2")
const FONTE_SB := preload("res://assets/fonts/Fredoka-SemiBold.woff2")
const REMENDO := preload("res://assets/ui/remendo_jeans.png")
const ARQUIVO := "user://configuracoes.cfg"
const CREME := Color(1.0, 0.95, 0.82)
const MARROM := Color(0.28, 0.18, 0.12)

var _fundo: ColorRect
var _painel: PanelContainer
var _principal: VBoxContainer
var _config: VBoxContainer
var _cfg := ConfigFile.new()


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_garantir_barramentos()
	_cfg.load(ARQUIVO)
	_aplicar_config()
	_montar()
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pausa"):
		get_viewport().set_input_as_handled()
		if visible:
			fechar()
		elif not GameState.cutscene:
			abrir()


func abrir() -> void:
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_mostrar(_principal)


func fechar() -> void:
	visible = false
	get_tree().paused = false


# ---------------- configurações ----------------

func _garantir_barramentos() -> void:
	for nome: String in ["Musica", "Efeitos"]:
		if AudioServer.get_bus_index(nome) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, nome)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")


func _aplicar_config() -> void:
	_volume("Musica", _cfg.get_value("audio", "musica", 0.8))
	_volume("Efeitos", _cfg.get_value("audio", "efeitos", 0.9))
	var cheia: bool = _cfg.get_value("video", "tela_cheia", false)
	if not Engine.is_editor_hint() and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if cheia else DisplayServer.WINDOW_MODE_WINDOWED)
	var idioma: String = _cfg.get_value("geral", "idioma", "")
	if not idioma.is_empty():
		TranslationServer.set_locale(idioma)


func _volume(bus: String, linear: float) -> void:
	var i: int = AudioServer.get_bus_index(bus)
	if i >= 0:
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(linear, 0.0001)))


func _salvar(secao: String, chave: String, valor: Variant) -> void:
	_cfg.set_value(secao, chave, valor)
	_cfg.save(ARQUIVO)
	_aplicar_config()


# ---------------- interface ----------------

func _montar() -> void:
	_fundo = ColorRect.new()
	_fundo.color = Color(0.08, 0.06, 0.14, 0.6)
	_fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fundo)
	_painel = PanelContainer.new()
	var estilo := StyleBoxTexture.new()
	estilo.texture = REMENDO
	estilo.texture_margin_left = 40
	estilo.texture_margin_right = 40
	estilo.texture_margin_top = 40
	estilo.texture_margin_bottom = 40
	estilo.content_margin_left = 54
	estilo.content_margin_right = 54
	estilo.content_margin_top = 44
	estilo.content_margin_bottom = 44
	_painel.add_theme_stylebox_override("panel", estilo)
	_painel.set_anchors_preset(Control.PRESET_CENTER)
	_painel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_painel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_painel)
	var pilha := VBoxContainer.new()
	_painel.add_child(pilha)

	_principal = _coluna("Pausa" if _pt() else "Paused")
	_principal.add_child(_botao("Continuar" if _pt() else "Continue", fechar))
	_principal.add_child(_botao("Configurações" if _pt() else "Settings", func() -> void: _mostrar(_config)))
	_principal.add_child(_botao("Voltar para a estante" if _pt() else "Back to the bookshelf", _voltar_estante))
	_principal.add_child(_botao("Sair do jogo" if _pt() else "Quit game", func() -> void: get_tree().quit()))
	pilha.add_child(_principal)

	_config = _coluna("Configurações" if _pt() else "Settings")
	_config.add_child(_slider("Música" if _pt() else "Music", "audio", "musica", 0.8))
	_config.add_child(_slider("Efeitos" if _pt() else "Effects", "audio", "efeitos", 0.9))
	var cheia := CheckButton.new()
	cheia.text = "Tela cheia" if _pt() else "Fullscreen"
	cheia.button_pressed = _cfg.get_value("video", "tela_cheia", false)
	_estilo_texto(cheia, 26)
	cheia.toggled.connect(func(v: bool) -> void: _salvar("video", "tela_cheia", v))
	_config.add_child(cheia)
	var idioma := OptionButton.new()
	idioma.add_item("Português", 0)
	idioma.add_item("English", 1)
	idioma.selected = 0 if _pt() else 1
	_estilo_texto(idioma, 24)
	idioma.item_selected.connect(func(i: int) -> void: _salvar("geral", "idioma", "pt_BR" if i == 0 else "en"))
	_config.add_child(idioma)
	_config.add_child(_botao("Voltar" if _pt() else "Back", func() -> void: _mostrar(_principal)))
	pilha.add_child(_config)


func _mostrar(coluna: VBoxContainer) -> void:
	_principal.visible = coluna == _principal
	_config.visible = coluna == _config
	for filho: Node in coluna.get_children():
		if filho is Control and (filho as Control).focus_mode != Control.FOCUS_NONE:
			(filho as Control).grab_focus.call_deferred()
			break


func _voltar_estante() -> void:
	fechar()
	GameState.acordar()


func _coluna(titulo: String) -> VBoxContainer:
	var c := VBoxContainer.new()
	c.add_theme_constant_override("separation", 14)
	c.custom_minimum_size = Vector2(440, 0)
	c.add_child(MenuEstanteUI._rotulo(titulo, FONTE_B, 44, CREME, Color(0.1, 0.1, 0.25), 8))
	return c


func _botao(texto: String, acao: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	_estilo_texto(b, 28)
	b.pressed.connect(acao)
	return b


## Pílula creme (normal) / amarela com borda vermelha (foco), igual para botões, check e lista.
func _pilula(b: Control) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.97, 0.93, 0.85)
	normal.set_corner_radius_all(22)
	normal.set_content_margin_all(10)
	var foco := normal.duplicate() as StyleBoxFlat
	foco.bg_color = Color(1.0, 0.82, 0.35)
	foco.set_border_width_all(3)
	foco.border_color = Color(0.85, 0.2, 0.3)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", foco)
	b.add_theme_stylebox_override("focus", foco)
	b.add_theme_stylebox_override("pressed", foco)
	b.add_theme_stylebox_override("hover_pressed", foco)


func _slider(texto: String, secao: String, chave: String, padrao: float) -> Control:
	var linha := HBoxContainer.new()
	var l := MenuEstanteUI._rotulo(texto, FONTE_SB, 26, CREME, Color(0.1, 0.1, 0.25), 6)
	l.custom_minimum_size = Vector2(150, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	linha.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = _cfg.get_value(secao, chave, padrao)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(func(v: float) -> void: _salvar(secao, chave, v))
	linha.add_child(s)
	return linha


func _estilo_texto(c: Control, tamanho: int) -> void:
	c.add_theme_font_override("font", FONTE_SB)
	c.add_theme_font_size_override("font_size", tamanho)
	for cor: String in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color",
			"font_hover_pressed_color"]:
		c.add_theme_color_override(cor, MARROM)
	_pilula(c)


static func _pt() -> bool:
	return TranslationServer.get_locale().begins_with("pt")
