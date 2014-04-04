-- entity name: g01_YMD_TestBed
--
-- Circuit to test the g01_YMD_Counter's functionality on the board
--
-- Copyright (C) 2014 Alex Carruthers, Dan Grencorn 
-- Version 1.0
-- Author: Alex Carruthers, Dan Greencorn; michael.carruthers@mail.mcgill.ca, dan.greencorn@mail.mcgill.ca 
-- Date: March 28, 2014


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity g01_YMD_TestBed is
	port ( clock : in std_logic;
		enable : in std_logic;
		reset : in std_logic;
		load_en : in std_logic;
		s0 : in std_logic;
		s1 : in std_logic;
		input : in std_logic_vector(5 downto 0);
		led0 : out std_logic_vector(6 downto 0);
		led1 : out std_logic_vector(6 downto 0);
		led2 : out std_logic_vector(6 downto 0);
		led3 : out std_logic_vector(6 downto 0)
	);
end g01_YMD_TestBed;


architecture behaviour of g01_YMD_TestBed is
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
	
	component g01_YMD_Counter
		port ( 
			clock : in std_logic;
			reset : in std_logic;
			day_count_en : in std_logic;
			load_en : in std_logic;
			Y_Set : in std_logic_vector(11 downto 0);
			M_Set : in std_logic_vector(3 downto 0);
			D_Set : in std_logic_vector(4 downto 0);
			Years : out std_logic_vector(11 downto 0);
			Months : out std_logic_vector(3 downto 0);
			Days : out std_logic_vector(4 downto 0)
		);
	end component;

	signal epulse : std_logic;
	signal year : std_logic_vector(11 downto 0);
	signal month : std_logic_vector(3 downto 0);
	signal day : std_logic_vector(4 downto 0);
	signal bcd_in : std_logic_vector(11 downto 0);
	signal bcd_out : std_logic_vector(15 downto 0);
	signal led1_rb : std_logic;
	signal led2_rb : std_logic;
	signal year_set : std_logic_vector(11 downto 0);
	signal month_set : std_logic_vector(3 downto 0);
	signal day_set : std_logic_vector(4 downto 0);
	------- binary to bcd converter
	------- Uses the ADD-3 (or Double-Dabble) algorithm
	------- 12 bit std_logic_vector in, 16 bit std_logic_vector out (4 BCD digits)
	------- USAGE:   BCD <= to_bcd(BIN);
	-------
	------- include this text at the beginning of the architecture body, after the signal declarations
	-------
	------- (adapted from an 8-bit design from http://vhdlguru.blogspot.ca/2010/04/8-bit-binary-to-bcd-converter-double.html)
	-------
	--
	function to_bcd ( bin : std_logic_vector((11) downto 0) ) return std_logic_vector is

		variable i : integer:=0;
		variable j : integer:=1;
		variable bcd : std_logic_vector((15) downto 0) := (others => '0');
		variable bint : std_logic_vector((11) downto 0) := bin;

		begin
		for i in 0 to 11 loop -- repeating 12 times.
			bcd((15) downto 1) := bcd((14) downto 0); --shifting the bits.
			bcd(0) := bint(11);
			bint((11) downto 1) := bint((10) downto 0);
			bint(0) :='0';

			l1: for j in 1 to 4 loop
				if(i < 11 and bcd(((4*j)-1) downto ((4*j)-4)) > "0100") then --add 3 if BCD digit is greater than 4.
					bcd(((4*j)-1) downto ((4*j)-4)) := std_logic_vector(unsigned(bcd(((4*j)-1) downto ((4*j)-4))) + "0011");
				end if;
			end loop l1;
		end loop;
		return bcd;
	end to_bcd; 
	
begin

	timer : g01_Earth_Mars_timer
		PORT MAP ( clk => clock, reset => reset, enable => enable, epulse => epulse);
	ymd : g01_YMD_Counter
		PORT MAP ( clock => clock,
					reset => reset,
					day_count_en => epulse, 
					load_en => load_en, 
					Y_Set => year_set,
					M_Set => month_set,
					D_Set => day_set,
					Years => year,
					Months => month,
					Days => day
				);
	mux : process(s0, s1, year, month, day)
	begin
		if (s0='0' AND s1='0') then
			bcd_in <= "0000000" & day;
		elsif (s0='1' AND s1='0') then
			bcd_in <= "00000000" & month;
		elsif (s0='0' AND s1='1') then
			bcd_in <= year;
		elsif (s0='1' AND s1='1') then
			bcd_in <= year;
		end if;
		bcd_out <= to_bcd(bcd_in);
	end process;
	
	demux : process(s0, s1, input)
	begin
		if (clock'event and clock = '1') then
			if (s0='0' AND s1='0') then
				day_set <= input(4 downto 0);
			elsif (s0='1' AND s1='0') then
				month_set <= input(3 downto 0);
			elsif (s0='0' AND s1='1') then
				year_set(5 downto 0) <= input;
			elsif (s0='1' AND s1='1') then
				year_set(11 downto 6) <= input;
			end if;
		end if;
	end process;
	
	led0_decoder : g01_7_segment_decoder
		PORT MAP (code => bcd_out(3 downto 0), RippleBlank_In => '0', segments => led0);
	led1_decoder : g01_7_segment_decoder
		PORT MAP (code => bcd_out(7 downto 4), RippleBlank_In => led1_rb, segments => led1);
	led2_decoder : g01_7_segment_decoder
		PORT MAP (code => bcd_out(11 downto 8), RippleBlank_In => led2_rb, RippleBlank_Out => led1_rb, segments => led2);
	led3_decoder : g01_7_segment_decoder
		PORT MAP (code => bcd_out(15 downto 12), RippleBlank_In => '1', RippleBlank_Out => led2_rb, segments => led3);
end behaviour;

