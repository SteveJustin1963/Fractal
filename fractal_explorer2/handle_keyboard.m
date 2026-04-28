function handle_keyboard(src, evt)
    global g_fractal_type g_xmin g_xmax g_ymin g_ymax g_max_iter g_fig g_quality;

    key = evt.Character;

    if ~isempty(key)
        fprintf('Key: "%s"\n', key);
    end

    changed = false;

    if key == '1' && g_fractal_type != 1
        g_fractal_type = 1;
        reset_view();
        fprintf('→ Mandelbrot Set\n');
        changed = true;
    elseif key == '2' && g_fractal_type != 2
        g_fractal_type = 2;
        reset_view();
        fprintf('→ Julia Set\n');
        changed = true;
    elseif key == '3' && g_fractal_type != 3
        g_fractal_type = 3;
        reset_view();
        fprintf('→ Burning Ship\n');
        changed = true;
    elseif key == '4' && g_fractal_type != 4
        g_fractal_type = 4;
        reset_view();
        fprintf('→ Tricorn\n');
        changed = true;
    elseif key == 'r'
        reset_view();
        fprintf('→ Reset view\n');
        changed = true;
    elseif key == '+'
        g_max_iter = min(g_max_iter + 50, 1000);
        fprintf('→ Iterations: %d\n', g_max_iter);
        changed = true;
    elseif key == '-'
        g_max_iter = max(g_max_iter - 50, 50);
        fprintf('→ Iterations: %d\n', g_max_iter);
        changed = true;
    elseif key == 'f'
        g_quality = 0;
        fprintf('→ Fast mode\n');
        changed = true;
    elseif key == 'n'
        g_quality = 1;
        fprintf('→ Normal quality\n');
        changed = true;
    elseif key == 'h'
        g_quality = 2;
        fprintf('→ High quality\n');
        changed = true;
    elseif key == 'q'
        fprintf('Closing...\n');
        close(g_fig);
        return;
    end

    if changed
        draw_fractal();
    end
end
