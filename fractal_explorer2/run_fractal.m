% Fractal Explorer Launcher Script
% This script launches the interactive fractal explorer

% Clear and setup
clear all;
close all;
clc;

% Global variables
global g_fractal_type g_xmin g_xmax g_ymin g_ymax g_max_iter g_fig g_quality;

% Initialize parameters
g_fractal_type = 1;  % 1=Mandelbrot, 2=Julia, 3=Burning Ship, 4=Tricorn
g_max_iter = 150;
g_quality = 1;  % 0=fast, 1=normal, 2=high
g_xmin = -2.5;
g_xmax = 1.5;
g_ymin = -1.5;
g_ymax = 1.5;

% Create figure window
g_fig = figure('Name', 'Fractal Explorer', ...
               'NumberTitle', 'off', ...
               'Position', [100, 100, 1000, 800], ...
               'Color', [0.15 0.15 0.15]);

% Display instructions
fprintf('\n');
fprintf('╔════════════════════════════════════════════════════════╗\n');
fprintf('║      INTERACTIVE FRACTAL EXPLORER - CONTROLS          ║\n');
fprintf('╠════════════════════════════════════════════════════════╣\n');
fprintf('║  MOUSE:                                                ║\n');
fprintf('║    • Drag to select zoom area                          ║\n');
fprintf('║    • Right-click to zoom out                           ║\n');
fprintf('║                                                        ║\n');
fprintf('║  KEYBOARD - FRACTALS:                                  ║\n');
fprintf('║    • 1 = Mandelbrot Set                                ║\n');
fprintf('║    • 2 = Julia Set                                     ║\n');
fprintf('║    • 3 = Burning Ship                                  ║\n');
fprintf('║    • 4 = Tricorn                                       ║\n');
fprintf('║                                                        ║\n');
fprintf('║  KEYBOARD - QUALITY:                                   ║\n');
fprintf('║    • f = Fast mode (500x375 - quick preview)           ║\n');
fprintf('║    • n = Normal mode (700x525 - balanced)              ║\n');
fprintf('║    • h = High quality (1000x750 - detailed)            ║\n');
fprintf('║                                                        ║\n');
fprintf('║  KEYBOARD - OTHER:                                     ║\n');
fprintf('║    • r = Reset view                                    ║\n');
fprintf('║    • + = More iterations (more detail)                 ║\n');
fprintf('║    • - = Less iterations (faster)                      ║\n');
fprintf('║    • q = Quit                                          ║\n');
fprintf('╚════════════════════════════════════════════════════════╝\n');
fprintf('\n');

% Draw initial fractal
draw_fractal();

% Set up event callbacks
set(g_fig, 'WindowButtonDownFcn', @handle_mouse);
set(g_fig, 'KeyPressFcn', @handle_keyboard);

% Wait for window to close
waitfor(g_fig);
fprintf('Fractal explorer closed.\n');
