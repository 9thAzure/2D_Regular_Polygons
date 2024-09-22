using System;
using System.Diagnostics;
using Godot;
using ComplexShapeCreation.MemberNames;

namespace ComplexShapeCreation;

/// <summary>
/// A Wrapper for a <see cref="Polygon2D"/> which contains the script specified in <see cref="GDScriptEquivalent"/>.
/// It also provides ways for creating such nodes.
/// </summary>
public class StarPolygon2D
{
    /// <inheritdoc cref="SimplePolygon2D.GDScriptEquivalentPath"/>
    public const string GDScriptEquivalentPath = "res://addons/complex_shape_creation/star_polygon_2d/star_polygon_2d.gd";
    /// <summary>The loaded <see cref="GDScript"/> of <see cref="GDScriptEquivalentPath"/>.</summary>
    public static readonly GDScript GDScriptEquivalent = GD.Load<GDScript>(GDScriptEquivalentPath);
    private static readonly Lazy<Polygon2D> _shared = new(() => GDScriptEquivalent.New().As<Polygon2D>());

    /// <summary>The <see cref="GDScriptEquivalent"/> instance this class wraps around.</summary>
    public Polygon2D Instance { get; }

    /// <summary>
    /// The number of points the star has.
    /// </summary>
    /// <remarks>If set to <c>1</c>, a line is drawn.</remarks>
    public int VerticesCount
    {
        get => (int)Instance.Get(PropertyName.VerticesCount);
        set => Instance.Set(PropertyName.VerticesCount, value);
    }
    [Obsolete("Property name has been replaced, use 'VerticesCount' instead.", false)]
    public int PointCount
    {
        get => (int)Instance.Get(PropertyName.PointCount);
        set => Instance.Set(PropertyName.PointCount, value);
    }
    /// <summary>
    /// The length of each point to the center of the star.
    /// </summary>
    /// <remarks>For lines, it determines the length of the top part.</remarks>
    public float Size
    {
        get => (float)Instance.Get(PropertyName.Size);
        set => Instance.Set(PropertyName.Size, value);
    }
    /// <summary>
    /// The length of the inner vertices to the center of the star.
    /// </summary>
    /// <remarks>For lines, it determines the length of the bottom part.</remarks>
    public float InnerSize
    {
        get => (float)Instance.Get(PropertyName.InnerSize);
        set => Instance.Set(PropertyName.InnerSize, value);
    }
    /// <inheritdoc cref="SimplePolygon2D.OffsetRotationDegrees"/>
    public float OffsetRotationDegrees
    {
        get => (float)Instance.Get(PropertyName.OffsetRotationDegrees);
        set => Instance.Set(PropertyName.OffsetRotationDegrees, value);
    }
    /// <inheritdoc cref="SimplePolygon2D.OffsetRotation"/>
    public float OffsetRotation
    {
        get => (float)Instance.Get(PropertyName.OffsetRotation);
        set => Instance.Set(PropertyName.OffsetRotation, value);
    }
    /// <inheritdoc cref="RegularPolygon2D.Width"/>
    public float Width
    {
        get => (float)Instance.Get(PropertyName.Width);
        set => Instance.Set(PropertyName.Width, value);
    }
    
    /// <inheritdoc cref="RegularPolygon2D.DrawnArcDegrees"/>
    public float DrawnArcDegrees
    {
        get => (float)Instance.Get(PropertyName.DrawnArcDegrees);
        set => Instance.Set(PropertyName.DrawnArcDegrees, value);
    }
    /// <inheritdoc cref="RegularPolygon2D.DrawnArc"/>
    public float DrawnArc
    {
        get => (float)Instance.Get(PropertyName.DrawnArc);
        set => Instance.Set(PropertyName.DrawnArc, value);
    }

    /// <inheritdoc cref="RegularPolygon2D.CornerSize"/>
    public float CornerSize
    {
        get => (float)Instance.Get(PropertyName.CornerSize);
        set => Instance.Set(PropertyName.CornerSize, value);
    }
    /// <summary>How many lines make up each corner</summary>
    /// <remarks>A value of <c>0</c> will use a value of <c>32</c> divided by <see cref="PointCount"/>.</remarks>
    public int CornerSmoothness
    {
        get => (int)Instance.Get(PropertyName.CornerSmoothness);
        set => Instance.Set(PropertyName.CornerSmoothness, value);
    }
    /// <inheritdoc cref="SimplePolygon2D.Color"/>
    public Color Color
    {
        get => Instance.Color;
        set => Instance.Color = value;
    }
    /// <inheritdoc cref="SimplePolygon2D.OffsetPosition"/>
    public Vector2 OffsetPosition
    {
        get => Instance.Offset;
        set => Instance.Offset = value;
    }
    /// <inheritdoc cref="SimplePolygon2D.Position"/>
    public Vector2 Position
    {
        get => Instance.Position;
        set => Instance.Position = value;
    }
    /// <inheritdoc cref="SimplePolygon2D.Rotation"/>
    public float Rotation
    {
        get => Instance.Rotation;
        set => Instance.Rotation = value;
    }
    /// <inheritdoc cref="SimplePolygon2D.RotationDegrees"/>
    public float RotationDegrees
    {
        get => Instance.RotationDegrees;
        set => Instance.RotationDegrees = value;
    }
    /// <inheritdoc cref="SimplePolygon2D.Scale"/>
    public Vector2 Scale
    {
        get => Instance.Scale;
        set => Instance.Scale = value;
    }

    /// <inheritdoc cref="RegularPolygon2D.ApplyTransformation(float, float, bool, bool)"/>
    /// <remarks>
    /// This method modifies the existing <see cref="Polygon2D.Polygon"/>, so is generally faster than changing <see cref="Size"/> and <see cref="OffsetRotation"/>.
    /// This only happens if the transformed shape is congruent to the original. If it is not or <see cref="Polygon2D.Polygon"/> isn't used, the shape is regenerated.
    /// <br/><br/><b>Warning</b>: Currently method does not check if the <see cref="CornerSize"/> value is clamped due to small side lengths.
    /// If this occurs in the original or transformed shape and <paramref name="scale_corner_size"/> is <see langword="false"/>, the shape will not be accurate to this node's properties.
    /// </remarks>
    /// <param name="scale_width">Toggles scaling <see cref="Width"/>, applying correction if <see langword="false"/>.</param>
    /// <param name="scale_corner_size">Toggles scaling <see cref="CornerSize"/>, applying correction if <see langword="false"/>.</param>
    public void ApplyTransformation(float rotation, float scale, bool scale_width = true, bool scale_corner_size = true) => Instance.Call(MethodName.ApplyTransformation, rotation, scale, scale_width, scale_corner_size);

    /// <summary>
    /// Sets <see cref="innerSize"/> such that the angle formed by each point is equivalent to <paramref name="angle"/>, in radians.
    /// </summary>
    public void SetPointAngle(float angle) => Instance.Call(MethodName.SetPointAngle, angle);

    /// <summary>
    /// Queues <see cref="Regenerate"/> for the next process frame. If this method is called multiple times, the shape is only regenerated once.
    /// </summary>
    /// <remarks>
    /// If this method is called when the node is outside the <see cref="SceneTree"/>, regeneration will be delayed to when the node enters the tree. 
    /// Use <see cref="Regenerate"/> directly to force initialization.
    /// </remarks>
    public void QueueRegenerate() => Instance.Call(MethodName.QueueRegenerate);

    /// <summary>
    /// Sets <see cref="Polygon2D.Polygon"> using the properties of this node. 
    /// This method can be used when the node is outside the <see cref="SceneTree"/> to force this, and ignores the result of <see cref="UsesPolygonMember"/>.
    /// </summary>
    public void Regenerate() => Instance.Call(MethodName.Regenerate);

    [Obsolete("Method name has changed, use 'Regenerate' instead.", false)]
    public void RegeneratePolygon() => Instance.Call(MethodName.RegeneratePolygon);

    /// <summary>
    /// Checks whether the current properties of this node will have it use <see cref="Polygon2D.Polygon">.
    /// </summary>
    public bool UsesPolygonMember() => (bool)Instance.Call(MethodName.UsesPolygonMember);

    /// <summary>Creates and wraps a <see cref="StarPolygon2D"/> around <paramref name="instance"/>.</summary>
    /// <param name="instance">The instance of <see cref="GDScriptEquivalent"/> to wrap.</param>
    /// <exception cref="ArgumentNullException"><paramref name="instance"/> is <see langword="null"/>.</exception>
    /// <exception cref="ArgumentException"><paramref name="instance"/> isn't a instance of <see cref="GDScriptEquivalent"/>.</exception>
    public StarPolygon2D(Polygon2D instance)
    {
        if (instance is null)
            throw new ArgumentNullException(nameof(instance));
        if (GDScriptEquivalent != instance.GetScript().As<GDScript>())
            throw new ArgumentException($"must have attached script '{GDScriptEquivalentPath}'.", nameof(instance));

        Instance = instance;
    }
    /// <inheritdoc cref="New(int, float, float, float, Color?, Vector2, float, float, float, int)"/>
    /// <summary>Creates an instance of <see cref="GDScriptEquivalent"/> wrapped by a new <see cref="RegularPolygon2D"/>.</summary>
    /// <remarks>See also: <seealso cref="New"/>.</remarks>
    /// <param name="pointCount">The number of points in the star.</param>
    public StarPolygon2D(int pontCount = 1, float size = 10, float innerSize = 5, float offsetRotation = 0, Color? color = default, Vector2 offsetPosition = default,
        float width = -0.001f, float drawnArc = Mathf.Tau, float cornerSize = 0, int cornerSmoothness = 0)
    {
        Instance = StarPolygon2D.New(pontCount, size, innerSize, offsetRotation, color, offsetPosition,
            width, drawnArc, cornerSize, cornerSmoothness);
    }
    /// <inheritdoc cref="RegularPolygon2D.New(int, float, float, Color?, Vector2, float, float, float, int)"/>
    /// <summary>Creates an instance of <see cref="GDScriptEquivalent"/> with the specified parameters.</summary>
    /// <param name="pointCount">The number of points in the star.</param>
    public static Polygon2D New(int pointCount = 1, float size = 10, float innerSize = 5, float offsetRotation = 0, Color? color = default, Vector2 offsetPosition = default,
        float width = -0.001f, float drawnArc = Mathf.Tau, float cornerSize = 0, int cornerSmoothness = 0)
    {
        Debug.Assert(GDScriptEquivalent is not null);
        color ??= Colors.White;
        return GDScriptEquivalent.New(pointCount, size, innerSize, offsetRotation, color.Value, offsetPosition,
            width, drawnArc, cornerSize, cornerSmoothness).As<Polygon2D>();
    }

    /// <inheritdoc cref="RegularPolygon2D.GetShapeVertices(int, float, float, Vector2, float, bool)"/>
    /// <summary>Returns an array of <see cref="Vector2"/> with points for forming the specified star shape.</summary>
    /// <param name="pointCount">The number of points in the star.</param>
    /// <param name="innerSize">The length of the inner vertices to the center of the star.</param>
    /// <param name="drawnArc">The drawn arc of the shape. Stars at the top point. Positive values go clockwise and negative values counter-clockwise.</param>
    public static Vector2[] GetStarVertices(int pointCount, float size, float innerSize, float offsetRotation = 0, 
        Vector2 offsetPosition = default, float drawnArc = Mathf.Tau, bool addCentralPoint = true)
    => _shared.Value.Call(MethodName.GetStarVertices, pointCount, size, innerSize, offsetRotation, offsetPosition, drawnArc, addCentralPoint).AsVector2Array();

    public static implicit operator Polygon2D(StarPolygon2D instance) => instance.Instance;
    public static explicit operator StarPolygon2D(Polygon2D instance) => new(instance);
}
