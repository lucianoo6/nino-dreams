extends Node
## Abre uma cena e salva um print depois de alguns segundos.
## CENA=res://... SHOTS=/pasta ESPERA=2.5 godot --path . res://tools/debug/FotoCena.tscn

func _ready() -> void:
	var cena: String = OS.get_environment("CENA")
	var espera: float = float(OS.get_environment("ESPERA")) if OS.get_environment("ESPERA") != "" else 2.5
	add_child((load(cena) as PackedScene).instantiate())
	await get_tree().create_timer(espera).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOTS") + "/cena.png")
	get_tree().quit()
