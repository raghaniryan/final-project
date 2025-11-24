-- Ryan Raghani – 301623888; Danny Woo – 301613129; Mitchell Kieper – 301590274;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clk_div is
    Port (
        clk_in  : in  STD_LOGIC;     -- 50 MHz Clock Input
        reset_n : in  STD_LOGIC;     -- Active Low Reset
        tick_1hz : out STD_LOGIC     -- 1 Hz Single-Cycle Pulse Output
    );
end clk_div;

architecture Behavioral of clk_div is

    constant MAX_COUNT : integer := 49999999;
    
    signal clk_counter : integer range 0 to MAX_COUNT := 0;
    signal tick_pulse  : std_logic := '0';

begin

    process(clk_in, reset_n)
    begin
        -- Hard Reset (Active Low)
        if reset_n = '0' then
            clk_counter <= 0;
            tick_pulse <= '0';
        
        elsif rising_edge(clk_in) then
            
            -- Default pulse low
            tick_pulse <= '0'; 
            
            if clk_counter = MAX_COUNT then
                -- Reset counter and generate a single-cycle pulse
                clk_counter <= 0;
                tick_pulse <= '1';
            else
                -- Increment counter every clock cycle
                clk_counter <= clk_counter + 1;
            end if;
            
        end if;
    end process;

    -- Output the 1 Hz single-cycle pulse
    tick_1hz <= tick_pulse;

end Behavioral;