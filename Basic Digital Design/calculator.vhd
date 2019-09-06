
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity calculator is
  Port(
  A         :in STD_LOGIC_VECTOR(3 downto 0);
  B         :in STD_LOGIC_VECTOR(3 downto 0);
  reg_out   :in STD_LOGIC_VECTOR(7 downto 0);
  Add       :in STD_LOGIC;
  Reset     :in STD_LOGIC;
  AC        :in STD_LOGIC;
  Clock     :in STD_LOGIC
  );
end calculator;

architecture behavioral of calculator is
type state_type is (s1,s2,s3);
signal y: state_type;
signal A_8bit, B_8bit, sum  :std_logic_vector(7 downto 0);
signal clear, load          :std_logic;

component reg is
  Port(
    clear     :in STD_LOGIC;
    load      :in STD_LOGIC;
    clock     :in STD_LOGIC;
    reset     :in STD_LOGIC;
    data_in   :in STD_LOGIC_VECTOR(7 downto 0);
    data_out  :out STD_LOGIC_VECTOR(7 downto 0));
 end component;
 
 begin
 -- Control circuit
 -- specify state transitions
 FSM_transition:process(reset, clock)
 begin
  if reset = '1' then
    y <= s1;
  elsif rising_edge(clock) then
    case y is
    when s1 =>
      if AC = '1' then y <= s1;
      elsif Add = '1' then y <= s2;
      else y <= s3;
      end if;
    when s2 =>
      if AC = '1' then y <= s1;
      elsif Add = '1' then y <= s2;
      else y <= s3;
      end if;
    when s3 =>
      if AC = '1' then y <= s1;
      elsif Add = '1' then y <= s2;
      else y <= s3;
      end if;
    end case;
  end if;
end process;


FSM_action: process(y)
begin
  clear <= '1';
  load  <= '0';
  case y is 
    when s1 =>
      clear <= '1';
      load  <= '0';
    when s2 =>
      clear <= '0';
      load  <= '1';
    when s3 =>
      clear <= '0';
      load  <= '0';
    end case;
end process;

--Datapath Circuit
A_8bit <= "0000" & A;
B_8bit <= "0000" & B;

sum <= A_8bit + B_8bit;

register1: reg 
  port map(
  clear       => clear,
  load        => load,
  clock       => clock,
  reset       => reset,
  data_in     => sum,
  data_out    => reg_out
  );
  
end behavioral;
