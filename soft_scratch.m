function [new_r] = soft_scratch(r, pos_sample, pos_repair, w_bin, iterations)
% SOFT_SCRATCH Same as base algorithm, except using a soft-edged mask
% instead of a binary mask.
    % Convert rectangle to points, to use in subcript operators.
    x0 = pos_repair(1); y0 = pos_repair(2);
    x1 = pos_repair(3)+x0; y1 = pos_repair(4)+y0;
    
    new_r = r;
    w_bin = imcrop(w_bin(:,:), pos_repair);  % Mask for the given subimage.
    w_soft = binary_to_soft_edged_mask(w_bin);
    
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
            r_n = r_n.*w_soft + r_0.*(1 - w_soft);
        end
        new_r(y0:y1, x0:x1, b) = r_n;
    end
end