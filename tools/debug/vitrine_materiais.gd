extends Node3D
## Vitrine: uma esfera (e um cubo arredondado) para cada material em materials/pbr/, com nome.
## Use com FotoCena: CENA=res://tools/debug/VitrineMateriais.tscn

const PASTA := "res://materials/pbr/"
const COLUNAS := 6


func _ready() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var ceu := Sky.new()
	var mat_ceu := ProceduralSkyMaterial.new()
	mat_ceu.sky_top_color = Color(0.55, 0.6, 0.8)
	mat_ceu.sky_horizon_color = Color(0.9, 0.85, 0.85)
	ceu.sky_material = mat_ceu
	e.background_mode = Environment.BG_SKY
	e.sky = ceu
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	e.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.environment = e
	add_child(env)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-40, 35, 0)
	sol.light_energy = 1.4
	sol.shadow_enabled = true
	add_child(sol)

	var nomes: Array[String] = []
	for f: String in ResourceLoader.list_directory(PASTA):
		if f.ends_with(".tres"):
			nomes.append(f)
	nomes.sort()
	var esfera := SphereMesh.new()
	esfera.radius = 0.45
	esfera.height = 0.9
	esfera.radial_segments = 64
	esfera.rings = 32
	for i in nomes.size():
		var m := MeshInstance3D.new()
		m.mesh = esfera
		m.material_override = load(PASTA + nomes[i]) as Material
		m.position = Vector3((i % COLUNAS) * 1.15, -int(i / COLUNAS) * 1.3, 0)
		add_child(m)
		var rotulo := Label3D.new()
		rotulo.text = nomes[i].trim_suffix(".tres")
		rotulo.font_size = 28
		rotulo.pixel_size = 0.004
		rotulo.position = m.position + Vector3(0, -0.6, 0)
		add_child(rotulo)
	# Fundo estampado atrás das esferas: mostra transparência/refração do vidro.
	var fundo := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(16, 10)
	fundo.mesh = plano
	fundo.rotation_degrees = Vector3(90, 0, 0)
	fundo.position = Vector3((COLUNAS - 1) * 1.15 / 2.0, -2.0, -1.2)
	var mat_fundo := load(PASTA + "chita.tres") as StandardMaterial3D
	if mat_fundo:
		mat_fundo = mat_fundo.duplicate() as StandardMaterial3D
		mat_fundo.uv1_triplanar = false
		mat_fundo.uv1_scale = Vector3(4, 3, 1)
		fundo.material_override = mat_fundo
	add_child(fundo)
	var cam := Camera3D.new()
	var linhas: int = ceili(nomes.size() / float(COLUNAS))
	cam.position = Vector3((COLUNAS - 1) * 1.15 / 2.0, -(linhas - 1) * 1.3 / 2.0, 7.5)
	cam.fov = 55
	add_child(cam)
	cam.current = true
