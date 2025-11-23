-- Ryan Raghani – 301623888; Danny Woo – 301613129; Mitchell Kieper – 301590274;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.elevator_types.all;


entity clk_div is
    generic(
        DIVISOR : integer := 50_000_000   -- 50 MHz turned into 1 Hz
    );
    port(
        clk_in   : in  std_logic;         -- 50 MHz system clock
        reset_n  : in  std_logic;         -- active-low reset
        tick_1hz : out std_logic          -- 1 cycle pulse every second
    );
end clk_div;

architecture rtl of clk_div is
    signal count : unsigned(31 downto 0) := (others => '0');
begin

    process(clk_in, reset_n)
    begin
        if reset_n = '0' then
            count    <= (others => '0');
            tick_1hz <= '0';

        elsif rising_edge(clk_in) then

            if count = DIVISOR - 1 then
                count    <= (others => '0');
                tick_1hz <= '1';          -- pulse for one cycle

            else
                count    <= count + 1;
                tick_1hz <= '0';          -- low all other cycles
            end if;

        end if;
    end process;

end rtl;
