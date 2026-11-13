class_name Personagem
extends Node3D
## Personagem do livro (NPC): fica parado no cenário com uma animação; quando o Nino chega perto,
## vira para ele e fala uma frase do texto original (tradução nossa) em balbucio, num balão sobre a cabeça.

const FONTE := preload("res://assets/fonts/Fredoka-SemiBold.woff2")

## Cena do modelo (.glb com esqueleto e animações).
@export var modelo: PackedScene
@export var escala: float = 0.8
## Os .glb do Hyper3D têm a origem no meio do corpo: sobe o modelo para os pés tocarem o chão.
@export var altura_pes: float = 0.71
## Altura do balão de fala acima da origem.
@export var altura_balao: float = 1.9
@export var anim_parado: StringName = &"human_000093"
@export var anim_falando: StringName = &""
@export var falas: PackedStringArray = PackedStringArray()
@export var tom_voz: float = 300.0
@export var raio_conversa: float = 4.0
@export var intervalo: float = 7.0

var _player: AnimationPlayer
var _corpo: Node3D
var _balao: Label3D
var _voz: BabbleVoice
var _espera: float = 0.0
var _falando: bool = false
var _proxima_fala: int = 0


func _ready() -> void:
	if modelo:
		_corpo = modelo.instantiate() as Node3D
		_corpo.scale = Vector3.ONE * escala
		_corpo.rotation.y = PI  # modelos do Hyper3D olham para +Z; o "frente" do Godot é -Z
		_corpo.position.y = altura_pes
		add_child(_corpo)
		_player = _corpo.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if _player:
			for nome: StringName in _player.get_animation_list():
				_player.get_animation(nome).loop_mode = Animation.LOOP_LINEAR
			_tocar(anim_parado)
	_balao = Label3D.new()
	_balao.font = FONTE
	_balao.font_size = 44
	_balao.pixel_size = 0.006
	_balao.outline_size = 14
	_balao.modulate = Color(1.0, 0.97, 0.88)
	_balao.outline_modulate = Color(0.3, 0.18, 0.12)
	_balao.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_balao.no_depth_test = true
	_balao.width = 420
	_balao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_balao.position = Vector3(0, altura_balao, 0)
	_balao.visible = false
	add_child(_balao)
	_voz = BabbleVoice.new()
	_voz.tom_base = tom_voz
	add_child(_voz)


func _process(delta: float) -> void:
	_espera -= delta
	var nino := get_tree().get_first_node_in_group("sonhador") as Node3D
	if nino == null:
		return
	var perto: bool = nino.global_position.distance_to(global_position) < raio_conversa
	if perto:
		_virar_para(nino.global_position, delta)
		if not _falando and _espera <= 0.0 and not falas.is_empty() and not GameState.cutscene:
			_falar(falas[_proxima_fala % falas.size()])
			_proxima_fala += 1


func _virar_para(alvo: Vector3, delta: float) -> void:
	if _corpo == null:
		return
	var up: Vector3 = global_basis.y.normalized()
	var para: Vector3 = alvo - global_position
	para -= up * para.dot(up)
	if para.length_squared() < 0.01:
		return
	var local: Vector3 = global_basis.inverse() * para
	var alvo_y: float = atan2(local.x, local.z)  # o modelo já está girado 180° (olha para +Z local)
	_corpo.rotation.y = lerp_angle(_corpo.rotation.y, alvo_y, 1.0 - exp(-5.0 * delta))


func _falar(frase: String) -> void:
	_falando = true
	if anim_falando != &"":
		_tocar(anim_falando)
	_balao.text = ""
	_balao.visible = true
	for i in frase.length():
		_balao.text = frase.substr(0, i + 1)
		if i % 2 == 0:
			_voz.blip(frase[i])
		await get_tree().create_timer(0.045).timeout
	await get_tree().create_timer(2.2).timeout
	_balao.visible = false
	_tocar(anim_parado)
	_espera = intervalo
	_falando = false


func _tocar(nome: StringName) -> void:
	if _player and _player.has_animation(nome):
		_player.play(nome, 0.25)
