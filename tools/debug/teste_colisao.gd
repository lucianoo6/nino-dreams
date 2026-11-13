extends Node
## Reproduz travamentos: coloca o Nino em situações (lateral do cogumelo, cair no bule, pisar em botão)
## e imprime posição/velocidade/estado. godot --headless --path . res://tools/debug/TesteColisao.tscn

const DURACAO := 3.0

var nino: DreamerController
var cam: DreamCamera
var t: float = 0.0
var cena: int = -1
var log_t: float = 0.0
var alvo: Vector3



func _ready() -> void:
	add_child((load("res://scenes/livros/alice/Cap07_ChaMaluco.tscn") as PackedScene).instantiate())
	await get_tree().physics_frame
	await get_tree().physics_frame
	nino = get_tree().get_first_node_in_group("sonhador") as DreamerController
	cam = nino.get_dream_camera()
	get_tree().get_first_node_in_group("mel").process_mode = Node.PROCESS_MODE_DISABLED
	_proxima()


func _proxima() -> void:
	cena += 1
	t = 0.0
	log_t = 0.0
	Input.action_release("move_forward")
	var raiz: Node = get_child(0)
	match cena:
		0:
			var cog := raiz.get_node("AncoraCogumelo1") as Node3D
			var up: Vector3 = cog.global_basis.y
			alvo = cog.global_position + up * 0.8
			_colocar(cog.global_position + cog.global_basis.x * 2.5 + up * 0.3, up)
			print("\n== CENA 0: andar contra a lateral do cogumelo")
		1:
			var pouso := raiz.get_node("AncoraPousoBule/Pouso") as Node3D
			var up2: Vector3 = (pouso.global_position - (raiz.get_node("Bule") as Node3D).global_position).normalized()
			alvo = pouso.global_position + up2.cross(Vector3.FORWARD).normalized() * 5.0
			_colocar(pouso.global_position + up2 * 2.5, up2)
			print("\n== CENA 1: cair no bule e andar")
		2:
			var b := raiz.get_node("AncoraBotaoDecor0") as Node3D
			var up3: Vector3 = b.global_basis.y
			alvo = b.global_position + b.global_basis.z * 3.0
			_colocar(b.global_position + up3 * 1.6 - b.global_basis.z * 0.2, up3)
			print("\n== CENA 2: cair num botão decorativo e andar")
		3:
			var cog2 := raiz.get_node("AncoraCogumelo1") as Node3D
			var up4: Vector3 = cog2.global_basis.y
			alvo = cog2.global_position + up4 * 1.8
			_colocar(cog2.global_position + cog2.global_basis.x * 2.2 + up4 * 1.6, up4)
			print("\n== CENA 3: pular contra a borda do chapéu do cogumelo (no ar) segurando para frente")
		_:
			get_tree().quit()


func _colocar(pos: Vector3, up: Vector3) -> void:
	nino.global_position = pos
	nino.velocity = Vector3.ZERO
	nino.up_direction = up


func _physics_process(delta: float) -> void:
	if nino == null or cena < 0:
		return
	t += delta
	# câmera olhando para o alvo, para "frente" = em direção ao obstáculo
	var up: Vector3 = nino.up_direction
	var f: Vector3 = alvo - nino.global_position
	f = (f - up * f.dot(up)).normalized()
	if f.length_squared() > 0.1:
		cam.global_basis = Basis.looking_at(f, up)
	if t > 0.6:
		Input.action_press("move_forward")
	if t >= log_t:
		log_t += 0.25
		var v: Vector3 = nino.velocity
		print("t=%.2f pos=(%.2f, %.2f, %.2f) vel=%.2f chao=%s parede=%s teto=%s anim=%s" % [t, nino.global_position.x,
			nino.global_position.y, nino.global_position.z, v.length(), nino.is_on_floor(), nino.is_on_wall(),
			nino.is_on_ceiling(), (nino.get_node("Visual") as CharacterAnimator)._player.current_animation])
	if t > DURACAO:
		_proxima()
