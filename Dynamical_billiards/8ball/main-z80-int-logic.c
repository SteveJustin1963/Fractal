#include <stdint.h>

// Define I/O ports using SDCC specific syntax
__sfr __at (0x01) PORT_ROW;
__sfr __at (0x02) PORT_COL;
__sfr __at (0x03) PORT_KBD;

#define SCALE 16
#define MAX_COORD (7 * SCALE)

// Lookup Tables for 8 directions (scaled by 8)
// 0, 45, 90, 135, 180, 225, 270, 315 degrees
int8_t cos_lut[] = {8, 6, 0, -6, -8, -6, 0, 6};
int8_t sin_lut[] = {0, 6, 8, 6, 0, -6, -8, -6};

typedef struct {
    int16_t x, y;
    int8_t dx, dy;
} Ball;

// Global variables (will be placed at --data-loc)
Ball cue = {32, 64, 0, 0}; 
uint8_t angle_idx = 0;

void update_display(uint8_t x, uint8_t y) {
    // Basic 8x8 multiplexing: Map coordinate to bitmask
    PORT_ROW = (1 << y);
    PORT_COL = (1 << x);
}

void main(void) {
    uint8_t key;
    volatile uint16_t i;

    while(1) {
        // 1. Get Input from Keyboard Port
        key = PORT_KBD;
        
        // Use ASCII values for '4','6','2','8' and '5'
        if (key == '4') cue.x -= 1; 
        if (key == '6') cue.x += 1; 
        if (key == '8') cue.y -= 1; 
        if (key == '2') cue.y += 1; 
        
        if (key == '5') {
            cue.dx = cos_lut[angle_idx];
            cue.dy = sin_lut[angle_idx];
        }

        // 2. Simple Physics
        if (cue.dx != 0 || cue.dy != 0) {
            cue.x += (int16_t)cue.dx;
            cue.y += (int16_t)cue.dy;

            // Bounce logic
            if (cue.x <= 0 || cue.x >= MAX_COORD) cue.dx *= -1;
            if (cue.y <= 0 || cue.y >= MAX_COORD) cue.dy *= -1;

            // Friction (Integer decay)
            if (cue.dx > 0) cue.dx--; else if (cue.dx < 0) cue.dx++;
            if (cue.dy > 0) cue.dy--; else if (cue.dy < 0) cue.dy++;
        }

        // 3. Render
        update_display((uint8_t)(cue.x / SCALE), (uint8_t)(cue.y / SCALE));
        
        // Delay loop for visibility
        for(i = 0; i < 500; i++); 
    }
}

