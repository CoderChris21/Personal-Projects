library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_rx is
generic (bit_width	: integer := 8;
         fclk       : real := 75000.0;  -- 75 MHz
         baud       : real := 115.2  -- 115.2 kBits/s
);
port (
    clk     	: IN  STD_LOGIC;								-- 100 MHz clock
    rst     	: IN  STD_LOGIC;								-- active high reset
	serial_in	: IN  STD_LOGIC;								-- asynchronous serial in
    fifo_wr_en 	: OUT STD_LOGIC;
    fifo_din	: OUT STD_LOGIC_VECTOR(bit_width-1 downto 0)
 );
end uart_rx;

architecture Behavioral of uart_rx is

type state_type is (idle,start_bit, data, stop,clear);
signal state:   state_type;

signal inbuf        :STD_LOGIC;
signal sdata        :STD_LOGIC;                       --serial data, active low start bit
signal index        :integer range 0 to bit_width-1;  --index for bit construction 

constant pulse      :integer:= integer(fclk/baud); 
signal p_count      :integer range 0 to pulse-1;     
signal outbuf       :STD_LOGIC_VECTOR(bit_width-1 downto 0); 

begin 

process(clk, rst)
begin
    if rst = '1' then
        index       <= 0;
        outbuf      <= (OTHERS => '0');
        p_count     <= 0;
        fifo_wr_en <= '0';
        state       <= idle;
        inbuf       <= '1';
        sdata       <= '1';
        fifo_din    <=(OTHERS => '0');
    elsif rising_edge(CLK) then 
        --Flopping Inputs
        inbuf   <= serial_in;
        sdata   <= inbuf;
        case state is
        when idle =>
        --start bit
        if sdata = '0' then
            p_count     <= 0;
            state       <= start_bit;
        else
            state <= idle;
        end if;

        when start_bit =>
            if p_count >= pulse/2 then    
                p_count         <= 0;
                if sdata = '0' then
                    state <= data;
                else
                    state <= idle;
                end if;
            else
                p_count     <= p_count + 1;
                state       <= start_bit;
            end if;
                        
        when data =>
            if p_count = pulse then    
                p_count         <= 0;
                outbuf(index)   <= sdata;       --assembles serial to parallel data assemble, LSB comes first. 
                if index < bit_width-1 then       
                    index           <= index + 1;
                    state           <= data;
                else
                    state           <= stop;
                end if;
            else
                p_count     <= p_count + 1;
                state       <= data;
            end if;
              
        when stop =>
            if p_count = pulse then    
                p_count         <= 0;
                fifo_wr_en      <= '1';         --data valid to be stored in FIFO    
                fifo_din        <= outbuf;
                state           <= clear;
            else
                p_count     <= p_count + 1;
                state       <= stop;
            end if;
            
        when clear =>
            fifo_wr_en          <= '0';         --clear misc signals back to "idle" state
            p_count             <= 0;
            outbuf              <= (OTHERS => '0');
            index               <= 0; 
            state               <= idle;    
        end case;
        
    end if;
end process;


end Behavioral;
