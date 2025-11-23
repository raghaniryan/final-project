-- Ryan Raghani – 301623888; Danny Woo – 301613129; Mitchell Kieper – 301590274;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
