class_name VoxelTecido
extends RefCounted
## Aplica o material de VOXEL DE TECIDO em todas as malhas de um modelo voxelizado
## (as que vêm do tools/blender/voxelizar.py — material "voxel_tecido").

const SHADER := preload("res://shaders/voxel_tecido.gdshader")
const FIBRA := preload("res://assets/materiais/feltro/albedo.png")
const FIBRA_NORMAL := preload("res://assets/materiais/feltro/normal.png")

static var _material: ShaderMaterial


static func material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = SHADER
		_material.set_shader_parameter("fibra", FIBRA)
		_material.set_shader_parameter("fibra_normal", FIBRA_NORMAL)
	return _material


## Troca o material das malhas voxelizadas dentro de `raiz` (e devolve quantas trocou).
static func aplicar(raiz: Node) -> int:
	var n: int = 0
	for f: Node in raiz.find_children("*", "MeshInstance3D", true, false):
		var mi := f as MeshInstance3D
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var m := mi.mesh.surface_get_material(s)
			if m and m.resource_name.begins_with("voxel_tecido"):
				mi.set_surface_override_material(s, material())
				n += 1
	return n
