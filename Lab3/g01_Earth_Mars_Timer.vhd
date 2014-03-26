-- entity name: g01_Earth_Mars_Timer
--
-- This circuit is supposed to use a 50 MHz clock to produce a 
-- 20ns pulse every earth and mars second on the EPULSE and MPULSE lines respectively
--
-- Copyright (C) 2014 Alex Carruthers, Dan Grencorn 
-- Version 1.0
-- Author: Alex Carruthers, Dan Greencorn; michael.carruthers@mail.mcgill.ca, dan.greencorn@mail.mcgill.ca 
-- Date: February 27, 2014


library ieee;
use ieee.std_logic_1164.all;

entity g01_Earth_Mars_Timer is
	port ( clk : in std_logic;
		enable : in std_logic;
		reset : in std_logic;
		epulse : out std_logic;
		mpulse : out std_logic
	);
end g01_Earth_Mars_Timer;


architecture behaviour of g01_Earth_Mars_Timer is
	component g01_Basic_Timer
		generic ( count_val : natural := 0);
		port ( clk : in std_logic;
			enable : in std_logic;
			reset : in std_logic;
			pulse : out std_logic
		);
	end component;
begin
	earth : g01_Basic_Timer
		GENERIC MAP ( count_val => 49999999)
--		GENERIC MAP ( count_val => 10000)
		PORT MAP ( clk => clk, enable => enable, reset => reset, pulse => epulse);
	mars : g01_Basic_Timer
		GENERIC MAP ( count_val => 51374562)
--		GENERIC MAP ( count_val => 1027)
		PORT MAP ( clk => clk, enable => enable, reset => reset, pulse => mpulse);
end behaviour;

