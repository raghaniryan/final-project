-- Ryan Raghani – 301623888; Danny Woo – 301613129; Mitchell Kieper – 301590274;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.elevator_types.all;


entity Elevator_Top is
    port(
        CLOCK_50 : in  std_logic;
        SW       : in  std_logic_vector(2 downto 0);   -- floor input
        KEY      : in  std_logic_vector(3 downto 0);   -- active-low keys

        LEDR     : out std_logic_vector(9 downto 0);   -- indicators
        HEX0     : out std_logic_vector(6 downto 0);   -- floor
        HEX1     : out std_logic_vector(6 downto 0)    -- direction: U/d/i
    );
end Elevator_Top;

architecture rtl of Elevator_Top is

    -- Internal Signals
    signal tick_1hz     : std_logic;

    -- Reset + control signals
    signal reset_hard   : std_logic;   -- KEY3
    signal reset_soft   : std_logic;   -- KEY2
    signal estop_btn    : std_logic;   -- KEY1 (toggle)
    signal confirm      : std_logic;   -- KEY0 (confirm request)

    -- Request system
    signal pending_req  : std_logic_vector(7 downto 0);
    signal clear_floor  : std_logic_vector(7 downto 0);

    -- Scheduler ↔ FSM
    signal curr_floor   : integer range 0 to 7;
    signal direction    : direction_t;

    signal sched_dir    : direction_t;
    signal sched_floor  : integer range 0 to 7;

    signal door_led     : std_logic;

begin

    -- KEY Mappings (active-low)
    reset_hard <= not KEY(3);
    reset_soft <= not KEY(2);
    estop_btn  <= not KEY(1);
    confirm    <= not KEY(0);

    -- Clock Divider (1 Hz pulse)
    u_clkdiv : entity work.clk_div
        generic map( DIVISOR => 50_000_000 )
        port map(
            clk_in     => CLOCK_50,
            reset_n    => not reset_hard,
            tick_1hz   => tick_1hz
        );

    -- Request Latch (ESTOP is the only thing that trumps it)
    u_reqlatch : entity work.req_latch
        port map(
            clk         => CLOCK_50,
            reset_soft  => reset_soft,
            reset_hard  => reset_hard,
            key0        => KEY(0),                  -- falling-edge RAW
            floor_bin   => SW(2 downto 0),
            clear_floor => clear_floor,
            pending     => pending_req
        );

    -- Scheduler (next direction + target floor)
    u_sched : entity work.scheduler
        port map(
            current_floor => curr_floor,
            pending       => pending_req,
            current_dir   => direction,
            next_dir      => sched_dir,
            target_floor  => sched_floor
        );

    -- Controller FSM (movement, doors, estop toggle, timers)
    u_fsm : entity work.controller_fsm
        port map(
            clk           => CLOCK_50,
            tick_1hz      => tick_1hz,
            reset_hard    => reset_hard,
            reset_soft    => reset_soft,
            estop_btn     => estop_btn,

            pending       => pending_req,
            clear_floor   => clear_floor,

            sched_dir     => sched_dir,
            sched_floor   => sched_floor,

            current_floor => curr_floor,
            direction     => direction,
            door_open_led => door_led
        );

    -- Display Driver (HEX0 floor, HEX1 direction)
    u_display : entity work.display_driver
        port map(
            current_floor => curr_floor,
            direction     => direction,

            HEX0 => HEX0,
            HEX1 => HEX1
        );

    -- LED Indicators
    -- Direction indicators
    LEDR(0) <= '1' when direction = DIR_UP   else '0';
    LEDR(1) <= '1' when direction = DIR_DOWN else '0';
    LEDR(2) <= '1' when direction = DIR_IDLE else '0';

    -- Door open
    LEDR(3) <= door_led;

    -- ESTOP indicator (active when FSM estop_active=1 inside FSM)
    LEDR(4) <= estop_btn;        -- raw estop button indicator


end rtl;
