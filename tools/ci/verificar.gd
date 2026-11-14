extends Node
## Verificação do CI: carrega TODOS os scripts e cenas do projeto e falha se algum não carregar
## ou não instanciar (pega erros de compilação como "Member redefined" antes de chegarem no editor).
## Roda como cena normal (com os autoloads GameState/Transicao/Pausa disponíveis):
##   godot --headless --path . res://tools/ci/Verificar.tscn

const IGNORAR := ["res://.godot", "res://.git", "res://addons"]


func _ready() -> void:
	var arquivos: Array[String] = []
	_listar("res://", arquivos)
	var falhas: Array[String] = []
	for caminho: String in arquivos:
		var res: Resource = ResourceLoader.load(caminho)
		if res == null:
			falhas.append("%s (não carregou)" % caminho)
			continue
		var script := res as GDScript
		if script and not script.can_instantiate():
			falhas.append("%s (script com erro)" % caminho)
		var cena := res as PackedScene
		if cena and not cena.can_instantiate():
			falhas.append("%s (cena não instancia)" % caminho)

	print("Verificados %d arquivos." % arquivos.size())
	if falhas.is_empty():
		print("✅ Tudo carregou.")
		get_tree().quit(0)
	else:
		for f: String in falhas:
			printerr("❌ " + f)
		get_tree().quit(1)


func _listar(pasta: String, saida: Array[String]) -> void:
	for ignorar: String in IGNORAR:
		if pasta.begins_with(ignorar):
			return
	for arquivo: String in DirAccess.get_files_at(pasta):
		if arquivo.ends_with(".gd") or arquivo.ends_with(".tscn"):
			saida.append(pasta.path_join(arquivo))
	for sub: String in DirAccess.get_directories_at(pasta):
		_listar(pasta.path_join(sub), saida)
