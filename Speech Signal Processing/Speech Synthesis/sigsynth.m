% sigsynth.m
% Resynthesizes speech based on LPC analysis parameters from EE428.m
% ---------------------------------Inputs---------------------------------
% x_lpc - Input lpc coefficients in matrix form.
% p - variance of the error calculated from LPC coefficients.
% vus - discrete vector with voiced/unvoiced/silence decisions from signal 
% frames.
% f_vec - Pitch frequency calculations per frame
% f_size - frame size
% fs- sampling frequency
% w - windowing function.  Default: bartlett window of length frame size.
% --------------------------------Outputs--------------------------------
% s_n - Output waveform of speeech signal based on LPC.
function s_n = sigsynth(x_lpc,p,vus,f_vec,f_size,fs,w)
    if nargin < 5
        w = bartlett(frame_size);
    end
    overlap = round(0.0005*fs);
    % Speech Synthesis
    s_n = [];     
    for i = 1:length(x_lpc)
        switch vus(i)
            case 2
                freq = f_vec(i,:);
                z = freq/freq(1);
% Rounding to one decimal place and subtracting each peak to determine if
% harmonics are present.  If they are, then frequency intervals between
% each peak should be very close to each other.
                if (round(z(1)-z(2),1) == round(z(2)-z(3),1))
                    s = w'.*filter(1,x_lpc(i,:),sqrt(p(i))*excite(f_size,freq(1)));
                    s_n = [s_n(1:end-2*overlap)  s];
                else
                    s = filter(1,x_lpc(i,:),sqrt(p(i))*rand([1 f_size]));
                    s_n = [s_n(1:end-2*overlap)  s];
                end
            case 1
                    s = filter(1,x_lpc(i,:),sqrt(p(i))*rand([1 f_size]));
                    s_n = [s_n(1:end-2*overlap)  s];
            otherwise
                s = zeros(1,f_size);
                s_n = [s_n(1:end-2*overlap) s];     
        end
    end
    s_n = 10*s_n;
    sound(s_n,fs)
end
