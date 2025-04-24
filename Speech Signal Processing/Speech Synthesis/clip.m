% Center-Clipping Function
% Center clips function to be used before autocorrelation
function  x = clip(x) 
% Defines clipping threshold at approx. 30% of signal max
threshold = 0.3*abs(max(x));
    for i = 1:length(x)
        if abs(x(i)) < threshold
            x(i) = 0;
        elseif x(i) > threshold
            x(i) = x(i) - threshold;
        else
            x(i) = x(i) + threshold;
        end
    end
end
