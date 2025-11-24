-- Ryan Raghani – 301623888; Danny Woo – 301613129; Mitchell Kieper – 301590274

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; 

entity Elevator_Top is
    Port (
        CLOCK_50 : in  STD_LOGIC;
        SW       : in  STD_LOGIC_VECTOR(7 downto 0); -- Floor requests
        KEY      : in  STD_LOGIC_VECTOR(3 downto 0); -- Resets and ESTOP (Active Low)
        HEX0     : out STD_LOGIC_VECTOR(6 downto 0); -- Floor Display
        HEX1     : out STD_LOGIC_VECTOR(6 downto 0); -- Status Display
        LEDR     : out STD_LOGIC_VECTOR(9 downto 0)  -- LEDs for Status/Debug
    );
end Elevator_Top;

architecture Structural of Elevator_Top is

    -- Internal Signals
    signal tick_1hz        : std_logic;
    signal current_floor_int : integer range 0 to 7;
    signal dir_code        : std_logic_vector(1 downto 0);
    signal state_code      : std_logic_vector(2 downto 0);
    
    -- Outputs from display_driver
    signal wire_led_dir    : std_logic_vector(2 downto 0);
    signal wire_led_estop  : std_logic;
    
    
    component clk_div
        Port ( 
            clk_in  : in STD_LOGIC;
            reset_n : in STD_LOGIC; 
            tick_1hz : out STD_LOGIC 
        );
    end component;
    
    component controller_fsm
        Generic ( 
            N_FLOORS, TRAVEL_COUNT, DOOR_OPEN_COUNT : integer 
        );
        Port (
            clk           : in  STD_LOGIC;
            tick_1hz      : in  STD_LOGIC;
            rst_hard_n    : in  STD_LOGIC;
            rst_soft_n    : in  STD_LOGIC;
            estop_n       : in  STD_LOGIC;
            pending       : in  STD_LOGIC_VECTOR(7 downto 0);
            current_floor : out integer range 0 to 7;
            direction     : out STD_LOGIC_VECTOR(1 downto 0);
            state_code    : out STD_LOGIC_VECTOR(2 downto 0)
        );
    end component;
    
    component display_driver
        Port (
            floor_in   : in  STD_LOGIC_VECTOR(2 downto 0);
            state_in   : in  STD_LOGIC_VECTOR(2 downto 0);
            led_dir    : out STD_LOGIC_VECTOR(2 downto 0);
            led_estop  : out STD_LOGIC;
            hex_floor  : out STD_LOGIC_VECTOR(6 downto 0);
            hex_door   : out STD_LOGIC_VECTOR(6 downto 0)
        );
    end component;

begin

    -- 1. CLK divider
    U_CLK : clk_div
    port map (
        clk_in   => CLOCK_50,
        reset_n  => KEY(3), 
        tick_1hz => tick_1hz
    );

    -- 2. Controller FSM
    U_CTRL : controller_fsm
    generic map (
        N_FLOORS        => 8,
        TRAVEL_COUNT    => 2,
        DOOR_OPEN_COUNT => 3
    )
    port map (
        clk           => CLOCK_50,
        tick_1hz      => tick_1hz,
        rst_hard_n    => KEY(3), 
        rst_soft_n    => KEY(2), 
        estop_n       => KEY(1), 
        pending       => SW(7 downto 0),
        current_floor => current_floor_int,
        direction     => dir_code,
        state_code    => state_code
    );
    
    -- 3. Display driver
    U_DISPLAY : display_driver
    port map (
        floor_in   => std_logic_vector(to_unsigned(current_floor_int, 3)), 
        state_in   => state_code,
        led_dir    => wire_led_dir,
        led_estop  => wire_led_estop,
        hex_floor  => HEX0,
        hex_door   => HEX1
    );

    -- 4. Output mapping
    LEDR(0) <= wire_led_dir(0);
    LEDR(1) <= wire_led_dir(1);
    LEDR(2) <= wire_led_dir(2);
    LEDR(3) <= wire_led_estop;
    
    LEDR(7 downto 5) <= std_logic_vector(to_unsigned(current_floor_int, 3)); 

end Structural;