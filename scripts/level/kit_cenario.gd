class_name KitCenario
extends RefCounted
## Coloca peças do kit de cenário esculpido (assets/models/cenario/*.glb, normalizados no Blender:
## base em y = 0, maior lado = 1) com escala livre e COLISÃO no formato da peça (casco convexo
## simplificado, já com a escala aplicada nos pontos — nada de cilindro ou caixa no lugar).

const PASTA := "res://assets/models/cenario/"

static var _cascos: Dictionary = {}  # caminho -> PackedVector3Array (pontos do casco, sem escala)


## Cria a peça dentro de `pai`. tipo_corpo: "" (só visual), "estatico" ou "animavel" (boia, plataforma móvel).
## teto: altura máxima (no espaço normalizado, 0..1) dos pontos da colisão — corta enfeites do topo
## (cogumelinhos, florzinhas) para o Nino pisar na superfície e não "flutuar" em cima deles.
static func colocar(pai: Node3D, nome: String, pos: Vector3, escala: Vector3, giro_y: float = 0.0,
		tipo_corpo: String = "", teto: float = 10.0) -> Node3D:
	var cena := load(PASTA + nome + ".glb") as PackedScene
	var raiz: Node3D
	match tipo_corpo:
		"estatico":
			raiz = StaticBody3D.new()
		"animavel":
			var a := AnimatableBody3D.new()
			a.sync_to_physics = true
			raiz = a
		_:
			raiz = Node3D.new()
	raiz.name = nome.capitalize().replace(" ", "")
	raiz.position = pos
	raiz.rotation.y = giro_y
	pai.add_child(raiz)
	var visual := cena.instantiate() as Node3D
	visual.scale = escala
	raiz.add_child(visual)
	if tipo_corpo != "":
		var forma := CollisionShape3D.new()
		var casco := ConvexPolygonShape3D.new()
		var pontos := PackedVector3Array()
		for p: Vector3 in _casco(nome, visual):
			pontos.append(Vector3(p.x, minf(p.y, teto), p.z) * escala)
		casco.points = pontos
		forma.shape = casco
		raiz.add_child(forma)
	return raiz


## Só a malha, para espalhar enfeites (juncos etc.) sem colisão.
static func enfeite(pai: Node3D, nome: String, pos: Vector3, escala: float, giro_y: float = 0.0) -> Node3D:
	var n := colocar(pai, nome, pos, Vector3.ONE * escala, giro_y)
	for m: Node in n.find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return n


static func _casco(nome: String, visual: Node3D) -> PackedVector3Array:
	if _cascos.has(nome):
		return _cascos[nome]
	var pontos := PackedVector3Array()
	for n: Node in visual.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var forma := mi.mesh.create_convex_shape(true, true) as ConvexPolygonShape3D
		# pontos no espaço local do "visual" (a escala dele é aplicada depois, em colocar())
		var base: Transform3D = visual.global_transform.affine_inverse() * mi.global_transform
		for p: Vector3 in forma.points:
			pontos.append(base * p)
	_cascos[nome] = pontos
	return pontos
