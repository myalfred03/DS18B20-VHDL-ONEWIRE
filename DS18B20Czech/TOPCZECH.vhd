----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:06:15 12/27/2015 
-- Design Name: 
-- Module Name:    TOPCZECH - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TOPCZECH is
    Port ( an     : out   STD_LOGIC_VECTOR (3 downto 0);
           MHZ50  : in    STD_LOGIC;
           R      : in    STD_LOGIC;
           a_to_g : out   STD_LOGIC_VECTOR (6 downto 0);
			  SW     : IN    STD_LOGIC_VECTOR (3 downto 0);
         --  en : in  STD_LOGIC;
			  LED    : out   STD_LOGIC_VECTOR (7 downto 0);
			  TX     : OUT   STD_LOGIC;
           DQ     : inout  STD_LOGIC
			  );
end TOPCZECH;

architecture Behavioral of TOPCZECH is


   COMPONENT DS18B20
	PORT(
		clk1m : IN std_logic;    
		ds_data_bus : INOUT std_logic;      
		crc_en : OUT std_logic;
		dataOut : OUT std_logic_vector(71 downto 0)
		);
	END COMPONENT;
	
	COMPONENT divider1MHz
	PORT(
		clk_in : IN std_logic;          
		clk_out : OUT std_logic
		);
	END COMPONENT;
	
	COMPONENT CRC
	PORT(
		clk : IN std_logic;
		data_en : IN std_logic;
		dataIn : IN std_logic_vector(71 downto 0);          
		dataOut : OUT std_logic_vector(15 downto 0);
		dataValid : OUT std_logic
		);
	END COMPONENT;
	
	
	COMPONENT Binary_To_BCD_16b
	PORT(
		ENTERO : IN std_logic_vector(15 downto 0);
		POINT : IN std_logic_vector(3 downto 0);          
		BCD : OUT std_logic_vector(18 downto 0);
		BCDPOINT : OUT std_logic_vector(7 downto 0)
		);
	END COMPONENT;
	
	COMPONENT X7seg
	PORT(
		x : IN std_logic_vector(15 downto 0);
		clk : IN std_logic;
		clr : IN std_logic;          
		an : OUT std_logic_vector(3 downto 0);
		a_to_g : OUT std_logic_vector(6 downto 0)
		);
	END COMPONENT;
	
	-----------------------------------------------------------
	
	COMPONENT transmitter
	PORT(
		clk : IN std_logic;
		enable : IN std_logic;
		sendRequest_T1 : IN std_logic;
		data_in_T1 : IN std_logic_vector(13 downto 0);
		sendRequest_H1 : IN std_logic;
		data_in_H1 : IN std_logic_vector(12 downto 0);
		sendRequest_T2 : IN std_logic;
		data_in_T2 : IN std_logic_vector(13 downto 0);
		sendRequest_H2 : IN std_logic;
		data_in_H2 : IN std_logic_vector(12 downto 0);          
		enable_LED : OUT std_logic;
		serialDataOut : OUT std_logic
		);
	END COMPONENT;
	
SIGNAL CLK1MHZ	: STD_LOGIC;
SIGNAL DOK   	: STD_LOGIC;
signal REQUEST : STD_LOGIC;
SIGNAL DATA    : STD_LOGIC_VECTOR(71 downto 0);
SIGNAL DATA16  : STD_LOGIC_VECTOR(15 downto 0);
SIGNAL DATA12  : STD_LOGIC_VECTOR(15 downto 0);
SIGNAL DATA4   : STD_LOGIC_VECTOR(3 downto 0);
SIGNAL Y       : STD_LOGIC_VECTOR(18 downto 0);
SIGNAL X       : STD_LOGIC_VECTOR(15 downto 0);
SIGNAL W       : STD_LOGIC_VECTOR(7 downto 0);




	
begin

DATA12 <= "0000" & DATA16(15 DOWNTO 4 );
DATA4 <= DATA16(3 DOWNTO 0 );


	U1: DS18B20 PORT MAP(
		clk1m => CLK1MHZ,
		crc_en => DOK,
		dataOut => DATA,
		ds_data_bus => DQ
	);

	U2: divider1MHz PORT MAP(
		clk_in => MHZ50,
		clk_out => CLK1MHZ
	);

	U3: CRC PORT MAP(
		clk => CLK1MHZ,
		data_en => DOK,
		dataIn => DATA,
		dataOut => DATA16,
		dataValid =>REQUEST 
	);
	
	U4: Binary_To_BCD_16b PORT MAP(
		ENTERO => DATA12,
		POINT => DATA4,
		BCD => Y,
		BCDPOINT => W 
	);

	U5: X7seg PORT MAP(
		x => X,
		clk => MHZ50,
		clr => R,
		an => an,
		a_to_g =>a_to_g 
	);

	U6: transmitter PORT MAP(
		clk => MHZ50,
		enable => SW(0),
		enable_LED => LED(6),
		sendRequest_T1 =>SW(0),
		data_in_T1 => DATA16(13 DOWNTO 0),
		sendRequest_H1 => SW(1),
		data_in_H1 => DATA16(12 DOWNTO 0),
		sendRequest_T2 => SW(2),
		data_in_T2 => DATA16(13 DOWNTO 0),
		sendRequest_H2 => SW(3),
		data_in_H2 => DATA16(12 DOWNTO 0),
		serialDataOut => TX
	);



X( 3 downto 0 )  <= W( 3 downto 0 );
X( 7 downto 4 )  <= W( 7 downto 4 );     		
X( 11 downto 8)  <= Y(3 downto 0 );     
X( 15 downto 12) <= Y(7 downto 4 );     		
		




end Behavioral;

