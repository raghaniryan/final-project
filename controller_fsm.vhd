-- Ryan Raghani – 301623888; Danny Woo – 301613129; Mitchell Kieper – 301590274;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.elevator_types.all;

entity controller_fsm is
    port (
        clk         : in  std_logic;           -- 50 MHz
        tick_1hz    : in  std_logic;           -- 1-second pulse

        -- Reset signals
        reset_hard  : in  std_logic;           -- KEY3 active-high
        reset_soft  : in  std_logic;           -- KEY2 active-high

        -- ESTOP toggle button (KEY1)
        estop_btn   : in  std_logic;           -- active-low physical input

        -- Data from req_latch
        pending      : in  std_logic_vector(7 downto 0);

        -- Outputs TO req_latch
        clear_floor  : out std_logic_vector(7 downto 0);

        -- Inputs from scheduler
        sched_dir    : in  direction_t;
        sched_floor  : in  integer range 0 to 7;

        -- Internal tracking
        current_floor : out integer range 0 to 7;
        direction     : out direction_t;

        -- Door indicator
        door_open_led : out std_logic
    );
end controller_fsm;

architecture rtl of controller_fsm is

    -- FSM States
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
    signal floor_reg      : integer range 0 to 7 := 0;
    signal dir_reg        : direction_t := DIR_IDLE;

    signal travel_timer   : integer range 0 to 2 := 0;   -- 2-second travel
    signal door_timer     : integer range 0 to 3 := 0;   -- 3-second door open

    -- ESTOP toggle logic
    signal estop_prev     : std_logic := '1';  -- track KEY1 previous
    signal estop_edge     : std_logic := '0';
    signal estop_active   : std_logic := '0';  -- latched toggle flip-flop

begin

    -- Output wiring
    current_floor <= floor_reg;
    direction     <= dir_reg;

    -- ESTOP Toggle Detection
    process(clk)
begin
    if rising_edge(clk) then

        estop_edge <= '0';

        if estop_prev = '1' and estop_btn = '0' then
            estop_edge <= '1';   -- falling edge detected
        end if;

        estop_prev <= estop_btn;

    end if;
end process;


    -- Next state combinational logic 
    process(state, pending, sched_dir, sched_floor, door_timer, floor_reg)
    begin
        next_state <= state;

        case state is

            when INIT =>
                next_state <= IDLE;

            when IDLE =>
                if pending /= "00000000" then
                    next_state <= SCHEDULE;
                end if;

            when SCHEDULE =>
                case sched_dir is
                    when DIR_UP   => next_state <= MOVE_UP;
                    when DIR_DOWN => next_state <= MOVE_DOWN;
                    when others   => next_state <= IDLE;
                end case;

            when MOVE_UP =>
                if floor_reg = sched_floor then next_state <= ARRIVE; end if;

            when MOVE_DOWN =>
                if floor_reg = sched_floor then next_state <= ARRIVE; end if;

            when ARRIVE =>
                next_state <= DOOR_OPEN;

            when DOOR_OPEN =>
                if door_timer = 3 then next_state <= DOOR_CLOSE; end if;

            when DOOR_CLOSE =>
                next_state <= IDLE;

            when ESTOP =>
                next_state <= ESTOP;

        end case;
    end process;


    -- Single sequential process 
    process(clk)
    begin
        if rising_edge(clk) then

            -- Default outputs
            clear_floor   <= (others => '0');
            door_open_led <= '0';
				
				if estop_edge = '1' then
					estop_active <= not estop_active;
				end if;

            -- Hard reset
            if reset_hard = '1' then
                state        <= INIT;
                dir_reg      <= DIR_IDLE;
                floor_reg    <= 0;
                travel_timer <= 0;
                door_timer   <= 0;
                estop_active <= '0';

            -- ESTOP
            elsif estop_active = '1' then
                state <= ESTOP;
                travel_timer <= 0;
                door_timer   <= 0;

            -- Normal fsm logic
            else
                state <= next_state;

                -- Travel logic
                if tick_1hz = '1' then

                    case state is
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

                    -- Door timing
                    case state is
                        when DOOR_OPEN =>
                            door_timer <= door_timer + 1;
                        when DOOR_CLOSE | IDLE =>
                            door_timer <= 0;
                        when others =>
                            null;
                    end case;
                end if;

                -- Clear request
                if state = ARRIVE then
                    clear_floor(floor_reg) <= '1';
                end if;

                -- Door LED
                if state = DOOR_OPEN then
                    door_open_led <= '1';
                end if;

                -- Direction output
                case state is
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