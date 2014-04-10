-- entity name: g01_to_local 
--
-- Copyright (C) 2014 Alex Carruthers, Dan Grencorn 
-- Version 1.0
-- Author: Alex Carruthers, Dan Greencorn; michael.carruthers@mail.mcgill.ca, dan.greencorn@mail.mcgill.ca 
-- Date: April 9, 2014

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity g01_to_local is
	port ( 
		Year_in : in std_logic_vector(11 downto 0);
		Month_in : in std_logic_vector(3 downto 0);
		Day_in : in std_logic_vector(4 downto 0);
		Hour_in : in std_logic_vector(4 downto 0);
		Minute_in : in std_logic_vector(5 downto 0);
		Second_in : in std_logic_vector(5 downto 0);
		
		DST : in std_logic;
		Time_Zone : in std_logic_vector(4 downto 0);
		
		Year_out : out std_logic_vector(11 downto 0);
		Month_out : out std_logic_vector(3 downto 0);
		Day_out : out std_logic_vector(4 downto 0);
		Hour_out : out std_logic_vector(4 downto 0);
		Minute_out : out std_logic_vector(5 downto 0);
		Second_out : out std_logic_vector(5 downto 0)
	);
end g01_to_local;

architecture behaviour of g01_to_local is
	signal Month_in_int : integer range 1 to 12;
	signal leap_year : std_logic;
begin
	-- Minutes and seconds aren't affected so we'll just pass them through to the output
	Minute_out <= Minute_in;
	Second_out <= Second_in;

	calculate_hour : process(Year_in, Month_in, Day_in, Hour_in, DST, Time_Zone, leap_year)
		variable year : integer := to_integer(unsigned(Year_in));
		variable month : integer := to_integer(unsigned(Month_in));
		variable day : integer := to_integer(unsigned(Day_in));
		variable hour : integer := to_integer(unsigned(Hour_in));
		variable orig_month : integer := to_integer(unsigned(Month_in));
	begin
		year := to_integer(unsigned(Year_in));
		month := to_integer(unsigned(Month_in));
		day := to_integer(unsigned(Day_in));
		hour := to_integer(unsigned(Hour_in));
		orig_month := to_integer(unsigned(Month_in));
		
		if (year mod 4 /= 0) then leap_year <='0';
		elsif (year mod 100 /= 0) then leap_year <='1';
		elsif (year mod 400 = 0) then leap_year <='1';
		else leap_year <='0';
		end if;
				
		if (DST = '1') then 
			hour := hour + 1;
		end if;
		
		hour := hour + (to_integer(unsigned(Time_Zone)) - 12);
		
		if (hour < 0) then
			day := day - 1;
			hour := 24 + hour;
			if (day = 0) then
				month := month - 1;
				
				if (orig_month = 1 
						OR orig_month = 2 
						OR orig_month = 4 
						OR orig_month = 6 
						OR orig_month = 9 
						OR orig_month = 11) then
					day := 31;
				elsif (orig_month = 5 
						OR orig_month = 5 
						OR orig_month = 10 
						OR orig_month = 12) then
					day := 30;
				elsif (orig_month = 3 AND leap_year = '1') then
					day := 29;
				elsif (orig_month = 3 AND leap_year = '0') then
					day := 28;
				end if;
				
				if (month = 0) then
					month := 12;
					year := year - 1;
				end if;
			end if;
		elsif (hour > 23) then
			day := day + 1;
			hour := 24 - hour;
			
			if ( ( day = 32 AND ( orig_month = 1
								  OR orig_month = 3
								  OR orig_month = 5
								  OR orig_month = 7
								  OR orig_month = 8
								  OR orig_month = 10
								  OR orig_month = 12 ) )
					OR ( day = 31 AND ( orig_month = 4
										OR orig_month = 6
										OR orig_month = 9
										OR orig_month = 11 ) )
					OR ( day = 30 AND orig_month = 2 AND leap_year = '1')
					OR ( day = 29 AND orig_month = 2 AND leap_year = '0')) then
				month := month + 1;
				day := 1;
				if (month = 13) then
					year := year + 1;
					month := 1;
				end if;
			end if;
		end if;
		Year_out <= std_logic_vector(to_unsigned(year, 12));
		Month_out <= std_logic_vector(to_unsigned(month, 4));
		Day_out <= std_logic_vector(to_unsigned(day, 5));
		Hour_out <= std_logic_vector(to_unsigned(hour, 5));
		
	end process;
end behaviour;