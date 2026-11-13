extends Node
## Autoload global (GameState): livro e capítulo escolhidos, progresso (marcador de página),
## missão, coop e registro dos controles.

signal mission_progress(atual: int, total: int)
signal mission_completed

const QUARTO_SCENE := "res://scenes/menu/Quarto.tscn"
## Livros sem fase própria ainda caem na fase de protótipo.
const CENA_PROTOTIPO := "res://scenes/dev/PlanetaTeste.tscn"
## Teclado/mouse valem para qualquer dispositivo; controles são separados por device (0 = Nino, 1 = Mel).
const ALL_DEVICES := -1
const ARQUIVO_PROGRESSO := "user://progresso.cfg"
## Em builds de debug todos os capítulos ficam liberados (para testar fases fora de ordem).
var liberar_todos_capitulos: bool = OS.is_debug_build()

var livro_atual: BookData
var capitulo_atual: ChapterData
var itens_coletados: int = 0
## Coop drop-in: o 2º jogador entra apertando pular/luz no controle dele e sai com "p2_leave".
var player_two_joined: bool = false
## Enquanto true, os jogadores não se mexem (intro das nuvens, falas, transições).
var cutscene: bool = false

var itens_necessarios: int:
	get:
		return capitulo_atual.itens_necessarios if capitulo_atual else 3

var _intro_das_nuvens: bool = false
var _progresso := ConfigFile.new()


func _ready() -> void:
	_registrar_controles()
	_progresso.load(ARQUIVO_PROGRESSO) # se não existir, começa vazio


# ---------------- Progresso (marcador de página) ----------------

## Próximo capítulo a ler (1-based): o primeiro COM FASE ainda não concluído.
func proximo_capitulo(livro: BookData) -> int:
	var lidos: PackedInt32Array = capitulos_concluidos(livro)
	for c: ChapterData in livro.lista_capitulos():
		if c.tem_fase() and not lidos.has(c.numero):
			return c.numero
	return livro.total_capitulos()


func capitulos_concluidos(livro: BookData) -> PackedInt32Array:
	return _progresso.get_value(livro.id, "concluidos", PackedInt32Array())


## Liberado = tem fase e todos os capítulos ANTERIORES que têm fase já foram concluídos.
func capitulo_liberado(livro: BookData, numero: int) -> bool:
	var cap: ChapterData = livro.lista_capitulos()[numero - 1]
	if not cap.tem_fase():
		return false
	if liberar_todos_capitulos:
		return true
	var lidos: PackedInt32Array = capitulos_concluidos(livro)
	for c: ChapterData in livro.lista_capitulos():
		if c.numero < numero and c.tem_fase() and not lidos.has(c.numero):
			return false
	return true


## O livro tem pelo menos uma fase pronta?
func livro_jogavel(livro: BookData) -> bool:
	for c: ChapterData in livro.lista_capitulos():
		if c.tem_fase():
			return true
	return false


func livro_terminado(livro: BookData) -> bool:
	var lidos: PackedInt32Array = capitulos_concluidos(livro)
	for c: ChapterData in livro.lista_capitulos():
		if c.tem_fase() and not lidos.has(c.numero):
			return false
	return livro_jogavel(livro)


func _marcar_concluido() -> void:
	if livro_atual == null or capitulo_atual == null:
		return
	var lidos: PackedInt32Array = capitulos_concluidos(livro_atual)
	if not lidos.has(capitulo_atual.numero):
		lidos.append(capitulo_atual.numero)
		_progresso.set_value(livro_atual.id, "concluidos", lidos)
		_progresso.save(ARQUIVO_PROGRESSO)


## O capítulo atual é pesadelo?
func e_pesadelo() -> bool:
	return capitulo_atual != null and capitulo_atual.tipo == BookData.DreamKind.PESADELO


func _unhandled_input(event: InputEvent) -> void:
	if not player_two_joined and (event.is_action_pressed("p2_jump") or event.is_action_pressed("p2_lamp")):
		player_two_joined = true
	elif player_two_joined and event.is_action_pressed("p2_leave"):
		player_two_joined = false

	if event.is_action_pressed("chamar_mel"):
		get_tree().call_group("mel", "chamar")
		get_tree().call_group("sonhador", "animar", &"ual/Idle_Rail_Call", 1.4) # Nino chama a irmã


## Chamado depois que o Nino lê o capítulo: ele dorme e sonha com ele.
func entrar_no_capitulo(livro: BookData, capitulo: ChapterData) -> void:
	livro_atual = livro
	capitulo_atual = capitulo
	itens_coletados = 0
	_intro_das_nuvens = true
	var cena: String = capitulo.cena if not capitulo.cena.is_empty() else CENA_PROTOTIPO
	get_tree().change_scene_to_file.call_deferred(cena)


## Atalho: entra no próximo capítulo não lido.
func entrar_no_livro(livro: BookData) -> void:
	var n: int = proximo_capitulo(livro)
	entrar_no_capitulo(livro, livro.lista_capitulos()[n - 1])


## A câmera do sonho chama isto: true uma única vez, logo depois de sair da estante.
func consumir_intro_das_nuvens() -> bool:
	var tinha: bool = _intro_das_nuvens
	_intro_das_nuvens = false
	return tinha


func coletar_item() -> void:
	itens_coletados += 1
	mission_progress.emit(itens_coletados, itens_necessarios)
	if itens_coletados >= itens_necessarios:
		completar_missao()


func completar_missao() -> void:
	mission_completed.emit()
	_marcar_concluido()
	print("✨ Missão completa! Hora de acordar.")
	cutscene = true
	# TODO: comemoração (estrelinhas, Nino e Mel pulando) antes das nuvens.
	get_tree().create_timer(1.5).timeout.connect(_acordar_com_nuvens)


func _acordar_com_nuvens() -> void:
	Transicao.cobrir(1.5).finished.connect(acordar)


func acordar() -> void:
	livro_atual = null
	capitulo_atual = null
	cutscene = false
	get_tree().change_scene_to_file.call_deferred(QUARTO_SCENE)


# ---- Controles (registrados em código para manter o project.godot simples) ----

func _registrar_controles() -> void:
	# Nino (jogador 1) — teclado/mouse + controle 0
	_add_keys("move_forward", [KEY_W, KEY_UP])
	_add_keys("move_back", [KEY_S, KEY_DOWN])
	_add_keys("move_left", [KEY_A, KEY_LEFT])
	_add_keys("move_right", [KEY_D, KEY_RIGHT])
	_add_keys("camera_left", [KEY_Q])
	_add_keys("camera_right", [KEY_E])
	_add_keys("jump", [KEY_SPACE])
	_add_keys("spin", [KEY_SHIFT])
	_add_keys("lamp", [KEY_F])
	_add_keys("interact", [KEY_ENTER])
	_add_keys("chamar_mel", [KEY_C])

	_add_joy_axis("move_forward", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_axis("move_back", JOY_AXIS_LEFT_Y, 1.0)
	_add_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_axis("camera_left", JOY_AXIS_RIGHT_X, -1.0)
	_add_joy_axis("camera_right", JOY_AXIS_RIGHT_X, 1.0)
	_add_joy_button("jump", JOY_BUTTON_A)
	_add_joy_button("spin", JOY_BUTTON_X)
	_add_joy_button("interact", JOY_BUTTON_B)
	_add_joy_button("chamar_mel", JOY_BUTTON_Y)
	_add_joy_axis("lamp", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_add_mouse("lamp", MOUSE_BUTTON_RIGHT)

	# Mel (jogador 2) — teclado IJKL + controle 1
	_add_keys("p2_move_forward", [KEY_I])
	_add_keys("p2_move_back", [KEY_K])
	_add_keys("p2_move_left", [KEY_J])
	_add_keys("p2_move_right", [KEY_L])
	_add_keys("p2_jump", [KEY_O, KEY_KP_0])
	_add_keys("p2_spin", [KEY_U])
	_add_keys("p2_lamp", [KEY_P])
	_add_keys("p2_leave", [KEY_BACKSPACE])
	_add_joy_axis("p2_move_forward", JOY_AXIS_LEFT_Y, -1.0, 1)
	_add_joy_axis("p2_move_back", JOY_AXIS_LEFT_Y, 1.0, 1)
	_add_joy_axis("p2_move_left", JOY_AXIS_LEFT_X, -1.0, 1)
	_add_joy_axis("p2_move_right", JOY_AXIS_LEFT_X, 1.0, 1)
	_add_joy_button("p2_jump", JOY_BUTTON_A, 1)
	_add_joy_button("p2_spin", JOY_BUTTON_X, 1)
	_add_joy_axis("p2_lamp", JOY_AXIS_TRIGGER_RIGHT, 1.0, 1)
	_add_joy_button("p2_leave", JOY_BUTTON_BACK, 1)


func _ensure(action: StringName) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)


func _add_keys(action: StringName, keys: Array) -> void:
	_ensure(action)
	for k: Key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		ev.device = ALL_DEVICES
		InputMap.action_add_event(action, ev)


func _add_joy_axis(action: StringName, axis: JoyAxis, dir: float, device: int = 0) -> void:
	_ensure(action)
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = dir
	ev.device = device
	InputMap.action_add_event(action, ev)


func _add_joy_button(action: StringName, button: JoyButton, device: int = 0) -> void:
	_ensure(action)
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	ev.device = device
	InputMap.action_add_event(action, ev)


func _add_mouse(action: StringName, button: MouseButton) -> void:
	_ensure(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.device = ALL_DEVICES
	InputMap.action_add_event(action, ev)
