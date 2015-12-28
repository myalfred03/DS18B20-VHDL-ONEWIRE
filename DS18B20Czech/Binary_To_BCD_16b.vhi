
-- VHDL Instantiation Created from source file Binary_To_BCD_16b.vhd -- 23:51:18 12/27/2015
--
-- Notes: 
-- 1) This instantiation template has been automatically generated using types
-- std_logic and std_logic_vector for the ports of the instantiated module
-- 2) To use this template to instantiate this entity, cut-and-paste and then edit

	COMPONENT Binary_To_BCD_16b
	PORT(
		ENTERO : IN std_logic_vector(15 downto 0);
		POINT : IN std_logic_vector(3 downto 0);          
		BCD : OUT std_logic_vector(18 downto 0);
		BCDPOINT : OUT std_logic_vector(7 downto 0)
		);
	END COMPONENT;

	Inst_Binary_To_BCD_16b: Binary_To_BCD_16b PORT MAP(
		ENTERO => ,
		POINT => ,
		BCD => ,
		BCDPOINT => 
	);


