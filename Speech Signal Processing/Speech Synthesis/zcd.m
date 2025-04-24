% Function to detect zero crossing.  Input data should be a vector.
function y = zcd(x)
    % upward zero-crossings to nearest time step
    threshold_h = x(1:end-1) <= 0 & x(2:end) > 0;
    % downward zero-crossings
    threshold_l = x(1:end-1) >= 0 & x(2:end) < 0;
    y = sum(threshold_h) + sum(threshold_l);
