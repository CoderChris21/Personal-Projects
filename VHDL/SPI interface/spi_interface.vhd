---------------------- IN PROGRESS (INCOMPLETE) -----------------------
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
    sensor_din         : in  std_logic_vector(data_width-1 downto 0);  
	
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
type rx_state is (idle, Display_TopRow_16char, Display_BotRow_16char, Battery_Ind_8bytes, Press_Bar_Leadingedge_8bytes, Press_Bar_Peak_8bytes, 
Event_Mask_16bit, Heartbeat_16bits, CRC_32bits, clean);	
signal spi_rx_state             :rx_state;			

type tx_state is (idle, Event_State_16bits,Flow_Rate_16bits, PresMeas_16bits, PlatPres_16bits, Breath_Rate_16bits, IE_Ratio_5char, 
padding_16bits, HeartBeat_Ack_16bits, CRC_32bits,clean);
signal spi_tx_state		        :tx_state;	

-- CRC32 Ethernet
-- Using Polynomial 0x04C11BD7

signal crc_reg                : STD_LOGIC_VECTOR(31 downto 0) := (OTHERS => '0');
signal crc_en                 : STD_LOGIC:= '0';
signal data_in				  : STD_LOGIC;


-- For generating interrupt every 5 ms.
constant sys_clk              : real := 33.554432E6;
-- Counter for how many clock cycles are equivalent to a 200 Hz (or 5 ms) interrupt 
constant int_timer            : integer := integer(sys_clk/200);
signal count_5ms              : integer range 0 to int_timer-1;

signal addr_index             : std_logic_vector(addr_width-1 downto 0) := X"00";
signal sensor_data            : std_logic_vector(data_width-1 downto 0);    -- Calculated sensor data 
signal char_din               : std_logic_vector(data_width-1 downto 0);    --for char inputs just in case


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
crc32: process(clk)
begin
	if rising_edge(clk) then
	   if crc_en = '1' then
           crc_reg(0)		<= data_in xor crc_reg(31);
           crc_reg(1)		<= data_in xor crc_reg(31) xor crc_reg(0);
           crc_reg(2)		<= data_in xor crc_reg(31) xor crc_reg(1);
           crc_reg(3)		<= crc_reg(2);
           crc_reg(4)		<= data_in xor crc_reg(31) xor crc_reg(3);
           crc_reg(5)		<= data_in xor crc_reg(31) xor crc_reg(4);
           crc_reg(6)		<= crc_reg(5);
           crc_reg(7)		<= data_in xor crc_reg(31) xor crc_reg(6);
           crc_reg(8)		<= data_in xor crc_reg(31) xor crc_reg(7);
           crc_reg(9)		<= crc_reg(8);
           crc_reg(10)		<= data_in xor crc_reg(31) xor crc_reg(9);
           crc_reg(11)		<= data_in xor crc_reg(31) xor crc_reg(10);
           crc_reg(12)		<= data_in xor crc_reg(31) xor crc_reg(11);
           crc_reg(13)		<= crc_reg(12);
           crc_reg(14)		<= crc_reg(13);
           crc_reg(15)		<= crc_reg(14);
           crc_reg(16)		<= data_in xor crc_reg(31) xor crc_reg(15);
           crc_reg(17)		<= crc_reg(16);
           crc_reg(18)		<= crc_reg(17);
           crc_reg(19)		<= crc_reg(18);
           crc_reg(20)		<= crc_reg(19);
           crc_reg(21)		<= crc_reg(20);
           crc_reg(22)		<= data_in xor crc_reg(31) xor crc_reg(21);
           crc_reg(23)		<= data_in xor crc_reg(31) xor crc_reg(22);
           crc_reg(24)		<= crc_reg(23);
           crc_reg(25)		<= crc_reg(24);
           crc_reg(26)		<= data_in xor crc_reg(31) xor crc_reg(25);
           crc_reg(27)		<= crc_reg(26);
           crc_reg(28)		<= crc_reg(27);
           crc_reg(29)		<= crc_reg(28);
           crc_reg(30)		<= crc_reg(29);
           crc_reg(31)		<= crc_reg(30);
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
		sensor_addr         <= (OTHERS => '0');
		addr_index          <= (OTHERS =>  '0');
		sensor_data         <= (OTHERS => '0');
	    FPGA_dout           <= '0';	
		spi_rx_state        <= idle; 
    elsif rising_edge(clk) then 
        case spi_rx_state is 
	       when idle =>
		      if SSPI_CS_N = '0' then
		         sensor_addr	    <= addr_index;		-- Load address from register map ?        
			     spi_rx_state 	    <= Display_TopRow_16char;
		      else	
			     spi_rx_state       <= idle;
		      end if;

	  when Display_TopRow_16char =>	
		
	  when Display_BotRow_16char =>
	  
	  when Battery_Ind_8bytes => 
	  
	  when Press_Bar_Leadingedge_8bytes =>	
	       
	  when Press_Bar_Peak_8bytes  =>	
	       
	  when Event_Mask_16bit =>	
	       
	  when CRC_32bits =>	
	  
	  when clean =>
		   sensor_addr         <= (OTHERS => '0');
		   sensor_data         <= (OTHERS => '0');
	       FPGA_dout           <= '0';	
		   spi_rx_state        <= idle; 
	  
	  when OTHERS =>
	       sensor_addr         <= (OTHERS => '0');
		   addr_index          <= (OTHERS =>  '0');
		   sensor_data         <= (OTHERS => '0');
	       FPGA_dout           <= '0';	
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
		sensor_addr         <= (OTHERS => '0');
		addr_index          <= (OTHERS =>  '0');
		sensor_data         <= (OTHERS => '0');
	    FPGA_dout           <= '0';	
		spi_tx_state        <= idle; 
    elsif rising_edge(clk) then 
        case spi_tx_state is 
	       when idle =>
		      if SSPI_CS_N = '1' then
		         sensor_addr	    <= addr_index;		-- Load address from register map ?        
			     spi_tx_state 	    <= Event_State_16bits;
		      else	
			     spi_tx_state       <= idle;
		      end if;

	  when Event_State_16bits =>	
		
	  when PresMeas_16bits =>
	  
	  when PlatPres_16bits =>	
	       
	  when Breath_Rate_16bits =>	
	       
	  when IE_Ratio_5char =>	
	    	  
	  when padding_16bits =>	
	       
	  when Heartbeat_Ack_16bits =>	
	   
	   when CRC_32bits =>	
	       spi_tx_state           <= clean;
	  
	  when clean =>
		   sensor_addr         <= (OTHERS => '0');
		   sensor_data         <= (OTHERS => '0');
	       FPGA_dout           <= '0';	
		   spi_tx_state        <= idle; 
	  
	  when OTHERS =>
	       sensor_addr         <= (OTHERS => '0');
		   addr_index          <= (OTHERS =>  '0');
		   sensor_data         <= (OTHERS => '0');
	       FPGA_dout           <= '0';	
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
