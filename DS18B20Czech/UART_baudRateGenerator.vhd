----------------------------------------------------------------------------
--	UART_baudRateGenerator.vhd - Submodul pro generovani taktu pro odesilani dat
----------------------------------------------------------------------------
-- Autor:  		 			Pavel Gregar
-- Datum vytvoreni:     20:44:36 03/03/2014
-- Modul:    				UART_baudRateGenerator - Behavioral 
-- Projekt: 				Meteostanice
-- Cilove zarizeni: 		Nexys4
-- Pouzite nastroje:		Xilinx 14.6
----------------------------------------------------------------------------
--
----------------------------------------------------------------------------
--	Tento submodul slouzi ke generovani taktu pro odesilani dat. Pro hodinovy signal 100 MHz je kazdych 
-- 8,68 us (868/(100*10^6)) generovana vzestupna hrana signalu pouzita v submodulu UART_transmitter.
-- Tim je dosazena rychlost odesilani zhruba 115 200 b/s (+0,0064%).
--         				
-- Porty submodulu:
--
--		clk				- 100 MHz takt.
--		enable			- Spusteni generatoru(aktivni v log. 1).
--		baudRateEnable	- Vystupni port s generovanym taktem. 			  
--
----------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity UART_baudRateGenerator is
    Port ( clk						:	in		STD_LOGIC;
           enable 				:	in		STD_LOGIC;
           baudRateEnable		:	out	STD_LOGIC);
end UART_baudRateGenerator;

architecture Behavioral of UART_baudRateGenerator is

begin

	-- Proces pro generovani taktu pro odesilani dat pres serovou linku.
	process (clk)
		variable clockCount	:	integer range 0 to 868 := 0;	-- citac pro generovani signalu o periode 8,68 us

		begin
		if rising_edge(clk) then
			if (enable = '0') then 										-- zastaveni generatoru
				baudRateEnable <= '0';									-- zruseni signalu
				clockCount 		:= 0;										-- reset citace
			else
				baudRateEnable <= '0';									-- zruseni vystupniho signalu
				clockCount := clockCount + 1;							-- inkrementace citace
				if (clockCount = 434) then								-- konec periody citace
					baudRateEnable <= '1';								-- nastaveni vystupniho signalu
					clockCount 		:= 0;									-- reset citace
				end if;
			end if;
		end if;
	end process;
	
end Behavioral;