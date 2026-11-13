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
    public int ItensColetados { get; private set; }
    public int ItensNecessarios => LivroAtual?.ItensNecessarios ?? 3;

    public override void _EnterTree() => Instance = this;

    public override void _Ready() => RegistrarControles();

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

    private static void Ensure(string action)
    {
        if (!InputMap.HasAction(action))
            InputMap.AddAction(action, 0.2f);
    }

    private static void AddKeys(string action, params Key[] keys)
    {
        Ensure(action);
        foreach (var k in keys)
            InputMap.ActionAddEvent(action, new InputEventKey { PhysicalKeycode = k });
    }

    private static void AddJoyAxis(string action, JoyAxis axis, float dir)
    {
        Ensure(action);
        InputMap.ActionAddEvent(action, new InputEventJoypadMotion { Axis = axis, AxisValue = dir });
    }

    private static void AddJoyButton(string action, JoyButton button)
    {
        Ensure(action);
        InputMap.ActionAddEvent(action, new InputEventJoypadButton { ButtonIndex = button });
    }

    private static void AddMouse(string action, MouseButton button)
    {
        Ensure(action);
        InputMap.ActionAddEvent(action, new InputEventMouseButton { ButtonIndex = button });
    }
}
