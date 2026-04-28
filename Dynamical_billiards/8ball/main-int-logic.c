#include <ncurses.h>
#include <unistd.h>

#define SCALE 100
#define TABLE_WIDTH (60 * SCALE)
#define TABLE_HEIGHT (20 * SCALE)

// A simple lookup table for Cosine (scaled by 100)
// Representing 0, 45, 90, 135, 180, 225, 270, 315 degrees
int cos_lut[] = {100, 70, 0, -70, -100, -70, 0, 70};
int sin_lut[] = {0, 70, 100, 70, 0, -70, -100, -70};

typedef struct {
    int x, y;   // Position (multiplied by SCALE)
    int dx, dy; // Velocity (multiplied by SCALE)
} Ball;

void draw_frame(Ball *cue, int angle_idx) {
    clear();
    // Border
    for (int i = 0; i <= 60; i++) {
        mvaddch(0, i, '-');
        mvaddch(20, i, '-');
    }

    // Draw Cue (Divide by SCALE to get actual screen pixel)
    int screen_x = cue->x / SCALE;
    int screen_y = cue->y / SCALE;
    mvaddch(screen_y, screen_x, 'O');

    // Draw Stick using integer LUT
    for (int i = 2; i < 6; i++) {
        int sx = screen_x - (cos_lut[angle_idx] * i) / 100;
        int sy = screen_y - (sin_lut[angle_idx] * i) / 100;
        if (sx > 0 && sx < 60 && sy > 0 && sy < 20)
            mvaddch(sy, sx, 'x');
    }
    refresh();
}

int main() {
    initscr();
    noecho();
    keypad(stdscr, TRUE);
    curs_set(0);

    Ball cue = {10 * SCALE, 10 * SCALE, 0, 0};
    int angle_idx = 0; // Index for our LUT (0 to 7)
    int running = 1;

    while (running) {
        draw_frame(&cue, angle_idx);
        
        timeout(50); // Non-blocking input
        int ch = getch();

        switch(ch) {
            case KEY_LEFT:  cue.x -= 1 * SCALE; break;
            case KEY_RIGHT: cue.x += 1 * SCALE; break;
            case KEY_UP:    cue.y -= 1 * SCALE; break;
            case KEY_DOWN:  cue.y += 1 * SCALE; break;
            case 'a':       angle_idx = (angle_idx + 1) % 8; break; // Rotate
            case ' ':       // Shoot!
                cue.dx = cos_lut[angle_idx] * 2; 
                cue.dy = sin_lut[angle_idx] * 2;
                break;
            case 'q':       running = 0; break;
        }

        // Integer Physics
        if (cue.dx != 0 || cue.dy != 0) {
            cue.x += cue.dx;
            cue.y += cue.dy;

            // Simple friction: reduce velocity by a fixed integer amount
            if (cue.dx > 0) cue.dx -= 2; else if (cue.dx < 0) cue.dx += 2;
            if (cue.dy > 0) cue.dy -= 2; else if (cue.dy < 0) cue.dy += 2;

            // Bounce logic
            if (cue.x <= 1 * SCALE || cue.x >= 59 * SCALE) cue.dx *= -1;
            if (cue.y <= 1 * SCALE || cue.y >= 19 * SCALE) cue.dy *= -1;
            
            // Stop ball if velocity is very low
            if (cue.dx < 5 && cue.dx > -5) cue.dx = 0;
            if (cue.dy < 5 && cue.dy > -5) cue.dy = 0;
        }
    }

    endwin();
    return 0;
}

