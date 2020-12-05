library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
generic (bit_width	: integer := 8;
         fclk       : real := 100000.0;  -- 100 MHz
         baud       : real := 115.2  -- 115.2 kBits/s
         );
port (
    clk     	  : IN  STD_LOGIC;		-- 100 MHz clock
    rst     	  : IN  STD_LOGIC;		-- active high reset
	  fifo_empty	: IN  STD_LOGIC;
    fifo_rd_en 	: OUT STD_LOGIC;
    fifo_dout	  : IN  STD_LOGIC_VECTOR(bit_width-1 downto 0);
	serial_out	  : OUT STD_LOGIC		-- asynchronous serial out	
 );
end uart_tx;

architecture Behavioral of uart_tx is

type state_type is (idle, rd_fifo, start_tx, bitstream,stop, clr);
signal state        : state_type;

signal empty        : std_logic;    -- logic 1 if FIFO is empty
signal fifo_reg     : std_logic_vector(bit_width-1 downto 0);
signal index        : integer range 0 to bit_width-1;

constant baud_eq   :integer:= integer(fclk/baud); 
signal   counter    :integer range 0 to baud_eq-1; 

begin
process(rst,clk)
begin
if rst = '1' then
    serial_out      <= '1';
    counter         <= 0;
    index           <= 0;
    fifo_rd_en      <= '0';
    fifo_reg        <= (OTHERS => '0');
    state           <= idle;
elsif rising_edge(clk) then
    case state is 
    when idle =>
    if empty = '0' then 
        fifo_rd_en  <= '1';             --read from FIFO to register
        state       <= rd_fifo;
    else
        state       <= idle;
    end if;
    
    when rd_fifo =>
        fifo_rd_en  <= '0';             --disable FIFO 
        state       <= start_tx;
        
    when start_tx =>
        fifo_reg    <= fifo_dout;
        serial_out  <= '0';           --Send start bit for TX
        --Transmit Start Bit for Baud Rate to System Clock Equivalent
        if counter = baud_eq then 
            counter   <= 0;
            state     <= bitstream;
        else    
            counter   <= counter + 1;
            state     <= start_tx;
        end if;
    
    when bitstream =>
        serial_out    <= fifo_reg(index);
        if counter = baud_eq then 
            counter   <= 0;
            if index < bit_width-1 then
                index   <= index + 1;
                state   <= bitstream;
            else
                state <= stop;
            end if;
        else    
            counter   <= counter + 1;
            state     <= bitstream;
        end if;
    
    when stop =>
        serial_out    <= '1';             -- send stop bit
        if counter = baud_eq then 
            counter   <= 0;
            state     <= clr;
        else    
            counter   <= counter + 1;
            state     <= stop;
        end if;
        
    when clr =>
        index           <= 0;
        counter         <= 0;
        fifo_reg        <= (OTHERS => '0');
        state       <= idle;
    
    end case;
end if;
end process;

empty           <= fifo_empty;


end Behavioral;
