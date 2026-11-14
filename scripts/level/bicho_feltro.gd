class_name BichoFeltro
extends RefCounted
## Bichinhos de bolinhas de feltro (pássaros e ratinhos) para preencher as fases com personagens do livro
## sem precisar de um modelo 3D: corpo, cabeça, olhos de botão, bico + asinhas (ou orelhas de rato).

## Bicho esculpido (kit: assets/models/cenario/bicho_<nome>.glb — dodo, pato, papagaio), com `altura` em metros,
## virado para -Z (a "frente" do Godot). Prefira este; `criar` fica para bichos sem modelo.
static func modelo(pai: Node3D, nome: String, altura: float) -> Node3D:
	var m := (load("res://assets/models/cenario/bicho_%s.glb" % nome) as PackedScene).instantiate() as Node3D
	m.scale = Vector3.ONE * altura
	m.rotation.y = PI
	pai.add_child(m)
	return m


## Monta o bichinho dentro de `pai` (os pés ficam em y = 0).
static func criar(pai: Node3D, cor: Color, cor_detalhe: Color, tamanho: float, rato: bool = false) -> Node3D:
	var corpo := Node3D.new()
	pai.add_child(corpo)
	var feltro := StandardMaterial3D.new()
	feltro.albedo_color = cor
	feltro.roughness = 0.95
	feltro.rim_enabled = true
	feltro.rim = 0.5
	var detalhe := StandardMaterial3D.new()
	detalhe.albedo_color = cor_detalhe
	detalhe.roughness = 0.9
	var preto := StandardMaterial3D.new()
	preto.albedo_color = Color(0.05, 0.05, 0.07)
	preto.roughness = 0.2
	var esf := SphereMesh.new()
	esf.radius = tamanho
	esf.height = tamanho * 2.1
	_m(corpo, esf, Vector3(0, tamanho, 0), feltro)
	var cabeca := SphereMesh.new()
	cabeca.radius = tamanho * 0.62
	cabeca.height = tamanho * 1.24
	_m(corpo, cabeca, Vector3(0, tamanho * 2.15, -tamanho * 0.15), feltro)
	for x: float in [-0.25, 0.25]:
		var olho := SphereMesh.new()
		olho.radius = tamanho * 0.1
		olho.height = tamanho * 0.2
		_m(corpo, olho, Vector3(x * tamanho, tamanho * 2.3, -tamanho * 0.7), preto)
	if rato:
		for x: float in [-0.45, 0.45]:
			var orelha := CylinderMesh.new()
			orelha.top_radius = tamanho * 0.32
			orelha.bottom_radius = tamanho * 0.32
			orelha.height = tamanho * 0.06
			var o := _m(corpo, orelha, Vector3(x * tamanho, tamanho * 2.75, -tamanho * 0.1), detalhe)
			o.rotation.x = PI / 2.0
	else:
		var bico := CylinderMesh.new()
		bico.top_radius = 0.0
		bico.bottom_radius = tamanho * 0.18
		bico.height = tamanho * 0.55
		var b := _m(corpo, bico, Vector3(0, tamanho * 2.05, -tamanho * 0.85), detalhe)
		b.rotation.x = -PI / 2.0
		for x: float in [-1.0, 1.0]:
			var asa := SphereMesh.new()
			asa.radius = tamanho * 0.45
			asa.height = tamanho * 1.3
			var a := _m(corpo, asa, Vector3(x * tamanho * 0.85, tamanho * 1.0, 0), feltro)
			a.scale = Vector3(0.35, 1.0, 1.0)
			a.rotation.z = x * 0.3
	return corpo



static func _m(pai: Node3D, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.position = pos
	m.material_override = mat
	pai.add_child(m)
	return m
