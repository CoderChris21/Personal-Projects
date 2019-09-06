% find_match.m
% finds best word match based on error calculations
% input x: lpc matrix of words in file
% output err: output matrix of error per word.  So in each row, each
% element represents the error between the word and the average lpc value
% for each.  Each row corresponds to a word in the file.  
% 5 words = 5 x 10 matrix, 10 words = 10 x 10 matrix etc....
function [y,err] = find_match(x)
    y = [];
    for i = 1:size(x,1)
        % extracts row
        temp_lp = x(i,:);
        % constructs error matrix for each word 1-10
        temp = error_mat(temp_lp);
        % calculates error per word via codebook
        for j = 1:size(temp,1)
            err_temp(j) = sqrt(sum(temp(j,:).^2));
        end
        % stores all errors in matrix
        err(i,:) = err_temp;
        % Matched Word
        choice = find(err_temp == min(err_temp));
        if length(choice) > 1
            choice = choice(1);
        end
            y =[y; choice]; 
    end
    y = y';


