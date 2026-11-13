"""Ferramentas de ruído 100% tileáveis (as bordas casam) para texturas procedurais.

Tudo opera em arrays numpy NxN com "wrap" (o pixel 0 é vizinho do N-1), então qualquer
textura gerada aqui repete sem emenda.
"""
import numpy as np
from scipy.spatial import cKDTree


def rng(seed):
    return np.random.default_rng(seed)


def campo(n, beta=2.0, fmin=1.0, fmax=None, seed=0):
    """Ruído gaussiano filtrado no espectro (1/f^beta) — tileável por construção.
    beta alto = mais suave; fmin/fmax limitam a faixa de frequências (em ciclos por tile)."""
    r = rng(seed)
    w = r.standard_normal((n, n))
    fx = np.fft.fftfreq(n) * n
    f = np.sqrt(fx[None, :] ** 2 + fx[:, None] ** 2)
    filtro = np.where(f >= fmin, 1.0 / np.maximum(f, 1e-6) ** (beta / 2.0), 0.0)
    if fmax:
        filtro *= np.exp(-((f / fmax) ** 4))
    out = np.real(np.fft.ifft2(np.fft.fft2(w) * filtro))
    return normalizar(out)


def normalizar(a):
    a = a - a.min()
    m = a.max()
    return a / m if m > 0 else a


def borrar(a, sigma):
    """Desfoque gaussiano com wrap (via FFT)."""
    n = a.shape[0]
    fx = np.fft.fftfreq(n)
    g = np.exp(-2 * (np.pi * sigma) ** 2 * (fx[None, :] ** 2 + fx[:, None] ** 2))
    return np.real(np.fft.ifft2(np.fft.fft2(a) * g))


def voronoi(n, pontos, seed=0, jitter=1.0):
    """Distâncias F1 e F2 ao ponto mais próximo (células periódicas). Retorna (f1, f2, id) em unidades de tile."""
    r = rng(seed)
    p = r.random((pontos, 2))
    arvore = cKDTree(p, boxsize=1.0)
    y, x = np.mgrid[0:n, 0:n] / n
    d, i = arvore.query(np.stack([y.ravel(), x.ravel()], 1), k=2)
    return d[:, 0].reshape(n, n), d[:, 1].reshape(n, n), i[:, 0].reshape(n, n)


def deformar(a, dx, dy, forca):
    """Domain warp: amostra `a` deslocado por (dx, dy)*forca pixels, com wrap."""
    n = a.shape[0]
    y, x = np.mgrid[0:n, 0:n].astype(np.float32)
    xs = (x + (dx - 0.5) * 2 * forca) % n
    ys = (y + (dy - 0.5) * 2 * forca) % n
    x0, y0 = np.floor(xs).astype(int), np.floor(ys).astype(int)
    fx, fy = xs - x0, ys - y0
    x1, y1 = (x0 + 1) % n, (y0 + 1) % n
    return (a[y0, x0] * (1 - fx) * (1 - fy) + a[y0, x1] * fx * (1 - fy)
            + a[y1, x0] * (1 - fx) * fy + a[y1, x1] * fx * fy)


def normal_de_altura(h, forca=4.0):
    """Mapa normal (convenção OpenGL / Godot: Y+) a partir da altura, com wrap."""
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5
    nx, ny, nz = -dx * forca, dy * forca, np.ones_like(h)
    comp = np.sqrt(nx ** 2 + ny ** 2 + nz ** 2)
    return np.stack([nx / comp, ny / comp, nz / comp], -1) * 0.5 + 0.5


def ao_de_altura(h, raio=8, forca=1.5):
    """Oclusão aproximada: quanto o pixel está abaixo da média da vizinhança."""
    media = borrar(h, raio)
    return np.clip(1.0 - np.maximum(media - h, 0) * forca * 4, 0, 1)


def linhas_tileaveis(n, quantidade, comprimento, largura, seed=0, curva=0.3, direcao=None, espalhar=np.pi):
    """Desenha fibras (segmentos curvos) que atravessam as bordas corretamente. Retorna altura 0..1."""
    from PIL import Image, ImageDraw
    r = rng(seed)
    img = Image.new("F", (n, n), 0.0)
    d = ImageDraw.Draw(img)
    for _ in range(quantidade):
        x, y = r.random() * n, r.random() * n
        ang = (direcao if direcao is not None else r.random() * np.pi) + (r.random() - 0.5) * espalhar
        L = comprimento * (0.5 + r.random())
        pts = []
        for k in range(6):
            t = k / 5
            a = ang + curva * np.sin(t * np.pi * (1 + r.random()))
            pts.append((x + np.cos(a) * L * t, y + np.sin(a) * L * t))
        brilho = 0.4 + 0.6 * r.random()
        for ox in (-n, 0, n):
            for oy in (-n, 0, n):
                d.line([(px + ox, py + oy) for px, py in pts], fill=brilho, width=largura)
    return np.array(img, dtype=np.float32)
