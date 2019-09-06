Library IEEE;
Use IEEE.STD_LOGIC_1164.ALL;

Entity dec2to4 is
  Port(
    Enable    : in  STD_LOGIC;
    SW        : in  STD_LOGIC_VECTOR(1 downto 0);
    LED       : out STD_LOGIC_VECTOR(1 downto 0)
    );
end dec2to4;

architecture behavioral of dec2to4 is

begin
  
  led <= "0000" when enable = '0' else
         "0001" when sw = "00" else
         "0010" when sw = "01" else
         "0100" when sw = "10" else
         "1000";
end behavioral;
