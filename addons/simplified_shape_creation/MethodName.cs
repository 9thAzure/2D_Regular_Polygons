using System;
using Godot;

namespace ComplexShapeCreation.MemberNames;

public static class MethodName
{
    public static readonly StringName GetShapeVertices = new("get_shape_vertices");
    [Obsolete("Method name has changed, use 'Regenerate' instead.", false)]
    public static readonly StringName RegeneratePolygon = new("regenerate_polygon");
    public static readonly StringName UsesPolygonMember = new("uses_polygon_member");
    public static readonly StringName GetSideLength = new("get_side_length");
    /// <remarks>The signature is slightly altered from its GDScript counterpart. An array of <see cref="Vector2"/> is returned instead, and the input array isn't modified.</remarks>
    public static readonly StringName AddRoundedCorners = new("_add_rounded_corners_result");
    public static readonly StringName QuadraticBezierInterpolate = new("quadratic_bezier_interpolate");
    /// <inheritdoc cref="AddRoundedCorners"/>
    public static readonly StringName AddHoleToPoints = new("_add_hole_to_points_result");
    public static readonly StringName QueueRegenerate = new("queue_regenerate");
    public static readonly StringName Regenerate = new("regenerate");
    public static readonly StringName SetPointAngle = new("set_point_angle");
    public static readonly StringName GetStarVertices = new("get_star_vertices");
    public static readonly StringName WidenPolyline = new("_widen_polyline_result");
    public static readonly StringName WidenMultiline = new("_widen_multiline_result");
    public static readonly StringName ApplyTransformation = new("apply_transformation");
}