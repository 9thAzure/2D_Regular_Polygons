# Complex Shape Creation

![Regular Polygon 2D icon](/addons/simplified_shape_creation/regular_polygon_2d/regular_polygon_2d.svg)

![GitHub Release](https://img.shields.io/github/v/release/9thAzure/simplified_shape_creation)
![GitHub License](https://img.shields.io/github/license/9thAzure/simplified_shape_creation)
![GitHub Issues or Pull Requests](https://img.shields.io/github/issues/9thAzure/simplified_shape_creation)
![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/9thAzure/simplified_shape_creation/total)

An addon for the  [Godot Engine](https://godotengine.org/) which adds several functions for creating and modifying shapes,
and a few nodes that uses those functions for creating visuals or for creating collision shapes.

These functions and nodes are written in GDScript to make them universally compatible.
They are exposed to C# via wrapper classes in the `ComplexShapeCreation` namespace. 

> [!NOTE]
> Most of the functions for modifying shapes have a slightly different signature in C# compared to GDScript.
> Since they rely on the shape being passed by reference, something that isn't maintained during interop,
> the C# equivalents returns the shape instead.

## Installation

There are 2 ways to download the plugin:

### Godot Asset Library download
1. In the Godot editor, go to the **AssetLib** tab.
2. Search for the "2D Regular Polygons" addon.
3. Select and click `install` (and subsequent `install`s.).

### Zip-file download.
1. Go to the **Releases** page.
2. Download the zip file in **Assets** section of the wanted release.
3. Extract the `simplified_shape_creation` folder from the zip file and put it in the `addons` folder in the target project.
    Create the `addons` folder if it does not exist yet project.

***

Once downloaded, the addon can be enabled in `Project` > `Project Settings` > `Plugins`.

## Quick Tutorial

This is a short introduction to how the addon works.

More in depth documentation can be found the [wiki](https://github.com/9thAzure/simplified_shape_creation/wiki)
or the documentation within the scripts, which is accessible within Godot editor's **Script** tab.

### Nodes

Currently, there are 4 nodes:
- [RegularPolygon2D] < `Polygon2D` - General purpose node for drawing shapes. 
- [SimplePolygon2D] < `Node2D` - counterpart to [RegularPolygon2D] that only draws simpler shapes.
- [StarPolygon2D] < `Polygon2D` - Version of [RegularPolygon2D] for drawing stars.
- [RegularCollisionPolygon2D] < `CollisionShape2D` - Node for creating both regular and star collision shapes.

### Properties

Every node share similar properties with similar effects.
They also generally do the same thing if they are named as a parameter in one of the functions used for creating shapes.

- `vertices_count` - Determines the kind of shape used. Usually, a value of `1` = circle and `2` = line.
- `size` - Determines the size of the shape, from the center to the outer vertices.
- `offset_rotation`- Determines the rotation of the created shape.
- `width` - Determines the thickness of the shape. Usually, values smaller than `0` or greater than `size` creates the full shape.
- `drawn_arc` - Defines the arc where the shape is created, leaving a gap where the arc ends.
- `corner_size` - Enables and controls the size of rounded corners.
- `corner_smoothness` - Determines how many lines make up a rounded corner. Nodes replace a value of `0` with their own value.

### Functions

Currently, functions used for creating shapes are split across the multiple nodes added.
Most of them are in [RegularPolygon2D].
Some exceptions are:

- a simplified version of `get_shape_vertices` is in [SimplePolygon2D].
- `widen_polyline` and `widen_multiline` are in [RegularCollisionPolygon2D].
- `get_star_vertices` is in [StarPolygon2D].

The `get_*` functions create shapes and returns a new `PackedVector2Array`.
All other functions **modify** the array passed in as the argument.

## License

This addon is available under the [MIT](https://mit-license.org/) license,
which is in the addon's [folder](/addons/simplified_shape_creation/LICENSE.txt).
A copy is available in the root [folder](/LICENSE.md).

## Plugins / Packages Used

This addon uses several external packages for unit testing:
- [GUT (Godot Unit Test)](https://github.com/bitwes/Gut) (Godot addon)
- [Chickensoft.GoDotTest](https://github.com/chickensoft-games/GoDotTest) (Nuget package)
- [Shouldly](https://github.com/shouldly/shouldly) (Nuget package)

[RegularPolygon2D]: (/addons/simplified_shape_creation/regular_polygon_2d/regular_polygon_2d.gd)
[SimplePolygon2D]: (/addons/simplified_shape_creation/simple_polygon_2d/simple_polygon_2d.gd)
[RegularCollisionPolygon2D]: (/addons/simplified_shape_creation/regular_collision_polygon_2d/regular_collision_polygon_2d.gd)
[StarPolygon2D]: (/addons/simplified_shape_creation/star_polygon_2d/star_polygon_2d.gd)
