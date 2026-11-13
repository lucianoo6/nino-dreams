namespace Sonhos.Core;

/// <summary>Tipo de noite: sonho bom (exploração/missão) ou pesadelo (enfrentar o vilão com a luz da lua).</summary>
public enum DreamKind
{
    Sonho,
    Pesadelo,
}

/// <summary>Tipo de missão de um sonho.</summary>
public enum MissionKind
{
    /// <summary>Encontrar N objetos (ex.: botões-estrela, pétalas, chaves).</summary>
    Encontrar,
    /// <summary>Chegar à saída do sonho (ex.: porta, toca do coelho, janela).</summary>
    Sair,
    /// <summary>Pesadelo: dissipar o vilão com a luz da lua.</summary>
    EnfrentarVilao,
}
