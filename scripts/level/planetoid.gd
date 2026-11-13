@tool
class_name Planetoid
extends StaticBody3D
## Planetinha de feltro com gravidade própria. Ajuste raio/cor/gravidade no Inspetor e ele se reconstrói
## (também no editor). Malha, colisão e área de gravidade são geradas por código — não precisam ser salvas na cena.

const FELTRO := preload("res://materials/feltro.tres")
## Camadas que a gravidade afeta: sonhador (2) + criaturas (3).
const MASCARA_GRAVIDADE := 2 | 4

@export_range(0.5, 100.0, 0.1) var raio: float = 8.0:
	set(v):
		raio = v
		_rebuild()
## Até onde a gravidade alcança além da superfície.
@export_range(0.5, 100.0, 0.1) var alcance_gravidade: float = 6.0:
	set(v):
		alcance_gravidade = v
		_rebuild()
@export var forca_gravidade: float = 25.0:
	set(v):
		forca_gravidade = v
		_rebuild()
## Planetas menores devem ter prioridade maior para "roubar" o jogador quando as áreas se sobrepõem.
@export var prioridade: int = 0:
	set(v):
		prioridade = v
		_rebuild()
@export var cor: Color = Color(0.55, 0.8, 0.5):
	set(v):
		cor = v
		_rebuild()
## Achatamento (1 = esfera). Útil para bule, almofada, botão gigante.
@export_range(0.2, 2.0, 0.05) var achatamento: float = 1.0:
	set(v):
		achatamento = v
		_rebuild()

var _mesh: MeshInstance3D
var _col: CollisionShape3D
var _area: Area3D
var _area_col: CollisionShape3D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _mesh == null:
		_mesh = MeshInstance3D.new()
		_mesh.name = "_Malha"
		add_child(_mesh, false, Node.INTERNAL_MODE_FRONT)
		_col = CollisionShape3D.new()
		_col.name = "_Colisao"
		add_child(_col, false, Node.INTERNAL_MODE_FRONT)
		_area = Area3D.new()
		_area.name = "_Gravidade"
		add_child(_area, false, Node.INTERNAL_MODE_FRONT)
		_area_col = CollisionShape3D.new()
		_area.add_child(_area_col)

	var sm := SphereMesh.new()
	sm.radius = raio
	sm.height = raio * 2.0
	sm.radial_segments = clampi(int(raio * 8.0), 24, 96)
	sm.rings = clampi(int(raio * 4.0), 12, 48)
	_mesh.mesh = sm
	_mesh.material_override = FELTRO
	_mesh.set_instance_shader_parameter("tint", cor)
	_mesh.scale = Vector3(1.0, achatamento, 1.0)

	var ss := SphereShape3D.new()
	ss.radius = raio
	_col.shape = ss
	_col.scale = Vector3(1.0, achatamento, 1.0)

	var gs := SphereShape3D.new()
	gs.radius = raio + alcance_gravidade
	_area_col.shape = gs
	_area.collision_layer = 0
	_area.collision_mask = MASCARA_GRAVIDADE
	_area.monitorable = false
	_area.priority = prioridade
	_area.gravity_space_override = Area3D.SPACE_OVERRIDE_REPLACE
	_area.gravity_point = true
	_area.gravity_point_center = Vector3.ZERO
	_area.gravity_point_unit_distance = 0.0
	_area.gravity = forca_gravidade


## Ponto na superfície numa direção (em coordenadas do mundo).
func ponto_na_superficie(direcao: Vector3, elevacao: float = 0.0) -> Vector3:
	var d: Vector3 = direcao.normalized()
	var local_d: Vector3 = global_basis.inverse() * d
	# Elipsoide (achatado em Y): raio na direção dada.
	var e: Vector3 = Vector3(local_d.x / raio, local_d.y / (raio * achatamento), local_d.z / raio)
	var r: float = 1.0 / e.length()
	return global_position + d * (r + elevacao)
