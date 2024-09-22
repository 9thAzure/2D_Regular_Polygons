// using Chickensoft.GoDotCollections;
using Chickensoft.GoDotLog;
using Chickensoft.GoDotTest;
using Godot;
using SimplifiedShapeCreation;
using Shouldly;

namespace SimplifiedShapeCreation.Tests;

public class SimplePolygon2DTests : TestClass
{
    // readonly GDLog _log = new GDLog(nameof(SimplePolygon2D));
    readonly SimplePolygon2D polygon = new();
    public SimplePolygon2DTests(Node testScene) : base(testScene)
    {
    }

    [Test]
    public void VerticesCount_Set3_Returns3()
    {
        polygon.VerticesCount = 3;
        
        polygon.VerticesCount.ShouldBe(3);
    }

    [Test]
    public void Size_Set8_Returns8()
    {
        polygon.Size = 8;

        polygon.Size.ShouldBe(8);
    }

    [Test]
    public void OffsetRotationDegrees_Set45_Returns45()
    {
        polygon.OffsetRotationDegrees = 45;

        polygon.OffsetRotationDegrees.ShouldBe(45);
    }

    [Test]
    public void OffsetRotation_Set2_Returns2()
    {
        polygon.OffsetRotation = 2;

        polygon.OffsetRotation.ShouldBe(2);
    }

    [Test]
    public void Color_SetRed_ReturnsRed()
    {
        polygon.Color = Colors.Red;

        polygon.Color.ShouldBe(Colors.Red);
    }

    [Test]
    public void OffsetPosition_SetOne_ReturnsOne()
    {
        polygon.OffsetPosition = Vector2.One;
        
        polygon.OffsetPosition.ShouldBe(Vector2.One);
    }

    [Test]
    public void GetShapeVertices_DiamondShape_Returns4LengthArray()
    {
        var array = SimplePolygon2D.GetShapeVertices(4, 1, Mathf.DegToRad(45));

        array.Length.ShouldBe(4);
    }

    [Test]
    public void ApplyTransform_SampleShape_ReturnsExpected()
    {
        const float rotationAmount = 1.2f;
        const float sizeScale = 2;
        RegularPolygon2D expected = new(4, 10, 0);
        RegularPolygon2D sample = new(4, 10, 0);
        expected.OffsetRotation += rotationAmount;
        expected.Size *= sizeScale;
        expected.RegeneratePolygon();
        sample.RegeneratePolygon();

        sample.ApplyTransformation(rotationAmount, sizeScale, false, false);

        sample.OffsetRotation.ShouldBe(expected.OffsetRotation);
        sample.Size.ShouldBe(expected.Size);
    }
}
