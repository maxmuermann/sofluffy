# SO FLUFFY!

SO FLUFFY is a shell fur rendering system for Godot 4. Shell rendering involves creating multiple copies of an object's geometry, scaling each one up a little more, thus creating a series or "shells" of increasing size surrounding the object.

A shader is then used to render cross-sections of fur strands on each shell.

A good reference on how shell rendering works is this video: https://www.youtube.com/watch?v=9dr-tRQzij4

## Features

- Material-based shell generation, no geometry is duplicated. SO FLUFFY use a cascade of next_pass materials for subsequent shells and performs all geomerty operations in its vertex shader
- Control over strand growth:
    - use a density texture or noise function
    - heightmap texture for precise control over where strands can grow
    - jitter - overlay random noise for displacing strands for a more organic look, or to model things like cowlicks or other turbulence
    - thickness profile - control the thickness of strands over their length to produce finer or thicker hair, or other organic shapes like moss or fungus
    - Fur can grow along surface normals, in a fixed directio nrelative to the object, or in a fixed direction in world space, or any combination of those
- Control over appearance:
    - color gradient applied along the length of each strand, this is 


## Quick start

1. Add some geometry to your scene - any subclass of GeometryInstance3D can be used to grow fur.
2. Add a Fur node as a child of your geometry and tweak parameters to your liking.

## What is it?

