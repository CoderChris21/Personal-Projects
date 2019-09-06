library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity reg is
  Port(
    clear     :in STD_LOGIC;
    load      :in STD_LOGIC;
    clock     :in STD_LOGIC;
    reset     :in STD_LOGIC;
    data_in   :in STD_LOGIC_VECTOR(7 downto 0);
    data_out  :out STD_LOGIC_VECTOR(7 downto 0));
  end reg;
  
  architecture behavioral of reg is
  begin
  process(clock,reset)
    begin
      if reset = '1' then
        data_out <= (others => '0');
      elsif rising_edge(clock) then
        if clear = '1' thn
          data_out <= (others => '0');
        elsif load = '1' then
          data_out <= data_in;
        end if;
      end if;
   end process;
  end behavioral;
