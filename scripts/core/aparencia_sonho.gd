class_name AparenciaSonho
extends Node
## Direção de arte aplicada em TODAS as fases (a Fase adiciona este nó):
## o sonho deve parecer uma MAQUETE DE FELTRO FOTOGRAFADA, não uma cena de engine.
##   • luz que rebate (SDFGI) — as cores do feltro "sangram" umas nas outras;
##   • sombras macias (sol com diâmetro angular) e oclusão de contato forte;
##   • lente macro: foco no Nino, frente e fundo desfocados (a pista nº 1 de "miniatura");
##   • pós: vinheta, grão leve, tom quente e halation.
## No Steam Deck (tag "steamdeck") o SDFGI fica desligado.

const POS := preload("res://shaders/pos_maquete.gdshader")

## Abertura da "lente" (quanto desfoca fora do foco).
@export var desfoque: float = 0.11

var _attrs: CameraAttributesPractical


func _ready() -> void:
	var raiz := get_parent()
	var we := raiz.find_child("WorldEnvironment", false, false) as WorldEnvironment
	if we and we.environment:
		_ambiente(we.environment)
		var a := we.camera_attributes as CameraAttributesPractical
		if a:
			_attrs = a
	for luz: Node in raiz.find_children("*", "DirectionalLight3D", false, false):
		var d := luz as DirectionalLight3D
		d.light_angular_distance = 2.2  # sombras macias, como luz de estúdio difusa
		d.shadow_blur = 1.4
		d.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	_pos()


func _ambiente(env: Environment) -> void:
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.05
	if not OS.has_feature("steamdeck"):
		env.sdfgi_enabled = true
		env.sdfgi_use_occlusion = true
		env.sdfgi_bounce_feedback = 0.6
		env.sdfgi_energy = 1.1
		env.sdfgi_cascades = 4
		env.sdfgi_min_cell_size = 0.15
	env.ssao_enabled = true
	env.ssao_radius = 1.6
	env.ssao_intensity = 2.6
	env.ssao_power = 1.6
	env.ssao_detail = 0.8
	env.ssil_enabled = true
	env.ssil_intensity = 1.2
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.06
	env.glow_hdr_threshold = 0.9
	env.fog_density *= 0.6
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.07
	env.adjustment_saturation = maxf(env.adjustment_saturation, 1.12)


func _pos() -> void:
	var camada := CanvasLayer.new()
	camada.layer = 30  # abaixo do HUD (40) e do título (60)
	add_child(camada)
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = POS
	r.material = m
	camada.add_child(r)


func _process(_delta: float) -> void:
	# lente macro: foca na distância até o Nino
	var cam := get_viewport().get_camera_3d()
	var nino := get_tree().get_first_node_in_group("sonhador") as Node3D
	if cam == null or nino == null:
		return
	if _attrs == null:
		_attrs = CameraAttributesPractical.new()
	if cam.attributes != _attrs and cam.attributes == null:
		cam.attributes = _attrs
	var d: float = cam.global_position.distance_to(nino.global_position + nino.global_basis.y * 0.6)
	_attrs.dof_blur_amount = desfoque
	_attrs.dof_blur_far_enabled = true
	_attrs.dof_blur_far_distance = d + 2.5
	_attrs.dof_blur_far_transition = d * 1.2 + 4.0
	_attrs.dof_blur_near_enabled = true
	_attrs.dof_blur_near_distance = maxf(d * 0.45, 0.5)
	_attrs.dof_blur_near_transition = maxf(d * 0.35, 0.5)
