function reset_view()
    global g_fractal_type g_xmin g_xmax g_ymin g_ymax;

    if g_fractal_type == 3  % Burning Ship has different bounds
        g_xmin = -2.0;
        g_xmax = 1.0;
        g_ymin = -2.0;
        g_ymax = 1.0;
    else
        g_xmin = -2.5;
        g_xmax = 1.5;
        g_ymin = -1.5;
        g_ymax = 1.5;
    end
end
