extends Node
## Print da manhã no quarto depois de um capítulo concluído.
## SHOTS=/pasta godot --path . res://tools/debug/TesteManha.tscn


func _ready() -> void:
	GameState._manha = "Alice no País das Maravilhas — Capítulo 7 — Um Chá Maluco"
	add_child((load("res://scenes/menu/Quarto.tscn") as PackedScene).instantiate())
	await get_tree().create_timer(4.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOTS") + "/manha.png")
	get_tree().quit()
