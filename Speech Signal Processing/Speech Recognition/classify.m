% Classify.m 
% Finds all the frames that are contained in end-point detection.  Given a
% discrete speech-silence signal, it groups all the frames corresponding to
% silence and speech and stores them in a cell-matrix.
%------Inputs-------------------------------------------
% vus - input silence-speech discrete signal
%------Outputs------------------------------------------
% test - output cell-maxtrix of corresponding frames
function test = classify(vus)
    test{1,1} = 1;
    test{2,1} = vus(1);
    index = 1;
    for z = 2:length(vus)
        if (z > 1) && (vus(z) == vus(z-1)) 
            test{1,index} = [test{1,index} z];
            test{2,index} = [test{2,index} vus(z)];
        else
            test{1,index+1} = z;
            test{2,index+1} = vus(z);
            index = index+1;
        end
    end 
