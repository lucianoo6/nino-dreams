using Godot;

namespace Sonhos.Nightmare;

/// <summary>
/// A luz em formato de lua do quarto, levada para dentro do pesadelo.
/// Segurar "lamp" acende o cone; criaturas de sombra dentro do cone perdem escuridão.
/// A bateria ("brilho") gasta enquanto acesa e recarrega apagada.
/// </summary>
public partial class MoonLamp : SpotLight3D
{
    [Signal] public delegate void GlowChangedEventHandler(float glow01);

    [Export] public float MaxGlow { get; set; } = 100f;
    [Export] public float DrainPerSecond { get; set; } = 22f;
    [Export] public float RechargePerSecond { get; set; } = 14f;
    [Export] public float LightPower { get; set; } = 1f;
    [Export] public float OnEnergy { get; set; } = 6f;

    public float Glow { get; private set; }
    public bool IsOn { get; private set; }

    public override void _Ready()
    {
        Glow = MaxGlow;
        LightEnergy = 0f;
    }

    public override void _PhysicsProcess(double delta)
    {
        float d = (float)delta;
        bool wantsOn = Input.IsActionPressed("lamp") && Glow > 0f;
        IsOn = wantsOn;

        Glow = IsOn
            ? Mathf.Max(0f, Glow - DrainPerSecond * d)
            : Mathf.Min(MaxGlow, Glow + RechargePerSecond * d);
        EmitSignal(SignalName.GlowChanged, Glow / MaxGlow);

        LightEnergy = Mathf.Lerp(LightEnergy, IsOn ? OnEnergy : 0f, 1f - Mathf.Exp(-14f * d));

        if (!IsOn) return;

        float cosHalf = Mathf.Cos(Mathf.DegToRad(SpotAngle));
        Vector3 origin = GlobalPosition;
        Vector3 forward = -GlobalBasis.Z.Normalized();
        var space = GetWorld3D().DirectSpaceState;

        foreach (Node n in GetTree().GetNodesInGroup("sombra"))
        {
            if (n is not ShadowCreature creature) continue;
            Vector3 to = creature.GlobalPosition - origin;
            float dist = to.Length();
            if (dist > SpotRange || dist < 0.01f) continue;
            if (forward.Dot(to / dist) < cosHalf) continue;

            // Linha de visão: só o mundo (layer 1) bloqueia a luz.
            var query = PhysicsRayQueryParameters3D.Create(origin, creature.GlobalPosition, 1u);
            if (space.IntersectRay(query).Count > 0) continue;

            float falloff = 1f - dist / SpotRange;
            creature.ReceiveLight(LightPower * (0.5f + falloff) * d);
        }
    }
}
