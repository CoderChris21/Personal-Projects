% MATLAB Function to convert signed fractional decimal number to 16-bit fixed
% point binary
% X : input value in decimal form
% y: output vectory in binary
function y = fp_bin(x)
    format short;
    y = [];
    temp = abs(single(x));
    for i = 1:16
        temp = temp*2;
        if temp > 1
            y = strcat(y,'1');
            temp = temp-1;
        else
            y = strcat(y,'0');
        end
    end
end
