% MATLAB Function to convert 16-bit binary to decimal
% X : input text file
% y: output vector in decimal
function decimal = bin_dp(x)
    fileID = fopen(x);
    read_file = textscan(fileID,'%s');
    fclose(fileID);
    C = read_file{1,1}; 
    val = []; val2 = [];
    for i = 1:size(C,1)
        val = [val; C{i,1}];
    end
    for ii = 1:size(val,1)
        val2(ii,:) = hex_convert(val(ii,:));
    end
    hex = char(binaryVectorToHex(val2));
    decimal = [];
    for j = 1:length(hex)
        el_1 = hex_lut(hex(j,1));
        el_2 = hex_lut(hex(j,2));
        el_3 = hex_lut(hex(j,3));
        el_4 = hex_lut(hex(j,4));
        output = (el_1/16) + (el_2/256) + (el_3/4096) + (el_4)/65536;
        decimal = [decimal; output];  
    end
end
