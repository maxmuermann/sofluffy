#### Flexible shell texture renderer for fur/hair/grass in Godot

### Features

- configurable number of shells
  - use next pass materials, set up and configure automatically
- base texture
- offset texture to simulate clumping, cowlicks, etc., animate for wind effects
  - could also animate for dynamic interaction, like walking through grass? Investigate later.
- vertex shader:
  - two modes: fixed direction (default up, useful for grass etc.), and normal (useful for fur and hair)
- Color (multiply those together)
  - color gradient (by height)
  - color tint
  - base color texture
- height threshold texture (for dynamic interaction, like simulating footsteps, vehicle tracks, etc.)
- Physics
  - gravity
    - strength
    - direction (default down)
  - spring model
    - min/max spring length (or fixed)
    - F
    - damping


Parameters
- shell count
- height
- base texture (noise)
  - density
  - taper
- tint color
- base color texture
- color gradient
- height threshold texture
- gravity
  - strength
  - direction
- physics
  - fixed/elastic spring flag
    - min spring length
    - max spring length
  - stiffness
  - damping
