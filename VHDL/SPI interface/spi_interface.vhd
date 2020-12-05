library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.Common.all;

entity spi_interface is
generic(
	addr_width				   : Integer:= 8;		
	data_width				   : Integer:= 8 			
);
port(
	--  FPGA Inputs
	clk                : in std_logic;            -- 2^25 MHz
    	rst                : in std_logic; 	 		
	-- Calculator I/O's 
	sensor_addr		   : out std_logic_vector(addr_width-1 downto 0);
	sensor_OE          : out std_logic;     
    	sensor_din         : in  std_logic;
    
    	wr_addr            : out std_logic_vector(addr_width-1 downto 0);
    	wr_en              : out std_logic;
    	mem_dout           : out std_logic;  
	
	--  MCU Connections
	SSPI_CS_N			: in std_logic;	--Chip Sel Active Low, Pin 60
	MCU_din		        : in std_logic;	--SI, Pin 62
	SCLK				: in std_logic;	--SCLK, Pin 10.  Typically SYSCLK/2, maxes out at 12.5 MHz
	CLKHOLD_N			: in std_logic;    	--CLKHOLD_N, Pin 59.  For use if multiple slaves on bus.
	FPGA_dout           : out std_logic;	--SO, Pin 61
    	Five_ms_en			: out std_logic	-- Heart beat Interrupt coming from MCU
	);
end spi_interface;
	
architecture behavioral of spi_interface is

-- SPI MCU data to FPGA
constant total_bits             : integer := 1000;
constant rx_bits                : integer := 20;

-- TX Registers
signal rd_addr                  : std_logic_vector(addr_width-1 downto 0) := X"00";
signal sensor_data              : std_logic;    -- Calculated sensor data
-- RX Registers
signal mem_din                  : std_logic; --Register for incoming data to send to calculator


type rx_state is (idle, receive_bits, crc, clean);	
--type rx_state is (idle, Display_TopRow_16char, Display_BotRow_16char, Battery_Ind_8bytes, Press_Bar_Leadingedge_8bytes, Press_Bar_Peak_8bytes, 
--Event_Mask_16bit, Heartbeat_16bits, CRC_32bits, clean);	
signal spi_rx_state             :rx_state;		
signal rx_count                 : integer range 0 to total_bits-1;	

--type tx_state is (idle, Event_State_16bits,Flow_Rate_16bits, PresMeas_16bits, PlatPres_16bits, Breath_Rate_16bits, IE_Ratio_5char, 
--padding_16bits, HeartBeat_Ack_16bits, CRC_32bits,clean);
type tx_state is (idle, send_bits, crc, clean);
signal spi_tx_state		        :tx_state;	
signal tx_count                 : integer range 0 to total_bits-1;	


-- CRC32 Ethernet
-- Using Polynomial 0x04C11BD7

signal rx_crc                     : STD_LOGIC_VECTOR(31 downto 0) := (OTHERS => '0');
signal rx_crc_en                  : STD_LOGIC;
signal rx_data_in		  : STD_LOGIC;
signal i_rx                       : integer range 0 to 31 := 0; --rx index to send crc

signal tx_crc                    : STD_LOGIC_VECTOR(31 downto 0) := (OTHERS => '0');
signal tx_crc_en                 : STD_LOGIC;
signal tx_data_in		 : STD_LOGIC;
signal i_tx                      : integer range 0 to 31 := 0; --tx index to send crc


-- For generating interrupt every 5 ms.
constant sys_clk              : real := 33.554432E6;
-- Counter for how many clock cycles are equivalent to a 200 Hz (or 5 ms) interrupt 
constant int_timer            : integer := integer(sys_clk/200);
signal count_5ms              : integer range 0 to int_timer-1;

begin

--Process to generate interrupt every 5 ms
Int_5ms:process(rst,clk)
begin
    if rst = '1' then
        count_5ms  <= 0;
        Five_ms_en <= '0';
    elsif rising_edge(clk) then
        if count_5ms = int_timer-1 then
            count_5ms <= 0;
            Five_ms_en <= '1';
        else
            count_5ms <= count_5ms + 1;
        end if;
    end if;
end process;

-- Xor Shifting to Implement CRC32, where 
-- XOR taps are '1's corresponding to polynomial 0x04C11BD7
tx_crc32: process(clk)
begin
	if rising_edge(clk) then
	   if tx_crc_en = '1' then
           tx_crc(0)		<= tx_data_in xor tx_crc(31);
           tx_crc(1)		<= tx_data_in xor tx_crc(31) xor tx_crc(0);
           tx_crc(2)		<= tx_data_in xor tx_crc(31) xor tx_crc(1);
           tx_crc(3)		<= tx_crc(2);
           tx_crc(4)		<= tx_data_in xor tx_crc(31) xor tx_crc(3);
           tx_crc(5)		<= tx_data_in xor tx_crc(31) xor tx_crc(4);
           tx_crc(6)		<= tx_crc(5);
           tx_crc(7)		<= tx_data_in xor tx_crc(31) xor tx_crc(6);
           tx_crc(8)		<= tx_data_in xor tx_crc(31) xor tx_crc(7);
           tx_crc(9)		<= tx_crc(8);
           tx_crc(10)		<= tx_data_in xor tx_crc(31) xor tx_crc(9);
           tx_crc(11)		<= tx_data_in xor tx_crc(31) xor tx_crc(10);
           tx_crc(12)		<= tx_data_in xor tx_crc(31) xor tx_crc(11);
           tx_crc(13)		<= tx_crc(12);
           tx_crc(14)		<= tx_crc(13);
           tx_crc(15)		<= tx_crc(14);
           tx_crc(16)		<= tx_data_in xor tx_crc(31) xor tx_crc(15);
           tx_crc(17)		<= tx_crc(16);
           tx_crc(18)		<= tx_crc(17);
           tx_crc(19)		<= tx_crc(18);
           tx_crc(20)		<= tx_crc(19);
           tx_crc(21)		<= tx_crc(20);
           tx_crc(22)		<= tx_data_in xor tx_crc(31) xor tx_crc(21);
           tx_crc(23)		<= tx_data_in xor tx_crc(31) xor tx_crc(22);
           tx_crc(24)		<= tx_crc(23);
           tx_crc(25)		<= tx_crc(24);
           tx_crc(26)		<= tx_data_in xor tx_crc(31) xor tx_crc(25);
           tx_crc(27)		<= tx_crc(26);
           tx_crc(28)		<= tx_crc(27);
           tx_crc(29)		<= tx_crc(28);
           tx_crc(30)		<= tx_crc(29);
           tx_crc(31)		<= tx_crc(30);
           end if;	
	end if;
end process;

rx_crc32: process(clk)
begin
	if rising_edge(clk) then
	   if rx_crc_en = '1' then
           rx_crc(0)		<= rx_data_in xor rx_crc(31);
           rx_crc(1)		<= rx_data_in xor rx_crc(31) xor rx_crc(0);
           rx_crc(2)		<= rx_data_in xor rx_crc(31) xor rx_crc(1);
           rx_crc(3)		<= rx_crc(2);
           rx_crc(4)		<= rx_data_in xor rx_crc(31) xor rx_crc(3);
           rx_crc(5)		<= rx_data_in xor rx_crc(31) xor rx_crc(4);
           rx_crc(6)		<= rx_crc(5);
           rx_crc(7)		<= rx_data_in xor rx_crc(31) xor rx_crc(6);
           rx_crc(8)		<= rx_data_in xor rx_crc(31) xor rx_crc(7);
           rx_crc(9)		<= rx_crc(8);
           rx_crc(10)		<= rx_data_in xor rx_crc(31) xor rx_crc(9);
           rx_crc(11)		<= rx_data_in xor rx_crc(31) xor rx_crc(10);
           rx_crc(12)		<= rx_data_in xor rx_crc(31) xor rx_crc(11);
           rx_crc(13)		<= rx_crc(12);
           rx_crc(14)		<= rx_crc(13);
           rx_crc(15)		<= rx_crc(14);
           rx_crc(16)		<= rx_data_in xor rx_crc(31) xor rx_crc(15);
           rx_crc(17)		<= rx_crc(16);
           rx_crc(18)		<= rx_crc(17);
           rx_crc(19)		<= rx_crc(18);
           rx_crc(20)		<= rx_crc(19);
           rx_crc(21)		<= rx_crc(20);
           rx_crc(22)		<= rx_data_in xor rx_crc(31) xor rx_crc(21);
           rx_crc(23)		<= rx_data_in xor rx_crc(31) xor rx_crc(22);
           rx_crc(24)		<= rx_crc(23);
           rx_crc(25)		<= rx_crc(24);
           rx_crc(26)		<= rx_data_in xor rx_crc(31) xor rx_crc(25);
           rx_crc(27)		<= rx_crc(26);
           rx_crc(28)		<= rx_crc(27);
           rx_crc(29)		<= rx_crc(28);
           rx_crc(30)		<= rx_crc(29);
           rx_crc(31)		<= rx_crc(30);
           end if;	
	end if;
end process;
					

-- State machine to receive data from MCU 

--  FPGA Input Data (From MCU):
--      Display_TopRow_16char
--      Display_BotRow_16char
--      Battery_Ind_8bytes
--      Press_Bar_Leadingedge_8bytes
--      Press_Bar_Peak_8bytes
--      Event_Mask_16bit
--      Heartbeat_16bits
--      CRC_32bits  with polynomial 0x4C11DB7
	
SPI_RX_SM: process(clk, rst)
begin 
    if rst = '1' then	
		wr_addr             <= (OTHERS =>  '0');
		wr_en               <= '0';
		mem_din             <= '0';
		mem_dout            <= '0';
		rx_count            <= 0;
		rx_crc_en           <= '0';
		spi_rx_state        <= idle; 
    elsif rising_edge(clk) then 
        case spi_rx_state is 
	       when idle =>
		      if SSPI_CS_N = '0' then
		         wr_en              <= '1'; 
		         rx_crc_en          <= '1';      
			 spi_rx_state 	    <= receive_bits;
		      else	
			 spi_rx_state       <= idle;
		      end if;
	       
	  when receive_bits =>
	       mem_din             <= MCU_din;
	       if rx_count < total_bits-1 then
	           if rx_count < rx_bits-1 then
	               mem_dout        <= mem_din;
	               rx_data_in      <= mem_din;
	            else
	               rx_crc_en       <= '0';
	               wr_en           <= '0';             --If all the useful bits received, keep counting since TX ongoing, but stop writing to memory. 
	            end if;
	            rx_count           <= rx_count + 1;
	            spi_rx_state       <= receive_bits;
	       else
	           rx_count            <= 0;
	           spi_rx_state        <= crc;
	       end if;
	  
	  when crc =>
	       mem_dout    <= rx_crc(i_rx);
	       if i_rx < 31 then
	           i_rx            <= i_rx + 1;
	           spi_rx_state    <= crc;
	       else
	           i_rx            <= 0;
	           spi_rx_state    <= clean;
	       end if;
	         	  
	  when clean =>
        	wr_addr             <= (OTHERS =>  '0');
		wr_en               <= '0';
		mem_din             <= '0';
		mem_dout            <= '0';
	    	rx_count            <= 0;
	    	rx_crc_en           <= '0';
		spi_rx_state        <= idle; 
	  
	  when OTHERS =>
		wr_addr             <= (OTHERS =>  '0');
		wr_en               <= '0';
		mem_din             <= '0';
		mem_dout            <= '0';
		rx_count            <= 0;
		rx_crc_en           <= '0';
		spi_rx_state        <= idle; 
	  
      end case; 
      
    end if;
 end process; 


-- State machine to send from FPGA to MCU

--  FPGA Output Data (To MCU):
--      Event_State_16bits
--      FlowRate_16bits
--      PresMeas_16bits
--      PlatPres_16bits
--      Breath_Rate_16bits
--      IE_Ratio_5char
--      padding_16bits
--      Heartbeat_Ack_16bits
--      CRC_32bits

SPI_TX_SM: process(clk, rst)
begin 
    if rst = '1' then	
    	rd_addr             <= (OTHERS =>  '0');
	sensor_addr         <= (OTHERS => '0');
	sensor_OE           <= '0';
	sensor_data         <= '0';
	FPGA_dout           <= '0';	
	tx_count            <= 0;
	tx_crc_en           <= '0';
	spi_tx_state        <= idle; 
    elsif rising_edge(clk) then 
        case spi_tx_state is 
		when idle =>
	        	if SSPI_CS_N = '1' then
		        	sensor_OE          <= '1';
		         	tx_crc_en          <= '1';
		         	sensor_addr	   <= rd_addr;		-- Load address from register map ?        
			     	spi_tx_state 	   <= send_bits;
		      else	
			     	spi_tx_state       <= idle;
		      end if;
	   
	   	when send_bits =>
	       		sensor_data            <= sensor_din;
	       		if tx_count < total_bits-1 then	
				FPGA_dout       <= sensor_data;
			   	tx_data_in      <= sensor_data;
			   	tx_count        <= tx_count + 1;               
			   	spi_tx_state    <= send_bits;
	       		else
				tx_count        <= 0;
				tx_crc_en       <= '0';
				spi_tx_state    <= crc;
	       		end if;
	  
	   	when crc =>
	       		FPGA_dout    <= tx_crc(i_tx);
	       		if i_tx < 31 then
				i_tx            <= i_tx + 1;
			   	spi_tx_state    <= crc;
	       		else
	           		i_tx            <= 0;
	           		spi_tx_state    <= clean;
	       		end if;
	  
	  	when clean =>
		rd_addr             <= (OTHERS =>  '0');
	    sensor_addr         <= (OTHERS => '0');
		sensor_OE           <= '0';
		sensor_data         <= '0';
	    	FPGA_dout           <= '0';	
	    	tx_count            <= 0;
	    	tx_crc_en           <= '0';
		spi_tx_state        <= idle; 
	  
	  when OTHERS =>
		rd_addr             <= (OTHERS =>  '0');
	    	sensor_addr         <= (OTHERS => '0');
		sensor_OE           <= '0';
		sensor_data         <= '0';
	   	FPGA_dout           <= '0';	
	    	tx_count            <= 0;
	    	tx_crc_en           <= '0';
		spi_tx_state        <= idle;  
	  
   	  end case; 
      
    end if;
 end process; 
 
End behavioral;

----------------------------------------------------
--      BACKUP
----------------------------------------------------

--      HALT TRANSACTION ( Don't know if needed yet)

--		if halt = '1' then
--		  CLKHOLD_N   <= '1';
--		  state <= halt;
--		end if;
	   
--	  when halt =>
--	   if transaction_comp = '1' then
--          CLKHOLD_N<= '0';
--          state   <= bitstream;
--	   else
--	       state  <= halt;
--	   end if;  
