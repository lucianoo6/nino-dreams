class_name ChapterPicker
extends CanvasLayer
## Sumário do livro: lista de capítulos com o marcador de página no próximo a ler.
## ✓ lido · 🔖 próximo · 🔒 ainda não. Use: `var n := await picker.escolher(livro)` (-1 = cancelou).

signal escolhido(numero: int)

var _painel: PanelContainer
var _lista: VBoxContainer
var _titulo: Label


func _ready() -> void:
	layer = 55
	_painel = PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(1.0, 0.97, 0.9, 0.97)
	estilo.border_color = Color(0.55, 0.42, 0.65)
	estilo.set_border_width_all(4)
	estilo.set_corner_radius_all(24)
	estilo.set_content_margin_all(28)
	estilo.shadow_color = Color(0, 0, 0, 0.3)
	estilo.shadow_size = 10
	_painel.add_theme_stylebox_override("panel", estilo)
	_painel.anchor_left = 0.58
	_painel.anchor_right = 0.95
	_painel.anchor_top = 0.08
	_painel.anchor_bottom = 0.92
	add_child(_painel)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 12)
	_painel.add_child(coluna)
	_titulo = Label.new()
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_titulo.add_theme_font_size_override("font_size", 30)
	_titulo.add_theme_color_override("font_color", Color(0.35, 0.22, 0.45))
	coluna.add_child(_titulo)

	var rolagem := ScrollContainer.new()
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	coluna.add_child(rolagem)
	_lista = VBoxContainer.new()
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.add_theme_constant_override("separation", 6)
	rolagem.add_child(_lista)

	var dica := Label.new()
	dica.text = "Esc / B: voltar"
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dica.add_theme_font_size_override("font_size", 18)
	dica.add_theme_color_override("font_color", Color(0.5, 0.42, 0.55))
	coluna.add_child(dica)
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_fechar(-1)


## Abre o sumário e espera a escolha. Retorna o número do capítulo, ou -1.
func escolher(livro: BookData) -> int:
	for filho: Node in _lista.get_children():
		filho.queue_free()
	_titulo.text = livro.titulo
	var lidos: PackedInt32Array = GameState.capitulos_concluidos(livro)
	var proximo: int = GameState.proximo_capitulo(livro)
	var foco: Button = null

	for c: ChapterData in livro.lista_capitulos():
		var b := Button.new()
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 22)
		var liberado: bool = GameState.capitulo_liberado(livro, c.numero)
		var marca: String = "✓" if lidos.has(c.numero) else ("🔖" if c.numero == proximo else ("🔒" if not liberado else "·"))
		var nome: String = c.titulo if liberado else "???"
		var pesadelo: String = "  🌑" if c.tipo == BookData.DreamKind.PESADELO and liberado else ""
		b.text = "%s  %d. %s%s" % [marca, c.numero, nome, pesadelo]
		b.disabled = not liberado
		b.pressed.connect(_fechar.bind(c.numero))
		_lista.add_child(b)
		if c.numero == proximo:
			foco = b

	visible = true
	_painel.pivot_offset = _painel.size / 2.0
	_painel.scale = Vector2(0.9, 0.9)
	create_tween().tween_property(_painel, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if foco:
		foco.grab_focus.call_deferred()
	var n: int = await escolhido
	return n


func _fechar(numero: int) -> void:
	visible = false
	escolhido.emit(numero)
