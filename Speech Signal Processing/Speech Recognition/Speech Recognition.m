% Christopher Sam
% User-Defined Functions:
% classify.m - classifies speech into voice/unvoiced
% error_mat.m - calculates error matrix for a single spectral vector
% find_match.m - finds best matched word by calculating error from codebook
% getFrames.m - Obtains Corresponding Frames from classify.m
% TrainingSet.m - Training Set to determine spectral vectors
% zcd.m  - Zero Crossing Detection
%% Speech Recognition.m
clear all
[y,fs] = audioread('one.wav');
[b,a] = butter(3,100/4000,'high');  %HPF to remove low-freq offsets
 
y_out = filter(b,a,y);
[yh,yl] = envelope(y_out);
 
max_t = (1/fs)*length(y_out);
t = 0:max_t/length(y):max_t-(1/fs);
 
% Framing The Signal
frame_step = 0.02;                             overlap = round(0.005*fs);
frame_size = round(frame_step*fs);              n = length(y_out);
% Number of frames 
n_f = floor(n/(frame_size));    
curr_frame = 0; % Frame counter/iterator
 
% Create frames
frames = ones(n_f,frame_size);  
frames_y = ones(n_f,frame_size);  
for a = 1 : n_f
   frames(a,:) = yh(curr_frame+1 : curr_frame+frame_size);
   frames_y(a,:) = y_out(curr_frame+1 : curr_frame+frame_size);
   curr_frame = curr_frame + frame_size;
end
% -----------------Preallocations for loops-------------------------------
        % Windowing Function                       
win = hanning(frame_size);                                
        %Windowing
win_frames = ones(n_f,frame_size);
        % Frame Energy                             % Zero Crossing
eng = ones(1,n_f);                          zcr = ones(1,n_f);                                          
%--------------------------------------------------------------------------
for b = 1:n_f
    % Windowed Frames 
    win_frames(b,:) = win'.*frames(b,:);
    zcr_frames(b,:) = win'.*frames_y(b,:);
    % Calculating frame energy to distinguish speech
    eng(b)= sum(abs(win_frames(b,:)).^2);
    % Zero Crossing Rate
    zcr(b) = zcd(zcr_frames(b,:));
end
eng = eng./max(eng);
zcr = zcr./max(zcr);
% Moving Average for a smoother signal
eng_x = movmean(eng,5);
zcr_x = movmean(zcr,5);
 
% Finds Local Min and Max for Energy/ZCR
lmax_e = islocalmax(eng_x > 0.02*max(eng_x));
lmin_e = islocalmin(zcr_x > 0.6*max(zcr_x));
 
% % Shows Locations of Local Maximas & Minimas for Thresholds
% % To Plot, Uncomment
% % X-axis vector
tx = 1:length(zcr_x);
% % Plotting Local Minimas for ZCR Threshold
% figure(3)
% plot(tx,zcr_x,tx(lmin_e),zcr_x(lmin_e),'r*')
% title('Local Minimas for ZCR Threshold')
% % Plotting Local Maximas for Signal Energy Threshold
% figure(4)
% plot(tx,eng_x,tx(lmax_e),eng_x(lmax_e),'r*')
% title('Local Maximas for Energy Threshold')
 
thres_e = min(eng_x(lmax_e)); 
thres_z = max(zcr_x(lmin_e));
 
% End-Point Detection
vus = eng_x;
words = 0;
for c = 1:length(eng_x)
    if (eng_x(c) >= 0.05*thres_e)
        % Voiced Decision
        vus(c) = 1;
    else
        % Unvoiced Decision
        vus(c) = 0;
    end
    if c > 1 && (vus(c) > vus(c-1))
        words = words + 1;
    end
end
 
% Overlaying End-point detection
vus2frame = classify(vus);
vu = zeros(1,length(vus2frame));
ord = 10;
 
lp = [];
ep =[];
cnt = 1;
for a = 1:length(vus2frame)
    all = vus2frame{1,a};
    vu(a) = sum(vus2frame{2,a});
    if vu(a) > 0
        lp(cnt,:) = getFrames(all,frames_y,ord);
        % frame_w{1,cnt} = time_frame(all,frames_y);
        % f_e(a,:) = eng(all);
        ep = [ep ones(1,length(all)*(frame_size))];
        cnt = cnt+1;
    else
        ep = [ep zeros(1,length(all)*(frame_size))];
    end
end
% figure(5)
% spectrogram(y,fs,[]);
% title('Spectrogram for the Word Ten')
% 
% figure(6)
% hold on
% plot(y_out)
% plot(ep)
% xlabel('Time in Seconds')
% ylabel('Amplitude in Volts')
% title('End-Point Detection for the Word Ten')
 

[match,e] = find_match(lp);
