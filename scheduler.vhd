-- Ryan Raghani – 301623888; Danny Woo – 301613129; Mitchell Kieper – 301590274;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity scheduler is
    port(
        current_floor : in  integer range 0 to 7;                 -- current floor
        pending       : in  std_logic_vector(7 downto 0);         -- pending requests
        current_dir   : in  direction_t;                          -- UP/DOWN/IDLE
        next_dir      : out direction_t;                          -- output next direction
        target_floor  : out integer range 0 to 7                  -- output target floor
    );
end scheduler;