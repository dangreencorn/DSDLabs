 -- Converts 17-bit representation of seconds to Fractional Days (ie. V(40-bits) in V/2^40)
 --
 -- entity name: g01_Seconds_to_Days
 --
 -- Copyright (C) 2014 Alex Carruthers & Dan Greencorn
 -- Version 1.0
 -- Author: Alex Carruthers, Dan Greencorn; alex@alexcarruthers.com, dan@dangreencorn.ca
 -- Date: Jan. 23, 2014
 
 library ieee;
 use ieee.std_logic_1164.all;
 use ieee.numeric_std.all;
 
 entity g01_Seconds_to_Days is
	port ( 	seconds			: in unsigned(16 downto 0);
			day_fraction 	: out unsigned(39 downto 0));
end g01_Seconds_to_Days;

architecture implementation of g01_Seconds_to_Days is
	signal adder1 : unsigned(19 downto 0);
	signal adder2 : unsigned(23 downto 0);
	signal adder3 : unsigned(26 downto 0);
	signal adder4 : unsigned(27 downto 0);
	signal adder5 : unsigned(28 downto 0);
	signal adder6 : unsigned(30 downto 0);
	signal adder7 : unsigned(34 downto 0);
	signal adder8 : unsigned(39 downto 0);
	
begin
	adder1 <= seconds + ('0' & seconds & "00");
	adder2 <= adder1 + ('0' & seconds & "000000");
	adder3 <= adder2 + ('0' & seconds & "000000000");
	adder4 <= adder3 + ('0' & seconds & "0000000000");
	adder5 <= adder4 + ('0' & seconds & "00000000000");
	adder6 <= adder5 + ('0' & seconds & "0000000000000");
	adder7 <= adder6 + ('0' & seconds & "00000000000000000");
	adder8 <= adder7 + ('0' & seconds & "0000000000000000000000");
	day_fraction <= adder8 + (seconds & "00000000000000000000000");
end implementation;