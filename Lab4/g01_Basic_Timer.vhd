-- entity name: g01_Basic_Timer
--
-- Copyright (C) 2014 Alex Carruthers, Dan Grencorn 
-- Version 1.0
-- Author: Alex Carruthers, Dan Greencorn; michael.carruthers@mail.mcgill.ca, dan.greencorn@mail.mcgill.ca 
-- Date: February 27, 2014


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

library lpm;
use lpm.lpm_components.all;


entity g01_Basic_Timer is
	generic ( count_val : natural :=1);
	port ( clk : in std_logic;
		enable : in std_logic;
		reset : in std_logic;
		pulse : out std_logic
	);
end g01_Basic_Timer;


architecture behaviour of g01_Basic_Timer is
	signal data : std_logic_vector(39 downto 0);
	signal sload : std_logic;
	signal q : std_logic_vector(39 downto 0);
	signal result : std_logic;
begin
	data <= conv_std_logic_vector(count_val,40);
	sload <= reset OR result;
	result <= '1' when (q = "0000000000000000000000000000000000000000") else '0';
	pulse <= result;

	counter : lpm_counter
		GENERIC MAP(
			lpm_width => 40,
			lpm_direction => "down"
		)
		PORT MAP(
			data => data,
			sload => sload,
			clock => clk,
			cnt_en => enable,
			q => q
		);	
end behaviour;

