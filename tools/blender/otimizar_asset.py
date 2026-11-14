"""Deixa um .glb do Hyper3D leve para o jogo: texturas até 1024 px, malha centrada
com a BASE em y = 0 (fica fácil de pousar no chão) e escala em que o maior lado mede 1.
Uso: python otimizar_asset.py entrada.glb saida.glb [deitar|tombar]
  deitar: o objeto veio "em pé" mas é chato (luva, folha, leque) → deita com a face para cima;
  tombar: deita um objeto alto de lado (garrafa caída).
"""
import sys

import bpy
from mathutils import Vector

MODOS = ("deitar", "tombar")
MODO = sys.argv[-1] if sys.argv[-1] in MODOS else ""
args = [a for a in sys.argv if a.endswith(".glb")]
entrada, saida = args[-2], args[-1]
MAX = 1024

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=entrada)
malhas = [o for o in bpy.data.objects if o.type == "MESH"]
for img in bpy.data.images:
    if img.size[0] > MAX or img.size[1] > MAX:
        img.scale(MAX, MAX)
# aplica transformações e normaliza: base em z=0 (Blender é Z para cima), centrado em XY, maior lado = 1
bpy.ops.object.select_all(action="DESELECT")
for o in malhas:
    o.select_set(True)
bpy.context.view_layer.objects.active = malhas[0]
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
for o in malhas:
    for v in o.data.vertices:
        x, y, z = v.co
        if MODO == "deitar":   # a espessura (Y do Blender) vira a altura
            v.co = Vector((x, -z, y))
        elif MODO == "tombar":  # a altura (Z) vira o comprimento (X)
            v.co = Vector((z, y, -x))
    o.data.update()
pts = [o.matrix_world @ Vector(c) for o in malhas for c in o.bound_box]
mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
centro = Vector(((mn.x + mx.x) / 2, (mn.y + mx.y) / 2, mn.z))
escala = 1.0 / max(mx - mn)
for o in malhas:
    for v in o.data.vertices:
        v.co = (v.co - centro) * escala
bpy.ops.export_scene.gltf(filepath=saida, export_format="GLB", export_image_format="AUTO",
                          export_apply=True, export_animations=False)
print("ok", saida, "tamanho original", tuple(round(x, 3) for x in (mx - mn)))
