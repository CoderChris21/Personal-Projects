Library IEEE;
Use IEEE.STD_LOGIC_1164.ALL;

Entity dec2to4_test is

end dec2to4_test;

architecture behavioral of dec2to4_test is

component dec2to4 is
  Port(
    Enable    : in  STD_LOGIC;
    SW        : in  STD_LOGIC_VECTOR(1 downto 0);
    LED       : out STD_LOGIC_VECTOR(1 downto 0)
    );
end component;

--Inputs
signal test_seq   :std_logic_vector(2 downto 0);
--Outputs
signal led        :std_logic_vector(3 downto 0);

begin
  
  UUT:dec2to4 
  Port Map(
  Enable    => test_seq(2),
  SW        => test_seq(1 downto 0),
  led       => led
  );
  
--Stimulus Process
  stim_proc:process
  begin
    test_seq <= "000";
    wait for 10ns;
    test_seq <= "001";
    wait for 10ns;
    test_seq <= "010";
    wait for 10ns;
    test_seq <= "011";
    wait for 10ns;
    test_seq <= "100";
    wait for 10ns;
    test_seq <= "101";
    wait for 10ns;
    test_seq <= "110";
    wait for 10ns;
    test_seq <= "111";
    wait;
  end process;
  
end behavioral;
