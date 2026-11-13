using Godot;

namespace Sonhos.Nightmare;

/// <summary>
/// ESTRELINHA — a luz da irmãzinha: uma estrela de luz QUENTE, redonda (aura), complementar à Luna (fria, em cone).
/// • Pesadelo: a aura é uma zona segura — sombras não entram; Luna recarrega mais rápido perto dela;
///   Luna + Estrelinha juntas na mesma sombra = "luz de amanhecer" (dano multiplicado).
/// • Sonho: revela coisas escondidas (nós no grupo "revelavel_estrela"), como fios-ponte e botões secretos.
/// Segurar a ação (p2_lamp) faz um "abraço de luz": aura maior por um tempo, depois descansa.
/// </summary>
public partial class StarLight : OmniLight3D
{
    public const float CrossLightBonus = 2.5f;

    [Export] public float BaseRadius { get; set; } = 3.5f;
    [Export] public float HugRadius { get; set; } = 7f;
    [Export] public float HugDuration { get; set; } = 2.5f;
    [Export] public float HugCooldown { get; set; } = 4f;
    [Export] public float LunaRechargeBoost { get; set; } = 2.5f;
    [Export] public string ActionName { get; set; } = "p2_lamp";
    /// <summary>Quando a IA controla a irmã, ela dá o "abraço de luz" sozinha se houver sombra muito perto.</summary>
    [Export] public bool AutoHugWhenAi { get; set; } = true;

    public float Radius { get; private set; }

    private float _hugTimer;
    private float _cooldown;
    private Player.SisterController? _owner;

    public override void _Ready()
    {
        AddToGroup("estrelinha");
        Radius = BaseRadius;
        _owner = GetParentOrNull<Player.SisterController>();
    }

    public override void _PhysicsProcess(double delta)
    {
        float d = (float)delta;
        _cooldown -= d;
        _hugTimer -= d;

        bool aiControlled = _owner != null && !_owner.PlayerControlled;
        bool wantsHug = aiControlled ? AutoHugWhenAi && ShadowNearby(BaseRadius * 1.3f) : Input.IsActionJustPressed(ActionName);
        if (wantsHug && _cooldown <= 0f)
        {
            _hugTimer = HugDuration;
            _cooldown = HugDuration + HugCooldown;
        }

        float targetRadius = _hugTimer > 0f ? HugRadius : BaseRadius;
        Radius = Mathf.Lerp(Radius, targetRadius, 1f - Mathf.Exp(-6f * d));
        OmniRange = Radius * 1.6f;

        Vector3 c = GlobalPosition;

        foreach (Node n in GetTree().GetNodesInGroup("sombra"))
        {
            if (n is ShadowCreature s && s.GlobalPosition.DistanceTo(c) < Radius)
            {
                s.IsInStarAura = true;
                s.RepelFrom = c;
            }
        }

        foreach (Node n in GetTree().GetNodesInGroup("luna"))
        {
            if (n is MoonLamp luna)
                luna.RechargeMultiplier = luna.GlobalPosition.DistanceTo(c) < Radius * 1.5f ? LunaRechargeBoost : 1f;
        }

        foreach (Node n in GetTree().GetNodesInGroup("revelavel_estrela"))
        {
            if (n is World.StarRevealable r)
                r.SetLit(r.GlobalPosition.DistanceTo(c) < Radius);
        }
    }

    private bool ShadowNearby(float r)
    {
        foreach (Node n in GetTree().GetNodesInGroup("sombra"))
            if (n is Node3D s && s.GlobalPosition.DistanceTo(GlobalPosition) < r) return true;
        return false;
    }
}
