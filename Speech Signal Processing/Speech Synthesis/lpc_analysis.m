% lpc_analysis.m 
% Reads a .wav file to do LPC analysis on, and outputs them in order to
% re-synthesize speech.
% -------------------------------------Inputs------------------------------
% X - Input file to read in .wav format
% ord - LPC Predictor Order
%-------------------------------------Outputs------------------------------
% frames_lpc - LPC coefficients per frame
% pwr - variance of the error calculated from LPC coefficients.
% frame_size - frame size or length based on sampling frequency of the
% input file and a 20ms frame length.
% vus - vector of voiced/unvoiced/silence decision where it is discretized
% as follows: voiced [2] , unvoiced [1] , silence [0]
% f_p - Pitch frequency calculations per frame.
% fs - sampling frequency
% win - windowing function
function [frames_lpc,pwr,frame_size,vus, f_p,fs, win] = lpc_analysis(X,ord)
    [y,fs] = audioread(X);
    [b,a] = butter(3,100/4000,'high');  %HPF to remove low-freq offsets
    y_out = filter(b,a,y);
    
    % Framing The Signal
    frame_step = 0.02;                          overlap = round(0.0005*fs);
    frame_size = round(frame_step*fs);          n = length(y_out);
    % Number of frames 
    n_f = floor(n/(frame_size-overlap));    
    curr_frame = 0; % Frame counter/iterator

    % Create frames
    frames = ones(n_f,frame_size);            
    for a = 1 : n_f
       frames(a,:) = y_out(curr_frame+1 : curr_frame+frame_size);
       curr_frame = curr_frame + frame_size-overlap;
    end
    % -----------------Preallocations for loops-------------------------------
            % Windowing Function                % Pitch of each Frame         
    win = hanning(frame_size);                  f_p = zeros(n_f,3);                  
            % FFT                               %Windowing
    f_frames = ones(n_f,frame_size);    win_frames = ones(n_f,frame_size);
            % Frame Energy                      % Zero Crossing
    eng = ones(1,n_f);                          zcr = ones(1,n_f); 
            % LPC Coefficients                  % LPC Error Variance
    frames_lpc = ones(n_f,ord+1);               pwr = ones(1,n_f);   
            % Magnitude of LPC Spectrum         % Frequency Locations
    h = zeros(n_f,512);                         w = zeros(n_f,512);
            % Signal LPC Representation
    y_lpc = [];
    %--------------------------------------------------------------------------
    for b = 1:n_f
        % Frequency Spectrum of Frames
        f_frames(b,:) = fft(frames(b,:));
        % Windowed Frames 
        win_frames(b,:) = win'.*frames(b,:);
        % Calculating frame energy to distinguish speech
        eng(b)= sum(abs(win_frames(b,:)).^2);
        % Zero Crossing Rate
        zcr(b) = zcd(win_frames(b,:));
        % Pitch of each Frame
        f_p(b,:) = Pitch(win_frames(b,:),fs);
        % Generating LPC Coefficients
        [frames_lpc(b,:), pwr(b)] = lpc(win_frames(b,1:end-overlap),ord);
        % LPC for entire signal
        y_lpc = [y_lpc frames_lpc(b,:)];
        % Generates LPC Spectrum
        [h(b,:), w(b,:)] = freqz(1,frames_lpc(b,:),512);
    end
    % Moving Average for a smoother signal
    eng_x = movmean(eng,5);
    zcr_x = movmean(zcr,5);

    % Finds Local Min and Max for Energy/ZCR
    lmax_e = islocalmax(eng_x > 0.01*max(eng_x));
    lmin_e = islocalmin(zcr_x);

    % Shows Locations of Local Maximas & Minimas for Thresholds
    % To Plot, Uncomment
    % X-axis vector
    % tx = 1:length(zcr_x);
    % Plotting Local Minimas for ZCR Threshold
    % plot(tx,zcr_x,tx(lmin_e),zcr_x(lmin_e),'r*')
    % Plotting Local Maximas for Signal Energy Threshold
    % plot(tx,eng_x,tx(lmax_e),eng_x(lmax_e),'r*')

    thres_e = min(eng_x(lmax_e)); 
    thres_z = max(zcr_x(lmin_e));

    % Word Count
    sig = eng_x;   words = 0;
    % Voiced/Unvoiced/Silence 
    vus = eng_x;

    for c = 1:length(eng_x)
        %Setting thresholds for speech
        if (eng_x(c) >= thres_e)
            sig(c) = 1;
        else
            sig(c) = 0;
        end 
        if (eng_x(c) >= thres_e)&&(zcr_x(c) <= thres_z)
            % Voiced Decision
            vus(c) = 2;
        elseif (eng_x(c) < thres_e) && (zcr_x(c) > thres_z)
            % Unvoiced Decision
            vus(c) = 1;
        else
            % Silence Decision
            vus(c) = 0;
        end
        if c > 1 && (sig(c) > sig(c-1)) 
            words = words + 1;
        end
    end
    fprintf('Number of Words Detected Method 1: %3.0f',words)     
    fprintf('           Thres: %3.4f  \n',thres_e)
%% Plots and Troubleshooting
% Plots each frame vs LPC spectrum
f = ((1:frame_size/2)-1)/frame_size*fs;         % Frequency Vector
% ---------------------Example Plot---------------------------------------
z = 25;
subplot(2,1,1)
plot(f,abs(f_frames(z,(1:end/2))))
title('FFT Spectrum of Frame')
subplot(2,1,2)
plot(abs(h(z,:)))
title('LPC Spectrum of Frame')
% -------Uncomment to pick a specific frame to look at FFT vs LPC spectrum
% j = input('Plot which frame? ');
% subplot(2,1,1)
% plot(f,abs(f_frames(j,(1:end/2))))
% title('FFT Spectrum of Frame')
% subplot(2,1,2)
% plot(abs(h(j,:)))
% title('LPC Spectrum of Frame')


% Plots Original Speech Signal 
max_t = (1/fs)*length(y_out);
t = 0:max_t/length(y):max_t-(1/fs);

sig_t = (1/fs)*length(sig);
t2 = 0:sig_t/length(sig):sig_t-(1/fs);
figure(2)
subplot(3,1,1)
plot(t,y_out)
title('Speech Signal in Time Domain')
subplot(3,1,2)
plot(t2,sig)
title('End Point Detection')
xlim([0 t2(end)])
subplot(3,1,3)
plot(y_lpc)
title('LPC Coefficients')
subplot(3,1,3)
plot(pwr)
title('Power Spectrum of Signal')
% Save output variables to matlab directory
save('LPC_OUT','frames_lpc','pwr','frame_size','vus','f_p','fs','win');
end
