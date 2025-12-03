#include <stdio.h>
#include <math.h>
#include <stdlib.h>

#define WIDTH 80   // Grid width
#define HEIGHT 40  // Grid height

// Function to compute Chladni figure for a given mode (m, n) on the plate
void generate_chladni_figure(int m, int n, double frequency, double amplitude) {
    char grid[HEIGHT][WIDTH];
    double x, y;
    
    // Iterate through each point on the grid
    for (int i = 0; i < HEIGHT; i++) {
        for (int j = 0; j < WIDTH; j++) {
            x = (double)j / WIDTH * 2 * M_PI; // Normalize x to [0, 2pi]
            y = (double)i / HEIGHT * 2 * M_PI; // Normalize y to [0, 2pi]

            // Calculate vibration pattern based on Chladni's law
            double vibration = amplitude * (sin(m * x) * sin(n * y) - frequency);
            
            // If the vibration value is close to zero (node), mark with ' '
            if (fabs(vibration) < 0.1) {
                grid[i][j] = ' ';
            } else {
                grid[i][j] = '*';  // Else mark with '*'
            }
        }
    }

    // Output the grid as a simple console visualization
    for (int i = 0; i < HEIGHT; i++) {
        for (int j = 0; j < WIDTH; j++) {
            printf("%c", grid[i][j]);
        }
        printf("\n");
    }
}

int main() {
    int m, n;
    double frequency = 1.0;
    double amplitude = 1.0;

    // Get mode numbers from user
    printf("Enter mode numbers m and n (e.g., 2 3): ");
    scanf("%d %d", &m, &n);

    // Generate and display the Chladni figure
    generate_chladni_figure(m, n, frequency, amplitude);

    return 0;
}
