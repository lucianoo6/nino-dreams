using Godot;
using Sonhos.Player;

namespace Sonhos.World;

/// <summary>
/// Algo no cenário que chama a atenção da irmãzinha: borboleta de feltro, botão brilhante, flor que canta…
/// Ela vai até lá e brinca por um tempo. Se <see cref="RevealsSecret"/>, a brincadeira revela um segredo
/// (ex.: um botão-estrela escondido aparece) — a distração vira ajuda.
/// </summary>
public partial class Distraction : Node3D
{
    [Signal] public delegate void SisterStartedPlayingEventHandler();
    [Signal] public delegate void SisterStoppedPlayingEventHandler();

    [Export] public string Descricao { get; set; } = "borboleta de feltro";
    [Export] public Vector2 PlayDuration { get; set; } = new(3f, 6f);
    [Export] public bool OnlyOnce { get; set; }
    [Export] public bool RevealsSecret { get; set; }
    [Export] public NodePath SecretPath { get; set; } = new();

    public bool IsAvailable => _claimedBy == null && !(OnlyOnce && _used);

    private SisterController? _claimedBy;
    private bool _used;

    public override void _Ready() => AddToGroup("distracao");

    /// <summary>Retorna quanto tempo ela vai brincar aqui.</summary>
    public float Claim(SisterController sister)
    {
        _claimedBy = sister;
        _used = true;
        EmitSignal(SignalName.SisterStartedPlaying);
        if (RevealsSecret && !SecretPath.IsEmpty && GetNodeOrNull<Node3D>(SecretPath) is { } secret)
            secret.Visible = true;
        return (float)GD.RandRange(PlayDuration.X, PlayDuration.Y);
    }

    public void Release()
    {
        _claimedBy = null;
        EmitSignal(SignalName.SisterStoppedPlaying);
    }
}
