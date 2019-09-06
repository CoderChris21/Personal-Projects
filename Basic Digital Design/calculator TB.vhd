library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity calculator_tb is
end calculator_tb;

architecture of calculator_tb is
component calculator is
  Port(
  A         :in STD_LOGIC_VECTOR(3 downto 0);
  B         :in STD_LOGIC_VECTOR(3 downto 0);
  reg_out   :in STD_LOGIC_VECTOR(7 downto 0);
  Add       :in STD_LOGIC;
  Reset     :in STD_LOGIC;
  AC        :in STD_LOGIC;
  Clock     :in STD_LOGIC
  );
end component;

--Inputs
signal A        :std_logic_vetor(3 downto 0) := (others => '0');
signal B        :std_logic_vetor(3 downto 0) := (others => '0');
signal Add      :std_logic := '0';
signal reset    :std_logic := '0';
signal AC       :std_logic := '0';
signal clock    :std_logic := '0';
--Outputs
signal reg_out  :std_logic_vetor(7 downto 0);

--Clock Definition
constant clock_period : time := 20 ns;
begin
  uut:calculator 
  port map (
  A       => A,
  B       => B,
  reg_out => reg_out,
  Add     => Add,
  Reset   => Reset,
  AC      => AC,
  Clock   => Clock
  );
  
clock_process:process
begin
  clock <= '0';
  wait for clock_period/2;
  clock <= '1';
  wait for clock_period/2;
end process;

stim_proc:process
begin
  reset <= '1';
  wait for 20ns;
  
  reset <= '0';
  wait for 20ns;
  
  A     <= "1100";
  B     <= "0011";
  Add   <= '1';
  wait for 20ns;
  
  Add   <= '0';
  wait for 20ns;
  
  AC <= '1';
  wait for 20ns;
  AC <= '0';
  wait for 20ns;
  
  A     <= "0100";
  B     <= "0001";
  Add   <= '1';
  wait for 20ns;
  
  Add   <= '0';
  wait for 20ns;
  
  reset <= '1';
  wait for 20ns;
  
  reset <= '0';
  wait for 20ns;
  
  A     <= "1000";
  B     <= "1000";
  Add   <= '1';
  wait for 20ns;
  
  Add   <= '0';
  wait for 20ns;
  
  AC    <= '1';
  wait for 20ns;
  
  AC    <='0';
  wait;
  
end process;
end;
