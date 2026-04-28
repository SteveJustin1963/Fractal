function M = compute_fractal(C, max_iter, ftype)
    % Optimized fractal computation - only processes active pixels
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
