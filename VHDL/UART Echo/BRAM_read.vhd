----------------------------------------------------------------------------------
-- Engineer: Chris Sam
-- Date: 12/4/2020
-- Module Name: BRAM_read
-- Description: 
-- Reads from BRAM once data has been written to it.  Address to be read is sent 
-- through double_flop, crossing clock domains while addressing metastable conditions 
-- that may arise.  Read for 2 cycles due to BRAM read latency.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity BRAM_read is
generic (bit_width	: integer := 8);
    Port ( 
        clk         : IN STD_LOGIC;
        rst         : IN STD_LOGIC;
        bram_dv     : IN STD_LOGIC;
        data_in     : IN  STD_LOGIC_VECTOR(bit_width-1 downto 0);
        ff_addr     : IN STD_LOGIC_VECTOR(8 downto 0);
        rd_bram     : OUT STD_LOGIC;
        fifo_rdy    : OUT STD_LOGIC;
        rd_addr     : OUT STD_LOGIC_VECTOR(8 downto 0);
        data_out    : OUT STD_LOGIC_VECTOR(bit_width-1 downto 0)
    );
end BRAM_read;

architecture Behavioral of BRAM_read is

type state_type is (stby, bram_wait, wait_cycle, bram_rd, fifo_wr, prep);
signal state    : state_type;

signal bram_data    :std_logic_vector(bit_width-1 downto 0);
signal fifo_data    :std_logic_vector(bit_width-1 downto 0);

signal i_bram_wr    : std_logic;
signal wip          : std_logic;
signal cnt          : integer range 0 to 5; --count for read cycle latency (2 clock edges)

begin
process(rst,clk)
begin
if rst = '1' then
    bram_data       <= (OTHERS => '0');
    fifo_data       <= (OTHERS => '0');
    rd_bram         <= '0';
    wip             <= '0';
    fifo_rdy        <= '0';
    cnt             <= 0;
    state           <= stby;
elsif rising_edge(clk) then
    case state is
    when stby =>
        if i_bram_wr = '1' then             --write in progress on BRAM
            wip         <= '1';
            state       <= bram_wait;
        else
            state       <= stby;
        end if;
        
    when bram_wait =>
        if i_bram_wr = '0' and wip = '1' then     --write finished on BRAM
            state       <= wait_cycle;
        else
            state       <= bram_wait;
        end if;
    
    when wait_cycle =>
        --2 cycle clock latency 
        rd_bram <= '1';
        if cnt = 2 then 
            rd_bram     <= '0';             --Stop read from BRAM
            state       <= bram_rd;
        else 
            cnt         <= cnt + 1 ;
            state       <= wait_cycle;
        end if;
        
    when bram_rd =>
        bram_data   <= data_in;
        state       <= fifo_wr;
        
    when fifo_wr =>
        fifo_rdy    <= '1';                  --Write to FIFO
        fifo_data   <= bram_data;            -- Latch data to output register
        state       <= prep;
        
    when prep =>
        bram_data       <= (OTHERS => '0');
        wip             <= '0';
        fifo_rdy        <= '0';
        cnt             <= 0;
        state           <= stby;
    end case;
end if;

end process;

i_bram_wr       <= bram_dv;                 --once signal pulses, data has been written to BRAM and can be read from
rd_addr         <= ff_addr;                 --read addr obtained thru FF
data_out        <= fifo_data;

end Behavioral;
