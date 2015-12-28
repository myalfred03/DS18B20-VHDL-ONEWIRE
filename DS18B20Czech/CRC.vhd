----------------------------------------------------------------------------
--	CRC.vhd - Modul pro kontrolu CRC dat ze senzoru DS18B20
----------------------------------------------------------------------------
-- Autor:  		 			Pavel Gregar
-- Datum vytvoreni:    	16:10:51 02/04/2014
-- Modul:    				CRC - Behavioral 
-- Projekt: 				Meteostanice
-- Cilove zarizeni: 		Nexys4
-- Pouzite nastroje:		Xilinx 14.6
----------------------------------------------------------------------------
--
----------------------------------------------------------------------------
--	Tento modul slouzi k vypoctu CRC prijatych dat ze senzoru DS18B20 podle rovnice 
-- CRC = x^8 + x^5 + x^4 + 1 pomoci LFSR a jeho porovnani s obdrzenym CRC. Modul je spusten nabeznou hranou
-- na portu data_en.
--
-- Porty modulu:
--
--		clk				- 100 MHz takt.
--		data_en			- Spusteni vypoctu kontrolniho souctu (aktivni na vzestupnou hranu).
--		dataIn			- Vstupni data a poslane CRC.
--		dataOut			- Vystupni data (namerena teplota/chyba CRC).
--		dataValid		- Indikace dokonceni overeni CRC prijatych dat.
--
---------------------------------------------------------------------------- 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity CRC is
    Port (	clk			: IN	STD_LOGIC;
				data_en		: IN	STD_LOGIC;
				dataIn 		: IN	STD_LOGIC_VECTOR (71 downto 0);
				dataOut	 	: OUT	STD_LOGIC_VECTOR (15 downto 0);
				dataValid	: OUT STD_LOGIC
	 );
end CRC;

architecture Behavioral of CRC is

-- obdrzena data ze senzoru + prijate CRC
SIGNAL data : STD_LOGIC_VECTOR(71 downto 0);

-- stavy FSM
TYPE STATE_TYPE IS (IDLE, CRC_CALC, CRC_CHECK);
-- momentalni stav FSM
SIGNAL crc_state: STATE_TYPE;


begin

	-- Proces pro vypocet a kontrolu CRC obdrzenych dat
	process(clk)
	
	-- delka obdrzenych dat v bitech
	CONSTANT DATA_WIDTH_C	: INTEGER := 72;
	
	-- prave zpracovavany bit
	VARIABLE i					: integer range 0 to DATA_WIDTH_C := 0;
	
	-- pomocny registr pro vypocet CRC
	VARIABLE CRC_temp			: STD_LOGIC_VECTOR(7 downto 0);
	
	-- registr s vypoctenym CRC
	VARIABLE CRC_val			: STD_LOGIC_VECTOR(7 downto 0);
	
	-- vystupni data indikujici chybu CRC
	CONSTANT CRC_ERROR_C 		: STD_LOGIC_VECTOR(15 downto 0) := "0111111111111111";
	-- vystupni data indikujici nepripojeni senzoru
	CONSTANT PRESENCE_ERROR_C 	: STD_LOGIC_VECTOR(15 downto 0) := "0011111111111111";
	-- vstupni data indikujici nepripojeni senzoru 
	CONSTANT PRESENCE_ERROR_DATA_C : STD_LOGIC_VECTOR(71 downto 0) := "101010101010101010101010101010101010101010101010101010101010101010101010";
	
	
	begin
		
		if (rising_edge(clk)) then
			-- FSM ridici cinnost modulu CRC
			case (crc_state) is
				when IDLE =>											-- vychozi stav
					dataValid <= '0';									-- zruseni signalu indikujiciho dokonceni vypoctu CRC
					if (data_en = '1') then							-- pozadavek na vypocet CRC
						crc_state <= CRC_CALC;						-- prechod do stavu CRC_CALC
					end if;

				when CRC_CALC =>										-- stav pro vypocet CRC
					if (i < DATA_WIDTH_C) then						-- pokracovani s vkladanim dat do posuvneho registru
						-- Vypocet CRC pomoci LFSR
						CRC_temp(7):= dataIn(i) XOR CRC_val(0);
						CRC_temp(2):= CRC_val(3) XOR (dataIn(i) XOR CRC_val(0));
						CRC_temp(3):= CRC_val(4) XOR (dataIn(i) XOR CRC_val(0));
						CRC_val(0) := CRC_val(1);
						CRC_val(1) := CRC_val(2);
						CRC_val(2) := CRC_temp(2);
						CRC_val(3) := CRC_temp(3);
						CRC_val(4) := CRC_val(5);
						CRC_val(5) := CRC_val(6);
						CRC_val(6) := CRC_val(7);
						CRC_val(7) := CRC_temp(7);
						i:=i+1;											-- inkrementace vstupniho bitu vkladaneho do posuvneho registru
					else
						crc_state <= CRC_CHECK;						-- prechod do stavu CRC_check
					end if;

				when CRC_CHECK =>										-- stav pro porovnani CRC
					if (CRC_val = "00000000") then				-- prijate CRC shodne s vypocitanym
						dataOut <= dataIn(15 downto 0); 			-- data prijata spravne, vystup nastaven na data obsahujici namerenou teplotu
					else													-- prijate CRC neni shodne s vypocitanym
						if (dataIn /= PRESENCE_ERROR_DATA_C) then	-- vstupni data obsahuji data ze senzoru
							dataOut <= CRC_ERROR_C; 				-- data nebyla prijata spravne, vystup nastaven na chybovou hodnotu
						else
							dataOut <= PRESENCE_ERROR_C;			-- senzor neni pripojen, vystup nastaven na chybovou hodnotu
						end if;
					end if;
					CRC_temp	 := "00000000";						-- reset vypocitaneho CRC
					CRC_val   := "00000000";						-- reset pomocneho registru
					i 			 := 0;									-- reset prave zpracovavaneho bitu dat
					dataValid <= '1';									-- indikace dokonceni vypoctu CRC	
					crc_state <= IDLE;								-- navrat do stavu IDLE
			end case;
		end if;
	end process;

end Behavioral;