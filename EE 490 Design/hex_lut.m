function y = hex_lut(x)
    switch x
        case '0'
            y = 0;
        case '1'
            y = 1;
        case '2'
            y = 2;
        case '3' 
            y = 3;
        case '4'
            y = 4;
        case '5'
            y = 5;
        case '6' 
            y = 6;
        case '7'
            y = 7;
        case '8'
            y = 8;
        case '9'
            y = 9;
        case 'A'
            y =10;
        case 'B'
            y = 11;
        case 'C'
            y = 12;
        case 'D'
            y = 13;
        case 'E'
            y = 14;
        case 'F' 
            y = 15;
        otherwise
            print('Error not Hex Value');
    end           
end
