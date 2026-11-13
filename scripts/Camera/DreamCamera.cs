using Godot;

namespace Sonhos.Camera;

/// <summary>
/// Câmera que segue o sonhador e se alinha suavemente com o "para cima" dele,
/// mantendo o yaw controlado pelo jogador (Q/E, analógico direito ou mouse).
/// Filhos esperados: SpringArm3D -> Camera3D.
/// </summary>
public partial class DreamCamera : Node3D
{
    [Export] public float FollowSpeed { get; set; } = 10f;
    [Export] public float AlignSpeed { get; set; } = 4f;
    [Export] public float YawSpeed { get; set; } = 2.5f;
    [Export] public float MouseSensitivity { get; set; } = 0.004f;

    private CharacterBody3D _target = null!;
    private float _mouseYaw;

    public override void _Ready()
    {
        _target = GetParent<CharacterBody3D>();
        TopLevel = true;
        GlobalTransform = _target.GlobalTransform;
    }

    public override void _UnhandledInput(InputEvent e)
    {
        if (e is InputEventMouseMotion mm && Input.MouseMode == Input.MouseModeEnum.Captured)
            _mouseYaw -= mm.Relative.X * MouseSensitivity;
        if (e is InputEventMouseButton { Pressed: true, ButtonIndex: MouseButton.Left })
            Input.MouseMode = Input.MouseModeEnum.Captured;
        if (e.IsActionPressed("ui_cancel"))
            Input.MouseMode = Input.MouseModeEnum.Visible;
    }

    public override void _Process(double delta)
    {
        float d = (float)delta;

        GlobalPosition = GlobalPosition.Lerp(_target.GlobalPosition, 1f - Mathf.Exp(-FollowSpeed * d));

        // Alinha o eixo Y da câmera com o up do sonhador pelo menor arco (preserva o yaw).
        Basis b = GlobalBasis.Orthonormalized();
        Vector3 up = _target.UpDirection;
        if (b.Y.Dot(up) > -0.999f)
        {
            var arc = new Quaternion(b.Y, up);
            Basis aligned = (new Basis(arc) * b).Orthonormalized();
            b = b.Slerp(aligned, 1f - Mathf.Exp(-AlignSpeed * d)).Orthonormalized();
        }

        float yaw = Input.GetAxis("camera_right", "camera_left") * YawSpeed * d + _mouseYaw;
        _mouseYaw = 0f;
        if (Mathf.Abs(yaw) > 0.00001f)
            b = (new Basis(b.Y, yaw) * b).Orthonormalized();

        GlobalBasis = b;
    }
}
