% error_mat.m
% Calculates a spectral vector's error in comparison to established LPC
% values of codebook
%---------------Input-------------------------------
% x - spectral vector to calculate error for
%---------------Output------------------------------
% y - error matrix per word.  
% Each row is error for word.  Each element in a row is the error per LPC
% coefficient.
function y = error_mat(x)
    load('Codebook.mat');
    y = zeros(10,11);
    y(1,:) = Calc_Error(x,One);
    y(2,:) = Calc_Error(x,Two);
    y(3,:) = Calc_Error(x,Three);
    y(4,:) = Calc_Error(x,Four);
    y(5,:) = Calc_Error(x,Five);
    y(6,:) = Calc_Error(x,Six);
    y(7,:) = Calc_Error(x,Seven);
    y(8,:) = Calc_Error(x,Eight);
    y(9,:) = Calc_Error(x,Nine);
    y(10,:) = Calc_Error(x,Ten);
end
