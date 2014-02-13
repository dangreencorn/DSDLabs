-- this circuit decodes binary into the signals required to drive a 7-segment display
-- if the RippleBlank_In is set high, and the binary value is zero, the display does not
-- show anything and the RippleBlank_Out is set high. (This removes any leading zeros)
--
-- entity name: g01_binary_to_BCD 
--
-- Copyright (C) 2014 Alex Carruthers, Dan Grencorn 
-- Version 1.0
-- Author: Alex Carruthers, Dan Greencorn; michael.carruthers@mail.mcgill.ca, dan.greencorn@mail.mcgill.ca 
-- Date: February 13, 2014

library ieee;
use ieee.std_logic_1164.all;

entity gNN_7_segment_decoder is
	port ( code : in std_logic_vector(3 downto 0);
		RippleBlank_In : in std_logic;
		RippleBlank_Out : out std_logic;
		segments : out std_logic_vector(6 downto 0)
	);
end gNN_7_segment_decoder;

architecture decode of g01_7_segment_decoder is

begin

	with RippleBlank_In & code
		select RippleBlank_Out & segments =>
			"01000000" when "00000", -- zero
			"01111001" when "00001", -- one
			"00100111" when "00010", -- two
			"00110000" when "00011", -- three
			"00011001" when "00100", -- four
			"00010010" when "00101", -- five
			"00000010" when "00110", -- six
			"01111000" when "00111", -- seven
			"00000000" when "01000", -- eight
			"00011000" when "01001", -- nine
			"00001000" when "01010", -- a
			"00000011" when "01011", -- b
			"00000110" when "01100", -- c
			"00100001" when "01101", -- d
			"00000110" when "01110", -- e
			"00001110" when "01111", -- f
			"11111111" when "10000", -- blank and RippleBlank_out
			"01111001" when "10001", -- one
			"00100111" when "10010", -- two
			"00110000" when "10011", -- three
			"00011001" when "10100", -- four
			"00010010" when "10101", -- five
			"00000010" when "10110", -- six
			"01111000" when "10111", -- seven
			"00000000" when "11000", -- eight
			"00011000" when "11001", -- nine
			"00001000" when "11010", -- a
			"00000011" when "11011", -- b
			"00000110" when "11100", -- c
			"00100001" when "11101", -- d
			"00000110" when "11110", -- e
			"00001110" when "11111"; -- f


end decode;