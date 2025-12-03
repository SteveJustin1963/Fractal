#!/usr/bin/octave -qf
% Interactive Fractal Explorer with Rectangle Selection
% Drag to select zoom area, right-click to zoom out

function fractal_interactive()
    % Initial parameters
    global fractal_type xmin xmax ymin ymax max_iter img_handle;

    fractal_type = 1;  % 1=Mandelbrot, 2=Julia, 3=Burning Ship, 4=Tricorn
    max_iter = 150;

    % Create figure
    fig = figure('Name', 'Interactive Fractal Explorer', ...
                 'NumberTitle', 'off', ...
                 'Position', [100, 100, 1000, 800], ...
                 'Color', [0.15 0.15 0.15]);

    % Set initial bounds
    reset_view();

    % Draw initial fractal
    draw_fractal();

    % Set up callbacks
    set(fig, 'WindowButtonDownFcn', @mouse_down);
    set(fig, 'KeyPressFcn', @key_press);

    % Print instructions
    print_instructions();

    % Keep the figure open
    waitfor(fig);
    disp('Fractal explorer closed.');
end

function print_instructions()
    disp(' ');
    disp('╔════════════════════════════════════════════════════════╗');
    disp('║      INTERACTIVE FRACTAL EXPLORER - CONTROLS          ║');
    disp('╠════════════════════════════════════════════════════════╣');
    disp('║  MOUSE:                                                ║');
    disp('║    • Drag rectangle: Select area to zoom in            ║');
    disp('║    • Right-click: Zoom out                             ║');
    disp('║                                                        ║');
    disp('║  KEYBOARD:                                             ║');
    disp('║    • 1: Mandelbrot Set                                 ║');
    disp('║    • 2: Julia Set                                      ║');
    disp('║    • 3: Burning Ship                                   ║');
    disp('║    • 4: Tricorn (Mandelbar)                            ║');
    disp('║    • r: Reset view                                     ║');
    disp('║    • +: More detail (slower)                           ║');
    disp('║    • -: Less detail (faster)                           ║');
    disp('║    • q: Quit                                           ║');
    disp('╚════════════════════════════════════════════════════════╝');
    disp(' ');
end

function reset_view()
    global fractal_type xmin xmax ymin ymax;

    if fractal_type == 3  % Burning Ship
        xmin = -2.0;
        xmax = 1.0;
        ymin = -2.0;
        ymax = 1.0;
    else
        xmin = -2.5;
        xmax = 1.5;
        ymin = -1.5;
        ymax = 1.5;
    end
end

function M = compute_fractal(C, max_iter, ftype)
    Z = zeros(size(C));
    M = zeros(size(C));

    switch ftype
        case 1  % Mandelbrot
            for k = 1:max_iter
                mask = abs(Z) <= 4;
                Z(mask) = Z(mask).^2 + C(mask);
                M(mask) = k;
            end

        case 2  % Julia
            c = -0.7 + 0.27015i;
            Z = C;
            for k = 1:max_iter
                mask = abs(Z) <= 4;
                Z(mask) = Z(mask).^2 + c;
                M(mask) = k;
            end

        case 3  % Burning Ship
            for k = 1:max_iter
                mask = abs(Z) <= 4;
                Z(mask) = (abs(real(Z(mask))) + 1i*abs(imag(Z(mask)))).^2 + C(mask);
                M(mask) = k;
            end

        case 4  % Tricorn
            for k = 1:max_iter
                mask = abs(Z) <= 4;
                Z(mask) = conj(Z(mask)).^2 + C(mask);
                M(mask) = k;
            end
    end
end

function draw_fractal()
    global fractal_type xmin xmax ymin ymax max_iter img_handle;

    % Resolution
    width = 800;
    height = 600;

    fprintf('Computing fractal... ');
    tic;

    % Create coordinate arrays
    x = linspace(xmin, xmax, width);
    y = linspace(ymin, ymax, height);
    [X, Y] = meshgrid(x, y);
    C = X + 1i*Y;

    % Compute fractal
    M = compute_fractal(C, max_iter, fractal_type);

    % Smooth coloring
    M_smooth = log(M + 1);

    % Get fractal name
    names = {'Mandelbrot Set', 'Julia Set', 'Burning Ship', 'Tricorn (Mandelbar)'};
    fractal_name = names{fractal_type};

    % Clear and redraw
    clf;
    img_handle = imagesc([xmin xmax], [ymin ymax], M_smooth);
    set(gca, 'YDir', 'normal');
    axis equal tight;

    % Styling
    colormap(jet(256));
    h = colorbar;
    set(h, 'Color', [1 1 1]);
    set(gca, 'Color', [0 0 0], 'XColor', [1 1 1], 'YColor', [1 1 1]);

    xlabel('Real axis', 'Color', [1 1 1], 'FontSize', 11);
    ylabel('Imaginary axis', 'Color', [1 1 1], 'FontSize', 11);

    title_str = sprintf('%s (Iterations: %d)\nDrag rectangle to zoom | Right-click: zoom out | 1-4: change fractal', ...
                       fractal_name, max_iter);
    title(title_str, 'Color', [1 1 1], 'FontSize', 12, 'FontWeight', 'bold');

    % Reset callbacks (they get cleared by clf)
    set(gcf, 'WindowButtonDownFcn', @mouse_down);
    set(gcf, 'KeyPressFcn', @key_press);

    elapsed = toc;
    fprintf('Done! (%.2f seconds)\n', elapsed);
end

function mouse_down(src, event)
    global xmin xmax ymin ymax;

    % Get button type
    button = get(gcf, 'SelectionType');

    if strcmp(button, 'normal')  % Left click - start rectangle selection
        % Get starting point
        point1 = get(gca, 'CurrentPoint');
        x1 = point1(1,1);
        y1 = point1(1,2);

        % Check if click is within axes
        if x1 < xmin || x1 > xmax || y1 < ymin || y1 > ymax
            return;
        end

        % Create rectangle for visual feedback
        rect_h = rectangle('Position', [x1, y1, 0, 0], ...
                          'EdgeColor', [1 1 0], ...
                          'LineWidth', 2, ...
                          'LineStyle', '--');

        % Set up motion and button up callbacks
        set(gcf, 'WindowButtonMotionFcn', {@mouse_move, x1, y1, rect_h});
        set(gcf, 'WindowButtonUpFcn', {@mouse_up, x1, y1, rect_h});

    elseif strcmp(button, 'alt')  % Right click - zoom out
        % Get click point
        point = get(gca, 'CurrentPoint');
        x_click = point(1,1);
        y_click = point(1,2);

        zoom_factor = 2.5;
        x_range = (xmax - xmin) * zoom_factor / 2;
        y_range = (ymax - ymin) * zoom_factor / 2;

        xmin = x_click - x_range;
        xmax = x_click + x_range;
        ymin = y_click - y_range;
        ymax = y_click + y_range;

        fprintf('Zooming out...\n');
        draw_fractal();
    end
end

function mouse_move(src, event, x1, y1, rect_h)
    % Update rectangle as mouse moves
    point2 = get(gca, 'CurrentPoint');
    x2 = point2(1,1);
    y2 = point2(1,2);

    width = x2 - x1;
    height = y2 - y1;

    set(rect_h, 'Position', [x1, y1, width, height]);
end

function mouse_up(src, event, x1, y1, rect_h)
    global xmin xmax ymin ymax;

    % Get ending point
    point2 = get(gca, 'CurrentPoint');
    x2 = point2(1,1);
    y2 = point2(1,2);

    % Remove rectangle
    delete(rect_h);

    % Clear motion callbacks
    set(gcf, 'WindowButtonMotionFcn', '');
    set(gcf, 'WindowButtonUpFcn', '');

    % Check if we have a valid rectangle (not just a click)
    if abs(x2 - x1) > (xmax - xmin) * 0.01 && abs(y2 - y1) > (ymax - ymin) * 0.01
        % Zoom to selected rectangle
        xmin_new = min(x1, x2);
        xmax_new = max(x1, x2);
        ymin_new = min(y1, y2);
        ymax_new = max(y1, y2);

        xmin = xmin_new;
        xmax = xmax_new;
        ymin = ymin_new;
        ymax = ymax_new;

        fprintf('Zooming to selected area...\n');
        draw_fractal();
    end
end

function key_press(src, event)
    global fractal_type xmin xmax ymin ymax max_iter;

    key = event.Character;

    if key == '1'
        if fractal_type != 1
            fractal_type = 1;
            reset_view();
            fprintf('Switched to Mandelbrot Set\n');
            draw_fractal();
        end
    elseif key == '2'
        if fractal_type != 2
            fractal_type = 2;
            reset_view();
            fprintf('Switched to Julia Set\n');
            draw_fractal();
        end
    elseif key == '3'
        if fractal_type != 3
            fractal_type = 3;
            reset_view();
            fprintf('Switched to Burning Ship\n');
            draw_fractal();
        end
    elseif key == '4'
        if fractal_type != 4
            fractal_type = 4;
            reset_view();
            fprintf('Switched to Tricorn\n');
            draw_fractal();
        end
    elseif key == 'r'
        reset_view();
        fprintf('Reset to initial view\n');
        draw_fractal();
    elseif key == '+'
        max_iter = min(max_iter + 50, 1000);
        fprintf('Increased iterations to %d\n', max_iter);
        draw_fractal();
    elseif key == '-'
        max_iter = max(max_iter - 50, 50);
        fprintf('Decreased iterations to %d\n', max_iter);
        draw_fractal();
    elseif key == 'q'
        fprintf('Closing fractal explorer...\n');
        close(gcf);
    end
end

% Run the explorer
fractal_interactive();
