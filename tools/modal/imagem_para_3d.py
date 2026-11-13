"""Imagem -> modelo 3D (.glb) com TRELLIS (Microsoft, licença MIT) rodando numa GPU da Modal.

Uso (na raiz do repositório, com `pip install modal` e `modal token set ...` feitos):

    modal run tools/modal/imagem_para_3d.py --imagem referencias/xicara.png
    modal run tools/modal/imagem_para_3d.py --imagem referencias/cogumelo.png --nome cogumelo --seed 7

Saída: assets/models/gerados/<nome>.glb  (abra no Blender para limpar/arredondar, depois importe no Godot).
Dica: imagem quadrada, objeto inteiro centralizado, fundo liso (o fundo é removido automaticamente).
"""

from __future__ import annotations

import pathlib

import modal

APP_NOME = "nino-dreams-imagem-para-3d"
MODELO = "microsoft/TRELLIS-image-large"
ARQUITETURAS_CUDA = "8.0;8.6;8.9;9.0"  # A100, A10G, L4/L40S, H100

imagem_trellis = (
    modal.Image.from_registry("nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04", add_python="3.10")
    .apt_install("git", "build-essential", "ninja-build", "libgl1", "libglib2.0-0", "libgomp1")
    .env(
        {
            "TORCH_CUDA_ARCH_LIST": ARQUITETURAS_CUDA,
            "SPCONV_ALGO": "native",
            "ATTN_BACKEND": "xformers",
            "HF_HOME": "/cache/huggingface",
        }
    )
    .pip_install(
        "torch==2.4.0",
        "torchvision==0.19.0",
        "xformers==0.0.27.post2",
        index_url="https://download.pytorch.org/whl/cu121",
    )
    .pip_install(
        "pillow",
        "imageio",
        "imageio-ffmpeg",
        "tqdm",
        "easydict",
        "opencv-python-headless",
        "scipy",
        "ninja",
        "rembg",
        "onnxruntime",
        "trimesh",
        "open3d",
        "xatlas",
        "pyvista",
        "pymeshfix",
        "igraph",
        "transformers",
        "huggingface_hub",
        "spconv-cu120",
        "git+https://github.com/EasternJournalist/utils3d.git@9a4eb15e4021b67b12c460c7057d642626897ec8",
    )
    .pip_install(
        "kaolin==0.17.0",
        find_links="https://nvidia-kaolin.s3.us-east-2.amazonaws.com/torch-2.4.0_cu121.html",
    )
    .run_commands(
        "git clone --recurse-submodules https://github.com/microsoft/TRELLIS.git /trellis",
        "git clone https://github.com/NVlabs/nvdiffrast.git /tmp/nvdiffrast && pip install /tmp/nvdiffrast",
        "git clone https://github.com/autonomousvision/mip-splatting.git /tmp/mip-splatting"
        " && pip install /tmp/mip-splatting/submodules/diff-gaussian-rasterization/",
    )
)

app = modal.App(APP_NOME, image=imagem_trellis)
cache = modal.Volume.from_name("nino-dreams-cache-modelos", create_if_missing=True)


@app.cls(gpu="A10G", volumes={"/cache": cache}, timeout=20 * 60, scaledown_window=120)
class Trellis:
    @modal.enter()
    def carregar(self) -> None:
        import sys

        sys.path.insert(0, "/trellis")
        from trellis.pipelines import TrellisImageTo3DPipeline

        self.pipeline = TrellisImageTo3DPipeline.from_pretrained(MODELO)
        self.pipeline.cuda()
        cache.commit()

    @modal.method()
    def gerar(self, imagem_bytes: bytes, seed: int = 1, tamanho_textura: int = 1024, simplificar: float = 0.95) -> bytes:
        import io
        import sys

        sys.path.insert(0, "/trellis")
        from PIL import Image
        from trellis.utils import postprocessing_utils

        imagem = Image.open(io.BytesIO(imagem_bytes))
        saidas = self.pipeline.run(imagem, seed=seed)
        glb = postprocessing_utils.to_glb(
            saidas["gaussian"][0],
            saidas["mesh"][0],
            simplify=simplificar,
            texture_size=tamanho_textura,
        )
        buffer = io.BytesIO()
        glb.export(buffer, file_type="glb")
        return buffer.getvalue()


@app.local_entrypoint()
def main(imagem: str, nome: str = "", seed: int = 1, textura: int = 1024) -> None:
    origem = pathlib.Path(imagem)
    nome = nome or origem.stem
    destino = pathlib.Path("assets/models/gerados") / f"{nome}.glb"
    destino.parent.mkdir(parents=True, exist_ok=True)

    print(f"🧵 Gerando 3D de {origem} (seed {seed})… a primeira vez demora (monta a imagem e baixa o modelo).")
    dados = Trellis().gerar.remote(origem.read_bytes(), seed=seed, tamanho_textura=textura)
    destino.write_bytes(dados)
    print(f"✅ Salvo em {destino} ({len(dados) / 1024:.0f} KB)")
