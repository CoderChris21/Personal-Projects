% getFrames.m
% Given a vector corresponding to frames, it produces a vector containing
% all the data points of that frame.
%------------------Inputs----------------------------------
% x - input vector
% y - frames corresponding to the input vector
% ord - LPC predictor order
%------------------Outputs---------------------------------
% vec - output averaged LPC coefficients
 
function vec = getFrames(x,y,ord) 
    v = zeros(length(x),ord+1);
    for i = 1:length(x)
        v(i,:) = lpc(y(x(i),:),ord);
    end
    % Averages LPC Coefficients
    vec = mean(v);
end
