#!/usr/bin/octave -qf
% Interactive Fractal Explorer - Mandelbrot Set
% Click to zoom in, right-click to zoom out, press 'r' to reset

function fractal_explorer()
    % Initial parameters
    global xmin xmax ymin ymax max_iter;
    xmin = -2.5;
    xmax = 1.5;
    ymin = -1.5;
    ymax = 1.5;
    max_iter = 100;

    % Create figure
    fig = figure('Name', 'Interactive Fractal Explorer', ...
                 'NumberTitle', 'off', ...
                 'Position', [100, 100, 800, 700]);

    % Draw initial fractal
    draw_mandelbrot();

    % Add instructions
    title(sprintf(['Mandelbrot Set (Iterations: %d)\n' ...
           'Left-click: Zoom in | Right-click: Zoom out | ''r'': Reset | ''+'': More detail | ''-'': Less detail'], max_iter));

    % Set up callbacks
    set(fig, 'WindowButtonDownFcn', @mouse_click);
    set(fig, 'KeyPressFcn', @key_press);

    disp('Interactive Fractal Explorer');
    disp('===========================');
    disp('Left-click: Zoom in at point');
    disp('Right-click: Zoom out');
    disp('Press ''r'': Reset view');
    disp('Press ''+'': Increase iterations (more detail)');
    disp('Press ''-'': Decrease iterations (faster)');
    disp('Press ''q'': Quit');
    disp(' ');
    disp('Window is open. Close the figure window or press ''q'' to exit.');

    % Keep the figure open
    waitfor(fig);
    disp('Fractal explorer closed.');
end

function draw_mandelbrot()
    global xmin xmax ymin ymax max_iter;

    % Resolution
    width = 800;
    height = 600;

    % Create coordinate arrays
    x = linspace(xmin, xmax, width);
    y = linspace(ymin, ymax, height);
    [X, Y] = meshgrid(x, y);
    C = X + 1i*Y;

    % Calculate Mandelbrot set
    Z = zeros(size(C));
    M = zeros(size(C));

    for k = 1:max_iter
        % Calculate next iteration
        mask = abs(Z) <= 2;
        Z(mask) = Z(mask).^2 + C(mask);
        M(mask) = k;
    end

    % Create colorful visualization
    imagesc([xmin xmax], [ymin ymax], M);
    set(gca, 'YDir', 'normal');
    axis equal tight;

    % Use colormap
    colormap(jet(max_iter));
    colorbar;

    xlabel('Real');
    ylabel('Imaginary');
    title(sprintf(['Mandelbrot Set (Iterations: %d)\n' ...
           'Left-click: Zoom in | Right-click: Zoom out | ''r'': Reset | ''+'': More detail | ''-'': Less detail'], max_iter));
end

function mouse_click(src, event)
    global xmin xmax ymin ymax;

    % Get click position
    point = get(gca, 'CurrentPoint');
    x_click = point(1,1);
    y_click = point(1,2);

    % Get button type (1=left, 3=right)
    button = get(gcf, 'SelectionType');

    if strcmp(button, 'normal')  % Left click - zoom in
        zoom_factor = 0.5;
        disp(sprintf('Zooming in at (%.4f, %.4f)', x_click, y_click));
    elseif strcmp(button, 'alt')  % Right click - zoom out
        zoom_factor = 2.0;
        disp(sprintf('Zooming out at (%.4f, %.4f)', x_click, y_click));
    else
        return;
    end

    % Calculate new bounds
    x_range = (xmax - xmin) * zoom_factor / 2;
    y_range = (ymax - ymin) * zoom_factor / 2;

    xmin = x_click - x_range;
    xmax = x_click + x_range;
    ymin = y_click - y_range;
    ymax = y_click + y_range;

    % Redraw
    draw_mandelbrot();
end

function key_press(src, event)
    global xmin xmax ymin ymax max_iter;

    key = event.Character;

    if key == 'r'  % Reset
        xmin = -2.5;
        xmax = 1.5;
        ymin = -1.5;
        ymax = 1.5;
        max_iter = 100;
        disp('Reset to initial view');
        draw_mandelbrot();

    elseif key == '+'  % Increase iterations
        max_iter = min(max_iter + 50, 1000);
        disp(sprintf('Increased iterations to %d', max_iter));
        draw_mandelbrot();

    elseif key == '-'  % Decrease iterations
        max_iter = max(max_iter - 50, 50);
        disp(sprintf('Decreased iterations to %d', max_iter));
        draw_mandelbrot();

    elseif key == 'q'  % Quit
        disp('Closing fractal explorer...');
        close(gcf);
    end
end

% Run the explorer
fractal_explorer();
