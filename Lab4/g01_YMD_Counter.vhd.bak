-- entity name: g01_YMD_Counter
--
-- Copyright (C) 2014 Alex Carruthers, Dan Grencorn 
-- Version 1.0
-- Author: Alex Carruthers, Dan Greencorn; michael.carruthers@mail.mcgill.ca, dan.greencorn@mail.mcgill.ca 
-- Date: February 27, 2014


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity g01_YMD_Counter is
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
end g01_YMD_Counter;


architecture behaviour of g01_YMD_Counter is
	signal int_years : integer range 1 to (2**Years'length)-1 := 1;
	signal int_months : integer range 1 to (2**Months'length)-1 := 1;
	signal int_days : integer range 1 to (2**Days'length)-1 := 1;
	signal last_day_of_month : std_logic := '0';
	signal leap_year : std_logic := '0';
	signal year_count_en : std_logic := '0';
	signal month_count_en : std_logic := '0';
begin
	is_leap_year : process(int_years)
	begin
		if (int_years mod 4 /= 0) then leap_year <='0';
		elsif (int_years mod 100 /= 0) then leap_year <='1';
		elsif (int_years mod 400 = 0) then leap_year <='1';
		else leap_year <='0';
		end if;
	end process;
	
	is_last_day_of_month : process(int_days)
	begin
		if ((int_days = 30 AND (int_months = 4 OR int_months = 6 OR int_months = 9 OR int_months = 11))
				OR
				(int_days = 31 AND (int_months = 1 OR int_months = 3 OR int_months = 5 OR int_months = 7 OR int_months = 8 OR int_months = 10 OR int_months = 12))
				OR
				(int_days = 28 AND int_months = 2 AND leap_year = '0')
				OR
				(int_days = 29 AND int_months = 2 AND leap_year = '1')) then
			last_day_of_month <= '1';
		else last_day_of_month <= '0';
		end if;
	end process;
	
	days_counter : process(clock, reset)
	begin
		if (reset = '1') then int_days <= 1;
		elsif (clock'event and clock = '1') then
			if (day_count_en = '1') then
				if (load_en = '1') then int_days <= to_integer(unsigned(D_Set));
				elsif (last_day_of_month = '1') then int_days <= 1;
				else int_days <= int_days + 1;
				end if;
			end if;
			if (last_day_of_month = '1') then month_count_en <= '1';
			else month_count_en <= '0';
			end if;
		end if;
	end process;
	
	months_counter : process(clock, reset)
	begin
		if (reset = '1') then int_months <= 1;
		elsif (clock'event and clock = '1') then
			if (day_count_en = '1' and load_en = '1') then int_months <= to_integer(unsigned(M_Set));
			elsif (month_count_en = '1' and day_count_en = '1') then
				if (int_months = 12) then int_months <= 1;
				elsif (day_count_en = '1') then int_months <= int_months + 1;
				end if;
			end if;
			if (int_months = 12 and last_day_of_month = '1') then year_count_en <= '1';
			else year_count_en <= '0';
			end if;
		end if;
	end process;
	
	years_counter : process(clock, reset)
	begin
		if (reset = '1') then int_years <= 1;
		elsif (clock'event and clock = '1') then
			if (day_count_en = '1' and load_en = '1') then int_years <= to_integer(unsigned(Y_Set));
			elsif (year_count_en = '1' and day_count_en = '1') then
				if (day_count_en = '1') then int_years <= int_years + 1;
				end if;
			end if;
		end if;
	end process;
	
	Years <= std_logic_vector(to_unsigned(int_years,12));
	Months <= std_logic_vector(to_unsigned(int_months,4));
	Days <= std_logic_vector(to_unsigned(int_days,5));
end behaviour;

