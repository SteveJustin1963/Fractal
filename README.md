# Fractals

An eclectic collection of **interactive visualizations**, **chaotic dynamical systems**, and **mathematical art** exploring fractals, billiards, standing waves, and conceptual nanoelectronics. Each subproject demonstrates beauty, chaos, and complexity in different computational environments.

---

## fractal_explorer2 (GNU Octave / MATLAB)

Interactive GUI fractal explorer supporting **Mandelbrot**, **Julia**, **Burning Ship**, and **Tricorn** sets.

**Purpose**: Real-time exploration of classic and variant fractals with smooth zooming, panning, iteration control, and multiple quality modes.

**Why it matters**: Makes deep mathematical objects intuitive and fun to explore. Demonstrates how tiny changes in parameters produce wildly different self-similar patterns.

**How to run**:
```bash
cd fractal_explorer2
octave fractal.m                    # Full-featured interactive version (recommended)
octave run_fractal.m                # Launcher script
octave multi_fractal.m              # Multi-fractal with hot colormap
octave fractal_explorer.m           # Simpler Mandelbrot-only version
```

**Controls**:
- Drag mouse = zoom in
- Right-click = zoom out
- Arrow keys = pan
- `1–4` = switch fractal type
- `r` = reset view
- `+/-` = change max iterations
- `f/n/h` = quality (fast/normal/high)
- `q` = quit

**Supporting modules** (called internally): `compute_fractal.m`, `draw_fractal.m`, `handle_keyboard.m`, `handle_mouse.m`, `reset_view.m`, `fractal_interactive.m`

**Dependencies**: GNU Octave (free) or MATLAB.

---

## Dynamical_billiards/sinai_billiard (C)

Real-time terminal ASCII simulation of **1000 particles** in a **Sinai billiard** — a rectangle containing an 8×8 grid of circular obstacles.

**Purpose**: Visually demonstrate classical chaos: exponential divergence of trajectories (positive Lyapunov exponent), ergodicity, mixing, and the ideal-gas analogy.

**Why it matters**: Sinai's 1970 proof that convex obstacles make billiards chaotic is the mathematical foundation of statistical mechanics. This simulation makes that theorem visible: particles fill the table uniformly regardless of starting conditions.

**Features**: Elastic collisions (walls, obstacles, ball–ball), spatial grid for O(n) collision detection, random perturbations per bounce to seed divergence, ANSI-coloured particles, adjustable simulation speed, handles terminal resize.

**How to run**:
```bash
cd Dynamical_billiards/sinai_billiard
./sinai_billiard                    # Use pre-compiled binary (Linux)
# or rebuild:
gcc -O2 -Wall -Wextra -o sinai_billiard sinai_billiard.c -lm
./sinai_billiard
```

**Controls**: `↑/↓` arrows = change speed (0.05×–8×), `q` = quit.

See `SINAI_BILLIARD.md` for full physics documentation, tunable constants, and mathematical background.

---

## Dynamical_billiards/8ball (C + Z80 assembly)

Terminal-based billiards/pool game with three progressively constrained implementations, showing how the same physics can be adapted from desktop to embedded hardware.

**Variants**:
| File | Target | Physics | Display |
|---|---|---|---|
| `main.c` | Desktop | Floating-point, friction, wall bounce | ncurses, colour balls, angle/power HUD |
| `main-int-logic.c` | Desktop (no FPU) | Fixed-point (SCALE=100), 8-direction LUT | ncurses |
| `main-z80-int-logic.c` | Z80 MCU | Fixed-point (SCALE=16), 8-direction LUT | Hardware I/O ports → LED matrix |

**Why it exists**: Demonstrates how to strip floating-point math out of a physics simulation using lookup tables and integer scaling — a technique required for microcontrollers and older CPUs without an FPU. The Z80 port is compiled with SDCC.

**Build & Run**:
```bash
cd Dynamical_billiards/8ball

# Full floating-point desktop version
gcc -o 8ball main.c -lncurses -lm
./8ball

# Integer-only desktop version
gcc -o 8ball_int main-int-logic.c -lncurses
./8ball_int

# Z80 microcontroller (requires SDCC)
sdcc -mz80 main-z80-int-logic.c
# Flash the generated main-z80-int-logic.ihx to Z80 hardware
```

**Controls** (desktop): Arrows = move cue, Shift+Arrows = rotate aim angle, hold/release Space = charge and shoot, `q` = quit.

Build artifacts (`.asm`, `.ihx`, `.map`, `.lk`, `.lst`, `.noi`, `.rel`, `.sym`) from the SDCC Z80 build are included.

---

## Fractal-Transistor (C + conceptual)

ASCII art generators inspired by wave physics and snowflake geometry, plus conceptual notes on a hypothetical **"Fractansistor"** nanoelectronic device.

**Programs**:

**`Chladni.c`** — Renders **Chladni figures**: the geometric nodal patterns that appear in sand on a vibrating plate. User enters harmonic mode numbers *m* and *n*; the program evaluates `sin(m·x)·sin(n·y)` across an 80×40 grid and prints `*` everywhere except the near-zero nodes (which remain blank), reproducing the classic standing-wave geometry.

**`snow.c`** — Generates unique random **ASCII snowflakes** with 6-fold rotational symmetry. Builds randomised arm lengths and branching sub-arms along one axis, then rotates each point through all six symmetry positions to produce a complete crystal on an 80×80 grid. Every run produces a different flake.

**Why it exists**: Explores the visual and mathematical connections between standing waves (Chladni), chaotic electron scattering (Sinai), and natural fractal growth (snowflakes) — all themes in the conceptual Fractansistor design.

**`README2.md`** — Conceptual design notes for a **Fractansistor**: a hypothetical nanoelectronic device in which cavity shape (square → Sinai geometry) controls whether electron scattering is regular or chaotic, producing controllable fractal conductance patterns. Discusses EBL/ALD nanofabrication, applications in quantum computing, ultra-sensitive sensors, and low-power electronics. Inspired by Richard Taylor's work on fractal nanoelectronics.

**Included PDFs**: Taylor's paper on fractals in nanoelectronics/solar cells; Mathematica Stack Exchange discussion on random snowflake generation.

**How to run**:
```bash
cd Fractal-Transistor

gcc -o chladni Chladni.c -lm
./chladni
# Enter mode numbers at the prompt, e.g.: 2 3

gcc -o snow snow.c -lm
./snow

# Pre-compiled binaries also provided: "Chladni mint" and "snow mint"
```

---

## Dependencies

| Subproject | Language | Tools / Libraries | Notes |
|---|---|---|---|
| fractal_explorer2 | GNU Octave / MATLAB | `octave` | Free at octave.org |
| sinai_billiard | C | `gcc`, `libm` | Single file, POSIX only |
| 8ball desktop | C + ncurses | `gcc`, `libncurses`, `libm` | Integer version needs no FPU |
| 8ball Z80 | C (SDCC) | `sdcc` | Targets embedded LED matrix |
| Fractal-Transistor | C | `gcc`, `libm` | No external libs |

All projects are lightweight, compile from a single command, and run on modest hardware.
