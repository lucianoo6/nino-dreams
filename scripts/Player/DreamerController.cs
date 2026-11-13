using Godot;
using Sonhos.Camera;

namespace Sonhos.Player;

/// <summary>
/// O sonhador. Movimento estilo "planetinhas": a gravidade vem das Area3D (gravity point)
/// de cada planeta, e o personagem alinha o "para cima" com o oposto da gravidade.
/// </summary>
public partial class DreamerController : CharacterBody3D
{
    [ExportGroup("Movimento")]
    [Export] public float MoveSpeed { get; set; } = 7f;
    [Export] public float GroundAccel { get; set; } = 45f;
    [Export] public float AirAccel { get; set; } = 18f;
    [Export] public float TurnSpeed { get; set; } = 12f;

    [ExportGroup("Pulo")]
    [Export] public float JumpVelocity { get; set; } = 11f;
    [Export] public float LowJumpMultiplier { get; set; } = 2.2f;
    [Export] public float CoyoteTime { get; set; } = 0.12f;
    [Export] public float JumpBuffer { get; set; } = 0.12f;

    [ExportGroup("Rodopio")]
    /// <summary>Giro no ar: um impulsinho para cima, uma vez por pulo. Deixa o controle "dançante".</summary>
    [Export] public float SpinBoost { get; set; } = 5f;

    [ExportGroup("Gravidade")]
    [Export] public float UpAlignSpeed { get; set; } = 10f;

    [Export] public NodePath CameraRigPath { get; set; } = new("CameraRig");

    public bool IsSpinning => _spinTimer > 0f;

    private DreamCamera _camera = null!;
    private float _coyote;
    private float _jumpBuffer;
    private bool _spinAvailable = true;
    private float _spinTimer;

    public override void _Ready()
    {
        AddToGroup("sonhador");
        _camera = GetNode<DreamCamera>(CameraRigPath);
        FloorSnapLength = 0.4f;
    }

    public override void _PhysicsProcess(double delta)
    {
        float d = (float)delta;
        Vector3 gravity = GetGravity();
        float gLen = gravity.Length();

        // 1) Alinhar "para cima" com o oposto da gravidade do planeta atual.
        if (gLen > 0.001f)
        {
            Vector3 targetUp = -gravity / gLen;
            float t = 1f - Mathf.Exp(-UpAlignSpeed * d);
            Vector3 newUp = UpDirection.Slerp(targetUp, t);
            UpDirection = newUp.LengthSquared() > 0.0001f ? newUp.Normalized() : targetUp;
        }
        Vector3 up = UpDirection;

        // 2) Separar velocidade em vertical (ao longo do up) e lateral (no plano tangente).
        Vector3 v = Velocity;
        float vertical = v.Dot(up);
        Vector3 lateral = v - up * vertical;

        // 3) Direção desejada relativa à câmera, projetada no plano tangente.
        Vector2 input = Input.GetVector("move_left", "move_right", "move_forward", "move_back");
        Basis cb = _camera.GlobalBasis;
        Vector3 camF = ProjectOnPlane(-cb.Z, up);
        Vector3 camR = ProjectOnPlane(cb.X, up);
        Vector3 wish = camR * input.X + camF * -input.Y;
        if (wish.LengthSquared() > 1f) wish = wish.Normalized();

        bool onFloor = IsOnFloor();
        lateral = lateral.MoveToward(wish * MoveSpeed, (onFloor ? GroundAccel : AirAccel) * d);

        // 4) Pulo com coyote time + buffer, e pulo curto ao soltar o botão.
        if (onFloor) { _coyote = CoyoteTime; _spinAvailable = true; }
        else _coyote -= d;

        if (Input.IsActionJustPressed("jump")) _jumpBuffer = JumpBuffer;
        else _jumpBuffer -= d;

        if (_jumpBuffer > 0f && _coyote > 0f)
        {
            vertical = JumpVelocity;
            _jumpBuffer = 0f;
            _coyote = 0f;
        }
        else
        {
            bool cutJump = vertical > 0f && !Input.IsActionPressed("jump");
            vertical -= gLen * d * (cutJump ? LowJumpMultiplier : 1f);
        }

        // 5) Rodopio.
        _spinTimer -= d;
        if (Input.IsActionJustPressed("spin") && _spinTimer <= 0f)
        {
            _spinTimer = 0.35f;
            if (!onFloor && _spinAvailable)
            {
                vertical = Mathf.Max(vertical, SpinBoost);
                _spinAvailable = false;
            }
        }

        Velocity = lateral + up * vertical;
        MoveAndSlide();

        // 6) Orientar o corpo: em pé no planeta e virado para onde anda.
        OrientBody(up, wish, d);
    }

    private void OrientBody(Vector3 up, Vector3 wish, float d)
    {
        Basis current = GlobalBasis.Orthonormalized();
        Basis target;
        if (wish.LengthSquared() > 0.01f)
        {
            target = Basis.LookingAt(wish.Normalized(), up);
        }
        else
        {
            Vector3 fwd = ProjectOnPlane(-current.Z, up);
            if (fwd.LengthSquared() < 0.001f) fwd = ProjectOnPlane(current.Y, up);
            target = Basis.LookingAt(fwd, up);
        }
        float t = 1f - Mathf.Exp(-TurnSpeed * d);
        GlobalBasis = current.Slerp(target, t).Orthonormalized();
    }

    private static Vector3 ProjectOnPlane(Vector3 v, Vector3 normal)
    {
        Vector3 p = v - normal * v.Dot(normal);
        return p.LengthSquared() > 0.0001f ? p.Normalized() : Vector3.Zero;
    }
}
