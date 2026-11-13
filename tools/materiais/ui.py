"""Texturas da interface (moldura de papelão kraft, remendo de jeans costurado, etiqueta de papel).
Feitas com o mesmo ruído tileável dos materiais. Saída em assets/ui/.

    python tools/materiais/ui.py
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(__file__))
from ruido import borrar, campo, linhas_tileaveis, normalizar  # noqa: E402

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SAIDA = os.path.join(RAIZ, "assets", "ui")


def kraft(w, h, seed=0):
    n = max(w, h)
    fibras = normalizar(borrar(linhas_tileaveis(512, 9000, 14, 1, seed=seed, curva=0.5), 0.6))
    nuvem = campo(512, beta=2.4, fmin=1, seed=seed + 1)
    t = np.clip(nuvem * 0.6 + fibras * 0.4, 0, 1)
    base = np.array([0.74, 0.60, 0.44]) * (0.86 + 0.18 * t[..., None])
    pintas = (campo(512, beta=1.0, fmin=40, seed=seed + 2) > 0.82)[..., None]
    base = base * (1 - 0.18 * pintas)
    img = Image.fromarray((np.clip(base, 0, 1) * 255).astype(np.uint8)).resize((n, n), Image.BICUBIC)
    return img.crop((0, 0, w, h)).convert("RGBA")


def borda_irregular(w, h, x0, y0, x1, y1, raio, amp, seed):
    """Máscara (L) de retângulo arredondado com borda levemente rasgada."""
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).rounded_rectangle([x0, y0, x1, y1], raio, fill=255)
    ruido = Image.fromarray((campo(256, beta=1.5, fmin=8, seed=seed) * 255).astype(np.uint8)).resize((w, h))
    m = Image.fromarray(np.clip(np.asarray(m, np.float32) + (np.asarray(ruido, np.float32) - 128) * amp, 0, 255)
                        .astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8))
    return Image.fromarray(np.where(np.asarray(m) > 127, 255, 0).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.7))


def moldura(w=1920, h=1080):
    img = kraft(w, h, seed=7)
    margem = 44
    # passe-partout creme (como foto colada no papelão)
    passe = borda_irregular(w, h, margem - 10, margem - 10, w - margem + 10, h - margem + 10, 18, 0.25, 8)
    creme = Image.new("RGBA", (w, h), (238, 228, 210, 255))
    img = Image.composite(creme, img, passe)
    # sombra interna sobre o papel
    janela = Image.new("L", (w, h), 0)
    ImageDraw.Draw(janela).rounded_rectangle([margem, margem, w - margem, h - margem], 14, fill=255)
    sombra = janela.filter(ImageFilter.GaussianBlur(10))
    arr = np.asarray(img, np.float32)
    s = 1 - 0.35 * (np.asarray(sombra, np.float32) / 255) * (1 - np.asarray(janela, np.float32) / 255)
    arr[..., :3] *= s[..., None]
    arr[..., 3] = 255 - np.asarray(janela, np.float32)
    return Image.fromarray(arr.astype(np.uint8))


def costura(d, x0, y0, x1, y1, raio, cor, traco=14, vazio=9, largura=3):
    """Pesponto tracejado ao redor de um retângulo arredondado."""
    pts = []
    perim = []
    for t in np.linspace(0, 1, 2000):
        # percorre o retângulo (sem os cantos arredondados: suficiente para tracejado)
        L = 2 * (x1 - x0) + 2 * (y1 - y0)
        p = t * L
        if p < x1 - x0:
            pts.append((x0 + p, y0))
        elif p < (x1 - x0) + (y1 - y0):
            pts.append((x1, y0 + p - (x1 - x0)))
        elif p < 2 * (x1 - x0) + (y1 - y0):
            pts.append((x1 - (p - (x1 - x0) - (y1 - y0)), y1))
        else:
            pts.append((x0, y1 - (p - 2 * (x1 - x0) - (y1 - y0))))
    passo = traco + vazio
    acum = 0.0
    for a, b in zip(pts, pts[1:]):
        seg = np.hypot(b[0] - a[0], b[1] - a[1])
        if acum % passo < traco:
            d.line([a, b], fill=cor, width=largura)
        acum += seg


def remendo_jeans(w=640, h=170):
    tile = Image.open(os.path.join(RAIZ, "assets", "materiais", "jeans", "albedo.png")).convert("RGB").resize((220, 220))
    jeans = Image.new("RGB", (w, h))
    for x in range(0, w, 220):
        for y in range(0, h, 220):
            jeans.paste(tile, (x, y))
    arr = np.asarray(jeans, np.float32) * np.array([0.62, 0.66, 0.78])  # índigo mais escuro e uniforme
    jeans = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8)).convert("RGBA")
    mascara = borda_irregular(w, h, 6, 6, w - 6, h - 6, 22, 0.35, 21)
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.paste(jeans, (0, 0), mascara)
    d = ImageDraw.Draw(out)
    costura(d, 20, 20, w - 20, h - 20, 16, (236, 220, 180, 255))
    return out


def etiqueta_papel(w=560, h=96):
    papel = Image.open(os.path.join(RAIZ, "assets", "materiais", "papel", "albedo.png")).convert("RGBA").crop((0, 0, w, h))
    mascara = borda_irregular(w, h, 4, 4, w - 4, h - 4, 10, 0.2, 31)
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.paste(papel, (0, 0), mascara)
    return out


if __name__ == "__main__":
    os.makedirs(SAIDA, exist_ok=True)
    moldura().save(os.path.join(SAIDA, "moldura_kraft.png"), optimize=True)
    remendo_jeans().save(os.path.join(SAIDA, "remendo_jeans.png"), optimize=True)
    etiqueta_papel().save(os.path.join(SAIDA, "etiqueta_papel.png"), optimize=True)
    print("ok")
