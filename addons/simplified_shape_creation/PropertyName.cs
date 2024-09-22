using System;
using Godot;

namespace ComplexShapeCreation.MemberNames;

public static class PropertyName
{
    public static readonly StringName VerticesCount = new("vertices_count");
    public static readonly StringName Size = new("size");
    public static readonly StringName OffsetRotationDegrees = new("offset_rotation_degrees");
    public static readonly StringName OffsetRotation = new("offset_rotation");
    public static readonly StringName Color = new("color");
    [Obsolete("Property name has been replaced, use 'Offset' instead.", false)]
    public static readonly StringName OffsetPosition = new("offset_position");
    public static readonly StringName Offset = new("offset");
    public static readonly StringName Width = new("width");
    public static readonly StringName DrawnArcDegrees = new("drawn_arc_degrees");
    public static readonly StringName DrawnArc = new("drawn_arc");
    public static readonly StringName CornerSize = new("corner_size");
    public static readonly StringName CornerSmoothness = new("corner_smoothness");
    [Obsolete("Property name has been replaced, use 'VerticesCount' instead.", false)]
    public static readonly StringName PointCount = new("vertices_count");
    public static readonly StringName InnerSize = new("inner_size");
}