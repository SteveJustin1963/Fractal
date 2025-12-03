function handle_mouse(src, evt)
    global g_xmin g_xmax g_ymin g_ymax g_fig;

    button = get(g_fig, 'SelectionType');

    if strcmp(button, 'normal')  % Left click - drag zoom
        set(g_fig, 'WindowButtonDownFcn', '');
        set(g_fig, 'KeyPressFcn', '');

        point1 = get(gca, 'CurrentPoint');
        rect_start = point1(1, 1:2);

        rbbox();

        point2 = get(gca, 'CurrentPoint');
        rect_end = point2(1, 1:2);

        x1 = rect_start(1);
        y1 = rect_start(2);
        x2 = rect_end(1);
        y2 = rect_end(2);

        dx = abs(x2 - x1);
        dy = abs(y2 - y1);

        if dx > (g_xmax - g_xmin) * 0.02 && dy > (g_ymax - g_ymin) * 0.02
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

            fprintf('Zooming to selected area...\n');
            draw_fractal();
        end

        set(g_fig, 'WindowButtonDownFcn', @handle_mouse);
        set(g_fig, 'KeyPressFcn', @handle_keyboard);

    elseif strcmp(button, 'alt')  % Right click - zoom out
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
