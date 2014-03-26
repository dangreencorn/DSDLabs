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

entity g01_UTC_to_MTC is
	
end g01_UTC_to_MTC;


architecture behaviour of g01_UTC_to_MTC is
	-- components
	-- 	lpm_counter
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
	component g01_YMD_Counter is
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
	entity g01_Seconds_to_Days is
		port ( 	seconds			: in unsigned(16 downto 0);
				day_fraction 	: out unsigned(39 downto 0));
	end g01_Seconds_to_Days;
	
	-- signals
	signal done : std_logic := 0;
begin
	
	-- determines when we are done counting
	process : done (Y,M,D,H,M,S)
	begin
		if (year = Y AND month = M AND day = D AND hour = H AND minute = M AND second = S) then
			done <= '1';

			-- assign new computed MTC H:M:S to output

		else;
			done <= '0';

			-- set 00:00:00 to H:M:S output
			
		end if;
	end process;

end behaviour;

