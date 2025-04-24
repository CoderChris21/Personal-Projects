% Calc_Error.m
% Calculates the error between two vectors of the same length.  If they are
% not the same length, it returns an error.
%-----------------Inputs--------------------------------------------------
% x,y - vectors to calculate error between
%----------------Outputs--------------------------------------------------
% z - output error per element between each input element.
function z = Calc_Error(x,y)
    if length(x) ~= length(y)
        print('Error Vectors not same Length !');
    else
        z = zeros(1, length(x));
        for i = 1:length(x)
            z(i) = (x(i) - y(i))^2;
        end
    end
end
