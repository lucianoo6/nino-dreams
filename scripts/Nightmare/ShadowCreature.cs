using Godot;
using Sonhos.Core;

namespace Sonhos.Nightmare;

/// <summary>
/// Criatura/vilão de pesadelo feita de lã escura e fios soltos.
/// Persegue o sonhador; sob a luz da lua desacelera, encolhe e por fim se desfaz em estrelinhas.
/// </summary>
public partial class ShadowCreature : CharacterBody3D
{
    [Signal] public delegate void DissipatedEventHandler();

    [Export] public float Darkness { get; set; } = 3f;
    [Export] public float ChaseSpeed { get; set; } = 3.5f;
    [Export] public float LitSlowdown { get; set; } = 0.2f;
    [Export] public bool IsBoss { get; set; }

    /// <summary>Atualizado pela Estrelinha a cada frame físico.</summary>
    public bool IsInStarAura { get; set; }
    /// <summary>Ponto de onde a criatura deve fugir (centro da aura da Estrelinha).</summary>
    public Vector3? RepelFrom { get; set; }

    private float _maxDarkness;
    private float _litTimer;
    private Node3D? _target;

    public override void _Ready()
    {
        AddToGroup("sombra");
        _maxDarkness = Darkness;
    }

    public void ReceiveLight(float amount)
    {
        Darkness -= amount;
        _litTimer = 0.15f;
        Scale = Vector3.One * Mathf.Lerp(0.4f, 1f, Mathf.Clamp(Darkness / _maxDarkness, 0f, 1f));
        if (Darkness <= 0f) Dissipate();
    }

    public override void _PhysicsProcess(double delta)
    {
        float d = (float)delta;
        _litTimer -= d;
        _target ??= GetTree().GetFirstNodeInGroup("sonhador") as Node3D;

        Vector3 gravity = GetGravity();
        if (gravity.LengthSquared() > 0.001f) UpDirection = -gravity.Normalized();
        Vector3 up = UpDirection;

        Vector3 lateral = Vector3.Zero;
        if (_target != null)
        {
            Vector3 to = _target.GlobalPosition - GlobalPosition;
            to -= up * to.Dot(up);
            if (to.LengthSquared() > 0.01f)
                lateral = to.Normalized() * ChaseSpeed * (_litTimer > 0f ? LitSlowdown : 1f);
        }
        // A luz quente da Estrelinha é uma zona segura: sombras não entram, são empurradas para fora.
        if (RepelFrom is Vector3 c)
        {
            Vector3 away = GlobalPosition - c;
            away -= up * away.Dot(up);
            if (away.LengthSquared() > 0.001f) lateral = away.Normalized() * ChaseSpeed * 1.2f;
        }
        IsInStarAura = false;
        RepelFrom = null;

        float vertical = Velocity.Dot(up) - gravity.Length() * d;
        Velocity = lateral + up * vertical;
        MoveAndSlide();
    }

    private void Dissipate()
    {
        EmitSignal(SignalName.Dissipated);
        // TODO: explosão de estrelinhas de feltro + o mundo recupera a cor.
        if (IsBoss) GameState.Instance.CompletarMissao();
        QueueFree();
    }
}
