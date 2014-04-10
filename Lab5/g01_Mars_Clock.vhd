-- entity name: g01_Mars_Clock_system
--
-- Circuit to test the g01_YMD_Counter's functionality on the board
--
-- Copyright (C) 2014 Alex Carruthers, Dan Grencorn 
-- Version 1.0
-- Author: Alex Carruthers, Dan Greencorn; michael.carruthers@mail.mcgill.ca, dan.greencorn@mail.mcgill.ca 
-- Date: April 9, 2014


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity g01_Mars_Clock_System is
	port ( clock : in std_logic;
		set : in std_logic;
		mode : in std_logic_vector(2 downto 0);
		data : in std_logic_vector(5 downto 0);
		buttons : in std_logic_vector(3 downto 0);
		ledsRed : out std_logic_vector(9 downto 0);
		ledsGreen : out std_logic_vector(7 downto 0);
		lcd0 : out std_logic_vector(6 downto 0);
		lcd1 : out std_logic_vector(6 downto 0);
		lcd2 : out std_logic_vector(6 downto 0);
		lcd3 : out std_logic_vector(6 downto 0)
	);
end g01_Mars_Clock_System;


architecture behaviour of g01_Mars_Clock_System is
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

	component g01_HMS_Counter is
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

	component g01_UTC_to_MTC is
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
	end component;
	
	component g01_to_local is
		PORT (
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
	end component;

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
	
	-- internal state
	signal state : std_logic_vector(1 downto 0) := "00";
	
	signal reset : std_logic;
	-- Earth second and day pulse signals
	signal E_pulse_sec : std_logic;
	signal E_pulse_day : std_logic;
	signal E_load : std_logic := '0';
	signal E_load_ymd : std_logic := '0';

	-- Earth timezone
	signal E_timezone : std_logic_vector(4 downto 0) := "00111";
	signal E_DST : std_logic := '0';

	-- Earth hours, minutes, seconds, year, month, day (UTC)
	signal E_Hour : std_logic_vector(4 downto 0);
	signal E_Minute : std_logic_vector(5 downto 0);
	signal E_Second : std_logic_vector(5 downto 0);
	signal E_Day : std_logic_vector(4 downto 0);
	signal E_Month : std_logic_vector(3 downto 0);
	signal E_Year : std_logic_vector(11 downto 0);

	-- Earth hours, minutes, seconds, year, month, day (timezone corrected)
	signal E_Hour_tz : std_logic_vector(4 downto 0);
	signal E_Minute_tz : std_logic_vector(5 downto 0);
	signal E_Second_tz : std_logic_vector(5 downto 0);
	signal E_Day_tz : std_logic_vector(4 downto 0);
	signal E_Month_tz : std_logic_vector(3 downto 0);
	signal E_Year_tz : std_logic_vector(11 downto 0);

	-- Earth values to load (UTC)
	signal E_Hour_set : std_logic_vector(4 downto 0) := "01100";
	signal E_Minute_set : std_logic_vector(5 downto 0) := "000000";
	signal E_Second_set : std_logic_vector(5 downto 0) := "000000";
	signal E_Day_set : std_logic_vector(4 downto 0) := "00110";
	signal E_Month_set : std_logic_vector(3 downto 0) := "0001";
	signal E_Year_set : std_logic_vector(11 downto 0) := "011111010000";	

	-- Mars second pulse
	signal M_pulse_sec : std_logic;
	signal M_load : std_logic := '0';
	
	-- Mars timezone
	signal M_timezone : std_logic_vector(4 downto 0) := "00011";

	-- Mars Hour, minute, second (MTC)
	signal M_Hour : std_logic_vector(4 downto 0);
	signal M_Minute : std_logic_vector(5 downto 0);
	signal M_Second : std_logic_vector(5 downto 0);

	-- Mars Hour, minute, second (timezone corrected)
	signal M_Hour_tz : std_logic_vector(4 downto 0);
	signal M_Minute_tz : std_logic_vector(5 downto 0);
	signal M_Second_tz : std_logic_vector(5 downto 0);
	
	signal M_Hour_set : std_logic_vector(4 downto 0);
	signal M_Minute_set : std_logic_vector(5 downto 0);
	signal M_Second_set : std_logic_vector(5 downto 0);



	-- signals for converting UTC to MTC
	signal convert_done : std_logic;
	signal convert_en : std_logic;
	signal convert_clr : std_logic;

	-- BCD output and ripple blanks for LCD Display
	signal bcd_out : std_logic_vector(15 downto 0);
	signal lcd1_rb : std_logic;
	signal lcd2_rb : std_logic;
begin
	
	reset <= NOT buttons(0);
	ledsRed(9) <= reset;
	-- The state managing process
	stateProcess : process (buttons(3), state)
	begin
		if (buttons(3) = '0' AND buttons(3)'event) then
			if (state = "00") then
				state <= "01";
				ledsGreen(3 downto 0) <= "1100";
			elsif (state = "01") then
				state <= "10";
				ledsGreen(3 downto 0) <= "1110";
			elsif (state = "10") then
				state <= "11";
				ledsGreen(3 downto 0) <= "1111";
			else
				state <= "00";
				ledsGreen(3 downto 0) <= "1000";
			end if;
		end if;
	end process;

	-- deals with displaying data to the display, given the mode and state
	modeProcess : process (mode, state, buttons(3), M_Hour_tz, M_Minute_tz, M_Second_tz, M_timezone, E_Hour_tz, E_Minute_tz, E_Second_tz, E_timezone, E_Year_tz, E_Month_tz, E_Day_tz)
	variable bcd_in : std_logic_vector(11 downto 0) := "000000000000";
	begin
		if (mode = "000") then
			-- Mars Time
			if (state = "00") then
				bcd_in := "0000000" & M_Hour_tz;
			elsif (state = "01") then
				bcd_in := "000000" & M_Minute_tz;
			elsif (state = "10") then
				bcd_in := "000000" & M_Second_tz;
			elsif (state = "11") then
				bcd_in := "0000000" & M_timezone;
			end if;
		elsif (mode = "001") then
			-- Earth Time
			if (state = "00") then
				bcd_in := "0000000" & E_Hour_tz;
			elsif (state = "01") then
				bcd_in := "000000" & E_Minute_tz;
			elsif (state = "10") then
				bcd_in := "000000" & E_Second_tz;
			elsif (state = "11") then
				bcd_in := "0000000" & E_timezone;
			end if;
		elsif (mode = "010") then
			-- Earth Date
			if (state = "00") then
				bcd_in := E_Year_tz;
			elsif (state = "01") then
				bcd_in := "00000000" & E_Month_tz;
			elsif (state = "10") then
				bcd_in := "0000000" & E_Day_tz;
			elsif (state = "11") then
				bcd_in := "0000000" & E_timezone;
			end if;
		elsif (mode = "011") then
			-- Set Timezones
			
			if (state = "00") then
				bcd_in := "0000000" & E_timezone;
			elsif (state = "01") then
				bcd_in := "0000000" & M_timezone;
			else
				-- show '3333' when invalid state for timezones
				bcd_in := "110100000101";
			end if;
		elsif (mode = "100") then
			-- Set Time
			if (state = "00") then
				bcd_in := "0000000" & E_Hour_tz;
			elsif (state = "01") then
				bcd_in := "000000" & E_Minute_tz;
			elsif (state = "10") then
				bcd_in := "000000" & E_Second_tz;
			else
				-- show '3333' when invalid state for set time
				bcd_in := "110100000101";
			end if;
		elsif (mode = "101") then
			-- Set Date
			if (state = "00") then
				bcd_in := E_Year_set;
			elsif (state = "01") then
				bcd_in := E_Year_set;
			elsif (state = "10") then
				bcd_in := "00000000" & E_Month_set;
			elsif (state = "11") then
				bcd_in := "0000000" & E_Day_set;
			end if;
		else
			-- show '3333' when invalid Mode (dip switch setting)
			bcd_in := "110100000101";
		end if;
		
		bcd_out <= to_bcd(bcd_in);
	end process;
	
	-- Can set Dates, timezones, and times on earth.
	-- epulse and mpulse stop when in a mode to set values
	dataProcess : process (clock, mode, state, data)
	begin
		
		if (mode = "000") then
			-- Mars Time
			-- view only
		elsif (mode = "001") then
			-- Earth Time
			-- view only
		elsif (mode = "010") then
			-- Earth Date
			-- view only
		elsif (mode = "011") then
			-- Set TZ
			if (state = "00") then
				E_timezone <= data(4 downto 0);
			elsif (state = "01") then
				M_timezone <= data (4 downto 0);
			end if;
		end if;
		-- special cases where load signals go high
		if (mode = "100") then
			-- stop the counters, and load the values into the HMS counter
			-- we must set hours, minutes and seconds
			E_load <= '1';
			-- Set Time
			if (state = "00") then
				E_Hour_set <= data(4 downto 0);
			elsif (state = "01") then
				E_Minute_set <= data(5 downto 0);
			elsif (state = "10") then
				E_Second_set <= data(5 downto 0);
			end if;
		else
			-- continue counting after the data has been loaded
			E_load <= '0';
		end if;
		if (mode = "101") then
			E_load_ymd <= '1';
			-- Set Date
			if (state = "00") then
				E_Year_set(11 downto 6) <= data (5 downto 0);
			elsif (state = "01") then
				E_Year_set(5 downto 0) <= data (5 downto 0);
			elsif (state = "10") then
				E_Month_set <= data (3 downto 0);
			elsif (state = "11") then
				E_Day_set <= data (4 downto 0);
			end if;
		else
			E_load_ymd <= '0';
		end if;
	end process;

	-- WORKING HERE
	-- Trying to trigger Sync circuit and control logic
	-- M_HMS is no longer working properly
	syncProcess : process (buttons(2), convert_done, clock)
	begin
		if (clock'event AND clock = '1') then
			if (buttons(2) = '0') then
				convert_clr <= '1';
			elsif (buttons(2) = '1' AND convert_clr = '1') then
				convert_clr <= '0';
				convert_en <= '1';
			end if;
		
			if (convert_done = '1') then
				M_load <= '1';
			end if;
		
			if (M_load = '1') then
				M_load <= '0';
				convert_en <= '0';
			end if;
		end if;
	end process;
	-- The Earth_Mars second Pulse Timer
	timer : g01_Earth_Mars_timer
		PORT MAP ( 
			clk => clock, 
			reset => reset, 
			enable => NOT (E_load OR E_load_ymd OR M_load OR convert_en), 
			epulse => E_pulse_sec,
			mpulse => M_pulse_sec
		);
	
	-- Earth Counters
	E_YMD : g01_YMD_Counter
		PORT MAP ( clock => clock,
			reset => reset,
			day_count_en => E_pulse_day, 
			load_en => E_load_ymd, 
			Y_Set => E_Year_set,
			M_Set => E_Month_set,
			D_Set => E_Day_set,
			Years => E_Year,
			Months => E_Month,
			Days => E_Day
		);
	E_HMS : g01_HMS_Counter
		PORT MAP (
			clock => clock,
			reset => reset,
			sec_clock => E_pulse_sec,
			count_enable => '1',
			load_enable => E_load,
			H_Set => E_Hour_set,
			M_Set => E_Minute_set,
			S_Set => E_Second_set,
			Hours => E_Hour,
			Minutes => E_Minute,
			Seconds => E_Second,
			end_of_day => E_pulse_day
		);

	-- Mars Counter and Converter
	M_HMS : g01_HMS_Counter
		PORT MAP (
			clock => clock,
			reset => reset,
			sec_clock => M_pulse_sec,
			count_enable => '1',
			load_enable => M_load,
			H_Set => M_Hour_set,
			M_Set => M_Minute_set,
			S_Set => M_Second_set,
			Hours => M_Hour,
			Minutes => M_Minute,
			Seconds => M_Second
		);
	M_Convert : g01_UTC_to_MTC
		PORT MAP (
			clock => clock,
			sec_clock => clock,
			reset => reset OR convert_clr,
			enable => convert_en,
			year => E_Year,
			month => E_Month,
			day => E_Day,
			hour => E_Hour,
			minute => E_Minute,
			second => E_Second,

			finished => convert_done,
			
			MHour => M_Hour_set,
			MMinute => M_Minute_set,
			MSecond => M_Second_set
		);

	-- Timezone Converters
	E_Timezone_Converter : g01_to_local
		PORT MAP (
			Year_in => E_year,
			Month_in => E_month,
			Day_in => E_day,
			Hour_in => E_hour,
			Minute_in => E_minute,
			Second_in => E_second,
			
			DST => E_DST,
			Time_Zone => E_timezone,
			
			Year_out => E_year_tz,
			Month_out => E_month_tz,
			Day_out => E_day_tz,
			Hour_out => E_hour_tz,
			Minute_out => E_minute_tz,
			Second_out => E_second_tz
		);
	M_Timezone_Converter : g01_to_local
		PORT MAP (
			Year_in => "000000000100",
			Month_in => "0100",
			Day_in => "00100",
			Hour_in => M_hour,
			Minute_in => M_minute,
			Second_in => M_second,
			
			DST => '0',
			Time_Zone => M_timezone,
			
			Hour_out => M_hour_tz,
			Minute_out => M_minute_tz,
			Second_out => M_second_tz
		);

	-- LCD Decoders, for displaying values --
	lcd0_decoder : g01_7_segment_decoder
		PORT MAP (
			code => bcd_out(3 downto 0), 
			RippleBlank_In => '0', 
			segments => lcd0
		);
	lcd1_decoder : g01_7_segment_decoder
		PORT MAP (
			code => bcd_out(7 downto 4), 
			RippleBlank_In => lcd1_rb, 
			segments => lcd1
		);
	lcd2_decoder : g01_7_segment_decoder
		PORT MAP (
			code => bcd_out(11 downto 8), 
			RippleBlank_In => lcd2_rb, 
			RippleBlank_Out => lcd1_rb, 
			segments => lcd2
		);
	lcd3_decoder : g01_7_segment_decoder
		PORT MAP (
			code => bcd_out(15 downto 12), 
			RippleBlank_In => '1', 
			RippleBlank_Out => lcd2_rb, 
			segments => lcd3
		);
end behaviour;

