----------------------------------------------------------------------------------
-- Engineer: Chris Sam
-- Date: 12/4/2020
-- Module Name: Top
--
-- Dependencies:
-- double_flop.vhd
-- uart_rx.vhd
-- uart_tx.vhd
-- BRAM_write.vhd
-- BRAM_read.vhd
-------------- Xilinx Instantiated IPs-----------------
-- BRAM
-- FIFO
-- Mixed Mode Clock Manager (MMCM)
--
-- Description: 
-- Receives serial data from host computer via UART, stores it in BRAM, and reads back to computer.
-- Write to BRAM at 75 MHz, read from BRAM at 100 Mhz.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;


entity Top is
    generic (bit_width	: integer := 8);
    Port (
     clk        :IN STD_LOGIC;
     rst        :IN STD_LOGIC;
     data_in    :IN STD_LOGIC;
     data_out   :OUT STD_LOGIC:= '0'
     );
end Top;

architecture Structure of Top is

--Clock Signals 
signal clk_rd, clk_wr   : STD_LOGIC;
signal clk_en,clk_lock  : STD_LOGIC; 

--RX Fifo Signals
signal rx_fifo          : STD_LOGIC_VECTOR(bit_width-1 downto 0);
signal rx_data_valid    : STD_LOGIC;

--FIFO BRAM Signals
signal rx_fifo_rd       : STD_LOGIC:='0';
signal fifo_to_bram     : STD_LOGIC_VECTOR(bit_width-1 downto 0);
signal rx_fifo_full     : STD_LOGIC;
signal rx_fifo_empty    : STD_LOGIC;

--BRAM Signals
signal bram_wr          : STD_LOGIC;
signal addr_in          : STD_LOGIC_VECTOR(8 downto 0);
signal bram_in          : STD_LOGIC_VECTOR(bit_width-1 downto 0);
signal bram_rd          : STD_LOGIC;
signal addr_out_ff      : STD_LOGIC_VECTOR(8 downto 0);
signal addr_out_bram    : STD_LOGIC_VECTOR(8 downto 0);
signal bram_out         : STD_LOGIC_VECTOR(bit_width-1 downto 0);

--TX FIFO Signals
signal bram_to_fifo     : STD_LOGIC_VECTOR(bit_width-1 downto 0);
signal tx_fifo_wr       : STD_LOGIC;
signal tx_data_valid    : STD_LOGIC;
signal tx_fifo_rdy      : STD_LOGIC;

signal fifo_tx          : STD_LOGIC_VECTOR(bit_width-1 downto 0);
signal tx_fifo_full     : STD_LOGIC;
signal tx_fifo_empty    : STD_LOGIC;

--Read Address Flopped Signals
signal ff_rd           : STD_LOGIC;


-----Instantiated IPs------------------------------------------------------

--BRAM--
--Write from Port A
--Read from Port B
Component blk_mem_gen_0 IS
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    clkb : IN STD_LOGIC;
    enb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END component;

--Synchronous FIFO----
component fifo_generator_1 IS
  PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
  );
END component;

--cross clock domain for address
component double_flop is
generic(width:  integer:= 9);
    Port ( 
        Clk  : in STD_LOGIC;
        Rst  : in STD_LOGIC;
        En   : in STD_LOGIC;
        D    : in STD_LOGIC_VECTOR(width-1 downto 0);
        Q    : out STD_LOGIC_VECTOR(width-1 downto 0));
end component;

--Clocking
component clk_wiz_0 is 
 port(
  clk_out1      : OUT STD_LOGIC;
  clk_out2      : OUT STD_LOGIC;
  reset         : IN STD_LOGIC;
  locked        : OUT STD_LOGIC;
  clk_in1       : IN STD_LOGIC
 );
 end component;

--------------Inferred Modules--------------------------------------------- 

component uart_rx is
generic (bit_width	: integer := 8);
port (
    clk     	  : IN  STD_LOGIC;								-- 100 MHz clock
    rst       	  : IN  STD_LOGIC;								-- active high reset
    serial_in	  : IN  STD_LOGIC;								-- asynchronous serial in
    fifo_wr_en 	  : OUT STD_LOGIC;
    fifo_din	  : OUT STD_LOGIC_VECTOR(bit_width-1 downto 0)
 );
end component;

component uart_tx is
generic (bit_width	: integer := 8);
port (
    clk     	  : IN  STD_LOGIC;		-- 100 MHz clock
    rst     	  : IN  STD_LOGIC;		-- active high reset
    fifo_empty	  : IN  STD_LOGIC;
    fifo_rd_en 	  : OUT STD_LOGIC;
    fifo_dout	  : IN  STD_LOGIC_VECTOR(bit_width-1 downto 0);
    serial_out	  : OUT STD_LOGIC		-- asynchronous serial in	
 );
end component;

Component BRAM_write is
generic (bit_width	: integer := 8);
Port (       
            clk         : IN STD_LOGIC;
            rst         : IN STD_LOGIC;
            fifo_wr     : IN STD_LOGIC;
            din         : IN  STD_LOGIC_VECTOR(bit_width-1 downto 0);
            fifo_req    : OUT STD_LOGIC;
            ff_en       : OUT STD_LOGIC;
            bram_rdy    : OUT STD_LOGIC;
            bram_addr   : OUT STD_LOGIC_VECTOR(8 downto 0);
            bram_data   : OUT STD_LOGIC_VECTOR(bit_width-1 downto 0)
    
    );
end component;

Component BRAM_read is
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
end component;

begin
clk_en <= not clk_lock;
	
--Clocking
clock_gen: clk_wiz_0  
 port map(
  clk_out1          => clk_wr,
  clk_out2          => clk_rd,
  reset             => rst,
  locked            => clk_lock,
  clk_in1           => clk
 );

	
---UART RX to FIFO-------------
rx: uart_rx
port map (
    clk     	=> clk_wr,
    rst     	=> clk_en,
    serial_in	=> data_in,
    fifo_wr_en 	=> rx_data_valid,
    fifo_din	=> rx_fifo
 );

RX_TO_FIFO: fifo_generator_1                                                                              
  PORT MAP(
    clk         => clk_wr,
    rst         => clk_en,
    din         => rx_fifo,
    wr_en       => rx_data_valid,  
    rd_en       => rx_fifo_rd,
    dout        => fifo_to_bram,
    full        => rx_fifo_full,
    empty       => rx_fifo_empty
  );

FIFO_BRAM_WR: BRAM_write
  Port Map (       
   clk          => clk_wr,
   rst          => clk_en,
   fifo_wr      => rx_data_valid,
   din          => fifo_to_bram,
   fifo_req     => rx_fifo_rd,
   ff_en        => ff_rd,    
   bram_rdy     => bram_wr,
   bram_addr    => addr_in,
   bram_data    => bram_in
   );

--Multi-flopped register for bram_read
BRAM_FF: double_flop
Port Map( 
        Clk  => clk_rd,
        Rst  => clk_en,
        En  => ff_rd,
        D   => addr_in,
        Q   => addr_out_ff
        );
  
BRAM: blk_mem_gen_0
  port map (
    clka        => clk_wr, 
    wea(0)      => bram_wr,   
    addra       => addr_in,
    dina        => bram_in,
    clkb        => clk_rd,
    enb         => bram_rd,
    addrb       => addr_out_bram,
    doutb       => bram_out
  );

-- Read from BRAM
BRAM_FIFO_RD: BRAM_read
  Port Map (       
   clk          => clk_rd,
   rst          => clk_en,
   bram_dv      => bram_wr,
   data_in      => bram_out,      -- Data output from BRAM
   ff_addr      => addr_out_ff,
   rd_bram      => bram_rd,
   fifo_rdy     => tx_data_valid,  --data ready to be transferred from bram to fifo
   rd_addr      => addr_out_bram,      -- Address for bram
   data_out     => bram_to_fifo   
   );
-- FIFO to UART_TX
-- Read BRAM, store in FIFO and transmit.
TX_FIFO: fifo_generator_1 
  PORT MAP(
    clk         => clk_rd,
    rst         => clk_en,
    din         => bram_to_fifo,
    wr_en       => tx_data_valid,        --Data read back being written to fifo
    rd_en       => tx_fifo_rdy,          --Data has been stored in fifo and ready for tx
    dout        => fifo_tx,
    full        => tx_fifo_full,
    empty       => tx_fifo_empty
  );

tx: uart_tx 
port map (
    clk     	    =>         clk_rd,
    rst     	    =>         clk_en,
	  fifo_empty	  =>         tx_fifo_empty,
    fifo_rd_en    =>         tx_fifo_rdy,
    fifo_dout	    =>         fifo_tx,      
	serial_out	    =>         data_out
 );

end structure;
