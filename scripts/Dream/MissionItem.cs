using Godot;
using Sonhos.Core;

namespace Sonhos.Dream;

/// <summary>
/// Item de missão (ex.: botão-estrela). Ao tocar no sonhador, conta para a missão "Encontrar".
/// Se <see cref="IsExit"/> for true, funciona como saída do sonho (missão "Sair").
/// </summary>
public partial class MissionItem : Area3D
{
    [Export] public bool IsExit { get; set; }
    [Export] public float BobHeight { get; set; } = 0.25f;
    [Export] public float SpinSpeed { get; set; } = 1.5f;

    private Node3D? _visual;
    private Vector3 _baseLocal;
    private float _time;

    public override void _Ready()
    {
        _visual = GetNodeOrNull<Node3D>("Visual");
        if (_visual != null) _baseLocal = _visual.Position;
        BodyEntered += OnBodyEntered;
    }

    public override void _Process(double delta)
    {
        if (_visual == null) return;
        _time += (float)delta;
        _visual.Position = _baseLocal + Vector3.Up * Mathf.Sin(_time * 2.5f) * BobHeight;
        _visual.RotateObjectLocal(Vector3.Up, SpinSpeed * (float)delta);
    }

    private void OnBodyEntered(Node3D body)
    {
        if (!body.IsInGroup("sonhador") && !body.IsInGroup("irmazinha")) return;
        if (IsExit) GameState.Instance.CompletarMissao();
        else GameState.Instance.ColetarItem();
        // TODO: partículas de fiapos/purpurina + som de "plim" de botão.
        QueueFree();
    }
}
