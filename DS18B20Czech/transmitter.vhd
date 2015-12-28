----------------------------------------------------------------------------
--	transmitter.vhd - Modul pro prenos namerenych dat do PC pres RS-232 rozhrani
----------------------------------------------------------------------------
-- Autor:  		 			Pavel Gregar
-- Datum vytvoreni:    	14:44:42 03/15/2014 
-- Modul:    				transmitter - Behavioral 
-- Projekt: 				Meteostanice
-- Cilove zarizeni: 		Nexys4
-- Pouzite nastroje:		Xilinx 14.6
----------------------------------------------------------------------------
--
----------------------------------------------------------------------------
--	Tento modul slouzi k odesilani namerenych hodnot ze senzoru do PC pomoci virtualizovane 
-- seriove linky pres USB. Modul se sklada ze submodulu UART a transmitControler, ktere jsou 
-- popsany v jejich souborech. Modul serializuje prijata data na portech data_in_XX a odesila
-- je na port serialDataOut.
--
-- Odesilana data maji tyto charakteristiky:
--         115200 b/s,
--         8 datovych bitu, prvni LSB,
--         zadna parita,
--         1 stop bit,
--			  rizeni toku - zadne
--         				
-- Porty modulu:
--
--		clk						- 100 MHz takt.
--		enable					- Spusteni vzorkovani a vysilani dat na seriovou linku (aktivni v log. 1).
--		transmit_enable_LED 	- Indikace LED vysilani.
--		sendRequest_T1			- Pouziva se k odebrani vzorku na portu data_in_T1. Predchozi modul
--							  		  by mel nastavit tento signal na jeden takt na hodnotu logicke 1.
--		data_in_T1				- Vstupni data ze senzoru teploty DS18B20.
--		sendRequest_T2			- Viz sendRequest_T1 (port data_in_T2).
--		data_in_T2				- Vstupni data ze senzoru teploty ADT7420.
--		sendRequest_H1			- Viz sendRequest_T1. (port data_in_H1).
--		data_in_H1				- Vstupni data ze senzoru vlhkosti DHT11.
--		sendRequest_H2			- Viz sendRequest_T1. (port data_in_H2).
--		data_in_H2				- Vstupni data ze senzoru vlhkosti DHT22.
--		serialDataOut			- Tento port je pripojen na pin pro odesilani dat pres seriovou linku.
--
----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity transmitter is
    Port ( clk 				: IN	STD_LOGIC;
			  enable				: IN	STD_LOGIC;
			  enable_LED		: OUT	STD_LOGIC;
			  sendRequest_T1 	: IN	STD_LOGIC;
			  data_in_T1		: IN	STD_LOGIC_VECTOR(13 DOWNTO 0);
			  sendRequest_H1 	: IN	STD_LOGIC;
			  data_in_H1		: IN	STD_LOGIC_VECTOR(12 DOWNTO 0); 
			  sendRequest_T2 	: IN	STD_LOGIC;
			  data_in_T2		: IN	STD_LOGIC_VECTOR(13 DOWNTO 0);
			  sendRequest_H2 	: IN	STD_LOGIC;
			  data_in_H2		: IN	STD_LOGIC_VECTOR(12 DOWNTO 0); 			  
			  serialDataOut	: OUT	STD_LOGIC
			  );
end transmitter;

architecture Structure of transmitter is

-- viz UART.vhd
component UART
    port ( clk 				: IN	STD_LOGIC;
           enable 			: IN	STD_LOGIC;
           serialDataOut 	: OUT	STD_LOGIC;
           parallelDataIn	: IN	STD_LOGIC_VECTOR (7 downto 0);
           transmitRequest : IN	STD_LOGIC;
           txIsReady 		: OUT	STD_LOGIC);
end component UART;

-- viz transmitControler.vhd
component transmitControler
    port ( clk 				: IN	STD_LOGIC;
			  enable 			: IN  STD_LOGIC;
			  enable_LED		: OUT	STD_LOGIC;
           sendRequest_T1	: IN  STD_LOGIC;
           data_in_T1 		: IN  STD_LOGIC_VECTOR (13 downto 0);
			  sendRequest_T2	: IN  STD_LOGIC;
           data_in_T2 		: IN  STD_LOGIC_VECTOR (13 downto 0);
			  sendRequest_H1	: IN  STD_LOGIC;
           data_in_H1 		: IN  STD_LOGIC_VECTOR (12 downto 0);
			  sendRequest_H2	: IN  STD_LOGIC;
           data_in_H2 		: IN  STD_LOGIC_VECTOR (12 downto 0);
           parallelDataOut	: OUT STD_LOGIC_VECTOR (7 downto 0);
           transmitRequest	: OUT	STD_LOGIC;
           txIsReady 		: IN  STD_LOGIC);
end component transmitControler;

signal transmitRequest	: STD_LOGIC := 'U';
signal txIsReady			: STD_LOGIC := 'U';
signal parallelDataOut	: STD_LOGIC_VECTOR(7 downto 0) := "UUUUUUUU";

begin

	UART_1 : UART port map (
					clk					=>	clk,
					enable				=>	enable,
					serialDataOut		=>	serialDataOut,
					parallelDataIn		=>	parallelDataOut,
					transmitRequest	=>	transmitRequest,
					txIsready			=>	txIsReady
	);
	
		transmitControler_1 : transmitControler port map (
					clk					=>	clk,
					sendRequest_T1		=>	sendRequest_T1,
					sendRequest_T2		=>	sendRequest_T2,
					sendRequest_H1		=>	sendRequest_H1,
					sendRequest_H2		=>	sendRequest_H2,
					enable				=> enable,
					enable_LED			=> enable_LED,
					data_in_T1			=>	data_in_T1,
					data_in_T2			=>	data_in_T2,
					data_in_H1			=>	data_in_H1,
					data_in_H2			=>	data_in_H2,
					parallelDataOut	=>	parallelDataOut,
					transmitRequest	=> transmitRequest,
					txIsReady			=> txIsReady
	);

end Structure;