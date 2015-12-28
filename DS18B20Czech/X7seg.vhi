
-- VHDL Instantiation Created from source file X7seg.vhd -- 23:28:03 12/27/2015
--
-- Notes: 
-- 1) This instantiation template has been automatically generated using types
-- std_logic and std_logic_vector for the ports of the instantiated module
-- 2) To use this template to instantiate this entity, cut-and-paste and then edit

	COMPONENT X7seg
	PORT(
		x : IN std_logic_vector(15 downto 0);
		clk : IN std_logic;
		clr : IN std_logic;          
		an : OUT std_logic_vector(3 downto 0);
		a_to_g : OUT std_logic_vector(6 downto 0)
		);
	END COMPONENT;

	Inst_X7seg: X7seg PORT MAP(
		x => ,
		clk => ,
		clr => ,
		an => ,
		a_to_g => 
	);


