-- Ryan Raghani – 301623888; Danny Woo – 301613129; Mitchell Kieper – 301590274;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.elevator_types.all;


-- tick_1hz is now a 1 Hz toggle
entity clk_div is
    generic(
        DIVISOR : integer := 50_000_000
    );
    port(
        clk_in   : in  std_logic;
        reset_n  : in  std_logic;
        tick_1hz : out std_logic
    );
end clk_div;

architecture rtl of clk_div is
    signal count     : unsigned(31 downto 0) := (others => '0');
    signal tick_reg  : std_logic := '0';      -- stores current 1 Hz state
begin

    process(clk_in, reset_n)
    begin
        if reset_n = '0' then
            count    <= (others => '0');
            tick_reg <= '0';

        elsif rising_edge(clk_in) then

            -- Only toggle at DIVISOR/2 for 1 Hz 50% duty cycle
            if count = DIVISOR/2 - 1 then
                tick_reg <= not tick_reg;
                count    <= (others => '0');

            else
                count <= count + 1;
            end if;

        end if;
    end process;

    tick_1hz <= tick_reg;   -- continuous square wave

end rtl;
