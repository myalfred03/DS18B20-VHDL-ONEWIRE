----------------------------------------------------------------------------
--	transmitControler.vhd - Submodul pro rizeni prenosu namerenych dat do PC pres RS-232
----------------------------------------------------------------------------
-- Autor:  		 			Pavel Gregar
-- Datum vytvoreni:     13:58:13 03/15/2014
-- Modul:    				transmitControler - Behavioral 
-- Projekt: 				Meteostanice
-- Cilove zarizeni: 		Nexys4
-- Pouzite nastroje:		Xilinx 14.6
----------------------------------------------------------------------------
--
----------------------------------------------------------------------------
--	Tento submodul slouzi k rizeni prenosu namerenych dat ze senzoru pomoci seriove linky.
-- Modul ceka na odber dat z pripojenych senzoru DS18B20, DHT11 a ADT7420, 
--	cekanim na nastaveni portu sendRequest_T1, sendRequest_T2 a sendRequest_H1. Pote je 
-- vytvorena sekvence bitu k odeslani na seriovou linku pomoci submodulu UART se kterym 
-- je komunikace rizena pomoci portu parallelDataOut, txIsReady a transmitRequest. 
-- 
--         				
-- Porty modulu:
--
--		clk						- 100 MHz takt.
--		enable					- Spusteni vysilani dat (aktivni v log. 1).
--		transmit_enable_LED 	- Indikace LED vysilani pres RS-232 do PC.
--		sendRequest_T1			- Pouziva se k indikaci prichodu novych dat na portu data_in_T1. Predchozi modul 
--									  by mel nastavit tento signal na jeden takt do logicke 1.			  
--		data_in_T1				- Vstupni data ze senzoru teploty DS18B20.
--		sendRequest_T2			- Viz sendRequest_T1.
--		data_in_T2				- Vstupni data ze senzoru teploty ADT7420.
--		sendRequest_H1			- Viz sendRequest_T1.
--		data_in_H1				- Vstupni data ze senzoru vlhkosti DHT11.
--		parallelDataOut		- Odesilany bajt data pro submodul UART.
--		transmitRequest		- Pouziva se k indikaci zadosti o spusteni vysilani dat z portu parallelDataOut.
--		txIsReady				- Kontrola pripravenosti submodulu UART k odeslani bajtu dat.
--
----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity transmitControler is
    Port ( clk 						: in  STD_LOGIC;
			  enable 					: in  STD_LOGIC;
			  enable_LED				: out	STD_LOGIC;
           sendRequest_T1 			: in  STD_LOGIC;
           data_in_T1				: in  STD_LOGIC_VECTOR (13 downto 0);
			  sendRequest_T2 			: in  STD_LOGIC;
           data_in_T2 				: in  STD_LOGIC_VECTOR (13 downto 0);
           sendRequest_H1 			: in  STD_LOGIC;
           data_in_H1				: in  STD_LOGIC_VECTOR (12 downto 0);
			  sendRequest_H2 			: in  STD_LOGIC;
           data_in_H2				: in  STD_LOGIC_VECTOR (12 downto 0);
           parallelDataOut 		: out  STD_LOGIC_VECTOR (7 downto 0);
           transmitRequest 		: out  STD_LOGIC;
           txIsReady 				: in  STD_LOGIC);
end transmitControler;

architecture Behavioral of transmitControler is

-- Funkce pro prevod dat z binarniho formatu na znak
function convertToChar(s: STD_LOGIC_VECTOR(3 downto 0)) return character is
	begin
		case (s) is
			when "0000" => return '0';
			when "0001" => return '1';
			when "0010" => return '2';
			when "0011" => return '3';
			when "0100" => return '4';
			when "0101" => return '5';
			when "0110" => return '6';
			when "0111" => return '7';
			when "1000" => return '8';
			when "1001" => return '9';
			when "1010" => return 'A';
			when "1011" => return 'B';
			when "1100" => return 'C';
			when "1101" => return 'D';
			when "1110" => return 'E';
			when "1111" => return 'F';
			when others => return NUL;
		end case;
	end convertToChar;

-- pouzite stavy FSM
TYPE controlerState IS (IDLE, PREPARE_SEQUENCE, PREPARE_CHAR, SEND_CHAR);
-- momentalni stav FSM
SIGNAL ctrl_state		: controlerState;

-- navzorkovana data ze senzoru T1: DS18B20
--										  T2: ADT7420
--										  H1: DHT11
--										  H2: DHT22
SIGNAL dataToSend_T1		: STD_LOGIC_VECTOR(13 DOWNTO 0);
SIGNAL dataToSend_T2		: STD_LOGIC_VECTOR(13 DOWNTO 0);
SIGNAL dataToSend_H1		: STD_LOGIC_VECTOR(12 DOWNTO 0);
SIGNAL dataToSend_H2		: STD_LOGIC_VECTOR(12 DOWNTO 0);

-- priznaky prichodu dat ze senzoru T1: DS18B20
--										 	   T2: ADT7420
--												H1: DHT11
--												H2: DHT22
SIGNAL dataReady_T1		: STD_LOGIC;
SIGNAL dataReady_T2		: STD_LOGIC;
SIGNAL dataReady_H1		: STD_LOGIC;
SIGNAL dataReady_H2		: STD_LOGIC;

	-- konstanty pouzite v stringToSend

begin
	-- Proces pro rizeni prenosu dat pres seriovou linku
	process(clk)

	-- citac prave odesilaneho znaku
	VARIABLE char_send_cnt 		: INTEGER RANGE 0 TO 26;

	-- prave odesilany znak
	VARIABLE charToSend			: CHARACTER;

	-- sekvence dat k odeslani od jednotlivych senzoru
	VARIABLE	stringToSend		: STRING(1 TO 26);
	-- stringy obsahujici data ze senzoru
	VARIABLE stringToSend_T1	: STRING(1 TO 6);
	VARIABLE stringToSend_T2	: STRING(1 TO 6);
	VARIABLE stringToSend_H1	: STRING(1 TO 6);
	VARIABLE stringToSend_H2	: STRING(1 TO 6);

	begin


		if (rising_edge(clk)) then
			if (enable = '0') then									-- vypnuti odesilani
				transmitRequest <= '0';								-- zruseni zadosti o odesilani
				parallelDataOut	<= (others => '0');			-- reset vsech dat
				charToSend			:= NUL;
				stringToSend_T1	:= (others => NUL);
				stringToSend_T2	:= (others => NUL);
				stringToSend_H1	:= (others => NUL);
				stringToSend_H2	:= (others => NUL);
				stringToSend := stringToSend_T1 & stringToSend_H1 & stringToSend_T2 & stringToSend_H2 & CR & LF;
				ctrl_state		<=	IDLE;								-- navrat do zakladniho stavu
			else
				case (ctrl_state) is
					when IDLE =>										-- zakladni stav modulu, cekani na data ze vsech senzoru
						-- Cekani na data ze vsech senzoru
						if (dataReady_T1 = '1' and dataReady_T2 = '1' and dataReady_H1 = '1' and dataReady_H2 = '1') then
							char_send_cnt 	 := 0;							-- reset citace odeslanych znaku
							ctrl_state 			 <= PREPARE_SEQUENCE;	-- prechod do stavu PREPARE_SEQUENCE
						end if;

					when PREPARE_SEQUENCE =>						-- stav pro pripravu sekvence dat pro odeslani
						-- vytvoreni stringu obsahujici data ze senzoru teploty DS18B20
						if (dataToSend_T1(13 downto 12) = "11") then -- data obsahuji cislo chyby
							stringToSend_T1 := "E " & convertToChar(dataToSend_T1(11 downto 8)) & convertToChar(dataToSend_T1(7 downto 4)) & convertToChar(dataToSend_T1(3 downto 0)) & ';';
						elsif (dataToSend_T1(13 downto 12) = "00") then -- data obsahuji kladnou hodnotu namerene teploty
							stringToSend_T1 := '+' & convertToChar(dataToSend_T1(11 downto 8)) & convertToChar(dataToSend_T1(7 downto 4)) & '.' & convertToChar(dataToSend_T1(3 downto 0)) & ';';
						elsif (dataToSend_T1(13 downto 12) = "01") then -- data obsahuji zapornou hodnotu namerene teploty
							stringToSend_T1 := '-' & convertToChar(dataToSend_T1(11 downto 8)) & convertToChar(dataToSend_T1(7 downto 4)) & '.'  &convertToChar(dataToSend_T1(3 downto 0)) & ';';
						else -- chyba obdrzenych dat
							stringToSend_T1 := "ER_T1" & ';';
						end if;
						
						-- vytvoreni stringu obsahujici data ze senzoru teploty ADT7420
						if (dataToSend_T2(13 downto 12) = "11") then -- data obsahuji cislo chyby
							stringToSend_T2 := "E " & convertToChar(dataToSend_T2(11 downto 8)) & convertToChar(dataToSend_T2(7 downto 4)) & convertToChar(dataToSend_T2(3 downto 0)) & ';';
						elsif (dataToSend_T2(13 downto 12) = "00") then -- data obsahuji kladnou hodnotu namerene teploty
							stringToSend_T2 := '+' & convertToChar(dataToSend_T2(11 downto 8)) & convertToChar(dataToSend_T2(7 downto 4)) & '.' & convertToChar(dataToSend_T2(3 downto 0)) & ';';
						elsif (dataToSend_T2(13 downto 12) = "01") then -- data obsahuji zapornou hodnotu namerene teploty
							stringToSend_T2 := '-' & convertToChar(dataToSend_T2(11 downto 8)) & convertToChar(dataToSend_T2(7 downto 4)) & '.'  &convertToChar(dataToSend_T2(3 downto 0)) & ';';
						else -- chyba obdrzenych dat
							stringToSend_T2 := "ER_T2" & ';';
						end if;
						
						--vytvoreni stringu obsahujici data ze senzoru vlhkosti DHT11
						if (dataToSend_H1(12) = '1') then -- data obsahuji cislo chyby
							stringToSend_H1 := "E " & convertToChar(dataToSend_H1(11 downto 8)) & convertToChar(dataToSend_H1(7 downto 4)) & convertToChar(dataToSend_H1(3 downto 0)) & ';';
						elsif (dataToSend_H1(12) = '0') then -- data obsahuji hodnotu namerene vlhkosti
							stringToSend_H1 := convertToChar(dataToSend_H1(7 downto 4)) & convertToChar(dataToSend_H1(3 downto 0)) & "%  " & ';';
						else -- chyba obdrzenych dat
							stringToSend_H1 := "ER_H1" & ';';
						end if;
						
						-- vytvoreni stringu obsahujici data ze senzoru vlhkosti DHT22
						if (dataToSend_H2(12) = '1') then -- data obsahuji cislo chyby
							stringToSend_H2 := "E " & convertToChar(dataToSend_H2(11 downto 8)) & convertToChar(dataToSend_H2(7 downto 4)) & convertToChar(dataToSend_H2(3 downto 0)) & ';';
						elsif (dataToSend_H2(12) = '0') then -- data obsahuji hodnotu namerene vlhkosti
							stringToSend_H2 := convertToChar(dataToSend_H2(11 downto 8)) & convertToChar(dataToSend_H2(7 downto 4)) & '.' &convertToChar(dataToSend_H2(3 downto 0)) & "%" & ';';
						else -- chyba obdrzenych dat
							stringToSend_H2 := "ER_H2" & ';';
						end if;
			
						-- vytvoreni kompletniho odesilaneho stringu
						stringToSend := stringToSend_T1 & stringToSend_H1 & stringToSend_T2 & stringToSend_H2 & CR & LF; -- zapis kompletni sekvence dat k odeslani dat
						ctrl_state <= PREPARE_CHAR;	-- prechod do stavu PREPARE_CHAR
	
					when PREPARE_CHAR =>						-- stav pro pripravu seriovych dat 
						transmitRequest <= '0';				-- zruseni pozadavku na odesilani znaku
						if (char_send_cnt < 26) then		-- pocitani odeslanych znaku
							charToSend := stringToSend(char_send_cnt+1); -- vyber odesilaneho znaku
							-- konverze dat z char do std_logic_vector
							parallelDataOut <= std_logic_vector(to_unsigned(character'pos(charToSend), 8));
							char_send_cnt 	 := char_send_cnt + 1;		-- inkrementace odesilaneho bitu
							ctrl_state 			 <= SEND_CHAR;				-- prechod do stavu SEND_CHAR
						else
							transmitRequest <= '0';							-- ukonceni odesilani dat po odeslani 26 znaku
							ctrl_state 			 <= IDLE;					-- prechod do stavu IDLE
						end if;

					when SEND_CHAR =>											-- stav pro odesilani bajtu dat
						if (txIsReady = '1') then							-- cekani na submodul UART
							transmitRequest <= '1';							-- pozadavek na odeslani bajtu dat
							ctrl_state 			 <= PREPARE_CHAR;			-- navrat k dalsimu odesilani ve stavu PREPARE_CHAR
						end if;
				end case;
			end if;
		end if;
	end process;
	
	-- Proces pro cekani na data ze senzoru DS18B20
	process(clk)
	begin
		if (rising_edge(clk)) then
			if (sendRequest_T1 = '1') then		-- prichod dat ze senzoru teploty DS18B20
				dataToSend_T1	<= data_in_T1;		-- odebrani vzorku dat ze senzoru teploty DS18B20
				dataReady_T1	<= '1';				-- nastaveni priznaku prichodu dat
			else
				if ctrl_state = PREPARE_SEQUENCE then
					dataReady_T1	<= '0';				-- zruseni priznaku prichodu dat
				end if;
			end if;
		end if;
	end process;
	
	-- Proces pro cekani na data ze senzoru ADT7420
	process(clk)
	begin
		if (rising_edge(clk)) then
			if (sendRequest_T2 = '1') then		-- prichod dat ze senzoru teploty ADT7420
				dataToSend_T2	<= data_in_T2;		-- odebrani vzorku dat ze senzoru teploty ADT7420
				dataReady_T2	<= '1';				-- nastaveni priznaku prichodu dat
			else
				if ctrl_state = PREPARE_SEQUENCE then
					dataReady_T2	<= '0';			-- zruseni priznaku prichodu dat
				end if;
			end if;
		end if;
	end process;
	
	-- Proces pro cekani na data ze senzoru DHT11
	process(clk)
	begin
		if (rising_edge(clk)) then
			if (sendRequest_H1 = '1') then		-- prichod dat ze senzoru vlhkosti DHT11
				dataToSend_H1	<= data_in_H1;		-- odebrani vzorku dat ze senzoru vlhkosti DHT11
				dataReady_H1	<= '1';				-- nastaveni priznaku prichodu dat
			else
				if ctrl_state = PREPARE_SEQUENCE then
					dataReady_H1	<= '0';				-- zruseni priznaku prichodu dat
				end if;
			end if;
		end if;
	end process;
	
		-- Proces pro cekani na data ze senzoru DHT22
	process(clk)
	begin
		if (rising_edge(clk)) then
			if (sendRequest_H2 = '1') then		-- prichod dat ze senzoru vlhkosti DHT22
				dataToSend_H2	<= data_in_H2;		-- odebrani vzorku dat ze senzoru vlhkosti DHT22
				dataReady_H2	<= '1';				-- nastaveni priznaku prichodu dat
			else
				if ctrl_state = PREPARE_SEQUENCE then
					dataReady_H2	<= '0';				-- zruseni priznaku prichodu dat
				end if;
			end if;
		end if;
	end process;
	
	enable_LED <= '1' when enable = '1' else '0';
	
end Behavioral;