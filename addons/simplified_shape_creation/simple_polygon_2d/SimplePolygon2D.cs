using System;
using System.Diagnostics;
using Godot;
using SimplifiedShapeCreation.MemberNames;

namespace SimplifiedShapeCreation;

/// <summary>
/// A Wrapper for a <see cref="Node2D"/> which contains the script specified in <see cref="SimplePolygon2D.GDScriptEquivalent"/>.
/// It also provides ways for creating such nodes.
/// </summary>
public partial class SimplePolygon2D
{
    /// <summary>The string path to the script this class wraps around.</summary>
    public const string GDScriptEquivalentPath = "res://addons/simplified_shape_creation/simple_polygon_2d/simple_polygon_2d.gd";
    /// <summary>The loaded <see cref="GDScript"/> of <see cref="GDScriptEquivalentPath"/>.</summary>
    public static readonly GDScript GDScriptEquivalent = GD.Load<GDScript>(GDScriptEquivalentPath);
    private static readonly Lazy<Node2D> _shared = new(() => GDScriptEquivalent.New().As<Node2D>());
    
    /// <summary>The <see cref="GDScriptEquivalent"/> instance this class wraps around.</summary>
    public Node2D Instance { get; }

    /// <summary>
    /// The number of vertices in the regular shape. A value of <c>1</c> creates a circle, and a value of <c>2</c> creates a line.
    /// </summary>
    public int VerticesCount
    {
        get => (int)Instance.Get(PropertyName.VerticesCount);
        set => Instance.Set(PropertyName.VerticesCount, value);
    }
    /// <summary>The length from each corner to the center of the shape.</summary>
    public float Size
    {
        get => (float)Instance.Get(PropertyName.Size);
        set => Instance.Set(PropertyName.Size, value);
    }
    /// <summary>The offset rotation of the shape, in degrees.</summary>
    public float OffsetRotationDegrees
    {
        get => (float)Instance.Get(PropertyName.OffsetRotationDegrees);
        set => Instance.Set(PropertyName.OffsetRotationDegrees, value);
    }
    /// <summary>The offset rotation of the shape, in radians.</summary>
    public float OffsetRotation
    {
        get => (float)Instance.Get(PropertyName.OffsetRotation);
        set => Instance.Set(PropertyName.OffsetRotation, value);
    }
    /// <summary>The color of the shape.</summary>
    public Color Color
    {
        get => (Color)Instance.Get(PropertyName.Color);
        set => Instance.Set(PropertyName.Color, value);
    }
    [Obsolete("Property name has been replaced, use 'Offset' instead.", false)]
    public Vector2 OffsetPosition
    {
        get => (Vector2)Instance.Get(PropertyName.OffsetPosition);
        set => Instance.Set(PropertyName.OffsetPosition, value);
    }
    /// <summary>The offset position of the shape.</summary>
    public Vector2 Offset
    {
        get => (Vector2)Instance.Get(PropertyName.Offset);
        set => Instance.Set(PropertyName.Offset, value);
    }
    /// <summary>Position, relative to the node's parent.</summary>
    public Vector2 Position
    {
        get => Instance.Position; 
        set => Instance.Position = value;
    }
    /// <summary>Rotation in radians, relative to the node's parent.</summary>
    public float Rotation
    {
        get => Instance.Rotation;
        set => Instance.Rotation = value;
    }
    /// <summary>Helper property to access <see cref="Node2D.Rotation"/> in degrees instead of radians.</summary>
    public float RotationDegrees
    {
        get => Instance.RotationDegrees;
        set => Instance.RotationDegrees = value;
    }
    /// <summary>The node's scale. Unscaled value: (1, 1).</summary>
    public Vector2 Scale
    {
        get => Instance.Scale;
        set => Instance.Scale = value;
    }

    /// <summary>
    /// Transforms <see cref="SimplePolygon2D"/>, rotating it by <paramref name="rotation"/> radians and scaling it by a factor of <paramref name="scale"/>.
    /// </summary>
    /// <remarks>Unlike other methods, this simply affects <see cref="OffsetRotation"/> and <see cref="Size"/>, regenerating the shape </remarks>
    /// <param name="rotation">The amount to rotate the shape in radians.</param>
    /// <param name="scale">The factor to scale the shape.</param>
    public void ApplyTransformation(float rotation, float scale, bool scale_width = true, bool scale_corner_size = true) => Instance.Call(MethodName.ApplyTransformation, rotation, scale, scale_width, scale_corner_size);
    public void ApplyTransformation(float rotation, float scale) => Instance.Call(MethodName.ApplyTransformation, rotation, scale);

    /// <inheritdoc cref="CanvasItem.QueueRedraw"/>
    public void QueueRedraw() => Instance.QueueRedraw();

    /// <summary>Creates and wraps a <see cref="SimplePolygon2D"/> around <paramref name="instance"/>.</summary>
    /// <param name="instance">The instance of <see cref="GDScriptEquivalent"/> to wrap.</param>
    /// <exception cref="ArgumentNullException"><paramref name="instance"/> is <see langword="null"/>.</exception>
    /// <exception cref="ArgumentException"><paramref name="instance"/> isn't a instance of <see cref="GDScriptEquivalent"/>.</exception>
    public SimplePolygon2D(Node2D instance)
    {
        if (instance is null)
            throw new ArgumentNullException(nameof(instance));
        if (GDScriptEquivalent != instance.GetScript().As<GDScript>())
            throw new ArgumentException($"must have attached script '{GDScriptEquivalentPath}'.", nameof(instance));

        Instance = instance;
    }
    /// <inheritdoc cref="New"/>
    /// <summary>Creates an instance of <see cref="GDScriptEquivalent"/> wrapped by a new <see cref="SimplePolygon2D"/>.</summary>
    /// <remarks>See also: <seealso cref="New"/>.</remarks>
    public SimplePolygon2D(int verticesCount = 1, float size = 10, float offsetRotation = 0, Color? color = default, Vector2 offsetPosition = default)
    {
        Instance = SimplePolygon2D.New(verticesCount, size, offsetRotation, color, offsetPosition);
    }
    /// <inheritdoc cref="GetShapeVertices"/>
    /// <summary>Creates an instance of <see cref="GDScriptEquivalent"/> with the specified parameters.</summary>
    /// <param name="verticesCount">The number of vertices in the shape. A <c>1</c> draws a circle, a <c>2</c> draws a line.</param>
    /// <param name="color">The color of the shape.</param>
    public static Node2D New(int verticesCount = 1, float size = 10, float offsetRotation = 0, Color? color = default, Vector2 offsetPosition = default)
    {
        Debug.Assert(GDScriptEquivalent is not null);
        color ??= Colors.White;
        return GDScriptEquivalent.New(verticesCount, size, offsetRotation, color.Value, offsetPosition).As<Node2D>();
    }

    /// <summary>Returns an array of <see cref="Vector2"/>s with the points for the shape with the specified <paramref name="verticesCount"/>.</summary>
    /// <param name="verticesCount">The number of vertices in the shape. If it is <c>1</c>, a value of <c>32</c> is used.</param>
    /// <param name="size">The distance each corner vertices is from the center.</param>
    /// <param name="offsetRotation">The rotation applied to the shape.</param>
    /// <param name="offsetPosition">The center of the shape.</param>
    public static Vector2[] GetShapeVertices(int verticesCount, float size = 1, float offsetRotation = 0, Vector2 offsetPosition = default)
    => _shared.Value.Call(MethodName.GetShapeVertices, verticesCount, size, offsetRotation, offsetPosition).As<Vector2[]>();

    public static implicit operator Node2D(SimplePolygon2D instance) => instance.Instance;
    public static explicit operator SimplePolygon2D(Node2D instance) => new(instance);
}
