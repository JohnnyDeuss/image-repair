function [new_r] = base_algorithm(r, pos_sample, pos_repair, noise_mask, iterations)
    % Convert rectangle to points, to use in subcript operators.
    x0 = pos_repair(1); y0 = pos_repair(2);
    x1 = pos_repair(3)+x0; y1 = pos_repair(4)+y0;
    
    new_r = r;
    local_mask = imcrop(noise_mask(:,:), pos_repair);  % Mask for the given subimage.
    
    for b = 1:size(r, 3)  % Process all bands separately.
        s = imcrop(r(:,:,b), pos_sample);  % Get the sample subimage.
        S = fft2(s);
        mag_S = abs(S);
        r_0 = imcrop(r(:,:,b), pos_repair);  % Get the repair subimage.
        r_n = r_0;
            
        for n = 1:iterations
            R_n = fft2(r_n);
            phase = angle(R_n);
            
            % P_min-dc projection.
            new_magnitude = arrayfun(@min, mag_S, abs(R_n));
            % Keep magnitude of R's DC component (only needed when not using A3).
            new_magnitude(1, 1) = R_n(1, 1);
            % Create new imaginary matrix using R's phase angle and the
            % min's magnitude.
            R_n = new_magnitude .* exp(1i*phase);
            r_n = ifft2(R_n);
            
            % P_real projection.
            r_n = real(r_n);  % Drop imaginary component.
            r_n(r_n < 0) = 0;  % Bring back into range [0,255]
            r_n(r_n > 255) = 255;
            
            % P_replace projection.
            r_n = r_n.*local_mask + r_0.*(1 - local_mask);
        end
        new_r(y0:y1, x0:x1, b) = r_n;
    end
end