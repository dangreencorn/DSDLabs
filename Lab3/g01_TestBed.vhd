-- entity name: g01_timer_testbed
--
-- Copyright (C) 2014 Alex Carruthers, Dan Grencorn 
-- Version 1.0
-- Author: Alex Carruthers, Dan Greencorn; michael.carruthers@mail.mcgill.ca, dan.greencorn@mail.mcgill.ca 
-- Date: February 27, 2014


library ieee;
use ieee.std_logic_1164.all;

library lpm;
use lpm.lpm_components.all;

entity g01_timer_testbed is
	port ( 
		clk : in std_logic;
		reset : in std_logic;
		earth_5_led : out std_logic_vector(6 downto 0);
		earth_9_led : out std_logic_vector(6 downto 0);
		mars_5_led : out std_logic_vector(6 downto 0);
		mars_9_led : out std_logic_vector(6 downto 0)
	);
end g01_timer_testbed;


architecture behaviour of g01_timer_testbed is
	component g01_7_segment_decoder
		port ( code : in std_logic_vector(3 downto 0);
			RippleBlank_In : in std_logic;
			RippleBlank_Out : out std_logic;
			segments : out std_logic_vector(6 downto 0)
		);
	end component;
	
	component g01_Earth_Mars_Timer
		port ( clk : in std_logic;
			enable : in std_logic;
			reset : in std_logic;
			epulse : out std_logic;
			mpulse : out std_logic
		);
	end component;
	
	component g01_59_up_counter
		port ( clk : in std_logic;
			reset : in std_logic;
			output_5 : out std_logic_vector(2 downto 0);
			output_9 : out std_logic_vector(3 downto 0)
		);
	end component;
	
	signal earth_second : std_logic;
	signal mars_second : std_logic;
	signal earth_tens : std_logic_vector(2 downto 0);
	signal earth_ones : std_logic_vector(3 downto 0);
	signal mars_tens : std_logic_vector(2 downto 0);
	signal mars_ones : std_logic_vector(3 downto 0);
	signal reset_inv : std_logic;
	
begin
	reset_inv <= not reset;
	timer : g01_Earth_Mars_timer
		PORT MAP ( clk => clk, reset => reset_inv, enable => '1', epulse => earth_second, mpulse => mars_second);
	earth_counter : g01_59_up_counter
		PORT MAP ( clk => earth_second, reset => reset_inv, output_5 => earth_tens, output_9 => earth_ones);
	mars_counter : g01_59_up_counter
		PORT MAP ( clk => mars_second, reset => reset_inv, output_5 => mars_tens, output_9 => mars_ones);
	earth_tens_display : g01_7_segment_decoder
		PORT MAP ( code => '0' & earth_tens, RippleBlank_In => '1', segments => earth_5_led);
	earth_ones_display : g01_7_segment_decoder
		PORT MAP ( code => earth_ones, RippleBlank_In => '0', segments => earth_9_led);
	mars_tens_display : g01_7_segment_decoder
		PORT MAP ( code => '0' & mars_tens, RippleBlank_In => '1', segments => mars_5_led);
	mars_ones_display : g01_7_segment_decoder
		PORT MAP ( code => mars_ones, RippleBlank_In => '0', segments => mars_9_led);

end behaviour;

