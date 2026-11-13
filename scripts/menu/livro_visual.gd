class_name LivroVisual
extends RefCounted
## Monta a malha de um livro de estante: capa de tecido tingida, faixas de linha dourada,
## emblema e o título escrito na lombada (de baixo para cima, como nos livros de verdade).
## Usado pelos livros jogáveis (ShelfBook) e pelos livros decorativos da estante.

const CAPAS: Array[Material] = [
	preload("res://materials/pbr/veludo_vermelho.tres"),
	preload("res://materials/pbr/feltro_creme.tres"),
	preload("res://materials/pbr/cotele_marrom.tres"),
]
const OURO := preload("res://materials/pbr/linha_dourada.tres")
const PAPEL := preload("res://materials/pbr/papel.tres")
const FONTE := preload("res://assets/fonts/Fredoka-SemiBold.woff2")


## Cria o livro como filhos de `pai`, com a base no chão (y = 0) e a lombada virada para +Z.
static func montar(pai: Node3D, titulo: String, cor: Color, largura: float, altura: float,
		profundidade: float, variacao: int) -> void:
	var capa_base: Material = CAPAS[variacao % CAPAS.size()]
	var capa_mat := capa_base.duplicate() as StandardMaterial3D
	capa_mat.albedo_color = cor
	_caixa(pai, Vector3(largura, altura, profundidade), Vector3(0, altura / 2.0, 0), capa_mat)
	# miolo de papel aparecendo em cima (as páginas)
	_caixa(pai, Vector3(largura * 0.86, 0.006, profundidade * 0.94),
		Vector3(0, altura + 0.001, -profundidade * 0.02), PAPEL)

	var frente: float = profundidade / 2.0 + 0.002
	# faixas douradas no alto e embaixo da lombada
	for y: float in [altura * 0.1, altura * 0.88]:
		_caixa(pai, Vector3(largura * 1.02, altura * 0.025, 0.004), Vector3(0, y, frente), OURO)
	if variacao % 3 == 0:  # alguns ganham um losango dourado
		var emb := _caixa(pai, Vector3(largura * 0.32, largura * 0.32, 0.004),
			Vector3(0, altura * 0.2, frente), OURO)
		emb.rotation.z = PI / 4.0

	if titulo.is_empty():
		return
	var rotulo := Label3D.new()
	rotulo.text = titulo
	rotulo.font = FONTE
	rotulo.pixel_size = 0.0006
	var caracteres_cabem: float = (altura * 0.62) / rotulo.pixel_size / 0.55
	rotulo.font_size = clampi(int(caracteres_cabem / maxf(titulo.length(), 1.0)), 18, 44)
	rotulo.modulate = Color(1.0, 0.86, 0.5) if cor.get_luminance() < 0.55 else Color(0.25, 0.16, 0.1)
	rotulo.outline_size = 0
	rotulo.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS  # escreve profundidade: o desfoque (DOF) não borra
	rotulo.rotation.z = PI / 2.0
	rotulo.position = Vector3(0, altura * 0.52, frente + 0.001)
	pai.add_child(rotulo)


static func _caixa(pai: Node3D, tamanho: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tamanho
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	pai.add_child(mi)
	return mi
