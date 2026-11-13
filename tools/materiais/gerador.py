"""Gerador procedural de materiais PBR tileáveis para Once Upon a Pillow.

Cada material gera: albedo.png, normal.png (OpenGL/Godot), roughness.png, ao.png, height.png
em assets/materiais/<nome>/ e um ou mais StandardMaterial3D em materials/pbr/<nome>*.tres.

Os albedos dos tecidos/cerâmica/plástico são quase brancos: a cor vem do `albedo_color` de cada
variante .tres — uma textura, muitas cores (economiza espaço e mantém tudo coerente).

Uso:
    python tools/materiais/gerador.py               # todos, 1024 px
    python tools/materiais/gerador.py feltro la -r 512
"""
import argparse
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from ruido import (ao_de_altura, borrar, campo, deformar, linhas_tileaveis,  # noqa: E402
                   normal_de_altura, normalizar, rng, voronoi)

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
MATERIAIS = {}


def material(nome):
    def reg(f):
        MATERIAIS[nome] = f
        return f
    return reg


def grade(n, celulas):
    """Coordenadas locais (u, v) 0..1 dentro de cada célula e índices (i, j) da célula."""
    y, x = np.mgrid[0:n, 0:n] / n * celulas
    return x % 1.0, y % 1.0, np.floor(x).astype(int), np.floor(y).astype(int)


def tingir(base, cor_a, cor_b, t):
    t = t[..., None]
    return np.asarray(cor_a) * (1 - t) + np.asarray(cor_b) * t


# ---------------------------------------------------------------- TECIDOS

@material("feltro")
def feltro(n):
    """Feltro: milhares de fibras curtas emaranhadas + grumos de baixa frequência."""
    fibras = linhas_tileaveis(n, int(n * n / 90), n * 0.02, 1, seed=1, curva=0.8)
    fibras += linhas_tileaveis(n, int(n * n / 400), n * 0.035, 2, seed=2, curva=1.2) * 0.6
    fibras = normalizar(borrar(fibras, 0.6))
    grumos = campo(n, beta=3.0, fmin=2, seed=3)
    h = normalizar(fibras * 0.55 + grumos * 0.45)
    var = campo(n, beta=2.2, fmin=3, seed=4)
    albedo = tingir(None, (0.66, 0.66, 0.66), (1.0, 1.0, 1.0), np.clip(var * 0.45 + fibras * 0.75, 0, 1))
    return dict(albedo=albedo, altura=h, rough=0.85 + 0.12 * (1 - fibras), forca_normal=6.0)


@material("la_trico")
def la_trico(n, colunas=10, carreiras=14):
    """Tricô ponto meia: colunas de 'V' (duas laçadas inclinadas), fio torcido e penugem."""
    u, v, i, j = grade(n, 1)  # só para shape
    y, x = np.mgrid[0:n, 0:n] / n
    gx, gy = x * colunas, y * carreiras
    h = np.zeros((n, n), np.float32)
    torcao = np.zeros((n, n), np.float32)
    for dv in (0.0, -1.0):  # a laçada da carreira de cima invade a de baixo
        lu = gx % 1.0
        lv = (gy % 1.0) - dv * 1.0
        for cx, ang in ((0.29, 0.55), (0.71, -0.55)):
            dxp, dyp = lu - cx, lv - 0.55
            ca, sa = np.cos(ang), np.sin(ang)
            a = dxp * ca - dyp * sa
            b = dxp * sa + dyp * ca
            e = (a / 0.17) ** 2 + (b / 0.42) ** 2
            bump = np.sqrt(np.clip(1 - e, 0, 1))
            h = np.maximum(h, bump)
            torcao = np.maximum(torcao, bump * (0.5 + 0.5 * np.sin(b * 60 + a * 8)))
    fuzz = linhas_tileaveis(n, int(n * n / 260), n * 0.015, 1, seed=11, curva=1.5)
    fuzz = normalizar(borrar(fuzz, 0.5))
    h = normalizar(h * 0.8 + torcao * 0.12 + fuzz * 0.08)
    var = campo(n, beta=2.5, fmin=2, seed=12)
    albedo = tingir(None, (0.74, 0.74, 0.74), (0.98, 0.98, 0.98), np.clip(h * 0.7 + var * 0.3, 0, 1))
    return dict(albedo=albedo, altura=h, rough=0.9 - 0.1 * torcao, forca_normal=5.0)


@material("cotele")
def cotele(n, gomos=16):
    """Veludo cotelê: gomos verticais arredondados cobertos de pelúcia curta."""
    y, x = np.mgrid[0:n, 0:n] / n
    perfil = np.abs(np.sin(np.pi * x * gomos)) ** 0.6
    pelos = linhas_tileaveis(n, int(n * n / 120), n * 0.006, 1, seed=21, direcao=np.pi / 2, espalhar=0.6)
    pelos = normalizar(borrar(pelos, 0.5))
    h = normalizar(perfil * 0.85 + pelos * 0.15)
    var = campo(n, beta=2.5, fmin=1, seed=22)
    albedo = tingir(None, (0.58, 0.58, 0.58), (0.98, 0.98, 0.98), np.clip(perfil * 0.75 + var * 0.25, 0, 1))
    return dict(albedo=albedo, altura=h, rough=0.75 + 0.2 * (1 - perfil), forca_normal=4.0, veludo=True)


def trama(n, fios, padrao, espessura=0.42, seed=0):
    """Tecelagem genérica: fios de urdume (verticais) e trama (horizontais).
    padrao(i, j) -> True quando o urdume passa POR CIMA. Retorna (altura, mascara_urdume, slub)."""
    y, x = np.mgrid[0:n, 0:n] / n * fios
    i, j = np.floor(x).astype(int), np.floor(y).astype(int)
    u, v = x % 1.0, y % 1.0
    slub_u = campo(n, beta=2.0, fmin=fios / 4, fmax=fios * 2, seed=seed + 1)
    slub_v = campo(n, beta=2.0, fmin=fios / 4, fmax=fios * 2, seed=seed + 2)
    perfil_u = np.sqrt(np.clip(1 - ((u - 0.5) / (espessura + 0.06 * slub_u)) ** 2, 0, 1))
    perfil_v = np.sqrt(np.clip(1 - ((v - 0.5) / (espessura + 0.06 * slub_v)) ** 2, 0, 1))
    por_cima = padrao(i, j)
    # ondulação: o fio sobe no meio do "ponto" em que está por cima
    ond_u = 0.75 + 0.25 * np.sin(np.pi * v)
    ond_v = 0.75 + 0.25 * np.sin(np.pi * u)
    h_u = perfil_u * ond_u * np.where(por_cima, 1.0, 0.55)
    h_v = perfil_v * ond_v * np.where(por_cima, 0.55, 1.0)
    urdume = h_u >= h_v
    return np.maximum(h_u, h_v), urdume, slub_u


@material("jeans")
def jeans(n, fios=48):
    """Brim/jeans: sarja 3x1 diagonal, urdume índigo e trama crua, com 'slub' e desbotado."""
    h, urdume, slub = trama(n, fios, lambda i, j: ((i + j) % 4) != 0, seed=30)
    desb = campo(n, beta=2.6, fmin=1, seed=33)
    indigo = tingir(None, (0.08, 0.14, 0.30), (0.30, 0.42, 0.62), np.clip(desb * 0.7 + slub * 0.5, 0, 1))
    cru = tingir(None, (0.72, 0.72, 0.68), (0.90, 0.90, 0.86), slub)
    albedo = np.where(urdume[..., None], indigo, cru) * (0.75 + 0.25 * h[..., None])
    return dict(albedo=albedo, altura=h, rough=0.88 - 0.1 * h, forca_normal=4.0, tingivel=False)


@material("chita")
def chita(n, fios=64):
    """Chita: algodão em tela 1x1 com estampa floral brasileira (flores grandes, folhas e fundo vibrante)."""
    h, _, _ = trama(n, fios, lambda i, j: ((i + j) % 2) == 0, espessura=0.45, seed=40)
    r = rng(41)
    img = Image.new("RGB", (n, n), (196, 30, 45))
    d = ImageDraw.Draw(img)
    paleta_flor = [(250, 205, 40), (245, 245, 235), (40, 90, 200), (240, 120, 160)]
    folha = (30, 120, 60)

    def carimbo(fx, fy, raio, cor):
        for ox in (-n, 0, n):
            for oy in (-n, 0, n):
                cx, cy = fx + ox, fy + oy
                for k in range(2):  # folhas
                    a = r.random() * np.tau if hasattr(np, "tau") else r.random() * 2 * np.pi
                    lx, ly = cx + np.cos(a) * raio * 1.3, cy + np.sin(a) * raio * 1.3
                    d.ellipse([lx - raio * 0.55, ly - raio * 0.3, lx + raio * 0.55, ly + raio * 0.3], fill=folha)
                for k in range(6):  # pétalas
                    a = k / 6 * 2 * np.pi
                    px, py = cx + np.cos(a) * raio * 0.6, cy + np.sin(a) * raio * 0.6
                    d.ellipse([px - raio * 0.45, py - raio * 0.45, px + raio * 0.45, py + raio * 0.45], fill=cor)
                d.ellipse([cx - raio * 0.32, cy - raio * 0.32, cx + raio * 0.32, cy + raio * 0.32], fill=(250, 180, 30))
                d.ellipse([cx - raio * 0.14, cy - raio * 0.14, cx + raio * 0.14, cy + raio * 0.14], fill=(120, 40, 20))

    for _ in range(14):
        carimbo(r.random() * n, r.random() * n, n * (0.06 + 0.04 * r.random()), paleta_flor[r.integers(0, 4)])
    for _ in range(40):  # florzinhas
        cx, cy, rr = r.random() * n, r.random() * n, n * 0.012
        for ox in (-n, 0, n):
            for oy in (-n, 0, n):
                d.ellipse([cx + ox - rr, cy + oy - rr, cx + ox + rr, cy + oy + rr], fill=(250, 240, 230))
    estampa = np.asarray(img, dtype=np.float32) / 255.0
    # tinta não cobre 100% (vê-se a trama) + leve desbotado
    desb = campo(n, beta=2.5, fmin=1, seed=42)[..., None]
    albedo = estampa * (0.78 + 0.22 * h[..., None]) * (0.92 + 0.08 * desb)
    return dict(albedo=albedo, altura=h, rough=0.85, forca_normal=3.0, tingivel=False)


# ---------------------------------------------------------------- CERÂMICA / VIDRO / BOTÕES

@material("ceramica")
def ceramica(n):
    """Cerâmica esmaltada artesanal: esmalte com variação de espessura, craquelê fino e pintinhas de ferro."""
    f1, f2, _ = voronoi(n, 900, seed=50)
    craq = np.clip(1 - (f2 - f1) / 0.0018, 0, 1)
    craq = craq * np.clip((campo(n, beta=2.0, fmin=2, seed=51) - 0.5) * 4, 0, 1)  # craquelê só em algumas regiões
    esmalte = campo(n, beta=3.0, fmin=1, seed=52)
    r = rng(53)
    pintas = np.zeros((n, n), np.float32)
    for _ in range(int(n * n / 9000)):
        x, y = r.integers(0, n, 2)
        pintas[y, x] = r.random()
    pintas = np.clip(borrar(pintas, 1.2) * 30, 0, 1)
    albedo = tingir(None, (0.86, 0.86, 0.86), (0.98, 0.98, 0.98), esmalte)
    albedo = albedo * (1 - 0.18 * craq[..., None]) * (1 - 0.6 * pintas[..., None])
    h = normalizar(esmalte * 0.8 - craq * 0.2)
    rough = 0.06 + 0.08 * campo(n, beta=2.0, fmin=4, seed=54) + 0.2 * craq
    return dict(albedo=albedo, altura=h, rough=rough, forca_normal=1.5, ceramica=True)


@material("vidro")
def vidro(n):
    """Vidro: quase sem textura — manchinhas de dedo, poeira e micro-riscos na rugosidade; ondulação leve."""
    manchas = np.clip((campo(n, beta=2.4, fmin=2, seed=60) - 0.55) * 4, 0, 1)
    riscos = normalizar(borrar(linhas_tileaveis(n, 220, n * 0.12, 1, seed=61, curva=0.1), 0.4))
    onda = campo(n, beta=3.5, fmin=1, seed=62)
    rough = np.clip(0.02 + manchas * 0.25 + riscos * 0.35, 0, 1)
    albedo = np.ones((n, n, 3)) * 0.98
    return dict(albedo=albedo, altura=onda * 0.5 + riscos * 0.02, rough=rough, forca_normal=0.6, vidro=True)


@material("botao_plastico")
def botao_plastico(n):
    """Plástico de botão antigo: marmorizado sutil (domain warp) e brilho."""
    a, b = campo(n, beta=2.5, fmin=1, seed=70), campo(n, beta=2.5, fmin=1, seed=71)
    veio = deformar(campo(n, beta=2.0, fmin=2, seed=72), a, b, n * 0.15)
    veio = np.abs(np.sin(veio * 12)) ** 3
    albedo = tingir(None, (0.85, 0.85, 0.85), (1.0, 1.0, 1.0), veio)
    return dict(albedo=albedo, altura=veio * 0.1, rough=0.18 + 0.1 * veio, forca_normal=0.5, ceramica=True)


@material("madeira")
def madeira(n):
    """Madeira clara de botão/carretel: anéis deformados, veios finos e poros."""
    y, x = np.mgrid[0:n, 0:n] / n
    a, b = campo(n, beta=2.8, fmin=1, seed=80), campo(n, beta=2.8, fmin=1, seed=81)
    base = np.sin(2 * np.pi * (x * 6 + (a - 0.5) * 1.6))  # anéis: periódicos em x
    aneis = deformar(base * 0.5 + 0.5, a, b, n * 0.03)
    veios = normalizar(borrar(linhas_tileaveis(n, int(n * 1.5), n * 0.25, 1, seed=82, direcao=np.pi / 2,
                                               espalhar=0.08, curva=0.05), 0.5))
    t = np.clip(aneis ** 1.5 * 0.7 + veios * 0.3, 0, 1)
    albedo = tingir(None, (0.55, 0.36, 0.20), (0.82, 0.62, 0.40), 1 - t)
    return dict(albedo=albedo, altura=1 - t, rough=0.55 + 0.2 * t, forca_normal=2.0, tingivel=False)


@material("madreperola")
def madreperola(n):
    """Madrepérola (botão de camisa): faixas iridescentes suaves."""
    a, b = campo(n, beta=2.6, fmin=1, seed=90), campo(n, beta=2.6, fmin=1, seed=91)
    faixas = deformar(campo(n, beta=2.2, fmin=2, seed=92), a, b, n * 0.2)
    t = faixas * 6 % 1.0
    cores = np.stack([0.80 + 0.20 * np.sin(2 * np.pi * t), 0.80 + 0.18 * np.sin(2 * np.pi * (t + 0.33)),
                      0.86 + 0.14 * np.sin(2 * np.pi * (t + 0.66))], -1)
    return dict(albedo=cores, altura=faixas * 0.2, rough=0.12 + 0.1 * faixas, forca_normal=0.8, tingivel=False,
                ceramica=True)


# ---------------------------------------------------------------- SAÍDA

VARIANTES = {
    # nome: [(sufixo, cor)]
    "feltro": [("verde", (0.45, 0.72, 0.42)), ("rosa", (0.95, 0.62, 0.70)), ("azul", (0.42, 0.58, 0.92)),
               ("creme", (0.97, 0.92, 0.80)), ("vermelho", (0.85, 0.22, 0.28)), ("roxo", (0.48, 0.36, 0.72))],
    "la_trico": [("creme", (0.95, 0.90, 0.80)), ("laranja", (0.95, 0.52, 0.25)), ("azul", (0.35, 0.48, 0.80))],
    "cotele": [("marrom", (0.42, 0.26, 0.16)), ("oliva", (0.36, 0.34, 0.24)), ("vinho", (0.50, 0.16, 0.22))],
    "ceramica": [("branca", (0.97, 0.96, 0.93)), ("azul", (0.50, 0.66, 0.88)), ("rosa", (0.96, 0.74, 0.80))],
    "vidro": [("claro", (0.95, 0.98, 1.0)), ("ambar", (1.0, 0.75, 0.40))],
    "botao_plastico": [("amarelo", (1.0, 0.82, 0.30)), ("vermelho", (0.90, 0.25, 0.25)), ("azul", (0.30, 0.55, 0.95))],
}

ESCALA_UV = {"feltro": 2, "la_trico": 1.5, "cotele": 3, "jeans": 3, "chita": 1, "ceramica": 1, "vidro": 1,
             "botao_plastico": 1, "madeira": 1, "madreperola": 1}


def salvar_png(caminho, arr):
    arr = np.clip(arr, 0, 1)
    modo = "RGB" if arr.ndim == 3 else "L"
    Image.fromarray((arr * 255 + 0.5).astype(np.uint8), modo).save(caminho, optimize=True)


def gerar(nome, n):
    m = MATERIAIS[nome](n)
    pasta = os.path.join(RAIZ, "assets", "materiais", nome)
    os.makedirs(pasta, exist_ok=True)
    h = m["altura"]
    if h.min() < 0 or h.max() > 1:  # relevo pequeno (plástico, vidro) NÃO é esticado
        h = normalizar(h)
    rough = np.broadcast_to(np.asarray(m["rough"], np.float32), (n, n))
    salvar_png(os.path.join(pasta, "albedo.png"), m["albedo"])
    salvar_png(os.path.join(pasta, "normal.png"), normal_de_altura(h, m.get("forca_normal", 3.0) * n / 256))
    salvar_png(os.path.join(pasta, "roughness.png"), rough)
    salvar_png(os.path.join(pasta, "ao.png"), ao_de_altura(h, raio=n / 128))
    salvar_png(os.path.join(pasta, "height.png"), h)
    escrever_tres(nome, m)
    return m


def escrever_tres(nome, m):
    pasta = os.path.join(RAIZ, "materials", "pbr")
    os.makedirs(pasta, exist_ok=True)
    tex = f"res://assets/materiais/{nome}"
    variantes = VARIANTES.get(nome, [("", (1.0, 1.0, 1.0))])
    for sufixo, cor in variantes:
        arquivo = f"{nome}_{sufixo}.tres" if sufixo else f"{nome}.tres"
        s = ESCALA_UV.get(nome, 1)
        linhas = [
            '[gd_resource type="StandardMaterial3D" load_steps=5 format=3]', "",
            f'[ext_resource type="Texture2D" path="{tex}/albedo.png" id="1_albedo"]',
            f'[ext_resource type="Texture2D" path="{tex}/normal.png" id="2_normal"]',
            f'[ext_resource type="Texture2D" path="{tex}/roughness.png" id="3_rough"]',
            f'[ext_resource type="Texture2D" path="{tex}/ao.png" id="4_ao"]', "",
            "[resource]",
            f'resource_name = "{arquivo[:-5]}"',
            "texture_filter = 5",
            f"albedo_color = Color({cor[0]}, {cor[1]}, {cor[2]}, 1)",
            'albedo_texture = ExtResource("1_albedo")',
            'roughness_texture = ExtResource("3_rough")',
            "normal_enabled = true",
            'normal_texture = ExtResource("2_normal")',
            "ao_enabled = true",
            'ao_texture = ExtResource("4_ao")',
            "uv1_triplanar = true",
            f"uv1_scale = Vector3({s}, {s}, {s})",
        ]
        if m.get("vidro"):
            linhas[linhas.index(f"albedo_color = Color({cor[0]}, {cor[1]}, {cor[2]}, 1)")] = \
                f"albedo_color = Color({cor[0]}, {cor[1]}, {cor[2]}, 0.18)"
            linhas += ["transparency = 1", "metallic_specular = 0.9", "refraction_enabled = true",
                       "refraction_scale = 0.07", 'refraction_texture = ExtResource("3_rough")',
                       "rim_enabled = true", "rim = 0.4", "rim_tint = 1.0"]
        elif m.get("ceramica"):
            linhas += ["metallic_specular = 0.6", "clearcoat_enabled = true", "clearcoat = 0.8",
                       "clearcoat_roughness = 0.08"]
        else:  # tecidos: sem especular forte, "penugem" na borda contra a luz
            linhas += ["metallic_specular = 0.25", "rim_enabled = true",
                       f"rim = {0.9 if m.get('veludo') else 0.55}", "rim_tint = 0.6",
                       "backlight_enabled = true", "backlight = Color(0.12, 0.1, 0.1, 1)"]
        with open(os.path.join(pasta, arquivo), "w", encoding="utf-8") as f:
            f.write("\n".join(linhas) + "\n")


def folha_contato(nomes, n_prev=192):
    """Prévia rápida: albedo + normal de cada material lado a lado (para conferência)."""
    tiles = []
    for nome in nomes:
        p = os.path.join(RAIZ, "assets", "materiais", nome)
        a = Image.open(os.path.join(p, "albedo.png")).resize((n_prev, n_prev))
        nrm = Image.open(os.path.join(p, "normal.png")).resize((n_prev, n_prev))
        tiles.append((nome, a, nrm))
    folha = Image.new("RGB", (n_prev * 2 * 5, n_prev * ((len(tiles) + 4) // 5)), "white")
    d = ImageDraw.Draw(folha)
    for k, (nome, a, nrm) in enumerate(tiles):
        x, y = (k % 5) * n_prev * 2, (k // 5) * n_prev
        folha.paste(a, (x, y))
        folha.paste(nrm, (x + n_prev, y))
        d.text((x + 4, y + 4), nome, fill=(255, 255, 0))
    return folha


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("nomes", nargs="*", help="materiais (vazio = todos): " + ", ".join(MATERIAIS))
    ap.add_argument("-r", "--resolucao", type=int, default=1024)
    ap.add_argument("--previa", help="salva folha de contato neste caminho")
    args = ap.parse_args()
    nomes = args.nomes or list(MATERIAIS)
    for nome in nomes:
        gerar(nome, args.resolucao)
        print("ok", nome)
    if args.previa:
        folha_contato(nomes).save(args.previa)
