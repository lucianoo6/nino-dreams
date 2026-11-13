extends SceneTree
## Lista os livros de data/livros com o número de capítulos e o começo da última linha.
## godot --headless --path . --script res://tools/debug/checa_livros.gd


func _initialize() -> void:
	for f: String in ResourceLoader.list_directory("res://data/livros/"):
		var b := load("res://data/livros/" + f) as BookData
		var ultimo: ChapterData = b.lista_capitulos()[-1]
		print("%s -> %s: %d caps, último: %s | %s" % [f, b.titulo, b.total_capitulos(), ultimo.titulo,
			ultimo.ultima_linha.substr(0, 40)])
	quit()
