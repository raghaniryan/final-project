-- Ryan Raghani – 301623888; Danny Woo – 301613129; Mitchell Kieper – 301590274

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clk_div_tb is
end clk_div_tb;

architecture Behavioral of clk_div_tb is

    -- Component Declaration for the Unit Under Test (UUT)
    component clk_div
        Port (
            clk_in   : in  STD_LOGIC;
            reset_n  : in  STD_LOGIC;
            tick_1hz : out STD_LOGIC
        );
    end component;

    -- Signal Declarations for UUT Ports
    signal clk_in_tb   : STD_LOGIC := '0';
    signal reset_n_tb  : STD_LOGIC := '0';
    signal tick_1hz_out : STD_LOGIC;

    -- Clock Period and Count Constants
    constant CLK_PERIOD : time := 20 ns;      -- 50 MHz clock period
    constant EXPECTED_TICK_TIME : time := 1000 ms; -- 1 second interval
    
begin

    -- Instantiate the Unit Under Test (UUT)
    uut: clk_div
    Port map (
        clk_in   => clk_in_tb,
        reset_n  => reset_n_tb,
        tick_1hz => tick_1hz_out
    );

    -- 1. CLOCK GENERATION (50 MHz)
    clk_gen: process
    begin
        loop
            clk_in_tb <= '0';
            wait for CLK_PERIOD/2;
            clk_in_tb <= '1';
            wait for CLK_PERIOD/2;
        end loop;
    end process;
    
    -- 2. STIMULUS AND VERIFICATION
    stimulus: process
    begin
        
        -- Apply Hard Reset
        reset_n_tb <= '0';
        wait for 4 * CLK_PERIOD;
        reset_n_tb <= '1';
        
        -- Loop to observe 5 complete 1-second ticks on the waveform
        for i in 1 to 5 loop
            
            -- Wait for the tick pulse to go high
            wait until tick_1hz_out = '1';

            -- Wait one full clock cycle, which is the duration of the pulse
            wait for CLK_PERIOD;
            
            -- Wait for the remaining time until the next pulse is due
            wait for EXPECTED_TICK_TIME - CLK_PERIOD;
            
        end loop;
        
        wait; -- End the simulation

    end process;

end Behavioral;