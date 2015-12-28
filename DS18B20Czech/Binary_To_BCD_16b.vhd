----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:18:39 07/22/2015 
-- Design Name: 
-- Module Name:    Binary_To_BCD_16b - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL; 
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Binary_To_BCD_16b is
PORT (
      ENTERO    : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		POINT     : IN STD_LOGIC_VECTOR(3 DOWNTO 0);	
		 BCD      : OUT STD_LOGIC_VECTOR(18 DOWNTO 0);
		 BCDPOINT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
		 );
		
end Binary_To_BCD_16b;

architecture Behavioral of Binary_To_BCD_16b is

signal temper: std_logic_vector(3 downto 0);
signal point_out: std_logic_vector(7 downto 0);

begin

temper  <= POINT;
BCDPOINT<= point_out;

	with temper select				  
		  point_out<= "0000"&"0000" when "0000",--0
						  "0000"&"0110" when "0001",--0.0625
						  "0001"&"0010" when "0010",--0.125
						  "0001"&"1001" when "0011",--0.1875 =0.19
						  "0010"&"0101" when "0100",--0.25
						  "0011"&"0101" when "0101",--0.31
						  "0011"&"1000" when "0110",--0.375  =0.38
						  "0100"&"0100" when "0111",--0.4375 =0.44
						  "0101"&"0000" when "1000",--0.5
						  "0101"&"0110" when "1001",--0.5625
						  "0110"&"0011" when "1010",--0.625 =0.63
						  "0110"&"1001" when "1011",--0.6875 =0.69
						  "0111"&"0101" when "1100",--0.75
						  "1000"&"0001" when "1101",--0.8125
						  "1000"&"1000" when "1110",--0.875	 =0.88
						  "1001"&"0100" when "1111",--0.9375	 =0.94	
						  "0000"&"0000" when others;		  	


BCD1: PROCESS(ENTERO) 
  VARIABLE Z:STD_LOGIC_VECTOR(34 DOWNTO 0);      
BEGIN 
  FOR I IN 0 TO 34 LOOP 
    Z(I):='0'; 
  END LOOP;  
  Z(18 DOWNTO 3):=ENTERO; 
  FOR I IN 0 TO 12 LOOP 
     IF Z(19 DOWNTO 16) > 4 THEN 
        Z(19 DOWNTO 16):= Z(19 DOWNTO 16)+3; 
     END IF;  
     IF Z(23 DOWNTO 20) > 4 THEN 
        Z(23 DOWNTO 20):= Z(23 DOWNTO 20)+3; 
     END IF;  
     IF Z(27 DOWNTO 24) > 4 THEN 
        Z(27 DOWNTO 24):= Z(27 DOWNTO 24)+3; 
     END IF; 
    
     IF Z(31 DOWNTO 28) > 4 THEN 
        Z(31 DOWNTO 28):= Z(31 DOWNTO 28)+3; 
     END IF; 
    
   Z(34 DOWNTO 1):= Z(33 DOWNTO 0); 
    
 END LOOP;  
  BCD<=Z(34 DOWNTO 16); 
 END PROCESS;


end Behavioral;

