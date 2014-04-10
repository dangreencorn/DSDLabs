-- entity name: g01_HMS_Counter
--
-- Copyright (C) 2014 Alex Carruthers, Dan Grencorn 
-- Version 1.0
-- Author: Alex Carruthers, Dan Greencorn; michael.carruthers@mail.mcgill.ca, dan.greencorn@mail.mcgill.ca 
-- Date: February 27, 2014


library ieee;
use ieee.std_logic_1164.all;

library lpm;
use lpm.lpm_components.all;

entity g01_HMS_Counter is
	port ( 
		clock : in std_logic;
		reset : in std_logic;
		sec_clock : in std_logic;
		count_enable : in std_logic;
		load_enable : in std_logic;
		H_Set : in std_logic_vector(4 downto 0);
		M_Set : in std_logic_vector(5 downto 0);
		S_Set : in std_logic_vector(5 downto 0);
		Hours : out std_logic_vector(4 downto 0);
		Minutes : out std_logic_vector(5 downto 0);
		Seconds : out std_logic_vector(5 downto 0);
		end_of_day : out std_logic
	);
end g01_HMS_Counter;


architecture behaviour of g01_HMS_Counter is
	signal int_hours : std_logic_vector(4 downto 0);
	signal int_minutes : std_logic_vector(5 downto 0);
	signal int_seconds : std_logic_vector(5 downto 0);
	signal second_en : std_logic;
	signal minute_en : std_logic;
	signal hour_en : std_logic;
	signal old_sec_clock : std_logic;
begin
	rising : process(clock, sec_clock)
	begin
		if (rising_edge(clock)) then
			old_sec_clock <= sec_clock;
			if (sec_clock = '1' and old_sec_clock = '0') then -- Rising sec_clock edge
				if (int_hours = "10111" AND int_minutes = "111011" AND int_seconds = "111011" AND count_enable = '1') then
					end_of_day <= '1';
				end if;
			end if;
			if (sec_clock = '0' and old_sec_clock = '1') then -- Falling sec_clock edge
				end_of_day <= '0';
				if (minute_en = '0' and int_seconds = "111011" AND count_enable = '1') then
					minute_en <= '1';
				elsif (minute_en = '1') then
					minute_en <= '0';
				end if;
				if (hour_en = '0' and int_seconds = "111011" AND int_minutes = "111011" AND count_enable = '1') then
					hour_en <= '1';
				elsif (hour_en = '1') then
					hour_en <= '0';
				end if;
			end if;
		end if;
		
	end process;
	counter_seconds : lpm_counter
		GENERIC MAP(
			lpm_width => 6,
			lpm_modulus => 60
		)
		PORT MAP(
			aclr => reset,
			clock => clock,
			cnt_en => sec_clock and count_enable,
			data => S_Set,
			sload => load_enable,
			q => int_seconds
		);
		
	counter_minutes : lpm_counter
		GENERIC MAP(
			lpm_width => 6,
			lpm_modulus => 60
		)
		PORT MAP(
			aclr => reset,
			clock => clock,
			cnt_en => minute_en and sec_clock,
			data => M_Set,
			sload => load_enable,
			q => int_minutes
		);
		
	counter_hours : lpm_counter
		GENERIC MAP(
			lpm_width => 5,
			lpm_modulus => 24
		)
		PORT MAP(
			aclr => reset,
			clock => clock,
			cnt_en => hour_en and sec_clock,
			data => H_Set,
			sload => load_enable,
			q => int_hours
		);
	Hours <= int_hours;
	Minutes <= int_minutes;
	Seconds <= int_seconds;

end behaviour;

