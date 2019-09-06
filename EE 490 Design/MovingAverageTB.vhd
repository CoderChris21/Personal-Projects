library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.TEXTIO.ALL; 
USE IEEE.STD_LOGIC_TEXTIO.ALL;

entity MovingAverage_tb is
--  Port ( );
end MovingAverage_tb;

architecture Behavioral of MovingAverage_tb is

    component MovingAverage is
        generic (
            N    :integer := 16;
            pwr  :integer := 8
        );
        port (
            Clk         :in std_logic;
            Rst         :in std_logic;
            en          :in std_logic;
            data_in     :in std_logic_vector(N-1 downto 0);
            data_out    :out std_logic_vector(N-1 downto 0)
        );
    end component;
    
    file file_in    : text is in "C:/Users/ChristopherSam/test_data/test_data.srcs/sim_1/new/EMG_G.txt";
    file file_out   : text;
    -- Inputs    
    signal Clk         :std_logic;
    signal Rst         :std_logic := '0';
    signal en          :std_logic;
    signal data_in     :std_logic_vector(15 downto 0);
     -- Outputs
    signal data_out    :std_logic_vector(15 downto 0);
    
    -- Clock process definitions
    constant CLK_period : time := 5 ns;
    
    begin
    
    -- Instantiate Unit Under Test
    uut:MovingAverage
        PORT MAP(
        Clk             => Clk,
        Rst             => Rst,
        en              => en,
        data_in         => data_in,
        data_out        => data_out
        );
        
	CLK_process :process
	begin
		CLK <= '0';
		wait for CLK_period;
		CLK <= '1';
		wait for CLK_period;
	end process;
	
		-- Reset process
	rst_proc : process
	begin
		Rst <= '1';
		wait for 10 ns;
		Rst <= '0';
		wait;
	end process;
	
	-- Write process
	text_test1 : process
	variable v_ILINE     : line;
    variable v_OLINE     : line;
    variable d_in        : std_logic_vector(15 downto 0);
    variable space       : character;
    variable d_out       : std_logic_vector(15 downto 0);
	begin		
	    file_open(file_in, "EMG_G.txt",  read_mode);
        file_open(file_out, "G_Out.txt", write_mode);
    while not endfile(file_in) loop
        readline(file_in, v_ILINE);
        read(v_ILINE, d_in);
      -- Value From Text File treated as Data In to Moving Average
        en <= '1';
        data_in    <= d_in;
        wait for 20 ns;
        write(v_OLINE,data_out,right,16);
        writeline(file_out, v_OLINE);
    end loop;
 
    file_close(file_in);
    file_close(file_out);
     
    wait;
    
	end process;
end Behavioral;
