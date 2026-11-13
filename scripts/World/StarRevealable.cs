using Godot;

namespace Sonhos.World;

/// <summary>
/// Algo que só existe sob a luz quente da Estrelinha (fio-ponte, plataforma de tule, botão secreto).
/// Fica um pouquinho visível depois que a luz sai (<see cref="LingerTime"/>) para não ser frustrante.
/// Colisões filhas (CollisionShape3D) são ligadas/desligadas junto.
/// </summary>
public partial class StarRevealable : Node3D
{
    [Export] public float LingerTime { get; set; } = 1.5f;
    [Export] public bool StayRevealed { get; set; }

    private float _linger;
    private bool _shown = true;

    public override void _Ready()
    {
        AddToGroup("revelavel_estrela");
        Apply(false);
    }

    public void SetLit(bool lit)
    {
        if (lit) _linger = LingerTime;
    }

    public override void _PhysicsProcess(double delta)
    {
        if (_shown && StayRevealed) return;
        _linger -= (float)delta;
        Apply(_linger > 0f);
    }

    private void Apply(bool show)
    {
        if (show == _shown) return;
        _shown = show;
        Visible = show;
        foreach (Node child in FindChildren("*", nameof(CollisionShape3D), true, false))
            ((CollisionShape3D)child).SetDeferred(CollisionShape3D.PropertyName.Disabled, !show);
    }
}
