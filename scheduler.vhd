-- Ryan Raghani – 301623888; Danny Woo – 301613129; Mitchell Kieper – 301590274;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.elevator_types.all;


entity scheduler is
    port(
        current_floor : in  integer range 0 to 7;                 -- current floor
        pending       : in  std_logic_vector(7 downto 0);         -- pending requests
        current_dir   : in  direction_t;                          -- UP/DOWN/IDLE
        next_dir      : out direction_t;                          -- output next direction
        target_floor  : out integer range 0 to 7                  -- output target floor
    );
end scheduler;


architecture rtl of scheduler is

    -- Local helper variables
    signal have_above : boolean;
    signal have_below : boolean;
    signal nearest_above : integer range 0 to 7;
    signal nearest_below : integer range 0 to 7;

begin

    process(current_floor, pending, current_dir)

        variable f : integer;
        variable found_above : boolean := false;
        variable found_below : boolean := false;

        variable above_target : integer := current_floor;
        variable below_target : integer := current_floor;

    begin

        -- Scan ABOVE current floor for the nearest request
        for f in current_floor+1 to 7 loop
            if pending(f) = '1' then
                above_target := f;
                found_above := true;
                exit;   -- nearest above found
            end if;
        end loop;

        -- Scan BELOW current floor for nearest request
        for f in current_floor-1 downto 0 loop
            if pending(f) = '1' then
                below_target := f;
                found_below := true;
                exit;   -- nearest below found
            end if;
        end loop;

        -- Save found status into signals
        have_above <= found_above;
        have_below <= found_below;

        nearest_above <= above_target;
        nearest_below <= below_target;

        -- SCHEDULING POLICY
        case current_dir is

            -- Continue UP if requests exist above
            when DIR_UP =>
                if found_above then
                    next_dir     <= DIR_UP;
                    target_floor <= above_target;

                elsif found_below then
                    next_dir     <= DIR_DOWN;
                    target_floor <= below_target;

                else
                    next_dir     <= DIR_IDLE;
                    target_floor <= current_floor;
                end if;

            -- Continue DOWN if requests exist below
            when DIR_DOWN =>
                if found_below then
                    next_dir     <= DIR_DOWN;
                    target_floor <= below_target;

                elsif found_above then
                    next_dir     <= DIR_UP;
                    target_floor <= above_target;

                else
                    next_dir     <= DIR_IDLE;
                    target_floor <= current_floor;
                end if;

            -- IDLE Case
            -- Pick nearest ABOVE then if none, nearest BELOW.
            when DIR_IDLE =>
                if found_above then
                    next_dir     <= DIR_UP;
                    target_floor <= above_target;

                elsif found_below then
                    next_dir     <= DIR_DOWN;
                    target_floor <= below_target;

                else
                    next_dir     <= DIR_IDLE;
                    target_floor <= current_floor;
                end if;

        end case;

    end process;

end rtl;