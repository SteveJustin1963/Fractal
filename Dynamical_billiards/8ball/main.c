#include <ncurses.h>
#include <math.h>
#include <unistd.h>

#define TABLE_WIDTH 60
#define TABLE_HEIGHT 20
#define PI 3.14159265

typedef struct {
    double x, y;
    double dx, dy;
    char symbol;
    int color;
} Ball;

void draw_table(Ball *cue, Ball *balls, int num_balls, double angle, double power, int aiming) {
    clear();
    // Draw Border
    for (int i = 0; i <= TABLE_WIDTH; i++) {
        mvaddch(0, i, '-');
        mvaddch(TABLE_HEIGHT, i, '-');
    }
    for (int i = 0; i <= TABLE_HEIGHT; i++) {
        mvaddch(i, 0, '|');
        mvaddch(i, TABLE_WIDTH, '|');
    }

    // Draw Colored Balls
    for (int i = 0; i < num_balls; i++) {
        attron(COLOR_PAIR(balls[i].color));
        mvaddch((int)balls[i].y, (int)balls[i].x, balls[i].symbol);
        attroff(COLOR_PAIR(balls[i].color));
    }

    // Draw Cue Ball
    mvaddch((int)cue->y, (int)cue->x, 'O');

    // Draw Cue Stick (Only when aiming)
    if (aiming) {
        int stick_len = 10 + (int)(power / 2);
        for (int i = 2; i < stick_len; i++) {
            int sx = (int)(cue->x - cos(angle) * i);
            int sy = (int)(cue->y - sin(angle) * i);
            if (sx > 0 && sx < TABLE_WIDTH && sy > 0 && sy < TABLE_HEIGHT) {
                mvaddch(sy, sx, 'x');
            }
        }
    }

    mvprintw(TABLE_HEIGHT + 1, 0, "Arrows: Move | Shift+Arrows: Angle | Space: Power/Shoot");
    refresh();
}

int main() {
    initscr();
    noecho();
    curs_set(0);
    keypad(stdscr, TRUE);
    start_color();

    init_pair(1, COLOR_YELLOW, COLOR_BLACK); // Striped/Solid placeholder
    init_pair(2, COLOR_RED, COLOR_BLACK);

    Ball cue = {30, 10, 0, 0, 'O', 0};
    Ball rack[1] = {{45, 10, 0, 0, '@', 1}}; // Simplified for example

    double angle = 0;
    double power = 0;
    int aiming = 1;
    int charging = 0;

    while (1) {
        draw_table(&cue, rack, 1, angle, power, aiming);
        
        int ch = getch();
        if (ch == 'q') break;

        if (aiming) {
            switch (ch) {
                case KEY_LEFT:  cue.x -= 1; break;
                case KEY_RIGHT: cue.x += 1; break;
                case KEY_UP:    cue.y -= 1; break;
                case KEY_DOWN:  cue.y += 1; break;
                case KEY_SLEFT: angle -= 0.1; break;
                case KEY_SRIGHT: angle += 0.1; break;
                case ' ':
                    charging = 1;
                    while (charging) {
                        power += 0.5;
                        draw_table(&cue, rack, 1, angle, power, aiming);
                        timeout(100);
                        if (getch() == ' ') { // Release
                            cue.dx = cos(angle) * (power / 5);
                            cue.dy = sin(angle) * (power / 5);
                            aiming = 0;
                            charging = 0;
                        }
                        if (power > 20) power = 0; // Reset power loop
                    }
                    break;
            }
        }

        // Simple Physics Loop
        if (!aiming) {
            while (fabs(cue.dx) > 0.01 || fabs(cue.dy) > 0.01) {
                cue.x += cue.dx;
                cue.y += cue.dy;
                cue.dx *= 0.98; // Friction
                cue.dy *= 0.98;

                // Wall Bounces
                if (cue.x <= 1 || cue.x >= TABLE_WIDTH - 1) cue.dx *= -1;
                if (cue.y <= 1 || cue.y >= TABLE_HEIGHT - 1) cue.dy *= -1;

                draw_table(&cue, rack, 1, angle, power, 0);
                usleep(30000);
            }
            cue.dx = 0; cue.dy = 0;
            aiming = 1;
            power = 0;
        }
    }

    endwin();
    return 0;
}