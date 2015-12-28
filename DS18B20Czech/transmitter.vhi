
-- VHDL Instantiation Created from source file transmitter.vhd -- 11:35:01 12/28/2015
--
-- Notes: 
-- 1) This instantiation template has been automatically generated using types
-- std_logic and std_logic_vector for the ports of the instantiated module
-- 2) To use this template to instantiate this entity, cut-and-paste and then edit

	COMPONENT transmitter
	PORT(
		clk : IN std_logic;
		enable : IN std_logic;
		sendRequest_T1 : IN std_logic;
		data_in_T1 : IN std_logic_vector(13 downto 0);
		sendRequest_H1 : IN std_logic;
		data_in_H1 : IN std_logic_vector(12 downto 0);
		sendRequest_T2 : IN std_logic;
		data_in_T2 : IN std_logic_vector(13 downto 0);
		sendRequest_H2 : IN std_logic;
		data_in_H2 : IN std_logic_vector(12 downto 0);          
		enable_LED : OUT std_logic;
		serialDataOut : OUT std_logic
		);
	END COMPONENT;

	Inst_transmitter: transmitter PORT MAP(
		clk => ,
		enable => ,
		enable_LED => ,
		sendRequest_T1 => ,
		data_in_T1 => ,
		sendRequest_H1 => ,
		data_in_H1 => ,
		sendRequest_T2 => ,
		data_in_T2 => ,
		sendRequest_H2 => ,
		data_in_H2 => ,
		serialDataOut => 
	);


