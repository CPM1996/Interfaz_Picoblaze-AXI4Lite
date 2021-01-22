library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_baud_gen is
generic (
	BAUD_RATE: NATURAL :=57_600;
	CLOCK_RATE: NATURAL:= 50_000_000
);
port(
	clk: in STD_LOGIC;
	rst: in STD_LOGIC;
	baud_x16_en: out STD_LOGIC
);
end;

architecture behavioral of uart_baud_gen is

constant OVERSAMPLE_RATE: NATURAL := BAUD_RATE * 16;
constant DIVIDER: NATURAL := CLOCK_RATE / OVERSAMPLE_RATE + 1;
constant OVERSAMPLE_VALUE: NATURAL:=DIVIDER-1;
--OVERSAMPLE_VALUE = DIVIDER - 1 = 54;
--CNT_WID = clogb2(DIVIDER) = 6;

--constant DIVIDER: NATURAL:=55;

signal internal_count: NATURAL range 0 to DIVIDER;
signal internal_count_m_1: NATURAL range 0 to DIVIDER;
signal baud_x16_en_reg: STD_LOGIC;

begin

internal_count_m_1 <= internal_count-1 when internal_count>0 else OVERSAMPLE_VALUE;

process(clk)
begin
if rising_edge(clk) then
	if(rst='1') then
		internal_count<=OVERSAMPLE_VALUE;
		baud_x16_en_reg<='0';
	else
		if internal_count_m_1 = 0 then baud_x16_en_reg<='1'; 
		else baud_x16_en_reg<='0'; 
		end if;
			
		if internal_count = 0 then internal_count<=OVERSAMPLE_VALUE;
		else internal_count<=internal_count_m_1; end if;
	end if;
end if;
end process;

baud_x16_en<=baud_x16_en_reg;

end;