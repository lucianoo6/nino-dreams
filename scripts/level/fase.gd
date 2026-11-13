class_name Fase
extends Node3D
## Raiz de uma fase. Mostra o título do livro e do capítulo enquanto a câmera desce das nuvens.
## Se o jogo veio da estante, o título vem do capítulo escolhido (GameState); senão, dos campos abaixo.

@export var titulo: String = "Capítulo 1"
@export var subtitulo: String = ""
@export var atraso: float = 1.2
@export var duracao: float = 3.0


func _ready() -> void:
	if GameState.livro_atual and GameState.capitulo_atual:
		titulo = GameState.livro_atual.titulo
		subtitulo = GameState.capitulo_atual.rotulo()
	var camada := CanvasLayer.new()
	camada.layer = 60
	add_child(camada)
	var caixa := VBoxContainer.new()
	caixa.set_anchors_preset(Control.PRESET_CENTER_TOP)
	caixa.anchor_left = 0.0
	caixa.anchor_right = 1.0
	caixa.offset_top = 80.0
	caixa.alignment = BoxContainer.ALIGNMENT_CENTER
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada.add_child(caixa)
	caixa.add_child(_rotulo(titulo, 64))
	if not subtitulo.is_empty():
		caixa.add_child(_rotulo(subtitulo, 34))
	caixa.modulate.a = 0.0

	var tw := create_tween()
	tw.tween_interval(atraso)
	tw.tween_property(caixa, "modulate:a", 1.0, 0.8)
	tw.tween_interval(duracao)
	tw.tween_property(caixa, "modulate:a", 0.0, 1.0)
	tw.tween_callback(camada.queue_free)


func _rotulo(texto: String, tamanho: int) -> Label:
	var l := Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", Color(1.0, 0.96, 0.85))
	l.add_theme_color_override("font_outline_color", Color(0.35, 0.25, 0.5))
	l.add_theme_constant_override("outline_size", 16)
	return l
