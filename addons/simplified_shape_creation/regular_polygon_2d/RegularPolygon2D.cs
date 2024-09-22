using System;
using System.Diagnostics;
using Godot;
using ComplexShapeCreation.MemberNames;

namespace ComplexShapeCreation;

/// <summary>
/// A Wrapper for a <see cref="Polygon2D"/> which contains the script specified in <see cref="GDScriptEquivalent"/>.
/// It also provides ways for creating such nodes.
/// </summary>
public class RegularPolygon2D
{
    /// <inheritdoc cref="SimplePolygon2D.GDScriptEquivalentPath"/>
    public const string GDScriptEquivalentPath = "res://addons/simplified_shape_creation/regular_polygon_2d/regular_polygon_2d.gd";
    /// <summary>The loaded <see cref="GDScript"/> of <see cref="GDScriptEquivalentPath"/>.</summary>
    public static readonly GDScript GDScriptEquivalent = GD.Load<GDScript>(GDScriptEquivalentPath);
    private static readonly Lazy<Polygon2D> _shared = new(() => GDScriptEquivalent.New().As<Polygon2D>());

    /// <summary>The <see cref="GDScriptEquivalent"/> instance this class wraps around.</summary>
    public Polygon2D Instance { get; }
    
    /// <inheritdoc cref="SimplePolygon2D.VerticesCount"/>
    public int VerticesCount
    {
        get => (int)Instance.Get(PropertyName.VerticesCount);
        set => Instance.Set(PropertyName.VerticesCount, value);
    }
    /// <inheritdoc cref="SimplePolygon2D.Size"/>
    public float Size
    {
        get => (float)Instance.Get(PropertyName.Size);
        set => Instance.Set(PropertyName.Size, value);
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
    /// <summary>Determines the width of the shape and whether is uses Draw* methods or <see cref="Polygon2D.Polygon"/>.</summary>
    /// <remarks>
    /// A value of <c>0</c> outlines the shape with lines, and a value smaller than <c>0</c> ignores this effect.
    /// Values greater than <c>0</c> will have <see cref="Polygon2D.Polygon"/> used,
    /// and value greater than <see cref="size"/> also ignores this effect while still using <see cref="Polygon2D.Polygon"/>.
    /// <br/><br/>For lines, <see cref="CanvasItem.DrawLine(Vector2, Vector2, Color, float, bool)"/> is always used, and this property 
    /// corresponds to the <c>width</c> parameter.
    /// Note: A value between <c>0</c> and <c>0.01</c> is converted to <c>0</c> when running in the editor.
    /// </remarks>
    public float Width
    {
        get => (float)Instance.Get(PropertyName.Width);
        set => Instance.Set(PropertyName.Width, value);
    }
    /// <summary>The arc of the drawn shape, in degrees, cutting off beyond that arc.</summary>
    /// <remarks>
    /// Values greater than <c>360</c> or <c>-360</c> draws a full shape. It starts in the middle of the bottom edge of the shapes. 
    /// The direction of the arc is clockwise with positive values and counterclockwise with negative values.
    /// <br/><br/>For lines, this property rotates the top half of the line.
    /// <b>Note</b>: if [member width] is used, this leaves a gap between the 2 lines on the outer angle. Using [member corner_size] fills it in.
    /// A value of <c>0</c> makes the node not draw anything.
    /// </remarks>
    public float DrawnArcDegrees
    {
        get => (float)Instance.Get(PropertyName.DrawnArcDegrees);
        set => Instance.Set(PropertyName.DrawnArcDegrees, value);
    }
    /// <summary>The arc of the drawn shape, radians, cutting off beyond that arc.</summary>
    /// <remarks>
    /// Values greater than <see cref="Mathf.Tau"/> or -<see cref="Mathf.Tau"/> draws a full shape. It starts in the middle of the bottom edge of the shapes. 
    /// The direction of the arc is clockwise with positive values and counterclockwise with negative values.
    /// <br/><br/>For lines, this property rotates the top half of the line.
    /// <b>Note</b>: if [member width] is used, this leaves a gap between the 2 lines on the outer angle. Using [member corner_size] fills it in.
    /// A value of <c>0</c> makes the node not draw anything.
    /// </remarks>
    public float DrawnArc
    {
        get => (float)Instance.Get(PropertyName.DrawnArc);
        set => Instance.Set(PropertyName.DrawnArc, value);
    }

    /// <summary>The distance from each vertex along the edge to the point where the rounded corner starts.</summary>
    /// <remarks>
    /// If this value is over half of the edge length, the mid-point of the edge is used instead.
    /// <br/><br/>This only has an effect on lines if [member drawn_arc] is also used.
    /// The maximum possible distance is the ends of the line from the middle.
    /// </remarks>
    public float CornerSize
    {
        get => (float)Instance.Get(PropertyName.CornerSize);
        set => Instance.Set(PropertyName.CornerSize, value);
    }
    /// <summary>How many lines make up each corner</summary>
    /// <remarks>
    /// A value of <c>0</c> will use a value of <c>32</c> divided by <see cref="VerticesCount"/>. 
    /// This only has an effect if [member corner_size] is used.
    /// </remarks>
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

    /// <inheritdoc cref="SimplePolygon2D.ApplyTransformation(float, float)"/>
    /// <summary>
    /// Transforms <see cref="Polygon2D.Polygon"/>, rotating it by <paramref name="rotation"/> radians and scaling it by a factor of <paramref name="scale"/>.
    /// </summary>
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

    /// <summary>Creates and wraps a <see cref="RegularPolygon2D"/> around <paramref name="instance"/>.</summary>
    /// <param name="instance">The instance of <see cref="GDScriptEquivalent"/> to wrap.</param>
    /// <exception cref="ArgumentNullException"><paramref name="instance"/> is <see langword="null"/>.</exception>
    /// <exception cref="ArgumentException"><paramref name="instance"/> isn't a instance of <see cref="GDScriptEquivalent"/>.</exception>
    public RegularPolygon2D(Polygon2D instance)
    {
        if (instance is null)
            throw new ArgumentNullException(nameof(instance));
        if (GDScriptEquivalent != instance.GetScript().As<GDScript>())
            throw new ArgumentException($"must have attached script '{GDScriptEquivalentPath}'.", nameof(instance));

        Instance = instance;
    }
    /// <inheritdoc cref="New"/>
    /// <summary>Creates an instance of <see cref="GDScriptEquivalent"/> wrapped by a new <see cref="RegularPolygon2D"/>.</summary>
    /// <remarks>See also: <seealso cref="New"/>.</remarks>
    public RegularPolygon2D(int verticesCount = 1, float size = 10, float offsetRotation = 0, Color? color = default, Vector2 offsetPosition = default,
        float width = -0.001f, float drawnArc = Mathf.Tau, float cornerSize = 0, int cornerSmoothness = 0)
    {
        Instance = RegularPolygon2D.New(verticesCount, size, offsetRotation, color, offsetPosition,
            width, drawnArc, cornerSize, cornerSmoothness);
    }
    /// <inheritdoc cref="SimplePolygon2D.New(int, float, float, Color?, Vector2)"/>
    /// <summary>Creates an instance of <see cref="GDScriptEquivalent"/> with the specified parameters.</summary>
    /// <param name="width">The width of the shape. Negative values draw a full shape.</param>
    /// <param name="drawnArc">The drawn arc of the shape. It starts in the middle of the base. Positive values go clockwise, negative values go counterclockwise.</param>
    /// <param name="cornerSize">The distance along each edge to the point where the corner starts.</param>
    /// <param name="cornerSmoothness">How many lines make up each corner.</param>
    public static Polygon2D New(int verticesCount = 1, float size = 10, float offsetRotation = 0, Color? color = default, Vector2 offsetPosition = default,
        float width = -0.001f, float drawnArc = Mathf.Tau, float cornerSize = 0, int cornerSmoothness = 0)
    {
        Debug.Assert(GDScriptEquivalent is not null);
        color ??= Colors.White;
        return GDScriptEquivalent.New(verticesCount, size, offsetRotation, color.Value, offsetPosition, 
            width, drawnArc, cornerSize, cornerSmoothness).As<Polygon2D>();
    }

    /// <inheritdoc cref="SimplePolygon2D.GetShapeVertices(int, float, float, Vector2)"/>
    /// <param name="drawnArc">
    /// The drawn arc of the shape. It starts in the middle of the base. Positive values go clockwise and negative values counter-clockwise.
    /// </param>
    /// <param name="addCentralPoint">
    /// <paramref name="add_central_point"/> adds <paramref name="offset_rotation"/> at the end of the array. 
    /// It only has an effect if <paramref name="drawn_arc"/> is used and isn't ±<see cref="Mathf.Tau"/>.
    /// It should be set to false when using <see cref="AddHoleToPoints"/>.
    /// </param>
    public static Vector2[] GetShapeVertices(int verticesCount, float size = 1, float offsetRotation = 0, Vector2 offsetPosition = default,
       float drawnArc = Mathf.Tau, bool addCentralPoint = true)
    => _shared.Value.Call(MethodName.GetShapeVertices, verticesCount, size, offsetRotation, offsetPosition, drawnArc, addCentralPoint).AsVector2Array();
    /// <summary>
    /// WARNING: This method is not meant to be used outside the class, and will be removed in the future
    /// </summary>
    public static Vector2 QuadraticBezierInterpolate(Vector2 start, Vector2 control, Vector2 end, float t)
    => _shared.Value.Call(MethodName.QuadraticBezierInterpolate, start, control, end, t).AsVector2();
    /// <summary>Returns a modified copy of <paramref name="points"/> so that the shape it represents have rounded corners. </summary>
    /// <remarks>The method uses quadratic Bézier curves for the corners (see <see cref="QuadraticBezierInterpolate"/>).</remarks>
    /// <param name="points">The array to clone and modify</param>
    /// <param name="cornerSize">The distance along each edge to the point where the corner starts.</param>
    /// <param name="cornerSmoothness">The number of lines that make up each corner.</param>
    public static Vector2[] AddRoundedCorners(Vector2[] points, float cornerSize, int cornerSmoothness)
    => _shared.Value.Call(MethodName.AddRoundedCorners, points, cornerSize, cornerSmoothness).AsVector2Array();
    /// <summary>
    /// Appends points, which are <paramref name="holeScaler"/> times the original <paramref name="points"/>, 
    /// to a clone of <paramref name="points"/>, in reverse order from <paramref name="points"/>.
    /// </summary>
    /// <remarks>This method doesn't work properly if there is an offset applied to <paramref name="points"/>.</remarks>
    /// <param name="points">The array to clone and modify.</param>
    /// <param name="holeScaler">The multiplier applied to the duplicated points.</param>
    /// <param name="closeShape">Adds the first point to the end of <paramref cref="points"/>.</param>
    public static Vector2[] AddHoleToPoints(Vector2[] points, float holeScaler, bool closeShape = true)
    => _shared.Value.Call(MethodName.AddHoleToPoints, points, holeScaler, closeShape).AsVector2Array();

    public static implicit operator Polygon2D(RegularPolygon2D instance) => instance.Instance;
    public static explicit operator RegularPolygon2D(Polygon2D instance) => new(instance);
}
