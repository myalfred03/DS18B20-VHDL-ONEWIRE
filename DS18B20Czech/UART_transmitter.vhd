----------------------------------------------------------------------------
--	UART_transmitter.vhd - Modul pro odesilani dat do PC pres serivou linku
----------------------------------------------------------------------------
-- Autor:  		 			Pavel Gregar
-- Datum vytvoreni:    	17:52:14 03/04/2014 
-- Modul:    				UART_transmitter - Behavioral 
-- Projekt: 				Meteostanice
-- Cilove zarizeni: 		Nexys4
-- Pouzite nastroje:		Xilinx 14.6
----------------------------------------------------------------------------
--
----------------------------------------------------------------------------
--	Tento submodul slouzi k odesilani bajtu dat prijateho na portu parallelDataOut. 
-- Modul serializuje prijata data a odesila je na port serialDataOut s temito parametry:
--         115200 b/s,
--         8 datovych bitu, prvni LSB,
--         zadna parita,
--         1 stop bit,
--			  rizeni toku - zadne.
--         				
-- Porty modulu:
--
--		clk				 - 100 MHz takt.
--		enable			 - Spusteni submodulu (aktivni v log. 1).
--		baudRateEnable	 - Takt pro odesilani jednotlivych bitu dat.
--		parallelDataIn	 - Vstupni bajt dat urceny k odeslani.
--		transmitRequest - Pozadavek k odesilani od submodulu transmitControler.
--		txIsReady		 - Oznameni pripravenosti k odeslani dalseho bajtu dat.
--		serialDataOut	 - Tento signal je pripojen na pin pro odesilani dat pres seriovou linku.
--
----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity UART_transmitter is
    Port ( clk						: IN	STD_LOGIC;
           enable 				: IN	STD_LOGIC;
           baudRateEnable		: IN	STD_LOGIC;
           parallelDataIn		: IN	STD_LOGIC_VECTOR (7 downto 0);
           transmitRequest		: IN	STD_LOGIC;
           txIsReady				: OUT	STD_LOGIC;
           serialDataOut		: OUT	STD_LOGIC);
end UART_transmitter;

architecture Behavioral of UART_transmitter is

-- pouzite stavy FSM
type transmitterState is (IDLE, SEND_START_BIT, SEND_DATA_BITS, SEND_STOP_BIT);

-- momentalni stav FSM
signal txState	: transmitterState := IDLE;

begin

	-- Proces pro odesilani dat pres seriovou linku
	process(clk)
	
	variable dataToTx		:	STD_LOGIC_VECTOR(7 downto 0);		-- navzorkovany bajt dat k odeslani
	variable bitToSend	:	INTEGER RANGE 0 TO 7 := 0;			-- citac prave odesilaneho bitu
	variable	go				:	STD_LOGIC := '0';						-- priznak k zahajeni odesilani
	
	begin
		if rising_edge(clk) then
			if (enable = '0') then										-- vypnuti odesilani
				txState			<=	IDLE;									-- navrat do vychoziho stavu
				txIsReady		<= '0';									-- indikace nepripravenosti k odesilani
				go					:= '0';									-- zruseni priznaku k zahajeni odesilani
				serialDataOut	<= '1';									-- nastaveni seriove linky do vychoziho stavu
			else
				if (transmitRequest = '1') then						-- prichod pozadavku k odesilani
					go := '1';												-- nastaveni priznaku k zahajeni odesilani
					dataToTx	:=	parallelDataIn;						-- navzorkovani prichozich dat
					txIsReady	<= '0';									-- indikace k nepripravenosti k dalsimu odesilani
				end if;
				if (baudRateEnable = '1') then						-- prichod taktu pro rychlost odesilani 115 200 Bd
					case(txState) is										-- stavovy automat
						when IDLE =>										-- vychozi stav
							txIsReady		<=	'1';						-- submodul pripraven k odeslani dalsich dat
							serialDataOut	<= '1';						-- nastaveni seriove linky do vychoziho stavu
							if (go = '1') then							-- zaznamenan pozadavek na odeslani dat
								go				:= '0';						-- zruseni priznaku k zahajeni odesilani
								bitToSend	:= 0;							-- reset citace pro odesilany bit
								txIsReady	<= '0';						-- submodul prave odesila data
								txState		<=	SEND_START_BIT;		-- prechod do stavu SEND_START_BIT
							end if;
							
						when SEND_START_BIT =>							-- stav pro odeslani start bitu
							serialDataOut	<= '0';						-- zacatek start bitu
							txState			<=	SEND_DATA_BITS;		-- prechod do stavu SEND_DATA_BITS
							
						when SEND_DATA_BITS =>							-- stav pro odesilani dat
							serialDataOut	<= dataToTx(bitToSend);	-- nastaveni seriove linky podle jednotlivych bitu dat
							if (bitToSend = 7) then						-- odeslan posledni bit dat
								txState	<=	SEND_STOP_BIT;				-- prechod do stavu SEND_STOP_BIT
							else
								bitToSend := bitToSend + 1;			-- inkrementace citace prave vyslaneho bitu
							end if;
							
						when SEND_STOP_BIT =>							-- stav pro odeslani stop bitu
							serialDataOut	<= '1';						-- zacatek stop bitu
							if (transmitRequest = '0') then			-- kontrola zruseni pozadavku na vysilani
								txState			<= IDLE;					-- prechod do stavu IDLE
							end if;
					end case;	
				end if;	
			end if;
		end if;
	end process;
end Behavioral;