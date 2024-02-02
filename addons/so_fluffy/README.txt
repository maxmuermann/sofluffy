# SO FLUFFY!

SO FLUFFY is a shell fur rendering system for Godot 4. Shell rendering involves creating multiple copies of an object's geometry, scaling each one up a little more, thus creating a series or "shells" of increasing size surrounding the object.

A shader is then used to render cross-sections of fur strands on each shell.

A good reference on how shell rendering works is this video: https://www.youtube.com/watch?v=9dr-tRQzij4

# Features

- Performance
    - Material-based shell generation, no geometry is duplicated. SO FLUFFY use a cascade of next_pass materials for subsequent shells and performs all geomerty operations in its vertex shader
    - dynamic LODs through disabling shells based on camera distance
- Control over strand growth:
    - fur density (strand per area)
    - sparseness (length distribution of strands)
    - heightmap texture for precise control over where strands can grow
    - turbulence - overlay noise for displacing strands for a more organic look, or to model things like cowlicks or other turbulence
    - thickness profile - control the thickness of strands over their length to produce finer or thicker hair, or other organic shapes like moss or fungus
    - Fur can grow along surface normals, in a fixed direction relative to the object, or in a fixed direction in world space, or any combination of those
- Control over appearance:
    - color gradient applied along the length of each strand, usefule for simulating self-shadowing or other effects (see demos)
    - albedo color - solid color or texture
    - emission - solid color or texture
- Physics
    - linear spring physics for satisfying bounciness on linear movement
    - rotational spring physics for satisfying swishiness on rotation
    - rotational physics effects can be scaled independently

# Quick start

1. Add some geometry to your scene - any subclass of GeometryInstance3D can be used to grow fur.
2. Add a Fur node as a child of your geometry and tweak parameters to your liking.

## How does it work?


# Caveats

Shell rendering is not exactly cheap. The major driver of rendering cost is the number of shells - the cost of rendering is O(N). Some features incur additional performance cost - any time a texture is used (height map, turbulence, albedo, emission, thickness curve, height gradient), more texture samples are required, which places extra load on the GPU.

### Noise and other artefacts

Because strands are rendered as a series of (infinitely) thin shells, viewing fur side-on causes a lot of visual noise. Two common approaches to solve this issues are to render textured "fins" perpendicular to the camera, or to perform some sort of post-process blurring in screen space.

Fin textures generally need to be hand-crafted to match the look of the fur being rendered; this addon does not intend to provide a fin rendering implementation.

SO FLUFFY also does not currently provide any post-processing to reduce noise, this may change in the future.

## LODs

SO FLUFFY comes with a simple dynamic LOD system. Since performance is mainly dependent on the number of shells being rendered, reducing the number of shells for far-awway objets can help control the performance load.

LODs are generated dynamically by dropping shells based on distance. This is done per-object, so if you're rendering terrain, it is advisable to break up the terrain into a number of separate, sufficiently small tiles to take advantage of this feature.

# Usage

## Setup

SO FLUFFY can be applied to any geometry in Godot that inherits frm GeometryNode3D. Simply add a "Fur" node as a child of the geometry you want to grow fur on.

Parameters of the Fur node are described below, grouped by category.

## General

### Preview in Editor

For configuring fur parameters, it is very handy to be able to preview the fur in the editor. However, since fur rendering comes at a performance cost, it is often advisable to turn off the editor preview. Enabling this feature will clear and re-generate all shells from scratch.

This setting does not affect the runtime behaviour.

## Target

By default, it uses the Geometry Node's Material Overlay to render fur.

If attached to a MeshInstance3D, you can optionally configure the fur system to render on one or more surfaces instead. To do so, enable the "Surface" toggle under the

## Shape

### Number of shells

The maximum number of shells used to render the fur. More shells are more expensive to render. For fur that is intended to be sen close up, 128 or even 256 shells may be appropriate. For far-away fur, or things like distant vegetation, values as low as 

LOD settings affect how many shells are actually rendered; this is the upper limit.

## Appearance

## Physics

## LOD

Since removing shells will have the effect of visually "thinning out" the fur, the LOD system can dynamically adjust the thickness of strands to maintain a consistent visual appearance between LOD levels.