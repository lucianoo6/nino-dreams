using Godot;
using Sonhos.Core;
using Sonhos.World;

namespace Sonhos.Player;

/// <summary>
/// A irmãzinha do Nino. Sozinha (IA) ela segue o irmão, mas é TODA distraída: para para brincar com o cenário
/// (borboletas de feltro, botões soltos, poças de lantejoula…) e fica para trás. Às vezes a distração dela
/// revela segredos. Nunca morre e nunca trava o progresso: se ficar longe demais, aparece de novo perto do Nino.
/// No coop (drop-in), o jogador 2 assume o controle a qualquer momento.
/// </summary>
public partial class SisterController : DreamerController
{
    public enum Mood { Seguindo, Distraida, Voltando, Coop }

    [Signal] public delegate void MoodChangedEventHandler(int mood);

    [ExportGroup("IA")]
    [Export] public float FollowDistance { get; set; } = 2.2f;
    [Export] public float CatchUpDistance { get; set; } = 7f;
    [Export] public float TeleportDistance { get; set; } = 28f;
    [Export] public float DistractionSearchRadius { get; set; } = 9f;
    [Export] public Vector2 DistractionCooldown { get; set; } = new(6f, 15f);
    /// <summary>Distância do Nino a partir da qual ela "se dá conta" e volta sozinha.</summary>
    [Export] public float SnapOutDistance { get; set; } = 18f;

    public Mood Estado { get; private set; } = Mood.Seguindo;
    public bool PlayerControlled => Estado == Mood.Coop;

    private DreamerController? _nino;
    private Distraction? _distraction;
    private float _distractionTimer;
    private float _cooldown;
    private bool _aiJump;
    private bool _aiJumpHeld;
    private readonly RandomNumberGenerator _rng = new();

    public override void _Ready()
    {
        base._Ready();
        RemoveFromGroup("sonhador"); // itens/sombras miram o Nino; ela tem grupo próprio
        AddToGroup("irmazinha");
        ActionPrefix = "p2_";
        _rng.Randomize();
        _cooldown = _rng.RandfRange(DistractionCooldown.X, DistractionCooldown.Y);
    }

    public override void _PhysicsProcess(double delta)
    {
        _nino ??= GetTree().GetFirstNodeInGroup("sonhador") as DreamerController;
        if (!PlayerControlled && GameState.Instance.PlayerTwoJoined) SetMood(Mood.Coop);
        if (PlayerControlled && !GameState.Instance.PlayerTwoJoined) SetMood(Mood.Seguindo);

        if (!PlayerControlled && _nino != null) ThinkAi((float)delta);
        base._PhysicsProcess(delta);
        _aiJump = false;
    }

    /// <summary>Nino chama a irmã (botão "chamar"): ela larga a brincadeira e corre até ele.</summary>
    public void Call()
    {
        if (PlayerControlled) return;
        _distraction?.Release();
        _distraction = null;
        SetMood(Mood.Voltando);
    }

    private void ThinkAi(float d)
    {
        float dist = GlobalPosition.DistanceTo(_nino!.GlobalPosition);

        if (dist > TeleportDistance)
        {
            // Ela "aparece" perto do irmão (TODO: puf de fiapos + risadinha).
            GlobalPosition = _nino.GlobalPosition + _nino.GlobalBasis.Z * 1.5f + _nino.UpDirection * 0.5f;
            Velocity = Vector3.Zero;
            _distraction?.Release();
            _distraction = null;
            SetMood(Mood.Seguindo);
            return;
        }

        switch (Estado)
        {
            case Mood.Seguindo:
                _cooldown -= d;
                if (_cooldown <= 0f && TryFindDistraction()) SetMood(Mood.Distraida);
                break;

            case Mood.Distraida:
                if (_distraction == null || !IsInstanceValid(_distraction)) { SetMood(Mood.Voltando); break; }
                if (GlobalPosition.DistanceTo(_distraction.GlobalPosition) < 1.2f) _distractionTimer -= d;
                if (_distractionTimer <= 0f || dist > SnapOutDistance)
                {
                    _distraction.Release();
                    _distraction = null;
                    SetMood(Mood.Voltando);
                }
                break;

            case Mood.Voltando:
                if (dist < FollowDistance * 1.5f) SetMood(Mood.Seguindo);
                break;
        }

        // Pula junto quando o irmão pula (imitando ele — fofo e ajuda a atravessar).
        if (Estado != Mood.Distraida && !_nino.IsOnFloor() && IsOnFloor() && dist < 6f
            && _nino.Velocity.Dot(_nino.UpDirection) > 2f)
        {
            _aiJump = true;
        }
        _aiJumpHeld = !IsOnFloor() && Velocity.Dot(UpDirection) > 0f;
    }

    private bool TryFindDistraction()
    {
        Distraction? best = null;
        float bestDist = DistractionSearchRadius;
        foreach (Node n in GetTree().GetNodesInGroup("distracao"))
        {
            if (n is not Distraction dz || !dz.IsAvailable) continue;
            float dd = GlobalPosition.DistanceTo(dz.GlobalPosition);
            if (dd < bestDist) { best = dz; bestDist = dd; }
        }
        _cooldown = _rng.RandfRange(DistractionCooldown.X, DistractionCooldown.Y);
        if (best == null) return false;
        _distraction = best;
        _distractionTimer = best.Claim(this);
        return true;
    }

    private void SetMood(Mood m)
    {
        if (Estado == m) return;
        Estado = m;
        EmitSignal(SignalName.MoodChanged, (int)m);
    }

    protected override Vector3 ComputeWish(Vector3 up)
    {
        if (PlayerControlled) return base.ComputeWish(up);
        if (_nino == null) return Vector3.Zero;

        Vector3 target = Estado == Mood.Distraida && _distraction != null
            ? _distraction.GlobalPosition
            : _nino.GlobalPosition;
        Vector3 to = target - GlobalPosition;
        to -= up * to.Dot(up);
        float dist = to.Length();

        float stopAt = Estado == Mood.Distraida ? 0.8f : FollowDistance;
        if (dist < stopAt) return Vector3.Zero;
        float speed01 = Estado == Mood.Voltando || dist > CatchUpDistance ? 1f : 0.7f;
        return to / dist * speed01;
    }

    protected override bool ReadJumpPressed() => PlayerControlled ? base.ReadJumpPressed() : _aiJump;
    protected override bool ReadJumpHeld() => PlayerControlled ? base.ReadJumpHeld() : _aiJumpHeld;
    protected override bool ReadSpinPressed() => PlayerControlled && base.ReadSpinPressed();
}
