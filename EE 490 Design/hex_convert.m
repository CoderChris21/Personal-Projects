function y = hex_convert(x)
    y = [];
    for i = 1:length(x)
        y = [y str2num(x(i))];
    end
end
