class_name CharacterAnimator
extends Node3D
## Escolhe a animação do personagem a partir do estado do DreamerController.
## Fontes de animação:
##   • embutidas no modelo (.glb do Hyper3D): "human_0000xx"
##   • biblioteca extra retargetada (Quaternius UAL, CC0): carregada em `biblioteca_extra`, nomes "ual/<Nome>"
## Sem pai DreamerController (ex.: Nino sentado no quarto), toca só `modo_fixo`.

const LIB_EXTRA := &"ual"

## .glb com as animações retargetadas para ESTE personagem (assets/animacoes/ual/*.glb).
@export var biblioteca_extra: PackedScene

@export_group("Animações")
@export var anim_parado: StringName = &"ual/Idle"
@export var anim_parado_pesadelo: StringName = &"human_000050" ## sad idle
## Parado segurando a luz acesa (Nino com a Luna).
@export var anim_parado_luz: StringName = &"ual/Idle_Torch"
@export var anim_andar: StringName = &"ual/Walk"
@export var anim_andar_pesadelo: StringName = &"ual/Crouch_Fwd"
@export var anim_nadar: StringName = &"ual/Swim_Fwd"
@export var anim_boiar: StringName = &"ual/Swim_Idle"
@export var anim_correr: StringName = &"ual/Jog_Fwd"
@export var anim_disparada: StringName = &"ual/Sprint"
@export var anim_pulo_inicio: StringName = &"ual/Jump_Start"
@export var anim_pulo_ar: StringName = &"ual/Jump" ## (Jump_Loop no .glb; o Godot tira o "_Loop")
@export var anim_aterrissar: StringName = &"ual/Jump_Land"
@export var anim_rodopio: StringName = &"human_000039" ## northern soul spin
@export var anim_comemorar: StringName = &"ual/Dance"

@export_group("Ritmo")
@export var limiar_andar: float = 0.4
@export var limiar_correr: float = 2.5
## Acima disto usa a disparada (por enquanto só com impulsos; velocidade normal máxima é 7).
@export var limiar_disparada: float = 8.5
## Velocidade (m/s) em que cada animação fica no ritmo natural (já na escala do modelo).
@export var ritmo_andar: float = 1.3
@export var ritmo_correr: float = 3.0
@export var ritmo_disparada: float = 5.5
@export var tempo_aterrissagem: float = 0.25
@export var mistura: float = 0.15

## Se preenchido, toca sempre esta animação (cutscenes, quarto).
@export var modo_fixo: StringName = &""

@export_group("Objeto na mão")
## Nó (relativo a este) que o personagem carrega na mão: a lua da Luna (Nino) ou a Estrelinha (Mel).
@export var objeto_na_mao: NodePath
## "LeftHand" combina com Idle_Torch (Nino); "RightHand" com Idle_Lantern (Mel).
@export var osso_mao: StringName = &"LeftHand"
@export var deslocamento_mao: Vector3 = Vector3(0.0, 0.1, 0.0)

var _player: AnimationPlayer
var _body: DreamerController
var _luna: MoonLamp
var _no_ar: float = 0.0
var _aterrissando: float = 0.0
var _estava_no_chao: bool = true
var _comemorando: bool = false
var _avisadas: Dictionary = {}


func _ready() -> void:
	VoxelTecido.aplicar(self)
	_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	_body = get_parent() as DreamerController
	if _player == null:
		push_warning("CharacterAnimator: AnimationPlayer não encontrado no modelo.")
		return
	if biblioteca_extra:
		_importar_biblioteca(biblioteca_extra)
	_configurar_loops()
	if _body:
		_luna = _body.get_node_or_null("Luna") as MoonLamp
		GameState.mission_completed.connect(func() -> void: _comemorando = true)
	_prender_na_mao.call_deferred()
	_tocar(modo_fixo if modo_fixo != &"" else anim_parado)


## Prende `objeto_na_mao` no osso da mão (BoneAttachment3D), compensando a escala do modelo.
func _prender_na_mao() -> void:
	if objeto_na_mao.is_empty():
		return
	var objeto := get_node_or_null(objeto_na_mao) as Node3D
	var esqueleto: Skeleton3D = null
	for n: Node in find_children("*", "Skeleton3D", true, false):
		esqueleto = n as Skeleton3D
		break
	if objeto == null or esqueleto == null or esqueleto.find_bone(osso_mao) < 0:
		return
	var anexo := BoneAttachment3D.new()
	anexo.name = "Mao_" + String(osso_mao)
	anexo.bone_name = osso_mao
	esqueleto.add_child(anexo)
	objeto.reparent(anexo, false)
	var escala: Vector3 = esqueleto.global_basis.get_scale()
	objeto.transform = Transform3D(Basis.from_scale(Vector3.ONE / escala), deslocamento_mao / escala.y)


## Copia as animações do .glb retargetado para o AnimationPlayer do modelo, apontando as trilhas
## para o Skeleton3D deste modelo (os caminhos de nó dos dois .glb não são idênticos).
func _importar_biblioteca(cena: PackedScene) -> void:
	var inst: Node = cena.instantiate()
	var origem := inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var raiz: Node = _player.get_node(_player.root_node)
	var esqueleto: Skeleton3D = null
	for n: Node in raiz.find_children("*", "Skeleton3D", true, false):
		esqueleto = n as Skeleton3D
		break
	if origem == null or esqueleto == null:
		push_warning("CharacterAnimator: biblioteca extra sem AnimationPlayer ou modelo sem Skeleton3D.")
		inst.free()
		return
	var caminho: String = String(raiz.get_path_to(esqueleto))
	var lib := AnimationLibrary.new()
	for nome: StringName in origem.get_animation_list():
		var anim := origem.get_animation(nome).duplicate(true) as Animation
		for t in anim.get_track_count():
			var p: String = String(anim.track_get_path(t))
			var i: int = p.find(":")
			if i >= 0:
				anim.track_set_path(t, NodePath(caminho + p.substr(i)))
		lib.add_animation(StringName(String(nome).trim_prefix("ual_")), anim)
	_player.add_animation_library(LIB_EXTRA, lib)
	inst.free()


func _configurar_loops() -> void:
	var sem_loop: Array[StringName] = [anim_pulo_inicio, anim_aterrissar, &"ual/LayToIdle", &"ual/Sitting_Enter",
		&"ual/Sitting_Exit", &"ual/Interact", &"ual/PickUp_Table", &"ual/Hit_Head", &"ual/Roll", &"ual/Yes"]
	for nome: StringName in _player.get_animation_list():
		var anim: Animation = _player.get_animation(nome)
		if anim:
			anim.loop_mode = Animation.LOOP_NONE if sem_loop.has(nome) else Animation.LOOP_LINEAR


func _process(delta: float) -> void:
	if _player == null:
		return
	if modo_fixo != &"" or _body == null:
		_tocar(modo_fixo if modo_fixo != &"" else anim_parado)
		return

	var pesadelo: bool = GameState.e_pesadelo()
	var up: Vector3 = _body.up_direction
	var v: Vector3 = _body.velocity
	var vertical: float = v.dot(up)
	var lateral: float = (v - up * vertical).length()
	var no_chao: bool = _body.is_on_floor()

	if no_chao:
		if not _estava_no_chao and _no_ar > 0.2:
			_aterrissando = tempo_aterrissagem
		_no_ar = 0.0
	else:
		_no_ar += delta
	_estava_no_chao = no_chao
	_aterrissando -= delta

	var forcada: StringName = _body.get_animation_override()
	if forcada != &"":
		_tocar(forcada)
	elif _comemorando:
		_tocar(anim_comemorar)
	elif _body.boiando():
		_tocar(anim_nadar if lateral > 0.6 else anim_boiar, clampf(lateral / 2.5, 0.8, 1.6))
	elif _body.is_launching() or _body.is_spinning:
		_tocar(anim_rodopio, 1.4)
	elif not no_chao:
		if _no_ar < 0.3 and vertical > 0.0:
			_tocar(anim_pulo_inicio, 1.6, 0.1)
		else:
			_tocar(anim_pulo_ar)
	elif _aterrissando > 0.0 and lateral < limiar_correr:
		_tocar(anim_aterrissar, 1.5)
	elif lateral > limiar_disparada and not pesadelo:
		_tocar(anim_disparada, clampf(lateral / ritmo_disparada, 0.8, 2.0))
	elif lateral > limiar_correr and not pesadelo:
		_tocar(anim_correr, clampf(lateral / ritmo_correr, 0.8, 2.0))
	elif lateral > limiar_andar:
		var andar: StringName = anim_andar_pesadelo if pesadelo else anim_andar
		_tocar(andar, clampf(lateral / ritmo_andar, 0.7, 2.2))
	elif _luna and _luna.is_on:
		_tocar(anim_parado_luz)
	else:
		_tocar(anim_parado_pesadelo if pesadelo else anim_parado)


func _tocar(nome: StringName, velocidade: float = 1.0, inicio: float = 0.0) -> void:
	if not _player.has_animation(nome):
		# O importador do Godot remove o sufixo "_Loop" dos nomes do .glb.
		var sem_loop := StringName(String(nome).trim_suffix("_Loop"))
		if _player.has_animation(sem_loop):
			nome = sem_loop
		else:
			if not _avisadas.has(nome):
				_avisadas[nome] = true
				push_warning("CharacterAnimator: animação '%s' não existe." % nome)
			nome = anim_parado if _player.has_animation(anim_parado) else nome
			if not _player.has_animation(nome):
				return
	if _player.current_animation != nome:
		_player.play(nome, mistura)
		if inicio > 0.0:
			_player.seek(inicio, true)
	_player.speed_scale = velocidade
