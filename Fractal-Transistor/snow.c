#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

#define SIZE 80  // Grid size (smaller to prevent overflow)
#define SYMMETRY 6  // 6-fold symmetry (like a snowflake)
#define BRANCHES 20  // Number of random branches per arm

// Function to initialize the grid
void initializeGrid(int grid[SIZE][SIZE]) {
    for (int i = 0; i < SIZE; i++) {
        for (int j = 0; j < SIZE; j++) {
            grid[i][j] = 0;
        }
    }
}

// Function to draw symmetric points with boundary checks
void drawSymmetricPoints(int grid[SIZE][SIZE], int x, int y) {
    int cx = SIZE / 2;
    int cy = SIZE / 2;
    double angle = 2 * M_PI / SYMMETRY;
    
    for (int i = 0; i < SYMMETRY; i++) {
        double rotatedX = (x - cx) * cos(i * angle) - (y - cy) * sin(i * angle);
        double rotatedY = (x - cx) * sin(i * angle) + (y - cy) * cos(i * angle);
        
        int sx = (int)round(cx + rotatedX);
        int sy = (int)round(cy + rotatedY);
        
        if (sx >= 0 && sx < SIZE && sy >= 0 && sy < SIZE) {
            grid[sx][sy] = 1;
        }
    }
}

// Function to generate random snowflake arms with branches
void generateSnowflake(int grid[SIZE][SIZE]) {
    int cx = SIZE / 2;
    int cy = SIZE / 2;
    
    for (int i = 0; i < BRANCHES; i++) {
        int length = rand() % (SIZE / 4) + 1;  // Ensure non-zero length
        int maxBranchLength = length / 2 + 1;  // Ensure non-zero branch length
        
        for (int j = 0; j < length; j++) {
            int x = cx + j;
            int y = cy;
            drawSymmetricPoints(grid, x, y);
        }
        
        // Random branches along the arm
        int numBranches = rand() % 3 + 1;  // Random number of branches
        for (int k = 0; k < numBranches; k++) {
            int branchStart = rand() % length;
            int branchLength = rand() % maxBranchLength + 1;  // Ensure non-zero branch length
            int direction = (rand() % 2 == 0) ? 1 : -1;  // Randomly choose up or down
            
            for (int l = 0; l < branchLength; l++) {
                int x = cx + branchStart + l;
                int y = cy + direction * l;
                if (x >= 0 && x < SIZE && y >= 0 && y < SIZE) {
                    drawSymmetricPoints(grid, x, y);
                }
            }
        }
    }
}

// Function to print the grid as ASCII without unnecessary newlines
void printGrid(int grid[SIZE][SIZE]) {
    for (int i = 0; i < SIZE; i++) {
        for (int j = 0; j < SIZE; j++) {
            if (grid[i][j] == 1) {
                printf("*");
            } else {
                printf(" ");
            }
        }
        printf("\n");  // Only add a newline at the end of each row
    }
}

int main() {
    int grid[SIZE][SIZE];
    srand((unsigned int)time(NULL));  // Initialize random seed
    initializeGrid(grid);
    generateSnowflake(grid);
    printGrid(grid);
    return 0;
}
