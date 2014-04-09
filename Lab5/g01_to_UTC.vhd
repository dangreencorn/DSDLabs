-- entity name: g01_to_UTC 
--
-- Copyright (C) 2014 Alex Carruthers, Dan Grencorn 
-- Version 1.0
-- Author: Alex Carruthers, Dan Greencorn; michael.carruthers@mail.mcgill.ca, dan.greencorn@mail.mcgill.ca 
-- Date: April 9, 2014

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity g01_to_UTC is
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
		Second_out : out std_logic_vector(5 downto 0);
		h : out integer range 0 to 23
	);
end g01_to_UTC;

architecture behaviour of g01_to_UTC is
	signal Year_in_int : integer range 1 to 4000;
	signal Month_in_int : integer range 1 to 12;
	signal Day_in_int : integer range 1 to 31;
	signal Hour_in_int : integer range 0 to 23;
	signal tz_int : integer range 0 to 23;
	signal leap_year : std_logic;
	signal Year_out_int : integer range 1 to 4000;
	signal Month_out_int : integer range 0 to 13;
	signal Day_out_int : integer range 0 to 32;
	signal Hour_out_int : integer range -13 to 45;
begin
	-- Minutes and seconds aren't affected so we'll just pass them through to the output
	Minute_out <= Minute_in;
	Second_out <= Second_in;

	
	
	calculate_hour : process(Year_in, Month_in, Day_in, Hour_in, DST, Time_Zone)
	begin
		Year_in_int <= to_integer(unsigned(Year_in));
		Month_in_int <= to_integer(unsigned(Month_in));
		Day_in_int <= to_integer(unsigned(Day_in));
		Hour_in_int <= to_integer(unsigned(Hour_in));
		tz_int <= to_integer(unsigned(Time_Zone));
		
		Year_out_int <= Year_in_int;
		Month_out_int <= Month_in_int;
		Day_out_int <= Day_in_int;
		Hour_out_int <= Hour_in_int;
		
		if (Year_in_int mod 4 /= 0) then leap_year <='0';
		elsif (Year_in_int mod 100 /= 0) then leap_year <='1';
		elsif (Year_in_int mod 400 = 0) then leap_year <='1';
		else leap_year <='0';
		end if;
				
		if (DST = '1') then 
			Hour_out_int <= Hour_out_int - 1;
		end if;
		
		Hour_out_int <= Hour_out_int - (tz_int - 12);
		
		if (Hour_out_int < 0) then
			Day_out_int <= Day_out_int - 1;
			Hour_out_int <= 24 + Hour_out_int;
			if (Day_out_int = 0) then
				Month_out_int <= Month_out_int - 1;
				
				if (Month_in_int = 1 
						OR Month_in_int = 2 
						OR Month_in_int = 4 
						OR Month_in_int = 6 
						OR Month_in_int = 9 
						OR Month_in_int = 11) then
					Day_out_int <= 31;
				elsif (Month_in_int = 5 
						OR Month_in_int = 5 
						OR Month_in_int = 10 
						OR Month_in_int = 12) then
					Day_out_int <= 30;
				elsif (Month_in_int = 3 AND leap_year = '1') then
					Day_out_int <= 29;
				elsif (Month_in_int = 3 AND leap_year = '0') then
					Day_out_int <= 28;
				end if;
				
				if (Month_out_int = 0) then
					Month_out_int <= 12;
					Year_out_int <= Year_out_int - 1;
				end if;
			end if;
		elsif (Hour_out_int > 23) then
			Day_out_int <= Day_out_int + 1;
			Hour_out_int <= 24 - Hour_out_int;
			
			if ( ( Day_out_int = 32 AND ( Month_in_int = 1
										  OR Month_in_int = 3
										  OR Month_in_int = 5
										  OR Month_in_int = 7
										  OR Month_in_int = 8
										  OR Month_in_int = 10
										  OR Month_in_int = 12 ) )
					OR ( Day_out_int = 31 AND ( Month_in_int = 4
												OR Month_in_int = 6
												OR Month_in_int = 9
												OR Month_in_int = 11 ) )
					OR ( Day_out_int = 30 AND Month_in_int = 2 AND leap_year = '1')
					OR ( Day_out_int = 30 AND Month_in_int = 2 AND leap_year = '0')) then
				Month_out_int <= Month_out_int + 1;
				Day_out_int <= 1;
				if (Month_out_int = 13) then
					Year_out_int <= Year_out_int + 1;
					Month_out_int <= 1;
				end if;
			end if;
		end if;
		h <= Hour_out_int;
		Year_out <= std_logic_vector(to_unsigned(Year_out_int, 12));
		Month_out <= std_logic_vector(to_unsigned(Month_out_int, 4));
		Day_out <= std_logic_vector(to_unsigned(Day_out_int, 5));
		Hour_out <= std_logic_vector(to_unsigned(Hour_out_int, 5));
	end process;
	
	

end behaviour;