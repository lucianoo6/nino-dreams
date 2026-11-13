class_name BabbleDialog
extends CanvasLayer
## Balão de fala com texto letra a letra + voz balbuciada.
## falar(): mostra uma frase. dizer_fim(): o grande "e FIM" pulando no meio da tela.

signal terminou

@export var segundos_por_letra: float = 0.035
@export var pausa_pontuacao: float = 0.22

var _painel: PanelContainer
var _texto: Label
var _fim: Label
var _pular: bool = false


func _ready() -> void:
	layer = 50
	_painel = PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(1.0, 0.96, 0.9, 0.95)
	estilo.border_color = Color(0.55, 0.42, 0.65)
	estilo.set_border_width_all(4)
	estilo.set_corner_radius_all(28)
	estilo.set_content_margin_all(24)
	estilo.shadow_color = Color(0, 0, 0, 0.25)
	estilo.shadow_size = 8
	_painel.add_theme_stylebox_override("panel", estilo)
	_painel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_painel.anchor_left = 0.15
	_painel.anchor_right = 0.85
	_painel.anchor_top = 0.74
	_painel.anchor_bottom = 0.94
	_painel.offset_left = 0
	_painel.offset_right = 0
	_painel.offset_top = 0
	_painel.offset_bottom = 0
	add_child(_painel)

	_texto = Label.new()
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_texto.add_theme_font_size_override("font_size", 30)
	_texto.add_theme_color_override("font_color", Color(0.3, 0.22, 0.38))
	_painel.add_child(_texto)

	_fim = Label.new()
	_fim.text = "e FIM"
	_fim.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fim.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_fim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fim.add_theme_font_size_override("font_size", 120)
	_fim.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75))
	_fim.add_theme_color_override("font_outline_color", Color(0.4, 0.28, 0.55))
	_fim.add_theme_constant_override("outline_size", 24)
	add_child(_fim)

	_painel.visible = false
	_fim.visible = false


func _unhandled_input(event: InputEvent) -> void:
	# Apertar durante a fala completa a frase de uma vez.
	if _painel.visible and (event.is_action_pressed("ui_accept") or event.is_action_pressed("jump")):
		_pular = true


## Mostra a frase letra a letra, balbuciando. Use com await.
func falar(frase: String, voz: BabbleVoice) -> void:
	_pular = false
	_texto.text = frase
	_texto.visible_characters = 0
	_painel.visible = true
	_painel.pivot_offset = _painel.size / 2.0
	_painel.scale = Vector2(0.85, 0.85)
	create_tween().tween_property(_painel, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var total: int = frase.length()
	for i in total:
		if _pular:
			break
		_texto.visible_characters = i + 1
		var c: String = frase[i]
		if i % 2 == 0 and voz:
			voz.blip(c)
		var espera: float = pausa_pontuacao if ".,!?…—".contains(c) else segundos_por_letra
		await get_tree().create_timer(espera).timeout
	_texto.visible_characters = -1
	await get_tree().create_timer(1.1).timeout


## O grande "e FIM": pula na tela com um balbucio mais grave e animado.
func dizer_fim(voz: BabbleVoice) -> void:
	_painel.visible = false
	_fim.visible = true
	_fim.pivot_offset = get_viewport().get_visible_rect().size / 2.0
	_fim.scale = Vector2(0.2, 0.2)
	_fim.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_fim, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_fim, "modulate:a", 1.0, 0.2)
	if voz:
		voz.blip("e", 0.9)
		await get_tree().create_timer(0.18).timeout
		voz.blip("i", 0.75)
	await get_tree().create_timer(1.3).timeout
	var saida := create_tween()
	saida.tween_property(_fim, "modulate:a", 0.0, 0.5)
	await saida.finished
	_fim.visible = false
	terminou.emit()
