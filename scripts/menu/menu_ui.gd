class_name MenuEstanteUI
extends CanvasLayer
## Interface da estante (no estilo do conceito): moldura de papelão kraft, título num remendo de jeans
## costurado, "ESCOLHA UMA HISTÓRIA" e, embaixo, o botão "Selecionar" + etiqueta de papel ‹ livro ›.

signal anterior
signal proximo
signal selecionar

const FONTE_B := preload("res://assets/fonts/Fredoka-Bold.woff2")
const FONTE_SB := preload("res://assets/fonts/Fredoka-SemiBold.woff2")
const MOLDURA := preload("res://assets/ui/moldura_kraft.png")
const REMENDO := preload("res://assets/ui/remendo_jeans.png")
const ETIQUETA := preload("res://assets/ui/etiqueta_papel.png")
const CREME := Color(1.0, 0.95, 0.82)
const MARROM := Color(0.28, 0.18, 0.12)

var _conteudo: Control
var _icone_estilo: StyleBoxFlat
var _icone_texto: Label
var _dispositivo: String = ""
var _titulo_livro: Label
var _detalhe_livro: Label


func _ready() -> void:
	layer = 30
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(raiz)

	var moldura := TextureRect.new()
	moldura.texture = MOLDURA
	moldura.set_anchors_preset(Control.PRESET_FULL_RECT)
	moldura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	moldura.stretch_mode = TextureRect.STRETCH_SCALE
	moldura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(moldura)

	_conteudo = Control.new()
	_conteudo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_conteudo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(_conteudo)

	# Título no remendo de jeans
	var remendo := NinePatchRect.new()
	remendo.texture = REMENDO
	remendo.patch_margin_left = 40
	remendo.patch_margin_right = 40
	remendo.patch_margin_top = 40
	remendo.patch_margin_bottom = 40
	remendo.anchor_left = 0.5
	remendo.anchor_right = 0.5
	remendo.offset_left = -360
	remendo.offset_right = 360
	remendo.offset_top = 26
	remendo.offset_bottom = 116
	remendo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_conteudo.add_child(remendo)
	var titulo := _rotulo(_titulo_do_jogo(), FONTE_B, 46, CREME, Color(0.1, 0.1, 0.25), 8)
	titulo.set_anchors_preset(Control.PRESET_FULL_RECT)
	remendo.add_child(titulo)

	var sub := _rotulo(tr("ESCOLHA UMA HISTÓRIA") if _pt() else "CHOOSE A STORY", FONTE_SB, 40, CREME,
		Color(0.25, 0.15, 0.1, 0.9), 10)
	sub.anchor_right = 1.0
	sub.offset_top = 128
	sub.offset_bottom = 180
	_conteudo.add_child(sub)

	# Barra de baixo: [Ⓐ Selecionar]  [‹  título do livro  ›]
	var barra := HBoxContainer.new()
	barra.anchor_left = 1.0
	barra.anchor_right = 1.0
	barra.anchor_top = 1.0
	barra.anchor_bottom = 1.0
	barra.offset_left = -820
	barra.offset_right = -70
	barra.offset_top = -126
	barra.offset_bottom = -54
	barra.alignment = BoxContainer.ALIGNMENT_END
	barra.add_theme_constant_override("separation", 14)
	_conteudo.add_child(barra)
	barra.add_child(_pilula_selecionar())
	barra.add_child(_etiqueta_livro())
	var joys: Array[int] = Input.get_connected_joypads()
	_aplicar_icone(_familia(Input.get_joy_name(joys[0])) if not joys.is_empty() else "teclado")


## Troca o ícone do botão conforme o último dispositivo usado (teclado, Xbox, PlayStation, Nintendo).
func _input(event: InputEvent) -> void:
	var tipo: String = ""
	if event is InputEventJoypadButton:
		tipo = _familia(Input.get_joy_name(event.device))
	elif event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.5:
		tipo = _familia(Input.get_joy_name(event.device))
	elif event is InputEventKey or event is InputEventMouseButton:
		tipo = "teclado"
	if tipo != "" and tipo != _dispositivo:
		_aplicar_icone(tipo)


static func _familia(nome: String) -> String:
	var n: String = nome.to_lower()
	for chave: String in ["playstation", "dualsense", "dualshock", "ps4", "ps5", "sony"]:
		if n.contains(chave):
			return "ps"
	for chave: String in ["nintendo", "switch", "joy-con", "pro controller"]:
		if n.contains(chave):
			return "nintendo"
	return "xbox"


func _aplicar_icone(tipo: String) -> void:
	_dispositivo = tipo
	# Botão de baixo do controle (o que confirma): A no Xbox, ✕ no PlayStation, B no layout Nintendo.
	var dados: Dictionary = {
		"xbox": ["A", Color(0.32, 0.62, 0.25)],
		"ps": ["X", Color(0.22, 0.36, 0.72)],
		"nintendo": ["B", Color(0.28, 0.28, 0.32)],
		"teclado": ["Enter", Color(0.45, 0.3, 0.2)],
	}
	var d: Array = dados.get(tipo, dados["teclado"])
	_icone_texto.text = d[0]
	_icone_estilo.bg_color = d[1]
	var largo: bool = String(d[0]).length() > 1
	_icone_estilo.set_corner_radius_all(12 if largo else 22)
	_icone_texto.add_theme_font_size_override("font_size", 20 if largo else 26)


func definir_livro(titulo: String, detalhe: String) -> void:
	_titulo_livro.text = titulo
	_detalhe_livro.text = detalhe
	_detalhe_livro.visible = not detalhe.is_empty()


## Esconde título e barra (a moldura fica) — usado enquanto o Nino lê.
func esconder(duracao: float = 0.4) -> void:
	create_tween().tween_property(_conteudo, "modulate:a", 0.0, duracao)


func mostrar(duracao: float = 0.4) -> void:
	create_tween().tween_property(_conteudo, "modulate:a", 1.0, duracao)


func _pilula_selecionar() -> Control:
	var pilula := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.97, 0.93, 0.85)
	estilo.border_color = Color(0.55, 0.42, 0.3)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(30)
	estilo.content_margin_left = 10
	estilo.content_margin_right = 22
	estilo.shadow_color = Color(0, 0, 0, 0.3)
	estilo.shadow_size = 5
	pilula.add_theme_stylebox_override("panel", estilo)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 10)
	pilula.add_child(linha)
	var icone := PanelContainer.new()
	var bola := StyleBoxFlat.new()
	_icone_estilo = bola
	bola.bg_color = Color(0.2, 0.32, 0.62)
	bola.set_corner_radius_all(22)
	bola.content_margin_left = 12
	bola.content_margin_right = 12
	icone.add_theme_stylebox_override("panel", bola)
	_icone_texto = _rotulo("A", FONTE_B, 26, Color.WHITE, Color(0, 0, 0, 0), 0)
	icone.add_child(_icone_texto)
	icone.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha.add_child(icone)
	linha.add_child(_rotulo("Selecionar" if _pt() else "Select", FONTE_SB, 30, MARROM, Color(0, 0, 0, 0), 0))
	var botao := Button.new()
	botao.flat = true
	botao.set_anchors_preset(Control.PRESET_FULL_RECT)
	botao.focus_mode = Control.FOCUS_NONE
	botao.pressed.connect(func() -> void: selecionar.emit())
	pilula.add_child(botao)
	return pilula


func _etiqueta_livro() -> Control:
	var etiqueta := NinePatchRect.new()
	etiqueta.texture = ETIQUETA
	etiqueta.patch_margin_left = 16
	etiqueta.patch_margin_right = 16
	etiqueta.patch_margin_top = 16
	etiqueta.patch_margin_bottom = 16
	etiqueta.custom_minimum_size = Vector2(500, 72)
	var linha := HBoxContainer.new()
	linha.set_anchors_preset(Control.PRESET_FULL_RECT)
	linha.offset_left = 12
	linha.offset_right = -12
	etiqueta.add_child(linha)
	linha.add_child(_seta("‹", anterior))
	var coluna := VBoxContainer.new()
	coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	coluna.alignment = BoxContainer.ALIGNMENT_CENTER
	coluna.add_theme_constant_override("separation", -6)
	linha.add_child(coluna)
	_titulo_livro = _rotulo("", FONTE_SB, 27, MARROM, Color(0, 0, 0, 0), 0)
	_titulo_livro.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	coluna.add_child(_titulo_livro)
	_detalhe_livro = _rotulo("", FONTE_SB, 17, Color(0.5, 0.35, 0.25), Color(0, 0, 0, 0), 0)
	coluna.add_child(_detalhe_livro)
	linha.add_child(_seta("›", proximo))
	return etiqueta


func _seta(texto: String, sinal: Signal) -> Button:
	var b := Button.new()
	b.text = texto
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", FONTE_B)
	b.add_theme_font_size_override("font_size", 40)
	b.add_theme_color_override("font_color", MARROM)
	b.add_theme_color_override("font_hover_color", Color(0.75, 0.4, 0.15))
	b.pressed.connect(func() -> void: sinal.emit())
	return b


static func _rotulo(texto: String, fonte: Font, tamanho: int, cor: Color, contorno: Color, espessura: int) -> Label:
	var l := Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", fonte)
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	l.add_theme_color_override("font_outline_color", contorno)
	l.add_theme_constant_override("outline_size", espessura)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	l.add_theme_constant_override("shadow_offset_y", 3)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func _pt() -> bool:
	return TranslationServer.get_locale().begins_with("pt")


static func _titulo_do_jogo() -> String:
	return "Era Uma Vez um Sonho" if _pt() else "Once Upon a Pillow"
