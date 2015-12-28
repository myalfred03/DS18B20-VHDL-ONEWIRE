----------------------------------------------------------------------------
--	divider1MHz.vhd - Modul pro deleni taktu pro senzory
----------------------------------------------------------------------------
-- Autor:  		 			Pavel Gregar
-- Datum vytvoreni:    	11:07:24 11/27/2013
-- Modul:    				divider1MHz - Behavioral 
-- Projekt: 				Meteostanice
-- Cilove zarizeni: 		Nexys4
-- Pouzite nastroje:		Xilinx 14.6
----------------------------------------------------------------------------
--
----------------------------------------------------------------------------
--	Tento modul slouzi k deleni taktu pro senzory DS18B20, DHT11, DHT22 a ADT7420. Vystupni signal
-- pro senzory ma frekvenci 1 MHz.
--         				
-- Porty modulu:
--
--		clk_in			- 100 MHz takt.
--		clk_out			- Vydeleny takt clk_in/100 = 1 MHz.
--
----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity divider1MHz is
    Port ( clk_in 	: IN	STD_LOGIC;
           clk_out 	: OUT	STD_LOGIC
	 );
end divider1MHz;

architecture Behavioral of divider1MHz is

SIGNAL count: INTEGER RANGE 0 to 99; -- citac

begin

	-- Proces pro deleni taktu 1/100
	process (clk_in)
	begin
		if (rising_edge(clk_in)) then
			count <= count + 1;				-- inkrementace citace
			if (count = 49) then				--	konec periody citace
				count <= 0;						-- reset citace
				clk_out <= '1';				-- nastaveni vystupniho signalu
			else
				clk_out <= '0';				-- zruseni vystupniho signalu
			end if;
		end if;
	end process;

end Behavioral;