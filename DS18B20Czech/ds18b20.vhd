----------------------------------------------------------------------------
--	DS18B20.vhd - Modul pro komunikaci se senzorem teploty DS18B20
----------------------------------------------------------------------------
-- Autor:  		 			Pavel Gregar
-- Datum vytvoreni:    	15:11:15 11/29/2013
-- Modul:    				DS18B20 - Behavioral 
-- Projekt: 				Meteostanice
-- Cilove zarizeni: 		Nexys4
-- Pouzite nastroje:		Xilinx 14.6
----------------------------------------------------------------------------
--
----------------------------------------------------------------------------
--	Tento modul slouzi ke komunikaci se senzorem teploty DS18B20. Pomoci posloupnosti prikazu
-- CCh (SKIP ROM), 44h (CONVERT TEMPERATURE), CCh (SKIP ROM), BEh (READ SCRATCHPAD) je nacten
-- obsah pameti scrathpad senzoru, ktery je odeslan ke kontrole CRC portem dataOut.
--
-- Porty modulu:
--
--		clk1m			- 1 MHz takt.
--		crc_en		- Rizeni spusteni vypoctu CRC z dat obdrzenych ze senzoru odeslanych na portu dataOut.
--		ds_data_bus	- 1-wire I/O, vstupne-vystupni datovy port senzoru.
--		dataOut	 	- Vystupni signal s daty obsahujici obsah pameti scratchpad
--
----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DS18B20 is
port
(
  clk1m				: IN		STD_LOGIC;
  crc_en				: OUT		STD_LOGIC;
  dataOut			: OUT		STD_LOGIC_VECTOR(71 downto 0);
  ds_data_bus		: INOUT	STD_LOGIC
);
end DS18B20;

architecture Behavioral of DS18B20 is

-- potrebne stavy FSM
TYPE STATE_TYPE is (WAIT_800ms, RESET, PRESENCE, SEND, WRITE_BYTE, WRITE_LOW, WRITE_HIGH, GET_DATA, READ_BIT);
-- momentalni stav FSM
SIGNAL state: STATE_TYPE;

-- nactena data z pameti scratchpad senzoru
SIGNAL data	: STD_LOGIC_VECTOR(71 downto 0);

-- synchroni reset citace
SIGNAL S_reset	: STD_LOGIC;
-- citac
SIGNAL i			: INTEGER RANGE 0 TO 799999;

-- odesilana instrukce pro senzor
SIGNAL write_command : STD_LOGIC_VECTOR(7 downto 0);

-- vzorek signalu pro detekci senzoru na sbernici
SIGNAL presence_signal		: STD_LOGIC;

SIGNAL WRITE_BYTE_CNT	: INTEGER RANGE 0 TO 8	:= 0;	-- citac pro odesilany bajt
SIGNAL write_low_flag	: INTEGER RANGE 0 TO 2	:= 0;	-- priznak pozice ve stavu WRITE_LOW
SIGNAL write_high_flag	: INTEGER RANGE 0 TO 2	:= 0;	--	priznak pozice ve stavu WRITE_HIGH
SIGNAL read_bit_flag		: INTEGER RANGE 0 TO 3	:= 0;	-- priznak pozice ve stavu READ_BIT
SIGNAL GET_DATA_CNT		: INTEGER RANGE 0 TO 72	:= 0;	-- citac pro pocet prectenych bitu

begin

	-- Proces pro komunikaci se senzorem DS18B20
	process(clk1m)

	-- vystupni data pri chybe detekce senzoru na sbernici
	CONSTANT PRESENCE_ERROR_DATA	: STD_LOGIC_VECTOR(71 downto 0):= "101010101010101010101010101010101010101010101010101010101010101010101010";

	VARIABLE bit_cnt	: INTEGER RANGE 0 TO 71;	-- prave cteny bit
	VARIABLE flag		: INTEGER RANGE 0 TO 5;		-- priznak pro odesilany prikaz

	begin
		if rising_edge(clk1m) then
			case	state is
				when RESET =>																-- stav pro reset senzoru
					S_reset <= '0';														-- reset citace
					if (i = 0) then 
						ds_data_bus <= '0';												--	zacatek resetovaciho pulzu
					elsif (i = 485) then 
						ds_data_bus <= 'Z';												-- uvolneni sbernice
					elsif (i = 550) then
						presence_signal <= ds_data_bus;								-- odebrani vzorku pro zjisteni pritomnosti senzoru 
					elsif (i = 1000) then 
						state <= PRESENCE;												-- prechod do stavu PRESENCE	
					end if;
			
				when PRESENCE =>															-- stav pro zjisteni pritomnosti senzoru na sbernici
					-- detekce senzoru na sbernici
					if (presence_signal = '0' and ds_data_bus = '1') then		-- senzor byl detkovan
						S_reset <= '1';													-- reset citace
						state	  <= SEND;													-- inicializace dokoncena, prechod do stavu SEND
					else																		-- senzor nebyl detekovan
						S_reset	<= '1';													-- reset citace
						dataOut 	<= PRESENCE_ERROR_DATA;								-- nastaveni dat indikujicich chybu na vystup
						crc_en	<= '1';													-- zahajeni vypoctu CRC
						state		<= WAIT_800ms;											-- prechod do stavu WAIT_800ms
					end if;

				when SEND =>																-- stav pro odesilani prikazu pro senzor
					-- sekvence odesilanych prikazu rizena priznakem flag
					if (flag = 0) then													-- prvni prikaz
						flag := 1;
						write_command <="11001100"; 									-- prikaz CCh - SKIP ROM
						state 		  <= WRITE_BYTE;									-- prechod do stavu WRITE BYTE
					elsif (flag = 1) then												-- druhy prikaz
						flag := 2;
						write_command <="01000100"; 									-- prikaz 44h - CONVERT TEMPERATURE
						state 		  <= WRITE_BYTE;									-- prechod do stavu WRITE BYTE
					elsif (flag = 2) then												-- treti prikaz
						flag := 3;	
						state <= WAIT_800ms; 											-- prechod do stavu WAIT_800ms, cekani na ukonceni prikazu 44h
					elsif (flag = 3) then												-- treti prikaz
						flag := 4;
						write_command <="11001100"; 									-- prikaz CCh - SKIP ROM
						state			  <= WRITE_BYTE;									-- prechod do stavu WRITE BYTE
					elsif (flag = 4) then												-- ctvrty prikaz
						flag := 5;
						write_command <="10111110"; 									-- prikaz BEh - READ SCRATCHPAD
						state			  <= WRITE_BYTE;									-- prechod do stavu WRITE BYTE
					elsif (flag = 5) then												-- ukonceni vysilani prikazu
						flag := 0;															-- reset priznaku pro odesilany prikaz
						state <= GET_DATA;												-- prechod do stavu GET_DATA
					end if;

				when  WAIT_800ms =>														-- stav cekani po dobu 800 ms
					CRC_en <= '0';															-- reset priznaku pro zahajeni vypoctu CRC
					S_reset <= '0';														-- spusteni citace
					if (i = 799999) then													-- konec periody citace
						S_reset <='1';														-- resetovani citace
						state	  <= RESET;													-- navrat do stavu RESET
					end if;

				when GET_DATA =>															-- stav pro precteni pameti scratchpad
					case GET_DATA_CNT is													-- pozice ve stavu GET_DATA
						when 0 to 71=>														-- cteni jednotlivych bitu pameti scratchpad
							ds_data_bus  <= '0';											-- zahajeni cteni na sbernici
							GET_DATA_CNT <= GET_DATA_CNT + 1;						-- inkrementace citace pro prave cteny bit
							state 		 <= READ_BIT;									-- prechod do stavu READ_BIT
						when 72=>															-- pamet prectena (72 bitu)
							bit_cnt := 0;													-- reset citace pro prave cteny bit
							GET_DATA_CNT <=0;												-- reset citace prectenych bitu
							dataOut 	 <= data(71 downto 0);							-- odeslani prectenych dat na vystupni port
							CRC_en 		 <= '1';											-- spusteni vypoctu CRC prectenych dat
							state 		 <= WAIT_800ms;								-- navrat do stavu WAIT_800ms
						when others =>	 													-- chyba ve stavu GET_DATA
							read_bit_flag <= 0;											-- reset pozice ve stavu READ_BIT
							GET_DATA_CNT  <= 0; 											-- reset citace pro pocet prectenych bitu
					end case;

				when READ_BIT =>															-- stav pro cteni bitu
					-- sekvence cteni bitu rizena priznakem read_bit_flag
					case read_bit_flag is												-- pozice ve stavu READ_BIT
						when 0=>																-- vyslani zacatku casoveho slotu pro cteni
							read_bit_flag <= 1;
						when 1=>																
							ds_data_bus <= 'Z';											-- uvolneni sbernice pro prijem bitu ze senzoru
							S_reset 		<= '0';											-- zapnuti citace
							if (i = 13) then												-- cekani 14 us
								S_reset		 <= '1';										-- reset citace
								read_bit_flag <= 2;
							end if; 
						when 2=>																-- odebrani vzorku dat ze sbernice
							data(bit_cnt)	<= ds_data_bus;							-- ulozeni vzorku dat do registru
							bit_cnt := bit_cnt + 1;										-- zvyseni citace pro prave cteny bit
							read_bit_flag	<= 3;
						when 3=>																-- dokonceni casoveho slotu
							S_reset <= '0';												-- zapnuti citace
							if (i = 63) then												-- cekani 62 us
								S_reset<='1';												-- reset citace
								read_bit_flag <= 0;										-- reset pozice ve stavu READ_BIT
								state 		  <= GET_DATA;								-- navrat do stavu GET_DATA
							end if;
						when others => 													-- chyba ve stavu READ_BIT
							read_bit_flag <= 0;											-- reset pozice ve stavu READ_BIT
							bit_cnt		  := 0;											-- reset citace pro prave cteny bit
							GET_DATA_CNT  <= 0;											-- reset citace prectenych bitu
							state			  <= RESET;										-- reset senzoru
					end case;

				when WRITE_BYTE =>														-- stav pro zapis bajtu dat na sbernici
					-- sekvence zapisu bajtu dat rizena citacem WRITE_BYTE_CNT
					case WRITE_BYTE_CNT is												-- pozice ve stavu WRITE_BYTE
						when 0 to 7=>														-- odesilani bitu 0-7
							if (write_command(WRITE_BYTE_CNT) = '0') then		-- odesilany bit ma hodnotu log. 0
								state <= WRITE_LOW; 										-- prechod do stavu WRITE_LOW
							else																-- odesilany bit ma hodnotu log. 1
								state <= WRITE_HIGH;										-- prechod do stavu WRITE_HIGH
							end if;
							WRITE_BYTE_CNT <= WRITE_BYTE_CNT + 1;					-- inkrementace citace odesilaneho bitu
						when 8=>																-- odesilani bajtu dokonceno
							WRITE_BYTE_CNT <= 0;											-- reset citace odesilaneho bitu
							state				<= SEND;										-- navrat do stavu SEND
						when others=>														-- chyba ve stavu WRITE_BYTE
							WRITE_BYTE_CNT  <= 0;										-- reset citace odesilaneho bitu
							write_low_flag  <= 0;										-- reset pozice ve stavu WRITE_LOW
							write_high_flag <= 0;										-- reset pozice ve stavu WRITE_HIGH
							state 		   <= RESET;									-- reset senzoru
						end case;

				when WRITE_LOW =>															-- stav pro zapis log. 0 na sbernici
					-- casovy slot pro zapis log 0 rizeny priznakem write_low_flag
					case write_low_flag is												-- pozice ve stavu WRITE_LOW
						when 0=>																-- vyslani zacatku casoveho slotu pro zapis log. 0
							ds_data_bus <= '0';											-- zacatek casoveho slotu
							S_reset 		<= '0';											-- zapnuti citace
							if (i = 59) then												-- cekani 60 us
								S_reset		   <='1';										-- reset citace
								write_low_flag <= 1;
							end if;
						when 1=>																-- uvolneni sbernice pro ukonceni casoveho slotu
							ds_data_bus <= 'Z';											-- uvolneni sbernice
							S_reset 		<= '0';											-- zapnuti citace
							if (i = 3) then												-- cekani 4 us na ustaleni sbernice 
								S_reset 		   <= '1';									-- reset citace
								write_low_flag <= 2;
							end if;
						when 2=>																-- konec zapisu log. 0
							write_low_flag <= 0;											-- reset pozice ve stavu WRITE_LOW
							state 		   <= WRITE_BYTE;								-- navrat do stavu WRITE_BYTE
						when others=>														-- chyba zapisu log. 0
							WRITE_BYTE_CNT  <= 0;										-- reset citace odesilaneho bitu
							write_low_flag  <= 0;										-- reset pozice ve stavu WRITE_LOW
							state 		    <= RESET;									-- reset senzoru
					end case;

				when WRITE_HIGH =>														-- stav pro zapis log. 1 na sbernici
					-- casovy slot pro zapis log 1 rizeny priznakem write_high_flag
					case write_high_flag is												-- pozice ve stavu WRITE_HIGH
						when 0=>																-- vyslani zacatku casoveho slotu pro zapis log. 1
							ds_data_bus <= '0';											-- zacatek casoveho slotu
							S_reset <= '0';												-- zapnuti citace
							if (i = 9) then												-- cekani 10 us
								S_reset 			<= '1';									-- reset citace
								write_high_flag <= 1;
							end if;
						when 1=>																-- uvolneni sbernice pro ukonceni casoveho slotu
							ds_data_bus <= 'Z';											-- uvolneni sbernice
							S_reset 		<= '0';											-- zapnuti citace
							if (i = 53) then												-- cekani 54 us
								S_reset			<= '1';									-- reset citace
								write_high_flag <= 2;
							end if;
						when 2=>																-- konec zapisu log. 1
							write_high_flag <= 0;										-- reset pozice ve stavu WRITE_HIGH
							state 			 <= WRITE_BYTE;							-- navrat do stavu WRITE BYTE
						when others =>														-- chyba zapisu log. 1
							WRITE_BYTE_CNT  <= 0;										-- reset citace odesilaneho bitu
							write_high_flag <= 0;										-- reset pozice ve stavu WRITE_HIGH
							state 		    <= RESET;									-- reset senzoru
					end case;

				when others =>																-- chyba FSM
					state <= RESET;														-- reset senzoru
					
			end case;
		end if;
	end process;

	-- Proces citace se synchronnim resetem
	process(clk1m, S_reset)

	begin
		if (rising_edge(clk1m)) then
			if (S_reset = '1')then		-- reset citace
				i <= 0;						-- vynulovani citace
			else
				i <= i + 1;					-- inkrementace citace
			end if;
		end if;
	end process;

end Behavioral;