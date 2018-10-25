function [new_r] = split_frequency(r, pos_sample, pos_repair, w_bin, iterations)
    % Convert rectangle to points, to use in subcript operators.
    x0 = pos_repair(1); y0 = pos_repair(2);
    x1 = pos_repair(3)+x0; y1 = pos_repair(4)+y0;
    
    new_r = r;
    w_bin = imcrop(w_bin(:,:), pos_repair);  % Mask for the given subimage.
    w_soft = binary_to_soft_edged_mask(w_bin);
    
    % Split with lowpass filter.
    lpf = fspecial('gaussian', size(w_soft), 5);
    % The maximum has to be 1.0, so the filter has to be scaled.
    lpf = lpf / max(max(lpf));  % Note: just using lpf[0,0] or the center is equivalent.
    % Shift the gaussian filter to center over the high frequencies and invert it.
    hpf = 1 - fftshift(lpf);
	hpf(1, 1) = 1;          % Note: forgot to pass the AC coefficient as-is.
	hpf = fftshift(hpf);
    
    for b = 1:size(r, 3)  % Process all bands separately.
        s = imcrop(r(:,:,b), pos_sample);  % Get the sample subimage.
        S = fft2(s);
        S_high = S .* hpf;
        mag_S = abs(S_high);
        r_0 = imcrop(r(:,:,b), pos_repair);  % Get the repair subimage.
        r_n = r_0;
        
        for n = 1:iterations
            R_n = fft2(r_n);

            % P_split projection.
            R_high = R_n .* hpf;
            r_high = ifft2(R_high);
            R_low = R_n - R_high;
            r_low = ifft2(R_low);
            
            phase = angle(R_high);
            
            % P_min projection.
            new_magnitude = arrayfun(@min, mag_S, abs(R_high));
            % Create new imaginary matrix using R's phase angle and the
            % min's magnitude.
            R_n = new_magnitude .* exp(1i*phase);
            r_n = ifft2(R_n);
            
            % P_replace projection.
            r_n = r_n.*w_soft + r_high.*(1 - w_soft);

            % P_merge projection.
            r_n = r_n + r_low;
            
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