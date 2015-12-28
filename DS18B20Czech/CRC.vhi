
-- VHDL Instantiation Created from source file CRC.vhd -- 23:12:17 12/27/2015
--
-- Notes: 
-- 1) This instantiation template has been automatically generated using types
-- std_logic and std_logic_vector for the ports of the instantiated module
-- 2) To use this template to instantiate this entity, cut-and-paste and then edit

	COMPONENT CRC
	PORT(
		clk : IN std_logic;
		data_en : IN std_logic;
		dataIn : IN std_logic_vector(71 downto 0);          
		dataOut : OUT std_logic_vector(15 downto 0);
		dataValid : OUT std_logic
		);
	END COMPONENT;

	Inst_CRC: CRC PORT MAP(
		clk => ,
		data_en => ,
		dataIn => ,
		dataOut => ,
		dataValid => 
	);


