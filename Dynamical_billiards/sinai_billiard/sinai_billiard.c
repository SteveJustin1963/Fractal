/*
 * Sinai Billiard Gas — Terminal ASCII Simulation
 *
 * 1000 @ balls with elastic collisions against walls, 8×8 circular
 * obstacles, and each other.  A small random angle perturbation on
 * every bounce (surface roughness) drives chaotic, gas-like mixing.
 *
 * Build: gcc -O2 -Wall -Wextra -o sinai_billiard sinai_billiard.c -lm
 * Run:   ./sinai_billiard     (↑↓ = speed, q = quit)
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <termios.h>
#include <time.h>
#include <signal.h>

#define NUM_BALLS    1000
#define GRID_R          8
#define GRID_C          8
#define ASPECT          2.1     /* terminal char height / width ratio        */
#define OBS_R           1.5     /* obstacle collision radius (physical units) */
#define BALL_R          0.5     /* ball radius for obstacle detection         */
#define COLL_DIST       1.0     /* ball-ball collision distance (char space)  */
#define PERTURB_MAX     0.10    /* max random angle added per bounce (rad)    */
#define BASE_SPEED      0.45    /* base ball speed (chars/frame)              */
#define MIN_SPEED       0.05
#define MAX_SPEED       8.0
#define SPEED_STEP      1.25
#define FRAME_US       35000
#define MAX_BUF    (512*256)

/* Spatial grid — avoids O(n²) ball-ball checks */
#define CELL_SZ  3
#define MAX_GW   (512/CELL_SZ + 2)
#define MAX_GH   (256/CELL_SZ + 2)

static int W, H;
static volatile int g_running = 1;
static volatile int g_resized = 0;
static double g_speed = 1.0;
static struct termios g_orig_termios;

typedef struct { double x, y, vx, vy; int ansi; } Ball;
typedef struct { double cx, cy; } Obs;

static Ball balls[NUM_BALLS];
static Obs  obs_arr[GRID_R * GRID_C];
static char scr[MAX_BUF];
static int  col[MAX_BUF];

static int ghead[MAX_GW * MAX_GH];
static int gnext[NUM_BALLS];
static int gw, gh;

/* ── terminal ─────────────────────────────────────────────────────────── */

static void restore_term(void) { tcsetattr(STDIN_FILENO, TCSAFLUSH, &g_orig_termios); }

static void raw_mode(void) {
    struct termios raw;
    tcgetattr(STDIN_FILENO, &g_orig_termios);
    atexit(restore_term);
    raw = g_orig_termios;
    raw.c_lflag &= ~(unsigned)(ECHO | ICANON);
    raw.c_cc[VMIN] = 0; raw.c_cc[VTIME] = 0;
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw);
    fcntl(STDIN_FILENO, F_SETFL, O_NONBLOCK);
}

static void on_sigint  (int s) { (void)s; g_running = 0; }
static void on_sigwinch(int s) { (void)s; g_resized  = 1; }

/* ── size / init ──────────────────────────────────────────────────────── */

static void get_term_size(void) {
    struct winsize ws = {0};
    ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws);
    W = (ws.ws_col > 8) ? (int)ws.ws_col : 80;
    H = (ws.ws_row > 4) ? (int)ws.ws_row : 24;
    if (W * H > MAX_BUF) { W = 80; H = 24; }
}

static void place_obstacles(void) {
    double sx = (double)(W - 2) / GRID_C;
    double sy = (double)(H - 2) / GRID_R;
    for (int r = 0; r < GRID_R; r++)
        for (int c = 0; c < GRID_C; c++) {
            obs_arr[r * GRID_C + c].cx = 1.0 + sx * (c + 0.5);
            obs_arr[r * GRID_C + c].cy = 1.0 + sy * (r + 0.5);
        }
}

static void init(void) {
    srand((unsigned)time(NULL));
    place_obstacles();
    static const int palette[] = {91, 92, 93, 94, 95, 96, 97};
    const int npal = (int)(sizeof palette / sizeof palette[0]);
    for (int i = 0; i < NUM_BALLS; i++) {
        balls[i].ansi = palette[i % npal];
        balls[i].x    = 2.0 + (rand() % (W - 4));
        balls[i].y    = 2.0 + (rand() % (H - 4));
        double angle  = (rand() % 360) * M_PI / 180.0;
        balls[i].vx   = BASE_SPEED * cos(angle);
        balls[i].vy   = BASE_SPEED * sin(angle) / ASPECT;
    }
}

/* ── physics ──────────────────────────────────────────────────────────── */

/* Rotate velocity by a tiny random angle — models surface roughness.
   Preserves speed so the system stays approximately thermalised. */
static void perturb(Ball *b) {
    double a  = ((rand() & 0xFFFF) - 32768) * (PERTURB_MAX / 32768.0);
    double ca = cos(a), sa = sin(a);
    double vx = b->vx * ca - b->vy * sa;
    double vy = b->vx * sa + b->vy * ca;
    b->vx = vx; b->vy = vy;
}

/* Elastic reflection off a circular obstacle (aspect-ratio-corrected) */
static void resolve_obs(Ball *b, const Obs *o) {
    double dx = b->x - o->cx;
    double dy = (b->y - o->cy) * ASPECT;
    double d2 = dx*dx + dy*dy;
    double md = OBS_R + BALL_R;
    if (d2 >= md * md) return;
    if (d2 < 1e-10)   { b->vx = -b->vx; b->vy = -b->vy; perturb(b); return; }

    double d   = sqrt(d2);
    double nx  = dx/d, ny = dy/d;
    double pvx = b->vx, pvy = b->vy * ASPECT;
    double dot = pvx*nx + pvy*ny;
    pvx -= 2.0*dot*nx; pvy -= 2.0*dot*ny;
    b->vx = pvx; b->vy = pvy / ASPECT;
    b->x += nx * (md - d);
    b->y += ny * (md - d) / ASPECT;
    perturb(b);
}

/* Elastic ball-ball collision in character space.
   Called only for pairs within grid-neighbour cells (guaranteed i > j). */
static void collide_pair(int i, int j) {
    double dx = balls[i].x - balls[j].x;
    double dy = balls[i].y - balls[j].y;
    double d2 = dx*dx + dy*dy;
    if (d2 >= COLL_DIST * COLL_DIST || d2 < 1e-10) return;

    double d   = sqrt(d2);
    double nx  = dx/d, ny = dy/d;

    /* Relative normal velocity — skip if already separating */
    double dv = (balls[i].vx - balls[j].vx) * nx
              + (balls[i].vy - balls[j].vy) * ny;
    if (dv >= 0.0) return;

    /* Equal-mass elastic: exchange normal components */
    balls[i].vx -= dv * nx;  balls[i].vy -= dv * ny;
    balls[j].vx += dv * nx;  balls[j].vy += dv * ny;

    /* Push balls apart so they no longer overlap */
    double ov = (COLL_DIST - d) * 0.51;
    balls[i].x += nx * ov;  balls[i].y += ny * ov;
    balls[j].x -= nx * ov;  balls[j].y -= ny * ov;

    perturb(&balls[i]);
    perturb(&balls[j]);
}

/* Move one ball, bounce off walls, resolve obstacle hits */
static void update_one(Ball *b, double dt) {
    b->x += b->vx * dt;
    b->y += b->vy * dt;

    if (b->x <= 1.5)   { b->x = 1.5;   b->vx =  fabs(b->vx); perturb(b); }
    if (b->x >= W-1.5) { b->x = W-1.5; b->vx = -fabs(b->vx); perturb(b); }
    if (b->y <= 1.5)   { b->y = 1.5;   b->vy =  fabs(b->vy); perturb(b); }
    if (b->y >= H-1.5) { b->y = H-1.5; b->vy = -fabs(b->vy); perturb(b); }

    for (int j = 0; j < GRID_R * GRID_C; j++)
        resolve_obs(b, &obs_arr[j]);
}

/* Build spatial grid, then check each pair exactly once (j < i). */
static void collide_all_balls(void) {
    gw = (W + CELL_SZ - 1) / CELL_SZ;
    gh = (H + CELL_SZ - 1) / CELL_SZ;
    memset(ghead, -1, (size_t)(gw * gh) * sizeof(int));

    for (int i = 0; i < NUM_BALLS; i++) {
        int cx = (int)(balls[i].x) / CELL_SZ;
        int cy = (int)(balls[i].y) / CELL_SZ;
        if (cx < 0) cx = 0; else if (cx >= gw) cx = gw-1;
        if (cy < 0) cy = 0; else if (cy >= gh) cy = gh-1;
        int cell = cy * gw + cx;
        gnext[i]    = ghead[cell];
        ghead[cell] = i;
    }

    for (int i = 0; i < NUM_BALLS; i++) {
        int cx = (int)(balls[i].x) / CELL_SZ;
        int cy = (int)(balls[i].y) / CELL_SZ;
        if (cx < 0) cx = 0; else if (cx >= gw) cx = gw-1;
        if (cy < 0) cy = 0; else if (cy >= gh) cy = gh-1;

        for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
                int nx = cx+dx, ny = cy+dy;
                if (nx < 0 || nx >= gw || ny < 0 || ny >= gh) continue;
                for (int j = ghead[ny*gw+nx]; j != -1; j = gnext[j]) {
                    if (j >= i) continue;   /* each pair checked once */
                    collide_pair(i, j);
                }
            }
        }
    }
}

static void update(void) {
    int    steps = (g_speed > 1.0) ? (int)ceil(g_speed) : 1;
    double dt    = g_speed / steps;
    for (int s = 0; s < steps; s++) {
        for (int i = 0; i < NUM_BALLS; i++)
            update_one(&balls[i], dt);
        collide_all_balls();
    }
}

/* ── input ────────────────────────────────────────────────────────────── */

static void handle_input(void) {
    char c;
    while (read(STDIN_FILENO, &c, 1) == 1) {
        if (c == 'q' || c == 'Q') { g_running = 0; return; }
        if (c == '\033') {
            char seq[2] = {0, 0};
            if (read(STDIN_FILENO, &seq[0], 1) < 1 ||
                read(STDIN_FILENO, &seq[1], 1) < 1) continue;
            if (seq[0] == '[') {
                if (seq[1] == 'A') { g_speed *= SPEED_STEP; if (g_speed > MAX_SPEED) g_speed = MAX_SPEED; }
                if (seq[1] == 'B') { g_speed /= SPEED_STEP; if (g_speed < MIN_SPEED) g_speed = MIN_SPEED; }
            }
        }
    }
}

/* ── render ───────────────────────────────────────────────────────────── */

static void put_px(int x, int y, char c, int clr) {
    if (x < 0 || x >= W || y < 0 || y >= H) return;
    scr[y*W+x] = c; col[y*W+x] = clr;
}

static void render(void) {
    int sz = W * H;
    memset(scr, ' ', (size_t)sz);
    memset(col,  0,  (size_t)sz * sizeof(int));

    for (int x = 0; x < W; x++) { scr[x] = '-'; scr[(H-1)*W+x] = '-'; }
    for (int y = 0; y < H; y++) { scr[y*W] = '|'; scr[y*W+W-1] = '|'; }
    scr[0] = scr[W-1] = scr[(H-1)*W] = scr[(H-1)*W+W-1] = '+';

    char status[128];
    int n = snprintf(status, sizeof status,
                     " Sinai Gas | %d balls | speed %.2fx | \xe2\x86\x91\xe2\x86\x93:speed | q:quit ",
                     NUM_BALLS, g_speed);
    int sx = (W - n) / 2;
    if (sx < 1) sx = 1;
    for (int k = 0; k < n && sx+k < W-1; k++) scr[sx+k] = status[k];

    for (int j = 0; j < GRID_R * GRID_C; j++) {
        int cx = (int)round(obs_arr[j].cx);
        int cy = (int)round(obs_arr[j].cy);
        put_px(cx-1, cy, '(', 0);
        put_px(cx,   cy, 'O', 0);
        put_px(cx+1, cy, ')', 0);
    }

    for (int i = 0; i < NUM_BALLS; i++) {
        int bx = (int)round(balls[i].x);
        int by = (int)round(balls[i].y);
        put_px(bx, by, '@', balls[i].ansi);
    }

    printf("\033[H");
    for (int y = 0; y < H; y++) {
        for (int x = 0; x < W; x++) {
            int idx = y*W+x;
            if (col[idx])
                printf("\033[%dm%c\033[0m", col[idx], scr[idx]);
            else
                putchar(scr[idx]);
        }
        if (y < H-1) putchar('\n');
    }
    fflush(stdout);
}

/* ── main ─────────────────────────────────────────────────────────────── */

int main(void) {
    setvbuf(stdout, NULL, _IOFBF, 131072);
    signal(SIGINT,   on_sigint);
    signal(SIGWINCH, on_sigwinch);
    raw_mode();
    get_term_size();
    init();
    printf("\033[?25l\033[2J");
    fflush(stdout);

    while (g_running) {
        if (g_resized) {
            g_resized = 0;
            get_term_size();
            place_obstacles();
            printf("\033[2J");
        }
        handle_input();
        update();
        render();
        usleep(FRAME_US);
    }

    printf("\033[?25h\033[0m\033[2J\033[H");
    puts("Simulation ended.");
    return 0;
}
