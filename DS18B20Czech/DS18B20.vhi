
-- VHDL Instantiation Created from source file DS18B20.vhd -- 23:06:39 12/27/2015
--
-- Notes: 
-- 1) This instantiation template has been automatically generated using types
-- std_logic and std_logic_vector for the ports of the instantiated module
-- 2) To use this template to instantiate this entity, cut-and-paste and then edit

	COMPONENT DS18B20
	PORT(
		clk1m : IN std_logic;    
		ds_data_bus : INOUT std_logic;      
		crc_en : OUT std_logic;
		dataOut : OUT std_logic_vector(71 downto 0)
		);
	END COMPONENT;

	Inst_DS18B20: DS18B20 PORT MAP(
		clk1m => ,
		crc_en => ,
		dataOut => ,
		ds_data_bus => 
	);


