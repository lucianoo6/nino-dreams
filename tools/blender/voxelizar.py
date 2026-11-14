"""VOXEL DE TECIDO — converte um .glb (Hyper3D, com textura) em voxels coloridos.

Gera:
  • um .glb com a malha de voxels (só as faces visíveis), cor por voxel (atributo de cor) e UV 0..1 em
    cada face — o shader do jogo usa a UV para desenhar cada face como um quadradinho de feltro estofado;
  • (opcional) um .vox do MagicaVoxel com a mesma grade e paleta, para editar à mão;
  • se o modelo tem esqueleto (--rig), os voxels herdam os pesos do modelo original e as animações
    continuam funcionando (inclusive as UAL retargetadas, que usam os mesmos ossos).

Uso:
  python voxelizar.py entrada.glb saida.glb [--res 44] [--cores 48] [--vox saida.vox] [--rig]
--res: quantos voxels no MAIOR lado do modelo.  --cores: tamanho da paleta (≤ 255).
"""
import argparse
import struct
import sys

import bpy
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ap = argparse.ArgumentParser()
ap.add_argument("entrada")
ap.add_argument("saida")
ap.add_argument("--res", type=int, default=44)
ap.add_argument("--cores", type=int, default=48)
ap.add_argument("--vox", default="")
ap.add_argument("--rig", action="store_true")
args = ap.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:])

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=args.entrada)
arm = next((o for o in bpy.data.objects if o.type == "ARMATURE"), None)
if arm:
    arm.data.pose_position = "REST"
malhas = [o for o in bpy.data.objects if o.type == "MESH" and not o.name.startswith("Icosphere")]
for o in bpy.data.objects:
    if o.type == "MESH" and o.name.startswith("Icosphere"):
        bpy.data.objects.remove(o, do_unlink=True)
bpy.context.view_layer.update()
dg = bpy.context.evaluated_depsgraph_get()


# ---------------------------------------------------------------- amostragem (BVH + textura)

def imagem_base(mat):
    """Pixels (float RGBA, HxWx4) da textura de cor base do material, ou None."""
    if mat is None or not mat.use_nodes:
        return None
    bsdf = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if bsdf is None:
        return None
    links = bsdf.inputs["Base Color"].links
    no = links[0].from_node if links else None
    while no is not None and no.type != "TEX_IMAGE":
        entradas = [i for i in no.inputs if i.links]
        no = entradas[0].links[0].from_node if entradas else None
    if no is None or no.image is None:
        return None
    img = no.image
    w, h = img.size
    px = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(px)
    return px.reshape(h, w, 4)


tris_pts, tris_idx, tris_uv, tris_img, tris_cor = [], [], [], [], []
for o in malhas:
    ev = o.evaluated_get(dg)
    me = ev.to_mesh()
    me.calc_loop_triangles()
    uv = me.uv_layers.active.data if me.uv_layers.active else None
    base = len(tris_pts)
    mw = o.matrix_world
    for v in me.vertices:
        tris_pts.append(mw @ v.co)
    imgs = [imagem_base(s.material) for s in o.material_slots] or [None]
    cores = []
    for s in o.material_slots:
        c = (0.8, 0.8, 0.8)
        if s.material and s.material.use_nodes:
            b = next((n for n in s.material.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
            if b:
                c = tuple(b.inputs["Base Color"].default_value[:3])
        cores.append(c)
    cores = cores or [(0.8, 0.8, 0.8)]
    for t in me.loop_triangles:
        tris_idx.append([base + i for i in t.vertices])
        tris_uv.append([tuple(uv[li].uv) for li in t.loops] if uv else [(0, 0)] * 3)
        mi = min(t.material_index, len(imgs) - 1)
        tris_img.append(imgs[mi])
        tris_cor.append(cores[min(t.material_index, len(cores) - 1)])
    ev.to_mesh_clear()

bvh = BVHTree.FromPolygons(tris_pts, tris_idx)


def cor_no_ponto(loc, ti):
    a, b, c = (tris_pts[i] for i in tris_idx[ti])
    # coordenadas baricêntricas
    v0, v1, v2 = b - a, c - a, loc - a
    d00, d01, d11 = v0.dot(v0), v0.dot(v1), v1.dot(v1)
    d20, d21 = v2.dot(v0), v2.dot(v1)
    den = d00 * d11 - d01 * d01 or 1e-9
    v = (d11 * d20 - d01 * d21) / den
    w = (d00 * d21 - d01 * d20) / den
    u = 1.0 - v - w
    img = tris_img[ti]
    if img is None:
        return tris_cor[ti]
    (ua, va), (ub, vb), (uc, vc) = tris_uv[ti]
    uu = (u * ua + v * ub + w * uc) % 1.0
    vv = (u * va + v * vb + w * vc) % 1.0
    h, wd = img.shape[:2]
    p = img[min(int(vv * h), h - 1), min(int(uu * wd), wd - 1)]
    return (float(p[0]), float(p[1]), float(p[2]))


# ---------------------------------------------------------------- grade de voxels

pts = np.array([tuple(p) for p in tris_pts])
mn, mx = pts.min(0), pts.max(0)
lado = float((mx - mn).max()) / args.res
dims = np.ceil((mx - mn) / lado).astype(int) + 2
origem = mn - lado
print("grade", tuple(dims), "voxel", round(lado, 4))

ocupado = np.zeros(dims, dtype=bool)
cor = np.zeros(tuple(dims) + (3,), dtype=np.float32)
for i in range(dims[0]):
    for j in range(dims[1]):
        for k in range(dims[2]):
            p = Vector(origem + (np.array([i, j, k]) + 0.5) * lado)
            loc, nor, ti, dist = bvh.find_nearest(p, lado * 3.0)
            if loc is None:
                continue
            dentro = dist < lado * 0.62 or (p - loc).dot(nor) < 0.0
            if not dentro:
                continue
            ocupado[i, j, k] = True
            cor[i, j, k] = cor_no_ponto(loc, ti)

# preenche o interior (para o .vox ficar "maciço" e sem buracos de normais esquisitas)
from collections import deque  # noqa: E402

fora = np.zeros(dims, dtype=bool)
fila = deque([(0, 0, 0)])
fora[0, 0, 0] = True
while fila:
    i, j, k = fila.popleft()
    for di, dj, dk in ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)):
        a, b, c = i + di, j + dj, k + dk
        if 0 <= a < dims[0] and 0 <= b < dims[1] and 0 <= c < dims[2] and not fora[a, b, c] and not ocupado[a, b, c]:
            fora[a, b, c] = True
            fila.append((a, b, c))
interior = ~fora & ~ocupado
ocupado |= interior
print("voxels", int(ocupado.sum()))

# ---------------------------------------------------------------- paleta (quantização)

from PIL import Image  # noqa: E402

idx_ocup = np.argwhere(ocupado)
cores_v = np.clip(cor[ocupado], 0, 1)
# voxels do interior não têm cor amostrada: herdam a do vizinho de superfície mais próximo (média simples)
sem_cor = cores_v.sum(1) == 0
if sem_cor.any():
    cores_v[sem_cor] = cores_v[~sem_cor].mean(0)
# um pouco mais de saturação (arte em voxel fica melhor com cores vivas)
cinza = cores_v.mean(1, keepdims=True)
cores_v = np.clip(cinza + (cores_v - cinza) * 1.2, 0, 1)
img = Image.fromarray((cores_v[None, :, :] * 255).astype(np.uint8), "RGB")
q = img.quantize(colors=min(args.cores, 255), method=Image.Quantize.MEDIANCUT)
paleta = np.array(q.getpalette()[: min(args.cores, 255) * 3], dtype=np.float32).reshape(-1, 3) / 255.0
indices = np.array(q).reshape(-1)
grade_idx = np.full(dims, -1, dtype=np.int32)
grade_idx[tuple(idx_ocup.T)] = indices

# ---------------------------------------------------------------- malha (só faces visíveis)

DIRS = [((1, 0, 0), [(1, 0, 0), (1, 1, 0), (1, 1, 1), (1, 0, 1)]),
        ((-1, 0, 0), [(0, 0, 0), (0, 0, 1), (0, 1, 1), (0, 1, 0)]),
        ((0, 1, 0), [(0, 1, 0), (0, 1, 1), (1, 1, 1), (1, 1, 0)]),
        ((0, -1, 0), [(0, 0, 0), (1, 0, 0), (1, 0, 1), (0, 0, 1)]),
        ((0, 0, 1), [(0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1)]),
        ((0, 0, -1), [(0, 0, 0), (0, 1, 0), (1, 1, 0), (1, 0, 0)])]
verts, faces, fcores = [], [], []
for (i, j, k) in idx_ocup:
    for (d, cantos) in DIRS:
        a, b, c = i + d[0], j + d[1], k + d[2]
        if 0 <= a < dims[0] and 0 <= b < dims[1] and 0 <= c < dims[2] and ocupado[a, b, c]:
            continue
        base = len(verts)
        for cx, cy, cz in cantos:
            verts.append(tuple(origem + (np.array([i + cx, j + cy, k + cz])) * lado))
        faces.append((base, base + 1, base + 2, base + 3))
        fcores.append(paleta[grade_idx[i, j, k]])

me = bpy.data.meshes.new("voxels")
me.from_pydata(verts, [], faces)
me.update()
uvl = me.uv_layers.new(name="UVMap")
for f in me.polygons:
    for n, li in enumerate(f.loop_indices):
        uvl.data[li].uv = ((0, 0), (1, 0), (1, 1), (0, 1))[n]
ca = me.color_attributes.new(name="Color", type="FLOAT_COLOR", domain="CORNER")


def linear(c):
    # a paleta está em sRGB (como na textura e no MagicaVoxel); o atributo de cor é linear
    c = np.asarray(c, dtype=np.float64)
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


for f, c in zip(me.polygons, fcores):
    cl = linear(c)
    for li in f.loop_indices:
        ca.data[li].color = (float(cl[0]), float(cl[1]), float(cl[2]), 1.0)
vox = bpy.data.objects.new("Voxels", me)
bpy.context.scene.collection.objects.link(vox)
mat = bpy.data.materials.new("voxel_tecido")
mat.use_nodes = True
nt = mat.node_tree
attr = nt.nodes.new("ShaderNodeVertexColor")
attr.layer_name = "Color"
nt.links.new(attr.outputs["Color"], nt.nodes["Principled BSDF"].inputs["Base Color"])
nt.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.95
me.materials.append(mat)
print("faces", len(faces), "paleta", len(paleta))

if args.rig and arm:
    # herda os pesos dos ossos do modelo original e deforma junto com o esqueleto
    vox.parent = arm
    vox.matrix_parent_inverse = arm.matrix_world.inverted()
    for g in malhas[0].vertex_groups:
        vox.vertex_groups.new(name=g.name)
    dt = vox.modifiers.new("Pesos", "DATA_TRANSFER")
    dt.object = malhas[0]
    dt.use_vert_data = True
    dt.data_types_verts = {"VGROUP_WEIGHTS"}
    dt.vert_mapping = "POLYINTERP_NEAREST"
    bpy.context.view_layer.objects.active = vox
    bpy.ops.object.datalayout_transfer(modifier="Pesos")
    bpy.ops.object.modifier_apply(modifier="Pesos")
    m = vox.modifiers.new("Armature", "ARMATURE")
    m.object = arm
    arm.data.pose_position = "POSE"

for o in malhas:
    bpy.data.objects.remove(o, do_unlink=True)

bpy.ops.export_scene.gltf(filepath=args.saida, export_format="GLB", export_animations=bool(args.rig and arm),
                          export_tangents=True, export_vertex_color="ACTIVE", export_all_vertex_colors=False)
print("ok", args.saida)

# ---------------------------------------------------------------- .vox do MagicaVoxel


def escrever_vox(caminho):
    # MagicaVoxel é Z para cima; nossa grade veio do Blender (também Z para cima) → direto.
    sx, sy, sz = (int(x) for x in dims)
    if max(sx, sy, sz) > 256:
        print("grade grande demais para .vox (máx. 256)")
        return
    xyzi = bytearray()
    n = 0
    for (i, j, k) in idx_ocup:
        xyzi += struct.pack("<BBBB", i, j, k, int(grade_idx[i, j, k]) + 1)
        n += 1

    def chunk(nome, conteudo, filhos=b""):
        return nome + struct.pack("<ii", len(conteudo), len(filhos)) + conteudo + filhos

    size = chunk(b"SIZE", struct.pack("<iii", sx, sy, sz))
    dados = chunk(b"XYZI", struct.pack("<i", n) + bytes(xyzi))
    rgba = bytearray()
    for c in range(256):
        if c < len(paleta):
            r, g, b = (int(x * 255) for x in paleta[c])
            rgba += struct.pack("<BBBB", r, g, b, 255)
        else:
            rgba += struct.pack("<BBBB", 0, 0, 0, 255)
    pal = chunk(b"RGBA", bytes(rgba))
    main = chunk(b"MAIN", b"", size + dados + pal)
    with open(caminho, "wb") as f:
        f.write(b"VOX " + struct.pack("<i", 150) + main)
    print("vox", caminho, n, "voxels")


if args.vox:
    escrever_vox(args.vox)
