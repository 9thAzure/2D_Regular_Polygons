using System;
using System.Reflection;
using Chickensoft.GoDotTest;
using Godot;

namespace SimplifiedShapeCreation.Tests;

public partial class TestRunner : Node
{
    // Called when the node enters the scene tree for the first time.
    [Export]
    public bool ExitOnFinish { get; set; } = true;
    public override void _Ready()
    {
        string[] arguments = ExitOnFinish ? new[] {"--run-tests", "--quit-on-finish"} : new[] {"--run-tests"};
        _ = GoTest.RunTests(Assembly.GetExecutingAssembly(), this, TestEnvironment.From(arguments));
    }

}
