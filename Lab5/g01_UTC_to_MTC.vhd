-- entity name: g01_UTC_to_MTC
--
-- Calculates an approximated time on Mars for a given date and time on Earth (UTC)
--
-- Copyright (C) 2014 Alex Carruthers, Dan Grencorn 
-- Version 1.0
-- Author: Alex Carruthers, Dan Greencorn; michael.carruthers@mail.mcgill.ca, dan.greencorn@mail.mcgill.ca 
-- Date: March 27, 2014


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library lpm;
use lpm.lpm_components.all;

entity g01_UTC_to_MTC is
	port (
		clock : in std_logic;
		sec_clock : in std_logic;
		reset : in std_logic;
		enable : in std_logic;
		
		year : in std_logic_vector(11 downto 0);
		month : in std_logic_vector(3 downto 0);
		day : in std_logic_vector(4 downto 0);
		hour : in std_logic_vector(4 downto 0);
		minute : in std_logic_vector(5 downto 0);
		second : in std_logic_vector(5 downto 0);

		finished : out std_logic;
		
		MHour : out std_logic_vector(4 downto 0);
		MMinute : out std_logic_vector(5 downto 0);
		MSecond : out std_logic_vector(5 downto 0)
	);
		
end g01_UTC_to_MTC;


architecture behaviour of g01_UTC_to_MTC is
	function to_dayfrac ( seconds : unsigned((16) downto 0) ) return std_logic_vector is
		variable adder1 : unsigned(19 downto 0);
		variable adder2 : unsigned(23 downto 0);
		variable adder3 : unsigned(26 downto 0);
		variable adder4 : unsigned(27 downto 0);
		variable adder5 : unsigned(28 downto 0);
		variable adder6 : unsigned(30 downto 0);
		variable adder7 : unsigned(34 downto 0);
		variable adder8 : unsigned(39 downto 0);
		variable day_fraction : unsigned(39 downto 0);
		
		begin
			adder1 := seconds + ('0' & seconds & "00");
			adder2 := adder1 + ('0' & seconds & "000000");
			adder3 := adder2 + ('0' & seconds & "000000000");
			adder4 := adder3 + ('0' & seconds & "0000000000");
			adder5 := adder4 + ('0' & seconds & "00000000000");
			adder6 := adder5 + ('0' & seconds & "0000000000000");
			adder7 := adder6 + ('0' & seconds & "00000000000000000");
			adder8 := adder7 + ('0' & seconds & "0000000000000000000000");
			day_fraction := adder8 + (seconds & "00000000000000000000000");
			return std_logic_vector(day_fraction);
	end to_dayfrac;

	-- components
	-- 	lpm_counter
	component g01_HMS_Counter
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
	
	-- signals
	signal done : std_logic := '0';
	--signal sec_clock : std_logic;
	signal EOD_Signal : std_logic;
	
	signal years_int : std_logic_vector (11 downto 0);
	signal months_int : std_logic_vector (3 downto 0);
	signal days_int : std_logic_vector (4 downto 0);
	signal hours_int : std_logic_vector (4 downto 0);
	signal minutes_int : std_logic_vector (5 downto 0);
	signal seconds_int : std_logic_vector (5 downto 0);
	
	signal JD_seconds : std_logic_vector (16 downto 0);
	signal JD_days : std_logic_vector (19 downto 0);	
begin
	
	-- determines when we are done counting
	done_count : process (years_int,months_int,days_int,hours_int,minutes_int,seconds_int, clock)
		
	begin
		if (clock'event and clock = '1') then
			if (year = years_int AND month = months_int AND day = days_int AND hour = hours_int AND minute = minutes_int AND second = seconds_int) then
				done <= '1';
			else
				done <= '0';
				-- set 00:00:00 to H:M:S output
			end if;
		end if;
		finished <= done;
	end process;
	
	calculate : process (done)
		variable pt97324_shifted_32 : std_logic_vector(31 downto 0) := 	"11111001001001101000100111001010";
		variable pt00072_shifted_42 : std_logic_vector(31 downto 0) := 	"10111100101111100110000111001111";
		variable JD_b4_mult : std_logic_vector(43 downto 0);
		variable pt97multJD : std_logic_vector(63 downto 0);
		variable afterSub : std_logic_vector(63 downto 0);
		variable fractionalPart : std_logic_vector(31 downto 0);
		variable MTC : std_logic_vector(31 downto 0);
		variable JD_2000 : std_logic_vector (31 downto 0);

	begin
		if (done'event AND done = '1') then
			-- assign new computed MTC H:M:S to output
			
			JD_2000(31 downto 12) := JD_days;
			JD_2000(11 downto 0):= to_dayfrac(unsigned(JD_seconds))(39 downto 28);
			-- JD_b4_mult := JD_2000 & "000000000000";
			-- JD_2000 is shifted 12 bits
			-- pt97324_shifted_32 is shifted 32 bits
			pt97multJD := std_logic_vector((unsigned(JD_2000) * unsigned(pt97324_shifted_32))); -- shifted 44 bits
			
			-- subtract
			afterSub := std_logic_vector((unsigned(pt97multJD) - (unsigned(pt00072_shifted_42 & "00")))); -- shifted 44 bits
			
			-- take the fractional part (keeping 32 bits of fractional)
			fractionalPart := afterSub(43 downto 12);
			-- get MTC (shifted 32 bits; need 6 bits to represent up to 60 [mins/seconds])
			MTC := std_logic_vector(24 * unsigned(fractionalPart))(36 downto 5);
			
			-- set hours
			MHour <= MTC(31 downto 27);
			
			-- set minutes
			MTC := MTC(26 downto 0) & "00000";
			MTC := std_logic_vector(unsigned(MTC) * 60)(37 downto 6);
			MMinute <= MTC(31 downto 26);
			
			-- set seconds
			MTC := MTC(25 downto 0) & "000000";
			MTC := std_logic_vector(unsigned(MTC) * 60)(37 downto 6);
			MSecond <= MTC(31 downto 26);
--		else
--			MHour <= "00000";
--			MMinute <= "000000";
--			MSecond <= "000000";
		end if;
	end process;
	
	-- HMS Counter
	HMS_count : g01_HMS_Counter
		port map (
			clock => clock,
			reset => '0',
			sec_clock => sec_clock,
			count_enable => (enable AND NOT done),
			load_enable => reset,
			H_Set => "01100",
			M_Set => "000000",
			S_Set => "000000",
			Hours => hours_int,
			Minutes => minutes_int,
			Seconds => seconds_int,
			end_of_day => EOD_Signal
		);
	-- YMD_Counter
	YMD_Count : g01_YMD_Counter
		port map(
			clock => clock,
			reset => '0',
			day_count_en => (EOD_Signal AND NOT done),
			load_en => reset,
			Y_Set => "011111010000",
			M_Set => "0001",
			D_Set => "00110",
			Years => years_int,
			Months => months_int,
			Days => days_int
		);
		
	-- seconds count
	sec_count : lpm_counter
		generic map (
			LPM_MODULUS => 86400,
			LPM_WIDTH => 17
		)
		port map (
			clock => clock,
			cnt_en => sec_clock and not done,
			aclr => reset,
			q => JD_seconds
		);
	-- days count
	day_count : lpm_counter
		generic map (
			LPM_WIDTH => 20
		)
		port map (
			clock => clock,
			cnt_en =>EOD_Signal,
			aclr => reset,
			q => JD_days
		);
end behaviour;

