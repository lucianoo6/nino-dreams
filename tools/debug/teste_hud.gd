extends Node
## Prints do HUD: 2 botões pegos, depois capítulo concluído. Depois a manhã no quarto.
## SHOTS=/pasta godot --path . res://tools/debug/TesteHud.tscn

var pasta: String = OS.get_environment("SHOTS")


func _ready() -> void:
	var alice := load("res://data/livros/alice.tres") as BookData
	GameState.livro_atual = alice
	GameState.capitulo_atual = alice.lista_capitulos()[6]
	add_child((load("res://scenes/livros/alice/Cap07_ChaMaluco.tscn") as PackedScene).instantiate())
	await get_tree().create_timer(2.0).timeout
	GameState.coletar_item()
	GameState.coletar_item()
	await get_tree().create_timer(0.6).timeout
	await _foto("hud_1")
	GameState.coletar_item()
	await get_tree().create_timer(1.2).timeout
	await _foto("hud_2")
	get_tree().quit()


func _foto(nome: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [pasta, nome])
