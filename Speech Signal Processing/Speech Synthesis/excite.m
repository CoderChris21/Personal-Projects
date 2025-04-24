% excite.m
% Function to model impulse train at a specific pitch period.
%-------------------------Inputs-----------------------------------------
% N - Length of output signal
% Fp - Pitch frequency to generate impulse train at
function impulse_train = excite(N,Fp)
    impulse_train = zeros(1,N);
    temp = 1000*(1/Fp);
    for i = 1:length(impulse_train)
        if rem(i,temp) == 0
            impulse_train(i) = 1;
        end
    end
end
