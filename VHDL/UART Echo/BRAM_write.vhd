----------------------------------------------------------------------------------
-- Engineer: Chris Sam
-- 
-- Module Name: BRAM_write
-- Description: 
-- Writes to BRAM once data has been received via UART and stored in fifo.  Instead
-- of writing to same address, it will use the next address the next time data is 
-- received.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity BRAM_write is
generic (bit_width	: integer := 8);
    Port 
    (       clk         : IN STD_LOGIC;
            rst         : IN STD_LOGIC;
            fifo_wr     : IN STD_LOGIC;
            din         : IN  STD_LOGIC_VECTOR(bit_width-1 downto 0);
            fifo_req    : OUT STD_LOGIC;
            ff_en       : OUT STD_LOGIC;
            bram_rdy    : OUT STD_LOGIC;
            bram_addr   : OUT STD_LOGIC_VECTOR(8 downto 0);
            bram_data   : OUT STD_LOGIC_VECTOR(bit_width-1 downto 0)
    
    );
end BRAM_write;

architecture Behavioral of BRAM_write is

type state_type is (stby, fifo_wait, data_req, data_rd, bram_wr, prep);
signal state    : state_type;

signal dout       : std_logic_vector(bit_width-1 downto 0);
signal fifo_data  : std_logic_vector(bit_width-1 downto 0);
signal i_fifo_wr  : std_logic;
signal wip        : integer range 0 to 2;
signal addr       : std_logic_vector(8 downto 0);

begin

process(clk,rst)
begin
    if rst = '1' then
        wip         <= 0;
        fifo_data   <= (OTHERS => '0');
        addr        <= (OTHERS => '0');
        bram_addr   <= (OTHERS => '0');
        bram_rdy    <= '0';
        fifo_req    <= '0';
        ff_en       <= '0';
        state       <= stby;
        dout        <= (OTHERS=> '0');
        
    elsif rising_edge(clk) then
        case state is
        --Waiting for UART to Store to FIFO
        when stby =>
            if i_fifo_wr = '1' then             --write in progress on FIFO
                state   <= fifo_wait;
            else
                state   <= stby;
            end if;
            
        when fifo_wait =>
            if i_fifo_wr = '0' and wip = 2 then   --write finished on FIFO, waiting 2 cycles before reading   
                fifo_req    <= '1';      --pulls read ena from fifo
                state   <= data_req;
            else
                wip     <= wip+1;
                state   <= fifo_wait;
            end if;
        
        when data_req =>
            fifo_req    <= '0';      
            state       <= data_rd;
            
        when data_rd =>
            fifo_data   <= din;      --stores fifo data 
            state       <= bram_wr;

        when bram_wr =>             
            bram_rdy    <= '1';         --pull write ena from bram
            ff_en       <= '1';         --transfer addr to bram_read thru flip flop
            bram_addr   <= addr;    
            dout        <= fifo_data;   --latch fifo data on output register for bram
            state       <= prep;    
            
        when prep =>                --clean up, resets to stby phase
            bram_rdy    <= '0';
            ff_en       <= '0';
            addr        <= addr + '1';
            wip         <= 0;
            state       <= stby;
        
        end case;
    end if;

end process;

    i_fifo_wr       <= fifo_wr;
    bram_data       <= dout;

end Behavioral;
