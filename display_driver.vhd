-- Ryan Raghani – 301623888; Danny Woo – 301613129; Mitchell Kieper – 301590274;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity display_driver is
    Port (
        floor_in   : in  STD_LOGIC_VECTOR(2 downto 0);
        state_in   : in  STD_LOGIC_VECTOR(2 downto 0);
        led_dir    : out STD_LOGIC_VECTOR(2 downto 0);
        led_estop  : out STD_LOGIC;
        hex_floor  : out STD_LOGIC_VECTOR(6 downto 0);
        hex_door   : out STD_LOGIC_VECTOR(6 downto 0)
    );
end display_driver;

architecture Behavioral of display_driver is
begin

    -- Process to handle State-dependent LEDs
    process(state_in)
    begin
        -- Default (e.g., IDLE or INIT):
        led_estop <= '0';
        led_dir   <= "000";         -- All direction LEDs off
        hex_door  <= "1000110";     -- Hex 'i' (IDLE/CLOSED)

        case state_in is
            when "010" =>           -- MOVE_UP
                led_dir <= "010"; 
                
            when "011" =>           -- MOVE_DOWN
                led_dir <= "001";   
					 
            when "101" =>           -- DOOR_OPEN
                hex_door <= "1000000"; -- Hex 'U' (OPEN)
                led_dir  <= "100";    

            when "111" =>           -- ESTOP
                led_estop <= '1';   
                hex_door  <= "1000110"; -- Hex 'i' 

            when others =>
                null;
        end case;
    end process;

    -- Process to handle Floor Hex Display
    process(floor_in)
    begin
        case floor_in is
            -- Segment mapping (active low)
            when "000" => hex_floor <= "1111001"; -- 0
            when "001" => hex_floor <= "0100100"; -- 1
            when "010" => hex_floor <= "0110000"; -- 2
            when "011" => hex_floor <= "0011001"; -- 3
            when "100" => hex_floor <= "0010010"; -- 4
            when "101" => hex_floor <= "0000010"; -- 5
            when "110" => hex_floor <= "1111000"; -- 6
            when "111" => hex_floor <= "0000000"; -- 7
            when others => hex_floor <= "1111111"; -- All off
        end case;
    end process;

end Behavioral;