function [soft_edged_mask] = binary_to_soft_edged_mask(binary_mask)
    % Create a soft-edged mask from a binary mask. The new mask is
    % calculated using the distances to the binary mask passed through
    % a gaussian function with a = 1.0, mu = 0.0 and sigma = 3.0.

    % Distance to the binary mask.
    d = bwdist(binary_mask);
    % Apply Gaussian function on distances.
    soft_edged_mask = arrayfun(@(x)gaussian(x, 1.0, 0.0, 3.0), d);

    % TODO: the soft edge mask has a hard edge if the noise mask
    % crosses the bounds of the subimage.

    function [I] = gaussian(x, a, mu, sigma)
        I = a*exp(-(x-mu)^2/(2*sigma)^2);
    end
end