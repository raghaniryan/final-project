-- Ryan Raghani – 301623888; Danny Woo – 301613129; Mitchell Kieper – 301590274;

library ieee;
use ieee.std_logic_1164.all;

package elevator_types is

    -- Global direction type shared by all modules. had to make this because direction_t wasnt declared
	 -- and it is hard to declare it elsewhere without making a package.
    -- Visible everywhere using:  use work.elevator_types.all;
    type direction_t is (DIR_UP, DIR_DOWN, DIR_IDLE);

end package elevator_types;
