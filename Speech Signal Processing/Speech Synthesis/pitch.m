% Determines Pitch Period 
% Takes an 512-point FFT and calculates peak frequencies from there to 
% determine fundamental and harmonic frequencies.  Finds 3 most prominent 
% peaks.  If less than 3, it pads with zeros instead.
%--------------------Inputs-----------------------------------------------
% x - Input signal with window already applied.
% Fs - sampling frequency
%--------------------Outputs----------------------------------------------
% fout - output frequency locations of 3 most prominent peaks 
function fout = Pitch(x,Fs)
    n = 512;
    % Computes 512-point FFT
    X = abs(fft(x,n));
    X = X(1:n/2); 
    f = ((1:n)-1)/n*Fs;
    % Finds peaks from highest peak to lowest
    [~, locs] = findpeaks(X,'npeaks',3,'sortstr','descend');
    % Gives frequency location of where peaks occur 
    fout = sort( f(locs) );
    % If peaks are less than 3, pad with zeros
    if length(fout) < 3
        fout(3) = 0;
    end
end
