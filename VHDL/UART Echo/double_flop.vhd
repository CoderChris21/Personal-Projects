----------------------------------------------------------------------------------
-- Engineer: Chris Sam
-- Date: 12/4/2020
-- Module Name: double_flop
-- Description: 
-- Sends BRAM address to be read from, crossing clock domains
-- from 75 to 100 Mhz.  To resolve metastability, synchronizer flip flops are used.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;


entity double_flop is
generic(width:  integer:= 9);
    Port ( 
        Clk  : in STD_LOGIC;
        Rst  : in STD_LOGIC;
        En   : in STD_LOGIC;
        D    : in STD_LOGIC_VECTOR(width-1 downto 0);
        Q    : out STD_LOGIC_VECTOR(width-1 downto 0));
end double_flop;

architecture Behavioral of double_flop is

signal En2    : std_logic;
signal En_reg : std_logic;

begin
process(rst,clk)
  begin
  if rst = '1' then
    Q    <=  (OTHERS => '0');
  elsif rising_edge(clk) then
    En2 	<= En;
	  En_reg 	<= En2;
	  if En_reg = '1' then
      Q    <= D;       
    end if;
  end if;
end process;

end Behavioral;
