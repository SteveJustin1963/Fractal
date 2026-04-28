#!/usr/bin/octave -qf
% Multi-Fractal Explorer - Multiple fractal types
% Press number keys to switch between different fractals

function multi_fractal()
    global fractal_type xmin xmax ymin ymax max_iter;

    fractal_type = 1;  % 1=Mandelbrot, 2=Julia, 3=Burning Ship, 4=Tricorn
    max_iter = 100;

    % Create figure
    fig = figure('Name', 'Multi-Fractal Explorer', ...
                 'NumberTitle', 'off', ...
                 'Position', [100, 100, 900, 700]);

    % Set initial bounds
    reset_view();

    % Draw initial fractal
    draw_fractal();

    % Set up callbacks
    set(fig, 'WindowButtonDownFcn', @mouse_click);
    set(fig, 'KeyPressFcn', @key_press);

    disp('Multi-Fractal Explorer');
    disp('=====================');
    disp('Press 1: Mandelbrot Set');
    disp('Press 2: Julia Set');
    disp('Press 3: Burning Ship');
    disp('Press 4: Tricorn (Mandelbar)');
    disp('Left-click: Zoom in');
    disp('Right-click: Zoom out');
    disp('Press ''r'': Reset view');
    disp('Press ''+''/''−'': Adjust detail');
    disp('Press ''q'': Quit');
    disp(' ');
    disp('Window is open. Close the figure window or press ''q'' to exit.');

    % Keep the figure open
    waitfor(fig);
    disp('Fractal explorer closed.');
end

function reset_view()
    global fractal_type xmin xmax ymin ymax;

    if fractal_type == 3  % Burning Ship has different default view
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

function M = compute_mandelbrot(C, max_iter)
    Z = zeros(size(C));
    M = zeros(size(C));

    for k = 1:max_iter
        mask = abs(Z) <= 2;
        Z(mask) = Z(mask).^2 + C(mask);
        M(mask) = k;
    end
end

function M = compute_julia(C, max_iter)
    % Julia set with c = -0.7 + 0.27015i (interesting constant)
    c = -0.7 + 0.27015i;
    Z = C;
    M = zeros(size(C));

    for k = 1:max_iter
        mask = abs(Z) <= 2;
        Z(mask) = Z(mask).^2 + c;
        M(mask) = k;
    end
end

function M = compute_burning_ship(C, max_iter)
    Z = zeros(size(C));
    M = zeros(size(C));

    for k = 1:max_iter
        mask = abs(Z) <= 2;
        % Burning Ship: z = (|Re(z)| + i|Im(z)|)^2 + c
        Z(mask) = (abs(real(Z(mask))) + 1i*abs(imag(Z(mask)))).^2 + C(mask);
        M(mask) = k;
    end
end

function M = compute_tricorn(C, max_iter)
    Z = zeros(size(C));
    M = zeros(size(C));

    for k = 1:max_iter
        mask = abs(Z) <= 2;
        % Tricorn: z = conj(z)^2 + c
        Z(mask) = conj(Z(mask)).^2 + C(mask);
        M(mask) = k;
    end
end

function draw_fractal()
    global fractal_type xmin xmax ymin ymax max_iter;

    % Resolution
    width = 800;
    height = 600;

    % Create coordinate arrays
    x = linspace(xmin, xmax, width);
    y = linspace(ymin, ymax, height);
    [X, Y] = meshgrid(x, y);
    C = X + 1i*Y;

    % Compute fractal based on type
    switch fractal_type
        case 1
            M = compute_mandelbrot(C, max_iter);
            fractal_name = 'Mandelbrot Set';
        case 2
            M = compute_julia(C, max_iter);
            fractal_name = 'Julia Set';
        case 3
            M = compute_burning_ship(C, max_iter);
            fractal_name = 'Burning Ship';
        case 4
            M = compute_tricorn(C, max_iter);
            fractal_name = 'Tricorn (Mandelbar)';
    end

    % Smooth coloring for better visuals
    M_smooth = log(M + 1);

    % Display
    imagesc([xmin xmax], [ymin ymax], M_smooth);
    set(gca, 'YDir', 'normal');
    axis equal tight;

    % Use colormap
    colormap(hot(256));
    colorbar;

    xlabel('Real');
    ylabel('Imaginary');
    title(sprintf(['%s (Iterations: %d)\n' ...
           '1:Mandelbrot 2:Julia 3:Burning Ship 4:Tricorn | Click:Zoom | r:Reset'], ...
           fractal_name, max_iter));
end

function mouse_click(src, event)
    global xmin xmax ymin ymax;

    point = get(gca, 'CurrentPoint');
    x_click = point(1,1);
    y_click = point(1,2);

    button = get(gcf, 'SelectionType');

    if strcmp(button, 'normal')
        zoom_factor = 0.4;
    elseif strcmp(button, 'alt')
        zoom_factor = 2.5;
    else
        return;
    end

    x_range = (xmax - xmin) * zoom_factor / 2;
    y_range = (ymax - ymin) * zoom_factor / 2;

    xmin = x_click - x_range;
    xmax = x_click + x_range;
    ymin = y_click - y_range;
    ymax = y_click + y_range;

    draw_fractal();
end

function key_press(src, event)
    global fractal_type xmin xmax ymin ymax max_iter;

    key = event.Character;

    if key == '1'
        fractal_type = 1;
        reset_view();
        disp('Switched to Mandelbrot Set');
        draw_fractal();
    elseif key == '2'
        fractal_type = 2;
        reset_view();
        disp('Switched to Julia Set');
        draw_fractal();
    elseif key == '3'
        fractal_type = 3;
        reset_view();
        disp('Switched to Burning Ship');
        draw_fractal();
    elseif key == '4'
        fractal_type = 4;
        reset_view();
        disp('Switched to Tricorn');
        draw_fractal();
    elseif key == 'r'
        reset_view();
        disp('Reset to initial view');
        draw_fractal();
    elseif key == '+'
        max_iter = min(max_iter + 50, 1000);
        disp(sprintf('Increased iterations to %d', max_iter));
        draw_fractal();
    elseif key == '-'
        max_iter = max(max_iter - 50, 50);
        disp(sprintf('Decreased iterations to %d', max_iter));
        draw_fractal();
    elseif key == 'q'
        disp('Closing fractal explorer...');
        close(gcf);
    end
end

% Run the explorer
multi_fractal();
