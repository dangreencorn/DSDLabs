-- this circuit computes the number of seconds since midnight given
-- the current time in Hours (using a 24-hour notation), Minutes, and Seconds
--
-- entity name: g01_dayseconds
--
-- Copyright (C) 2014 Alex Carruthers, Dan Greencorn
-- Version 1.0
-- Author: Alex Carruthers, Dan Greencorn
-- Date: 2014-02-12

library ieee;
use ieee.std_logic_1164.all; -- allows use of the std_logic_vector type
use ieee.numeric_std.all; -- allows use of the unsigned type

library lpm;
use lpm.lpm_components.all; -- allows use of the Altera library modules

entity g01_dayseconds is
	port ( Hours : in unsigned(4 downto 0);
		   Minutes, Seconds : in unsigned(5 downto 0);
		   DaySeconds : out unsigned(16 downto 0));
end g01_dayseconds;

architecture behaviour of g01_dayseconds is
	signal sixty : std_logic_vector(5 downto 0);
	signal product1 : std_logic_vector(10 downto 0);
	signal sum1 : std_logic_vector (10 downto 0);
	signal product2 : std_logic_vector(16 downto 0);
	
begin
	sixty <= "111100";
	
	mult1 : lpm_mult
	GENERIC MAP(
		lpm_widtha => 6,
		lpm_widthb => 5,
		lpm_widthp => 11)
	PORT MAP(dataa => sixty, datab => std_logic_vector(Hours), result => product1);
	
	mult2 : lpm_mult
	GENERIC MAP(
		lpm_widtha => 11,
		lpm_widthb => 6,
		lpm_widthp => 17)
	PORT MAP(dataa => sum1, datab => sixty, result => product2);
	
	add1 : lpm_add_sub
	GENERIC MAP(
		lpm_width => 11)
	PORT MAP(dataa => product1, datab => "00000" & std_logic_vector(Minutes), result => sum1);
	
	add2 : lpm_add_sub
	GENERIC MAP(
		lpm_width => 17)
	PORT MAP(dataa => product2, datab => "00000000000" & std_logic_vector(Seconds), unsigned(result) => DaySeconds);
	
	
end behaviour;