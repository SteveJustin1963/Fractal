# Sinai Billiard Gas — Terminal ASCII Simulation

A real-time ASCII simulation of a chaotic gas system rooted in the mathematics of Sinai billiards. One thousand particles bounce elastically inside a rectangular table studded with a regular 8×8 grid of circular obstacles, colliding with each other and every surface. A tiny random angle perturbation on every bounce drives exponential trajectory divergence — the hallmark of classical chaos.

---

## Plain Language Summary

Sinai Billiard Geometry is a concept in mathematics and physics related to the study of chaotic systems. It was named after the Russian mathematician Yakov Sinai, who has made significant contributions to this field.

In its simplest form, the Sinai billiard can be visualised as an idealised rectangular table with one or more circular obstacles inside it. Imagine throwing a ball onto such a surface and letting it bounce off the walls and the obstacles until it eventually leaves the table. The path of the ball is called a trajectory.

Sinai's work on billiards was instrumental in understanding chaos theory, which is a branch of mathematics that studies systems where small changes can result in significant outcomes. In the context of billiard geometry, this translates to the complex paths the ball takes as it bounces off obstacles and walls, creating intricate patterns.

In terms of geometric properties, Sinai billiard geometry often involves studying the distribution of these trajectories over time. This includes analysing quantities like the number of times a trajectory intersects with an obstacle or wall, how fast the trajectory spreads out in space, and how it interacts with other trajectories.

The study of Sinai billiard geometry has applications not just in mathematics but also in physics, particularly in areas such as fluid dynamics, statistical mechanics, and quantum chaos.

---

## Background: What Is a Sinai Billiard?

A classical billiard is a point particle moving inside a bounded region, reflecting off the boundary. If the region is a plain rectangle and there are no obstacles, the system is **integrable**: trajectories are predictable and often periodic. Two particles starting at nearly identical positions and angles stay close together forever.

In 1970, Yakov Sinai proved that inserting one or more **convex obstacles** into the interior changes everything. The geometry of circular obstacles creates a **defocusing** effect — trajectories that are close before hitting an obstacle are spread apart after the bounce. This causes nearby trajectories to diverge **exponentially** over time (positive Lyapunov exponent). The system becomes:

- **Ergodic** — a single trajectory visits every region of the table with equal frequency over infinite time.
- **Mixing** — any two regions become statistically independent given enough time.
- **K-system** — it has positive entropy in the sense of Kolmogorov.

These are the same statistical properties that underpin thermodynamics. A Sinai billiard with many particles is therefore a rigorous mathematical model of an **ideal gas**.

---

## The Simulation

### Table Layout

```
+-------- Sinai Gas | 1000 balls | speed 1.00x | ↑↓:speed | q:quit --------+
|   @  @                  @        @@         @        @         @@         |
| @@@@O)@ @@@  @(O@@@@  @ (O)@@@@  @(O@@@@@ @(O)  @@@  @(O@ @@@@  @@@O)@  |
|    (O)       (O)       (O)       (O)       (O)       (O)       (O)        |
...
+----------------------------------------------------------------------------+
```

- **Border** (`+`, `-`, `|`): the four reflecting walls of the table.
- **Obstacles** (`(O)`): 64 circular scatterers in an 8×8 grid, evenly distributed across the play area. Each is rendered as three characters; the collision boundary is a circle in aspect-corrected physical space.
- **Balls** (`@`): 1000 particles, coloured using seven bright ANSI colours cycling by index.
- **Status bar**: embedded in the top border; shows live ball count and speed multiplier.

---

## Physics Rules

### 1. Free Motion

Between collisions, every ball moves in a straight line at constant speed. There is no gravity, no friction, and no energy dissipation. Speed is conserved at `BASE_SPEED = 0.45` character-columns per frame, multiplied by the current speed setting.

```
x(t+dt) = x(t) + vx * dt
y(t+dt) = y(t) + vy * dt
```

### 2. Wall Reflection

When a ball reaches the inner edge of any border wall, the perpendicular velocity component is negated. A ball hitting the left or right wall has `vx` flipped; top or bottom flips `vy`. The ball is clamped to the wall position so it cannot escape. After each wall bounce a small random perturbation is applied (see §5).

```
if x ≤ 1.5  → x = 1.5,   vx = +|vx|   (bounce right)
if x ≥ W-1.5 → x = W-1.5, vx = -|vx|  (bounce left)
if y ≤ 1.5  → y = 1.5,   vy = +|vy|   (bounce down)
if y ≥ H-1.5 → y = H-1.5, vy = -|vy|  (bounce up)
```

### 3. Obstacle Reflection (Aspect-Ratio Corrected)

Terminal characters are approximately **2.1× taller than they are wide**. If distances were computed in raw character coordinates, circular obstacles would behave like vertical ellipses — balls would pass through them too easily from above or below. To compensate, the y-component of every distance calculation is scaled by `ASPECT = 2.1` before comparison, placing the physics in a square-pixel "physical space".

Given obstacle centre `(cx, cy)` and ball position `(bx, by)`:

```
dx = bx - cx
dy = (by - cy) * ASPECT          ← y scaled to physical space

d  = sqrt(dx² + dy²)             ← distance in physical space
md = OBS_R + BALL_R = 2.0        ← collision threshold
```

If `d < md`, a collision is resolved:

1. Compute the outward surface normal `n = (dx/d, dy/d)` in physical space.
2. Convert the ball's velocity to physical space: `pvy = vy * ASPECT`.
3. Reflect: `v' = v - 2(v·n)n` in physical space.
4. Convert reflected velocity back to character space: `vy' = pvy' / ASPECT`.
5. Push the ball out of the obstacle along the normal by the overlap amount.
6. Apply perturbation.

This gives geometrically correct elastic reflection off a true circle, regardless of the terminal's aspect ratio.

### 4. Ball–Ball Elastic Collision

Balls collide with each other as rigid discs of equal mass. Collision is detected in character space when the distance between two balls falls below `COLL_DIST = 1.0` character column.

Given balls `i` and `j`:

```
dx = xi - xj
dy = yi - yj
d  = sqrt(dx² + dy²)
n  = (dx/d, dy/d)               ← collision normal (char space)
dv = (vi - vj) · n              ← relative normal velocity
```

If `dv < 0` (balls are approaching), exchange the normal components:

```
vi' = vi - dv * n
vj' = vj + dv * n
```

The tangential components are unchanged — a grazing hit barely deflects; a head-on hit fully reverses. Momentum and kinetic energy are both conserved. After the velocity update the balls are pushed apart by `(COLL_DIST - d) × 0.51` to eliminate overlap, then both receive a perturbation.

### 5. Perturbation (Surface Roughness)

After **every** collision — wall, obstacle, or ball–ball — the velocity vector is rotated by a uniformly-distributed random angle in `[-PERTURB_MAX, +PERTURB_MAX]` (default ±0.10 rad ≈ ±5.7°):

```
θ ~ Uniform(-0.10, +0.10)
vx' = vx cosθ - vy sinθ
vy' = vx sinθ + vy cosθ
```

This is a pure rotation, so **speed is exactly preserved**. The energy of the system does not change. What changes is direction — slightly. This models real-world surface imperfections and quantum uncertainty. Its effect accumulates: two trajectories that were identical before a bounce will diverge by 0.10 rad per collision, leading to exponential separation. Increasing `PERTURB_MAX` makes the system mix faster; setting it to zero recovers the idealised Sinai billiard.

### 6. Sub-Step Integration

At speed multipliers greater than 1×, the simulation advances the physics in multiple sub-steps per rendered frame rather than taking one large step. If `g_speed = S`, the number of sub-steps is `ceil(S)` and each sub-step advances time by `dt = S / ceil(S)`. This prevents fast balls from tunnelling through obstacles (skipping collision detection entirely) at high speed settings.

```
steps = ceil(g_speed)
dt    = g_speed / steps
for each sub-step:
    move all balls by dt
    resolve walls and obstacles
    resolve ball-ball collisions
```

---

## Spatial Grid (Collision Acceleration)

Checking all 1000×999/2 ≈ 500 000 ball pairs every sub-step would be slow at high speeds. Instead, the table is divided into a grid of `CELL_SZ = 3` character cells. Each ball is inserted into its cell via a linked list (`ghead` / `gnext` arrays). Ball–ball collision checks are restricted to each ball's 3×3 neighbourhood of cells.

For a typical 80×24 terminal this yields roughly 27×8 = 216 cells with ~4.6 balls per cell on average, reducing expected pair checks from 500 000 to about 4.6² × 9 / 2 ≈ 95 pairs per ball — a ~5 000× speedup. The grid is rebuilt from scratch every sub-step (cost is O(n), negligible).

Each ordered pair `(i, j)` is checked exactly once by only considering neighbours with index `j < i` when processing ball `i`.

---

## Rendering

Each frame:

1. A character-and-colour buffer (`scr[]`, `col[]`) is cleared to spaces.
2. The border characters are written into the buffer edges.
3. The status line is stamped into the centre of the top border row.
4. Each obstacle is drawn as `(O)` at its grid-snapped centre.
5. Each ball is drawn as `@` at its rounded position with its ANSI colour. Balls drawn later overwrite earlier ones at the same cell (no compositing).
6. The cursor is moved to the top-left with `\033[H` and the buffer is emitted in a single buffered write via a 128 KB `setvbuf` buffer, flushed once per frame. Coloured characters emit `\033[<n>m@\033[0m`; plain characters use `putchar`.

The terminal is put into **raw mode** (no echo, non-canonical) with non-blocking stdin so key presses are read without stalling the render loop. The cursor is hidden during the simulation and restored on exit. `SIGWINCH` (terminal resize) causes the table and obstacle grid to be recalculated and the screen to be cleared on the next frame.

---

## Build & Run

```bash
# Build
gcc -O2 -Wall -Wextra -o sinai_billiard sinai_billiard.c -lm

# Run
./sinai_billiard
```

### Controls

| Key | Action |
|-----|--------|
| `↑` | Increase speed (×1.25 per press, max 8×) |
| `↓` | Decrease speed (÷1.25 per press, min 0.05×) |
| `q` / `Q` | Quit |
| `Ctrl+C` | Quit (SIGINT) |

The terminal is automatically restored to its original state on exit via `atexit`.

---

## Tunable Constants

All physics parameters are `#define` constants at the top of `sinai_billiard.c`. Recompile after changing any of them.

| Constant | Default | Effect |
|----------|---------|--------|
| `NUM_BALLS` | 1000 | Number of particles |
| `GRID_R` / `GRID_C` | 8 / 8 | Obstacle grid dimensions |
| `ASPECT` | 2.1 | Terminal character aspect ratio (height/width) |
| `OBS_R` | 1.5 | Obstacle collision radius in physical units |
| `BALL_R` | 0.5 | Ball radius used for obstacle collision |
| `COLL_DIST` | 1.0 | Ball–ball collision distance in character columns |
| `PERTURB_MAX` | 0.10 | Maximum random angle perturbation per bounce (radians) |
| `BASE_SPEED` | 0.45 | Ball speed in character columns per frame |
| `MIN_SPEED` | 0.05 | Minimum speed multiplier |
| `MAX_SPEED` | 8.0 | Maximum speed multiplier |
| `SPEED_STEP` | 1.25 | Multiplier applied per arrow key press |
| `FRAME_US` | 35 000 | Frame delay in microseconds (~28 fps) |
| `CELL_SZ` | 3 | Spatial grid cell size in character columns |

Setting `PERTURB_MAX = 0` gives a near-ideal Sinai billiard (the only remaining source of non-determinism is floating-point rounding). Setting it high (e.g. 0.5 rad) causes extremely rapid mixing but makes individual trajectories look nearly random. The range 0.05–0.15 rad gives visually satisfying gas behaviour while preserving clearly directed motion between bounces.

---

## Mathematical Notes

### Why Circular Obstacles?

Flat walls produce specular reflection — angle in equals angle out exactly. Two trajectories that differ by a small angle before hitting a flat wall differ by the same small angle after. Separation grows at most linearly.

A **convex** obstacle defocuses: two rays that both hit the curved surface leave at angles that are further apart than they arrived. Separation grows geometrically with each obstacle hit. This is the mechanism Sinai identified: a grid of circular obstacles guarantees that almost every trajectory hits an obstacle in finite time, so the defocusing accumulates without bound. The rate of divergence is quantified by the **Lyapunov exponent** λ > 0.

### Ergodicity and the Gas Analogy

In statistical mechanics, an ideal gas is assumed to be ergodic: time averages equal ensemble averages. Sinai's proof provides a rigorous dynamical system — the billiard — where this can be verified mathematically. The simulation makes this visible: starting from any initial configuration, the `@` particles fill the available space uniformly after a short mixing time, regardless of where they began.

The perturbation term accelerates this but is not required. Even without it, the hyperbolic geometry of the obstacle collisions ensures exponential mixing. With it, the system also models **diffusion**: a cluster of identically positioned particles (if you could create one) would spread to fill the table in time proportional to `1/PERTURB_MAX`.

### Energy Conservation

Because every collision is elastic and every perturbation is a rotation:

- Individual ball speeds are exactly preserved through every interaction.
- The total kinetic energy of the system is constant.
- The system is **microcanonical** — it evolves on a constant-energy surface in phase space.

What is not conserved: momentum (the walls act as a reservoir of momentum), and individual ball identities (balls pass through each other in the render but not in the physics — each `@` is a distinct particle).

---

## File Structure

```
sinai_billiard.c      source — single file, no dependencies beyond libc and libm
sinai_billiard        compiled binary (after build)
SINAI_BILLIARD.md     this document
```

**Dependencies:** C99 compiler, POSIX environment (`ioctl`, `termios`, `usleep`), `libm`. No external libraries. Tested on Linux with GCC.
