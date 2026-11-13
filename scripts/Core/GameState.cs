using Godot;

namespace Sonhos.Core;

/// <summary>
/// Autoload global: guarda o livro escolhido, o progresso da missão e registra os controles.
/// </summary>
public partial class GameState : Node
{
    public const string QuartoScene = "res://scenes/dev/PlanetaTeste.tscn"; // TODO: trocar pelo Quarto (hub) quando existir

    [Signal] public delegate void MissionProgressEventHandler(int atual, int total);
    [Signal] public delegate void MissionCompletedEventHandler();

    public static GameState Instance { get; private set; } = null!;

    public BookData? LivroAtual { get; private set; }

    /// <summary>Coop drop-in: o 2º jogador entra apertando qualquer botão dele e sai com "p2_leave".</summary>
    public bool PlayerTwoJoined { get; private set; }
    public int ItensColetados { get; private set; }
    public int ItensNecessarios => LivroAtual?.ItensNecessarios ?? 3;

    public override void _EnterTree() => Instance = this;

    public override void _Ready() => RegistrarControles();

    public override void _UnhandledInput(InputEvent e)
    {
        if (!PlayerTwoJoined && (e.IsActionPressed("p2_jump") || e.IsActionPressed("p2_lamp")))
            PlayerTwoJoined = true;
        else if (PlayerTwoJoined && e.IsActionPressed("p2_leave"))
            PlayerTwoJoined = false;

        if (e.IsActionPressed("call_sister"))
            foreach (Node n in GetTree().GetNodesInGroup("irmazinha"))
                (n as Player.SisterController)?.Call();
    }

    /// <summary>Chamado ao escolher um livro na estante: o menino dorme e entra no sonho.</summary>
    public void EntrarNoLivro(BookData livro)
    {
        LivroAtual = livro;
        ItensColetados = 0;
        if (!string.IsNullOrEmpty(livro.CenaDoSonho))
            GetTree().CallDeferred(SceneTree.MethodName.ChangeSceneToFile, livro.CenaDoSonho);
    }

    public void ColetarItem()
    {
        ItensColetados++;
        EmitSignal(SignalName.MissionProgress, ItensColetados, ItensNecessarios);
        if (ItensColetados >= ItensNecessarios)
            CompletarMissao();
    }

    public void CompletarMissao()
    {
        EmitSignal(SignalName.MissionCompleted);
        GD.Print("✨ Missão completa! Hora de acordar.");
        // TODO: transição de "acordar" (cortina de tecido fechando) e volta ao quarto.
    }

    public void Acordar()
    {
        LivroAtual = null;
        GetTree().CallDeferred(SceneTree.MethodName.ChangeSceneToFile, QuartoScene);
    }

    // ---- Controles (registrados em código para manter o project.godot simples) ----

    private static void RegistrarControles()
    {
        AddKeys("move_forward", Key.W, Key.Up);
        AddKeys("move_back", Key.S, Key.Down);
        AddKeys("move_left", Key.A, Key.Left);
        AddKeys("move_right", Key.D, Key.Right);
        AddKeys("camera_left", Key.Q);
        AddKeys("camera_right", Key.E);
        AddKeys("jump", Key.Space);
        AddKeys("spin", Key.Shift);
        AddKeys("lamp", Key.F);
        AddKeys("interact", Key.Enter);
        AddKeys("call_sister", Key.C);

        // Jogador 2 (irmãzinha) — teclado IJKL / segundo controle (device 1).
        AddKeys("p2_move_forward", Key.I);
        AddKeys("p2_move_back", Key.K);
        AddKeys("p2_move_left", Key.J);
        AddKeys("p2_move_right", Key.L);
        AddKeys("p2_jump", Key.Kp0, Key.O);
        AddKeys("p2_spin", Key.U);
        AddKeys("p2_lamp", Key.P);
        AddKeys("p2_leave", Key.Backspace);
        AddJoyAxis("p2_move_forward", JoyAxis.LeftY, -1, 1);
        AddJoyAxis("p2_move_back", JoyAxis.LeftY, 1, 1);
        AddJoyAxis("p2_move_left", JoyAxis.LeftX, -1, 1);
        AddJoyAxis("p2_move_right", JoyAxis.LeftX, 1, 1);
        AddJoyButton("p2_jump", JoyButton.A, 1);
        AddJoyButton("p2_spin", JoyButton.X, 1);
        AddJoyAxis("p2_lamp", JoyAxis.TriggerRight, 1, 1);
        AddJoyButton("p2_leave", JoyButton.Back, 1);
        AddJoyButton("call_sister", JoyButton.Y);

        AddJoyAxis("move_forward", JoyAxis.LeftY, -1);
        AddJoyAxis("move_back", JoyAxis.LeftY, 1);
        AddJoyAxis("move_left", JoyAxis.LeftX, -1);
        AddJoyAxis("move_right", JoyAxis.LeftX, 1);
        AddJoyAxis("camera_left", JoyAxis.RightX, -1);
        AddJoyAxis("camera_right", JoyAxis.RightX, 1);
        AddJoyButton("jump", JoyButton.A);
        AddJoyButton("spin", JoyButton.X);
        AddJoyButton("interact", JoyButton.B);
        AddJoyAxis("lamp", JoyAxis.TriggerRight, 1);

        AddMouse("lamp", MouseButton.Right);
    }

    /// <summary>Teclado/mouse valem para qualquer dispositivo; controles são separados por device (0 = Nino, 1 = irmã).</summary>
    private const int AllDevices = -1;

    private static void Ensure(string action)
    {
        if (!InputMap.HasAction(action))
            InputMap.AddAction(action, 0.2f);
    }

    private static void AddKeys(string action, params Key[] keys)
    {
        Ensure(action);
        foreach (var k in keys)
            InputMap.ActionAddEvent(action, new InputEventKey { PhysicalKeycode = k, Device = AllDevices });
    }

    private static void AddJoyAxis(string action, JoyAxis axis, float dir, int device = 0)
    {
        Ensure(action);
        InputMap.ActionAddEvent(action, new InputEventJoypadMotion { Axis = axis, AxisValue = dir, Device = device });
    }

    private static void AddJoyButton(string action, JoyButton button, int device = 0)
    {
        Ensure(action);
        InputMap.ActionAddEvent(action, new InputEventJoypadButton { ButtonIndex = button, Device = device });
    }

    private static void AddMouse(string action, MouseButton button)
    {
        Ensure(action);
        InputMap.ActionAddEvent(action, new InputEventMouseButton { ButtonIndex = button, Device = AllDevices });
    }
}
