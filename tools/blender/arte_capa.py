"""Arte de capa (key art) do jogo, renderizada no Blender (Cycles) com os modelos de verdade.

Nino de pano pulando com a Luna acesa na mão, Mel com a Estrelinha, num planetinha de feltro
sob uma lua crescente gigante, livros e botões flutuando no céu roxo.

Uso (Blender 4.2+ ou o módulo `bpy` do pip):
    python arte_capa.py SAIDA.png [largura altura amostras]
    blender -b -P arte_capa.py -- SAIDA.png 1920 1080 96
"""
import math
import os
import random
import sys

import bpy
from mathutils import Vector

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ASSETS = os.path.join(RAIZ, "assets")

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
SAIDA = args[0] if args else os.path.join(RAIZ, "docs", "referencias", "arte_capa.png")
LARG = int(args[1]) if len(args) > 1 else 1920
ALT = int(args[2]) if len(args) > 2 else 1080
AMOSTRAS = int(args[3]) if len(args) > 3 else 96

random.seed(7)
bpy.ops.wm.read_factory_settings(use_empty=True)
cena = bpy.context.scene


# ---------------------------------------------------------------- materiais

def mat_tecido(nome, cor, textura=None, escala=6.0, sheen=0.45, rugosidade=0.85):
    """Tecido: Principled com 'sheen' (o brilho aveludado do feltro) e textura de fibra opcional."""
    m = bpy.data.materials.new(nome)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*cor, 1.0)
    bsdf.inputs["Roughness"].default_value = rugosidade
    bsdf.inputs["Sheen Weight"].default_value = sheen
    bsdf.inputs["Sheen Tint"].default_value = (*[min(1.0, c * 1.6) for c in cor], 1.0)
    if textura:
        pasta = os.path.join(ASSETS, "materiais", textura)
        coord = nt.nodes.new("ShaderNodeTexCoord")
        mapa = nt.nodes.new("ShaderNodeMapping")
        mapa.inputs["Scale"].default_value = (escala, escala, escala)
        nt.links.new(coord.outputs["Generated"], mapa.inputs["Vector"])
        alb = nt.nodes.new("ShaderNodeTexImage")
        alb.image = bpy.data.images.load(os.path.join(pasta, "albedo.png"))
        alb.projection = "BOX"
        alb.projection_blend = 0.3
        nt.links.new(mapa.outputs["Vector"], alb.inputs["Vector"])
        mult = nt.nodes.new("ShaderNodeMix")
        mult.data_type = "RGBA"
        mult.blend_type = "MULTIPLY"
        mult.inputs["Factor"].default_value = 1.0
        entradas = [i for i in mult.inputs if i.type == "RGBA"]
        saida = next(o for o in mult.outputs if o.type == "RGBA")
        entradas[1].default_value = (*cor, 1.0)
        nt.links.new(alb.outputs["Color"], entradas[0])
        nt.links.new(saida, bsdf.inputs["Base Color"])
        nor_img = nt.nodes.new("ShaderNodeTexImage")
        nor_img.image = bpy.data.images.load(os.path.join(pasta, "normal.png"))
        nor_img.image.colorspace_settings.name = "Non-Color"
        nor_img.projection = "BOX"
        nor_img.projection_blend = 0.3
        nt.links.new(mapa.outputs["Vector"], nor_img.inputs["Vector"])
        nor = nt.nodes.new("ShaderNodeNormalMap")
        nor.inputs["Strength"].default_value = 0.8
        nt.links.new(nor_img.outputs["Color"], nor.inputs["Color"])
        nt.links.new(nor.outputs["Normal"], bsdf.inputs["Normal"])
    return m


def mat_luz(nome, cor, forca):
    m = bpy.data.materials.new(nome)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*cor, 1.0)
    bsdf.inputs["Emission Color"].default_value = (*cor, 1.0)
    bsdf.inputs["Emission Strength"].default_value = forca
    return m


def aplicar(obj, mat):
    obj.data.materials.clear()
    obj.data.materials.append(mat)


# ---------------------------------------------------------------- personagens

def importar(caminho):
    antes = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=caminho)
    return [o for o in bpy.data.objects if o not in antes]


def personagem(modelo, animacoes, acao, quadro, pos, giro_z, escala=1.0):
    # As ações de animação (retarget UAL) vêm do .glb de animações; o resto dele é descartado.
    for o in importar(os.path.join(ASSETS, "animacoes", "ual", animacoes)):
        bpy.data.objects.remove(o, do_unlink=True)
    objs = importar(os.path.join(ASSETS, "models", "personagens", modelo))
    arm = next(o for o in objs if o.type == "ARMATURE")
    for o in objs:
        if o.type == "MESH" and o.name.startswith("Icosphere"):
            bpy.data.objects.remove(o, do_unlink=True)
    act = bpy.data.actions[acao]
    arm.animation_data_create()
    arm.animation_data.action = act
    if hasattr(arm.animation_data, "action_slot") and len(act.slots) > 0:
        arm.animation_data.action_slot = act.slots[0]
    cena.frame_set(quadro)
    arm.location = pos
    arm.rotation_mode = "XYZ"
    arm.rotation_euler = (0.0, 0.0, giro_z)
    arm.scale = (escala, escala, escala)
    return arm


def osso_mundo(arm, osso):
    bpy.context.view_layer.update()
    pb = arm.pose.bones[osso]
    return arm.matrix_world @ pb.head


# o planetinha: o topo fica em z = 0
RAIO = 7.0
bpy.ops.mesh.primitive_uv_sphere_add(radius=RAIO, location=(0, 0, -RAIO), segments=96, ring_count=48)
planeta = bpy.context.active_object
bpy.ops.object.shade_smooth()
aplicar(planeta, mat_tecido("Grama", (0.3, 0.55, 0.26), "feltro", escala=2.5, sheen=0.25))

nino = personagem("nino_pano.glb", "nino_pano_ual.glb", "ual_Jump_Loop", 8, (-0.55, 0.0, 1.55), math.radians(-18))
mel = personagem("mel_pano.glb", "mel_pano_ual.glb", "ual_Idle_Lantern_Loop", 8, (0.75, 0.25, 0.74), math.radians(16),
                 0.82)

# a Luna (lua crescente) na mão do Nino e a Estrelinha na mão da Mel
mao_nino = osso_mundo(nino, "LeftHand")
mao_mel = osso_mundo(mel, "RightHand")

bpy.ops.mesh.primitive_uv_sphere_add(radius=0.16, location=mao_nino + Vector((0.0, -0.08, 0.12)))
luna = bpy.context.active_object
bpy.ops.object.shade_smooth()
aplicar(luna, mat_luz("Luna", (1.0, 0.96, 0.78), 18.0))
bpy.ops.object.light_add(type="POINT", location=luna.location)
bpy.context.active_object.data.energy = 60
bpy.context.active_object.data.color = (0.8, 0.88, 1.0)
bpy.context.active_object.data.shadow_soft_size = 0.2

bpy.ops.mesh.primitive_ico_sphere_add(radius=0.11, subdivisions=1, location=mao_mel + Vector((0.0, -0.08, 0.06)))
estrela = bpy.context.active_object
estrela.scale = (1.0, 0.45, 1.0)
aplicar(estrela, mat_luz("Estrelinha", (1.0, 0.75, 0.3), 25.0))
bpy.ops.object.light_add(type="POINT", location=estrela.location)
bpy.context.active_object.data.energy = 45
bpy.context.active_object.data.color = (1.0, 0.7, 0.35)
bpy.context.active_object.data.shadow_soft_size = 0.15


# ---------------------------------------------------------------- cenário

# lua crescente gigante no céu (disco claro menos um disco "de céu" deslocado)
bpy.ops.mesh.primitive_cylinder_add(vertices=160, radius=3.2, depth=0.1, location=(4.2, 14.0, 5.2), rotation=(math.pi / 2, 0, 0))
lua = bpy.context.active_object
bpy.ops.mesh.primitive_cylinder_add(vertices=160, radius=3.0, depth=0.6, location=(5.5, 13.9, 6.0), rotation=(math.pi / 2, 0, 0))
corte = bpy.context.active_object
mod = lua.modifiers.new("Crescente", "BOOLEAN")
mod.operation = "DIFFERENCE"
mod.object = corte
bpy.context.view_layer.objects.active = lua
bpy.ops.object.modifier_apply(modifier="Crescente")
bpy.data.objects.remove(corte, do_unlink=True)
aplicar(lua, mat_luz("LuaDoCeu", (1.0, 0.78, 0.42), 0.75))

# estrelinhas no fundo
mat_estrela = mat_luz("EstrelaCeu", (1.0, 0.95, 0.8), 12.0)
for _ in range(140):
    ang = random.uniform(-1.4, 1.4)
    alt = random.uniform(-0.5, 1.2)
    p = Vector((math.sin(ang) * 30.0, math.cos(ang) * 30.0 + 5.0, alt * 14.0 + 3.0))
    bpy.ops.mesh.primitive_ico_sphere_add(radius=random.uniform(0.03, 0.09), subdivisions=1, location=p)
    aplicar(bpy.context.active_object, mat_estrela)

# livros flutuando (capa de veludo, miolo de papel) e botões de costura
cores_livro = [(0.75, 0.18, 0.22), (0.2, 0.35, 0.7), (0.3, 0.55, 0.3), (0.85, 0.6, 0.2), (0.55, 0.3, 0.6)]
papel = mat_tecido("Papel", (0.95, 0.92, 0.82), rugosidade=0.9, sheen=0.2)
for i, (x, y, z) in enumerate([(-3.4, 3.0, 0.9), (3.0, 2.0, 3.4), (-1.6, 6.0, 4.2), (2.2, 5.0, 1.6), (-4.2, 6.5, 0.8)]):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x, y, z),
                                    rotation=(random.uniform(-0.6, 0.6), random.uniform(-0.6, 0.6), random.uniform(0, 3)))
    livro = bpy.context.active_object
    livro.scale = (0.32, 0.08, 0.45)
    bpy.ops.object.modifier_add(type="BEVEL")
    livro.modifiers["Bevel"].width = 0.02
    aplicar(livro, mat_tecido("Capa%d" % i, cores_livro[i % 5], "veludo", escala=3.0))
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=livro.location, rotation=livro.rotation_euler)
    miolo = bpy.context.active_object
    miolo.scale = (0.3, 0.085, 0.43)
    miolo.location += Vector((0.02, 0, 0))
    aplicar(miolo, papel)

cores_botao = [(1.0, 0.78, 0.25), (0.95, 0.35, 0.4), (0.35, 0.6, 0.95)]
for i, (x, y, z) in enumerate([(-2.4, 1.0, 1.1), (1.9, 0.6, 2.4), (-0.8, 3.0, 3.3), (3.6, 4.0, 0.6)]):
    bpy.ops.mesh.primitive_cylinder_add(radius=0.18, depth=0.06, location=(x, y, z),
                                        rotation=(random.uniform(0.6, 1.4), random.uniform(-0.5, 0.5), 0))
    b = bpy.context.active_object
    bpy.ops.object.modifier_add(type="BEVEL")
    b.modifiers["Bevel"].width = 0.02
    b.modifiers["Bevel"].segments = 3
    m = bpy.data.materials.new("Botao%d" % i)
    m.use_nodes = True
    bs = m.node_tree.nodes["Principled BSDF"]
    bs.inputs["Base Color"].default_value = (*cores_botao[i % 3], 1)
    bs.inputs["Roughness"].default_value = 0.25
    bs.inputs["Coat Weight"].default_value = 0.6
    aplicar(b, m)

# florzinhas de feltro no planeta
for i in range(18):
    a = random.uniform(-1.0, 1.0)
    bb = random.uniform(-0.5, 0.9)
    n = Vector((math.sin(a) * 0.6, math.sin(bb) * 0.6, 1.0)).normalized()
    pos = Vector((0, 0, -RAIO)) + n * RAIO
    if (pos.xy - Vector((0.0, 0.1))).length < 1.3:
        continue
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.09, location=pos + n * 0.06)
    aplicar(bpy.context.active_object, mat_tecido("Flor%d" % i, [(1, 0.55, 0.65), (1, 0.85, 0.35), (0.75, 0.6, 1.0)][i % 3]))


# ---------------------------------------------------------------- luz, céu e câmera

mundo = bpy.data.worlds.new("Ceu")
cena.world = mundo
mundo.use_nodes = True
fundo = mundo.node_tree.nodes["Background"]
coord = mundo.node_tree.nodes.new("ShaderNodeTexCoord")
sep = mundo.node_tree.nodes.new("ShaderNodeSeparateXYZ")
rampa = mundo.node_tree.nodes.new("ShaderNodeValToRGB")
rampa.color_ramp.elements[0].position = 0.35
rampa.color_ramp.elements[0].color = (0.42, 0.2, 0.42, 1)
rampa.color_ramp.elements[1].position = 0.75
rampa.color_ramp.elements[1].color = (0.06, 0.05, 0.2, 1)
mundo.node_tree.links.new(coord.outputs["Window"], sep.inputs["Vector"])
mundo.node_tree.links.new(sep.outputs["Y"], rampa.inputs["Fac"])
mundo.node_tree.links.new(rampa.outputs["Color"], fundo.inputs["Color"])
fundo.inputs["Strength"].default_value = 0.6

bpy.ops.object.light_add(type="AREA", location=(-4.0, -5.0, 5.0))
chave = bpy.context.active_object
chave.data.energy = 900
chave.data.size = 5.0
chave.data.color = (1.0, 0.82, 0.65)
chave.rotation_euler = (math.radians(50), 0, math.radians(-38))
bpy.ops.object.light_add(type="AREA", location=(3.5, 6.0, 4.0))
contra = bpy.context.active_object
contra.data.energy = 700
contra.data.size = 4.0
contra.data.color = (0.6, 0.7, 1.0)
contra.rotation_euler = (math.radians(-60), 0, math.radians(150))

bpy.ops.object.camera_add(location=(0.2, -7.2, 1.55))
cam = bpy.context.active_object
cena.camera = cam
cam.data.lens = 38
alvo = Vector((0.1, 0.5, 1.35))
cam.rotation_euler = (alvo - cam.location).to_track_quat("-Z", "Y").to_euler()
cam.data.dof.use_dof = True
cam.data.dof.focus_distance = (alvo - cam.location).length
cam.data.dof.aperture_fstop = 2.8

cena.render.engine = "CYCLES"
cena.cycles.samples = AMOSTRAS
cena.cycles.use_denoising = True
cena.cycles.device = "CPU"
cena.render.resolution_x = LARG
cena.render.resolution_y = ALT
cena.render.film_transparent = False
cena.view_settings.view_transform = "AgX"
cena.view_settings.look = "AgX - Medium High Contrast"
cena.render.filepath = SAIDA
bpy.ops.render.render(write_still=True)
print("arte salva em", SAIDA)
