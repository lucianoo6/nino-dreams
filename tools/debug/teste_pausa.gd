extends Node
## Prints do menu de pausa (principal e configurações) por cima do Cap. 7.
## SHOTS=/pasta godot --path . res://tools/debug/TestePausa.tscn

var pasta: String = OS.get_environment("SHOTS")


func _ready() -> void:
	var alice := load("res://data/livros/alice.tres") as BookData
	GameState.livro_atual = alice
	GameState.capitulo_atual = alice.lista_capitulos()[6]
	add_child((load("res://scenes/livros/alice/Cap07_ChaMaluco.tscn") as PackedScene).instantiate())
	await get_tree().create_timer(1.5).timeout
	var ev := InputEventAction.new()
	ev.action = "pausa"
	ev.pressed = true
	Input.parse_input_event(ev)
	for i in 5:
		await get_tree().process_frame
	print("pausado=", get_tree().paused, " visivel=", Pausa.visible)
	await _foto("pausa_1")
	Pausa._mostrar(Pausa._config)
	for i in 3:
		await get_tree().process_frame
	await _foto("pausa_2")
	Pausa.fechar()
	print("despausado=", not get_tree().paused)
	get_tree().quit()


func _foto(nome: String) -> void:
	await RenderingServer.frame_post_draw
	if not pasta.is_empty():
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [pasta, nome])
