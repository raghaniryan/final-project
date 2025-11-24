-- Ryan Raghani – 301623888; Danny Woo – 301613129; Mitchell Kieper – 301590274;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.elevator_types.all;

entity controller_fsm is
    port(
        clk          : in  std_logic;
        tick_1hz     : in  std_logic;

        reset_hard   : in  std_logic;
        reset_soft   : in  std_logic;

        estop_btn    : in  std_logic;

        pending       : in  std_logic_vector(7 downto 0);
        clear_floor   : out std_logic_vector(7 downto 0);

        sched_dir     : in direction_t;
        sched_floor   : in integer range 0 to 7;

        current_floor : out integer range 0 to 7;
        direction     : out direction_t;
        door_open_led : out std_logic
    );
end controller_fsm;


architecture rtl of controller_fsm is

    -- State Encodings
    type state_t is (
        INIT,
        IDLE,
        SCHEDULE,
        MOVE_UP,
        MOVE_DOWN,
        ARRIVE,
        DOOR_OPEN,
        DOOR_CLOSE,
        ESTOP
    );

    signal state, next_state : state_t;

    -- Internal Registers
    signal floor_reg    : integer range 0 to 7 := 0;
    signal dir_reg      : direction_t := DIR_IDLE;

    signal travel_timer : integer range 0 to 2 := 0;
    signal door_timer   : integer range 0 to 3 := 0;

    -- ESTOP TOGGLE LOGIC
    signal estop_prev  : std_logic := '1';
    signal estop_edge  : std_logic := '0';
    signal estop_active : std_logic := '0';

begin

    current_floor <= floor_reg;
    direction     <= dir_reg;


    -- ESTOP Edge Detect
    process(clk)
    begin
        if rising_edge(clk) then
            estop_edge <= '0';

            if estop_prev = '1' and estop_btn = '0' then
                estop_edge <= '1';   -- falling edge toggle
            end if;

            estop_prev <= estop_btn;
        end if;
    end process;



    -- Next state logic which is all combinational 
    process(state, pending, sched_floor, sched_dir, door_timer, floor_reg)
    begin
        next_state <= state;   -- default

        case state is

            when INIT =>
                next_state <= IDLE;

            when IDLE =>
                if pending /= "00000000" then
                    next_state <= SCHEDULE;
                else
                    next_state <= IDLE;
                end if;

            when SCHEDULE =>
                case sched_dir is
                    when DIR_UP   => next_state <= MOVE_UP;
                    when DIR_DOWN => next_state <= MOVE_DOWN;
                    when others   => next_state <= IDLE;
                end case;

            when MOVE_UP =>
                if floor_reg = sched_floor then
                    next_state <= ARRIVE;
                else
                    next_state <= MOVE_UP;
                end if;

            when MOVE_DOWN =>
                if floor_reg = sched_floor then
                    next_state <= ARRIVE;
                else
                    next_state <= MOVE_DOWN;
                end if;

            when ARRIVE =>
                next_state <= DOOR_OPEN;

            when DOOR_OPEN =>
                if door_timer = 3 then
                    next_state <= DOOR_CLOSE;
                else
                    next_state <= DOOR_OPEN;
                end if;

            when DOOR_CLOSE =>
                next_state <= IDLE;

            when ESTOP =>
                next_state <= ESTOP;

        end case;
    end process;



    -- Sequencial process
    process(clk)
    begin
        if rising_edge(clk) then

            clear_floor   <= (others => '0');
            door_open_led <= '0';

            -- toggle ESTOP
            if estop_edge = '1' then
                estop_active <= not estop_active;
            end if;


            -- Hard reset
            if reset_hard = '1' then
                state        <= INIT;
                floor_reg    <= 0;
                dir_reg      <= DIR_IDLE;
                travel_timer <= 0;
                door_timer   <= 0;
                estop_active <= '0';


            -- ESTOP 
            elsif estop_active = '1' then
                state        <= ESTOP;
                travel_timer <= 0;
                door_timer   <= 0;


            -- Normal operation
            else

                -- Update state first
                state <= next_state;

                -- Travel timer 
                if tick_1hz = '1' then

                    case next_state is
                        when MOVE_UP =>
                            travel_timer <= travel_timer + 1;
                            if travel_timer = 2 then
                                travel_timer <= 0;
                                floor_reg <= floor_reg + 1;
                            end if;

                        when MOVE_DOWN =>
                            travel_timer <= travel_timer + 1;
                            if travel_timer = 2 then
                                travel_timer <= 0;
                                floor_reg <= floor_reg - 1;
                            end if;

                        when others =>
                            travel_timer <= 0;
                    end case;


                    -- Door timer
                    case next_state is
                        when DOOR_OPEN =>
                            door_timer <= door_timer + 1;
                        when IDLE | DOOR_CLOSE =>
                            door_timer <= 0;
                        when others =>
                            null;
                    end case;

                end if;


                -- Clear floor when arrives
                if next_state = ARRIVE then
                    clear_floor(floor_reg) <= '1';
                end if;


                -- Door LED
                if next_state = DOOR_OPEN then
                    door_open_led <= '1';
                end if;


                -- Direction logic
                case next_state is
                    when SCHEDULE =>
                        dir_reg <= sched_dir;

                    when MOVE_UP =>
                        dir_reg <= DIR_UP;

                    when MOVE_DOWN =>
                        dir_reg <= DIR_DOWN;

                    when others =>
                        dir_reg <= DIR_IDLE;
                end case;

            end if;
        end if;
    end process;

end rtl;