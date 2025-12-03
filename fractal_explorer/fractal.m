% INTERACTIVE FRACTAL EXPLORER
% Run with: octave fractal.m

function fractal()
    % Global state variables
    global g_fractal_type g_xmin g_xmax g_ymin g_ymax g_max_iter g_fig g_quality;

    % Initialize parameters
    g_fractal_type = 1;
    g_max_iter = 80;  % Reduced for speed
    g_quality = 0;
    g_xmin = -2.5;
    g_xmax = 1.5;
    g_ymin = -1.5;
    g_ymax = 1.5;

    % Create figure
    g_fig = figure('Name', 'Fractal Explorer', ...
                   'NumberTitle', 'off', ...
                   'Position', [100, 100, 1000, 800], ...
                   'Color', [0.15 0.15 0.15]);

    % Print instructions
    fprintf('\n');
    fprintf('╔════════════════════════════════════════════════════════╗\n');
    fprintf('║      INTERACTIVE FRACTAL EXPLORER - CONTROLS          ║\n');
    fprintf('╠════════════════════════════════════════════════════════╣\n');
    fprintf('║  MOUSE:                                                ║\n');
    fprintf('║    • Click and drag to select zoom area                ║\n');
    fprintf('║    • Right-click to zoom out                           ║\n');
    fprintf('║                                                        ║\n');
    fprintf('║  KEYBOARD - FRACTALS:                                  ║\n');
    fprintf('║    • 1 = Mandelbrot Set                                ║\n');
    fprintf('║    • 2 = Julia Set                                     ║\n');
    fprintf('║    • 3 = Burning Ship                                  ║\n');
    fprintf('║    • 4 = Tricorn                                       ║\n');
    fprintf('║                                                        ║\n');
    fprintf('║  KEYBOARD - QUALITY:                                   ║\n');
    fprintf('║    • f = Fast mode (300x225 - very quick)              ║\n');
    fprintf('║    • n = Normal mode (500x375 - balanced)              ║\n');
    fprintf('║    • h = High quality (800x600 - detailed)             ║\n');
    fprintf('║                                                        ║\n');
    fprintf('║  KEYBOARD - OTHER:                                     ║\n');
    fprintf('║    • Arrow keys = Pan view (left/right/up/down)        ║\n');
    fprintf('║    • r = Reset view                                    ║\n');
    fprintf('║    • + = More iterations  | - = Less iterations        ║\n');
    fprintf('║    • q = Quit                                          ║\n');
    fprintf('╚════════════════════════════════════════════════════════╝\n');
    fprintf('\n');

    % Draw initial fractal
    draw_fractal();

    % Set up event callbacks
    set(g_fig, 'WindowButtonDownFcn', @handle_mouse_down);
    set(g_fig, 'KeyPressFcn', @handle_keyboard);

    % Keep window open
    waitfor(g_fig);
    fprintf('Fractal explorer closed.\n');
end

% ========== DRAWING ==========

function draw_fractal()
    global g_fractal_type g_xmin g_xmax g_ymin g_ymax g_max_iter g_fig g_quality;

    fprintf('Computing... ');
    tic;

    % Resolution - reduced for speed
    switch g_quality
        case 0
            width = 300; height = 225;  % Very fast
        case 1
            width = 500; height = 375;  % Balanced
        otherwise
            width = 800; height = 600;  % High quality
    end

    % Create mesh
    x = linspace(g_xmin, g_xmax, width);
    y = linspace(g_ymin, g_ymax, height);
    [X, Y] = meshgrid(x, y);
    C = X + 1i*Y;

    % Compute
    M = compute_fractal(C, g_max_iter, g_fractal_type);
    M_display = log(M + 1);

    % Fractal name
    names = {'Mandelbrot Set', 'Julia Set', 'Burning Ship', 'Tricorn'};
    fname = names{g_fractal_type};

    % Render
    figure(g_fig);
    clf;
    imagesc([g_xmin g_xmax], [g_ymin g_ymax], M_display);
    set(gca, 'YDir', 'normal');
    axis tight;

    % Styling
    colormap(jet(256));
    cb = colorbar;
    set(cb, 'Color', [1 1 1]);
    set(gca, 'Color', [0 0 0], 'XColor', [1 1 1], 'YColor', [1 1 1]);
    xlabel('Real', 'Color', [1 1 1]);
    ylabel('Imaginary', 'Color', [1 1 1]);

    quality_names = {'FAST', 'NORMAL', 'HIGH'};
    title_str = sprintf('%s [%s] (%d iter) | Drag=zoom | 1-4/f/n/h/+/-/q', ...
                       fname, quality_names{g_quality + 1}, g_max_iter);
    title(title_str, 'Color', [1 1 1], 'FontWeight', 'bold');

    % Restore callbacks
    set(g_fig, 'WindowButtonDownFcn', @handle_mouse_down);
    set(g_fig, 'KeyPressFcn', @handle_keyboard);

    fprintf('done (%.2fs)\n', toc);
    drawnow;  % Force display update
end

function M = compute_fractal(C, max_iter, ftype)
    [rows, cols] = size(C);
    M = zeros(rows, cols);
    Z = zeros(rows, cols);
    active = true(rows, cols);

    switch ftype
        case 1  % Mandelbrot
            for k = 1:max_iter
                if ~any(active(:)); break; end
                Z_active = Z(active);
                C_active = C(active);
                Z_active = Z_active.^2 + C_active;
                escaped = abs(Z_active) > 2;
                active_indices = find(active);
                M(active_indices(escaped)) = k;
                Z(active) = Z_active;
                active(active_indices(escaped)) = false;
            end

        case 2  % Julia
            c = -0.7 + 0.27015i;
            Z = C;
            for k = 1:max_iter
                if ~any(active(:)); break; end
                Z_active = Z(active);
                Z_active = Z_active.^2 + c;
                escaped = abs(Z_active) > 2;
                active_indices = find(active);
                M(active_indices(escaped)) = k;
                Z(active) = Z_active;
                active(active_indices(escaped)) = false;
            end

        case 3  % Burning Ship
            for k = 1:max_iter
                if ~any(active(:)); break; end
                Z_active = Z(active);
                C_active = C(active);
                Z_active = (abs(real(Z_active)) + 1i*abs(imag(Z_active))).^2 + C_active;
                escaped = abs(Z_active) > 2;
                active_indices = find(active);
                M(active_indices(escaped)) = k;
                Z(active) = Z_active;
                active(active_indices(escaped)) = false;
            end

        case 4  % Tricorn
            for k = 1:max_iter
                if ~any(active(:)); break; end
                Z_active = Z(active);
                C_active = C(active);
                Z_active = conj(Z_active).^2 + C_active;
                escaped = abs(Z_active) > 2;
                active_indices = find(active);
                M(active_indices(escaped)) = k;
                Z(active) = Z_active;
                active(active_indices(escaped)) = false;
            end
    end
    M(active) = max_iter;
end

% ========== MOUSE EVENTS ==========

function handle_mouse_down(src, evt)
    global g_xmin g_xmax g_ymin g_ymax g_fig;

    button = get(g_fig, 'SelectionType');

    if strcmp(button, 'normal')  % Left - drag zoom
        point1 = get(gca, 'CurrentPoint');
        x1 = point1(1,1);
        y1 = point1(1,2);

        rect_h = rectangle('Position', [x1, y1, 0.001, 0.001], ...
                          'EdgeColor', [1 1 0], 'LineWidth', 2, 'LineStyle', '--');

        set(g_fig, 'WindowButtonMotionFcn', {@handle_mouse_drag, x1, y1, rect_h});
        set(g_fig, 'WindowButtonUpFcn', {@handle_mouse_up, x1, y1, rect_h});

    elseif strcmp(button, 'alt')  % Right - zoom out
        point = get(gca, 'CurrentPoint');
        x_click = point(1,1);
        y_click = point(1,2);

        zoom_factor = 2.0;
        x_range = (g_xmax - g_xmin) * zoom_factor / 2;
        y_range = (g_ymax - g_ymin) * zoom_factor / 2;

        g_xmin = x_click - x_range;
        g_xmax = x_click + x_range;
        g_ymin = y_click - y_range;
        g_ymax = y_click + y_range;

        fprintf('Zooming out...\n');
        draw_fractal();
    end
end

function handle_mouse_drag(src, evt, x1, y1, rect_h)
    point2 = get(gca, 'CurrentPoint');
    x2 = point2(1,1);
    y2 = point2(1,2);
    set(rect_h, 'Position', [x1, y1, x2-x1, y2-y1]);
    drawnow;
end

function handle_mouse_up(src, evt, x1, y1, rect_h)
    global g_xmin g_xmax g_ymin g_ymax g_fig;

    point2 = get(gca, 'CurrentPoint');
    x2 = point2(1,1);
    y2 = point2(1,2);

    fprintf('Mouse up: start=(%.3f,%.3f) end=(%.3f,%.3f)\n', x1, y1, x2, y2);

    delete(rect_h);
    set(g_fig, 'WindowButtonMotionFcn', '');
    set(g_fig, 'WindowButtonUpFcn', '');

    dx = abs(x2 - x1);
    dy = abs(y2 - y1);
    threshold_x = (g_xmax - g_xmin) * 0.005;
    threshold_y = (g_ymax - g_ymin) * 0.005;

    fprintf('Selection: dx=%.3f dy=%.3f, threshold_x=%.3f threshold_y=%.3f\n', dx, dy, threshold_x, threshold_y);

    % Much smaller threshold - 0.5% instead of 2%
    if dx > threshold_x && dy > threshold_y
        fprintf('✓ Valid selection - zooming!\n');
        new_xmin = min(x1, x2);
        new_xmax = max(x1, x2);
        new_ymin = min(y1, y2);
        new_ymax = max(y1, y2);

        x_center = (new_xmin + new_xmax) / 2;
        y_center = (new_ymin + new_ymax) / 2;
        x_range = new_xmax - new_xmin;
        y_range = new_ymax - new_ymin;

        window_aspect = 4 / 3;
        selection_aspect = x_range / y_range;

        if selection_aspect > window_aspect
            y_range = x_range / window_aspect;
        else
            x_range = y_range * window_aspect;
        end

        g_xmin = x_center - x_range / 2;
        g_xmax = x_center + x_range / 2;
        g_ymin = y_center - y_range / 2;
        g_ymax = y_center + y_range / 2;

        fprintf('Zooming in... New bounds: X[%.3f to %.3f] Y[%.3f to %.3f]\n', ...
                g_xmin, g_xmax, g_ymin, g_ymax);
        drawnow;  % Force display update
        draw_fractal();
    else
        fprintf('✗ Selection too small - ignored\n');
    end
end

% ========== KEYBOARD ==========

function handle_keyboard(src, evt)
    global g_fractal_type g_xmin g_xmax g_ymin g_ymax g_max_iter g_fig g_quality;

    key = evt.Character;

    % Check for arrow keys (they don't have Character, use Key instead)
    if isempty(key)
        key = evt.Key;
    end

    if isempty(key); return; end

    changed = false;

    if key == '1' && g_fractal_type != 1
        g_fractal_type = 1; reset_view();
        fprintf('→ Mandelbrot\n'); changed = true;
    elseif key == '2' && g_fractal_type != 2
        g_fractal_type = 2; reset_view();
        fprintf('→ Julia\n'); changed = true;
    elseif key == '3' && g_fractal_type != 3
        g_fractal_type = 3; reset_view();
        fprintf('→ Burning Ship\n'); changed = true;
    elseif key == '4' && g_fractal_type != 4
        g_fractal_type = 4; reset_view();
        fprintf('→ Tricorn\n'); changed = true;
    elseif key == 'r'
        reset_view();
        fprintf('→ Reset\n'); changed = true;
    elseif key == '+'
        g_max_iter = min(g_max_iter + 50, 1000);
        fprintf('→ Iter: %d\n', g_max_iter); changed = true;
    elseif key == '-'
        g_max_iter = max(g_max_iter - 50, 50);
        fprintf('→ Iter: %d\n', g_max_iter); changed = true;
    elseif key == 'f'
        g_quality = 0;
        fprintf('→ Fast\n'); changed = true;
    elseif key == 'n'
        g_quality = 1;
        fprintf('→ Normal\n'); changed = true;
    elseif key == 'h'
        g_quality = 2;
        fprintf('→ High\n'); changed = true;
    elseif key == 'q'
        fprintf('Closing...\n');
        close(g_fig);
        return;

    % Arrow keys for panning
    elseif strcmp(key, 'left')
        pan_amount = (g_xmax - g_xmin) * 0.1;  % Pan 10% of view
        g_xmin = g_xmin - pan_amount;
        g_xmax = g_xmax - pan_amount;
        fprintf('← Pan left\n'); changed = true;
    elseif strcmp(key, 'right')
        pan_amount = (g_xmax - g_xmin) * 0.1;
        g_xmin = g_xmin + pan_amount;
        g_xmax = g_xmax + pan_amount;
        fprintf('→ Pan right\n'); changed = true;
    elseif strcmp(key, 'up')
        pan_amount = (g_ymax - g_ymin) * 0.1;
        g_ymin = g_ymin + pan_amount;
        g_ymax = g_ymax + pan_amount;
        fprintf('↑ Pan up\n'); changed = true;
    elseif strcmp(key, 'down')
        pan_amount = (g_ymax - g_ymin) * 0.1;
        g_ymin = g_ymin - pan_amount;
        g_ymax = g_ymax - pan_amount;
        fprintf('↓ Pan down\n'); changed = true;
    end

    if changed
        draw_fractal();
    end
end

function reset_view()
    global g_fractal_type g_xmin g_xmax g_ymin g_ymax;
    if g_fractal_type == 3
        g_xmin = -2.0; g_xmax = 1.0;
        g_ymin = -2.0; g_ymax = 1.0;
    else
        g_xmin = -2.5; g_xmax = 1.5;
        g_ymin = -1.5; g_ymax = 1.5;
    end
end
