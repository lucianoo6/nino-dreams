using Godot;

namespace Sonhos.Core;

/// <summary>
/// Um livro da estante do quarto. Cada livro é uma "galáxia" de sonhos.
/// Só usar obras em DOMÍNIO PÚBLICO — ver docs/LIVROS.md.
/// </summary>
[GlobalClass]
public partial class BookData : Resource
{
    [Export] public string Id { get; set; } = "";
    [Export] public string Titulo { get; set; } = "";
    [Export] public string Autor { get; set; } = "";
    [Export] public int AnoPublicacao { get; set; }
    /// <summary>Ano de morte do autor (para conferir domínio público: vida + 70 anos na maioria dos países).</summary>
    [Export] public int AnoMorteAutor { get; set; }

    [Export(PropertyHint.MultilineText)] public string Sinopse { get; set; } = "";

    [Export] public DreamKind Tipo { get; set; } = DreamKind.Sonho;
    [Export] public MissionKind Missao { get; set; } = MissionKind.Encontrar;
    /// <summary>Quantos itens a encontrar (quando Missao == Encontrar).</summary>
    [Export] public int ItensNecessarios { get; set; } = 3;

    [Export(PropertyHint.File, "*.tscn")] public string CenaDoSonho { get; set; } = "";
    [Export] public Color CorDaCapa { get; set; } = new(0.8f, 0.4f, 0.4f);
}
