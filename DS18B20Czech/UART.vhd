----------------------------------------------------------------------------
--	UART.vhd - Submodul pro vysilani bajtu dat pres serivou linku
----------------------------------------------------------------------------
-- Autor:  		 			Pavel Gregar
-- Datum vytvoreni:     17:26:30 03/03/2014 
-- Modul:    				UART - Behavioral 
-- Projekt: 				Meteostanice
-- Cilove zarizeni: 		Nexys4
-- Pouzite nastroje:		Xilinx 14.6
----------------------------------------------------------------------------
--
----------------------------------------------------------------------------
--	Tento submodul slouzi k odesilani bajtu dat pomoci virtualizovane seriove linky pres USB 
-- pripravku Nexys4. Sklada se ze submodulu UART_baudRateGenerator a UART_transmitter, ktere 
-- jsou popsany v jejich souborech. Submodul serializuje prijata data na portu parallelDataIn 
-- a odesila je na port serialDataOut. 
--         				
-- Porty submodulu:
--
--		clk					- 100 MHz takt.
--		enable				- Spusteni vysilani dat (aktivni v log. 1).
--		parallelDataIn		- Paralelni vstupni data k odeslani.
--		transmitRequest	- Pouziva se ke spusteni vysilani dat z portu parallelDataIn..
--		txIsReady			- Indikace moznosti vysilani dalsiho bajtu dat.
--		serialDataOut		- Seriova vystupni data odesilana pres seriovou linku.
--
----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity UART is
    Port ( clk 				: IN	STD_LOGIC;
           enable 			: IN	STD_LOGIC;
           parallelDataIn	: IN	STD_LOGIC_VECTOR (7 downto 0);
           transmitRequest : IN	STD_LOGIC;
			  txIsReady			: OUT	STD_LOGIC;
           serialDataOut 	: OUT	STD_LOGIC
			  );
end UART;

architecture Structure of UART is

-- viz UART_baudRateGenerator.vhd
component UART_baudRateGenerator
port (clk						:	IN	 STD_LOGIC;
		enable					:	IN	 STD_LOGIC;
		baudRateEnable			:	OUT STD_LOGIC
		);
end component UART_baudRateGenerator;

-- viz UART_transmitter.vhd
component UART_transmitter
port (clk					:	IN  STD_LOGIC;
		enable				:	IN  STD_LOGIC;
		baudRateEnable		:	IN  STD_LOGIC;
		parallelDataIn		:	IN	 STD_LOGIC_VECTOR(7 downto 0);
		transmitRequest	:	IN	 STD_LOGIC;
		txIsReady			:	OUT STD_LOGIC;
		serialDataOut		:	OUT STD_LOGIC
		);
end component UART_transmitter;
		
signal baudRateEnable		:	STD_LOGIC;

		
begin
	baudRateGenerator : UART_baudRateGenerator port map (
					clk						=>	clk,
					enable					=>	enable,
					baudRateEnable			=>	baudRateEnable
	);

	transmitter : UART_transmitter port map (
					clk					=>	clk,
					enable				=> enable,
					baudRateEnable		=>	baudRateEnable,
					parallelDataIn		=>	parallelDataIn,
					transmitRequest	=>	transmitRequest,
					txIsReady			=>	txIsReady,
					serialDataOut		=> serialDataOut
	);
end Structure;