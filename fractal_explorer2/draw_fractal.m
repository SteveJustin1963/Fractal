function draw_fractal()
    global g_fractal_type g_xmin g_xmax g_ymin g_ymax g_max_iter g_fig g_quality;

    fprintf('Computing... ');
    tic;

    % Resolution based on quality
    switch g_quality
        case 0
            width = 500; height = 375;
        case 1
            width = 700; height = 525;
        otherwise
            width = 1000; height = 750;
    end

    % Create coordinate mesh
    x = linspace(g_xmin, g_xmax, width);
    y = linspace(g_ymin, g_ymax, height);
    [X, Y] = meshgrid(x, y);
    C = X + 1i*Y;

    % Compute fractal with optimization
    M = compute_fractal(C, g_max_iter, g_fractal_type);

    % Apply smooth coloring
    M_display = log(M + 1);

    % Get fractal name
    names = {'Mandelbrot Set', 'Julia Set', 'Burning Ship', 'Tricorn'};
    fname = names{g_fractal_type};

    % Render to figure
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
    title_str = sprintf('%s [%s] (iter=%d) | Drag=zoom | f/n/h=quality', ...
                       fname, quality_names{g_quality + 1}, g_max_iter);
    title(title_str, 'Color', [1 1 1], 'FontWeight', 'bold');

    % Restore callbacks
    set(g_fig, 'WindowButtonDownFcn', @handle_mouse);
    set(g_fig, 'KeyPressFcn', @handle_keyboard);

    fprintf('done (%.2fs)\n', toc);
end
