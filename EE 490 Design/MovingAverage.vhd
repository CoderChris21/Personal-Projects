library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity MovingAverage is
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
end entity;

architecture RTL of MovingAverage is
   -- Can also normalize [0,1] with unsigned if necessary
   type mat_vector is array (0 to 2**pwr-1) of signed(N-1 downto 0);
   -- register for storing previous samples via Circcular Buffering
   signal master_reg        :mat_vector; 
   -- Pointers
   signal read_data         :signed(N-1 downto 0);
   signal write_data        :signed(N-1 downto 0);
   signal read_point        :integer :=0;
   signal write_point       :integer :=0;
   -- accumulator
   signal sum               :signed(N+pwr-1 downto 0);
   signal diff              :integer :=0;
   signal ct                :integer :=0;
 
   
begin
x: process(rst,clk)
   variable write_ptr       : integer  := 0;
   variable read_ptr        : integer  := 0;
   variable temp            : integer  := 0;
   variable count           : integer  := 0;
begin
   if Rst = '1' then
         data_out       <= (others => '0');
         master_reg     <= (others=>(others => '0'));
         sum            <= (others => '0');
         count          := 0;
         read_ptr       := 0;
         write_ptr      := 0;
         temp           := 0;
         read_point     <= read_ptr;
         write_point    <= write_ptr;
    elsif rising_edge(Clk) then
        if en = '1' then
            if (count = 0) then
                read_point      <= read_ptr;  
                temp := 256-read_ptr; 
                diff <= temp; 
                read_data   <= master_reg(master_reg'length-temp); 
                sum         <= sum - master_reg(master_reg'length-temp); 
                read_ptr    := read_ptr + 1;
                count := count + 1;
                if (read_ptr > 2**pwr-1)then 
                    read_ptr  :=0;
                end if;
            else
                write_point     <= write_ptr;
                master_reg(write_ptr) <= signed(data_in);
                write_data  <= signed(data_in);
                sum   <= sum + signed(data_in);
                write_ptr        := write_ptr + 1;
                count := 0;
                if (write_ptr > 2**pwr-1)then 
                    write_ptr  :=0;
                end if;
            end if;
        else
            sum<=sum;
        end if;         
    -- Division by 256 is the same as bit shift left 8 times.
	-- 2^8 = 256.  Therefore, shift left 8 times.
       data_out <= std_logic_vector(sum(N+pwr-1 downto pwr)); 
   end if; 
end process;

end architecture;
