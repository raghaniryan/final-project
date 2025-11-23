-- Ryan Raghani – 301623888; Danny Woo – 301613129; Mitchell Kieper – 301590274;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity req_latch is
    port(
        clk        : in  std_logic;                      -- 50 MHz clock
        reset_soft : in  std_logic;                      -- clears pending requests only
        reset_hard : in  std_logic;                      -- clears everything
        key0       : in  std_logic;                      -- active-low confirm button
        floor_bin  : in  std_logic_vector(2 downto 0);   -- from SW2 to SW0
        clear_floor: in  std_logic_vector(7 downto 0);    -- from FSM when serving a floor
        pending    : out std_logic_vector(7 downto 0)     -- latched requests
    );
end req_latch;
