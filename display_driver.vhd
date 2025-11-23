-- Ryan Raghani – 301623888; Danny Woo – 301613129; Mitchell Kieper – 301590274;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.elevator_types.all;

-- direction_t is declared in package

entity display_driver is
    port (
        current_floor : in  integer range 0 to 7;
        direction     : in  direction_t;

        HEX0 : out std_logic_vector(6 downto 0);  -- floor digit
        HEX1 : out std_logic_vector(6 downto 0)   -- direction letter
    );
end display_driver;

architecture rtl of display_driver is

    -- 7-Segment Encoding

    -- Digit encodings for 0-7 
    function seg_digit(d : integer) return std_logic_vector is
    begin
        case d is
            when 0 => return "1000000";  -- 0
            when 1 => return "1111001";  -- 1
            when 2 => return "0100100";  -- 2
            when 3 => return "0110000";  -- 3
            when 4 => return "0011001";  -- 4
            when 5 => return "0010010";  -- 5
            when 6 => return "0000010";  -- 6
            when 7 => return "1111000";  -- 7
            when others => return "1111111"; -- blank
        end case;
    end function;

    -- ASCII Letter Encoding
	 
    function seg_letter(dir : direction_t) return std_logic_vector is
    begin
        case dir is
            when DIR_UP => 
                return "1000001";   -- U

            when DIR_DOWN =>
                return "1010000";   -- d

            when DIR_IDLE =>
                return "1111001";    -- i
					 
        end case;
    end function;

begin

    -- FLOOR DISPLAY (HEX0)
    HEX0 <= seg_digit(current_floor);

    -- DIRECTION DISPLAY (HEX1)
    HEX1 <= seg_letter(direction);

end rtl;
