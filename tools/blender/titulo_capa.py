"""Põe o título na arte renderizada e gera os recortes da Steam (cápsula principal e cabeçalho).
Uso: python titulo_capa.py RENDER.png PASTA_SAIDA
"""
import io
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont
from fontTools.ttLib import TTFont

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def fonte(nome, tamanho):
    # Fredoka vem em .woff2; o Pillow precisa de .ttf/.otf, então converte em memória.
    f = TTFont(os.path.join(RAIZ, "assets", "fonts", nome))
    f.flavor = None
    buf = io.BytesIO()
    f.save(buf)
    buf.seek(0)
    return ImageFont.truetype(buf, tamanho)


def texto(img, xy, s, tam, ancora="la"):
    d = ImageDraw.Draw(img)
    f = fonte("Fredoka-Bold.woff2", tam)
    # sombra suave + contorno roxo + creme (igual aos títulos do jogo)
    sombra = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(sombra).text((xy[0] + tam * 0.04, xy[1] + tam * 0.06), s, font=f, anchor=ancora,
                                fill=(20, 8, 40, 160), stroke_width=int(tam * 0.12), stroke_fill=(20, 8, 40, 160))
    img.alpha_composite(sombra.filter(ImageFilter.GaussianBlur(tam * 0.05)))
    d.text(xy, s, font=f, anchor=ancora, fill=(255, 243, 214), stroke_width=int(tam * 0.09), stroke_fill=(88, 52, 120))


def main():
    render, pasta = sys.argv[1], sys.argv[2]
    os.makedirs(pasta, exist_ok=True)
    arte = Image.open(render).convert("RGBA")
    w, h = arte.size
    capa = arte.copy()
    texto(capa, (w * 0.05, h * 0.07), "Once Upon a Pillow", int(h * 0.105))
    texto(capa, (w * 0.05, h * 0.2), "Nino & Mel", int(h * 0.085))
    capa.convert("RGB").save(os.path.join(pasta, "arte_capa.png"))
    arte.convert("RGB").save(os.path.join(pasta, "arte_capa_sem_titulo.png"))
    # Steam: cápsula principal 616x353 e cabeçalho 460x215 (mesma arte, título proporcional)
    for nome, (cw, ch) in {"steam_capsula_principal": (616, 353), "steam_cabecalho": (460, 215)}.items():
        escala = max(cw / w, ch / h)
        r = arte.resize((int(w * escala), int(h * escala)), Image.LANCZOS)
        x = (r.width - cw) // 2
        r = r.crop((x, 0, x + cw, ch))
        texto(r, (cw * 0.05, ch * 0.06), "Once Upon a Pillow", int(ch * 0.12))
        texto(r, (cw * 0.05, ch * 0.2), "Nino & Mel", int(ch * 0.095))
        r.convert("RGB").save(os.path.join(pasta, nome + ".png"))
    print("ok", pasta)


main()
