-- Ryan Raghani – 301623888; Danny Woo – 301613129; Mitchell Kieper – 301590274

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity controller_fsm_tb is
end controller_fsm_tb;

architecture Behavioral of controller_fsm_tb is

    -- Component Declaration for the Unit Under Test (UUT)
    component controller_fsm
        Generic (
            N_FLOORS        : integer := 8;
            TRAVEL_COUNT    : integer := 1;
            DOOR_OPEN_COUNT : integer := 2
        );
        Port (
            clk           : in  STD_LOGIC;
            tick_1hz      : in  STD_LOGIC;
            rst_hard_n    : in  STD_LOGIC;
            rst_soft_n    : in  STD_LOGIC;
            estop_n       : in  STD_LOGIC;
            pending       : in  STD_LOGIC_VECTOR(N_FLOORS-1 downto 0);
            current_floor : out integer range 0 to 7;
            direction     : out STD_LOGIC_VECTOR(1 downto 0);
            state_code    : out STD_LOGIC_VECTOR(2 downto 0)
        );
    end component;

    -- Signal Declarations for UUT Ports
    signal clk_tb          : STD_LOGIC := '0';
    signal tick_1hz_tb     : STD_LOGIC := '0';
    signal rst_hard_n_tb   : STD_LOGIC := '0';
    signal rst_soft_n_tb   : STD_LOGIC := '0';
    signal estop_n_tb      : STD_LOGIC := '0';
    signal pending_tb      : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

    -- Output Signals
    signal current_floor_out : integer range 0 to 7;
    signal direction_out     : STD_LOGIC_VECTOR(1 downto 0);
    signal state_code_out    : STD_LOGIC_VECTOR(2 downto 0);

    -- Clock Period and Tick Period Constants
    constant CLK_PERIOD : time := 20 ns;     -- 50 MHz clock
    -- Define a faster tick for simulation (100 ms instead of 1 s)
    constant TEST_TICK_PULSE_TIME : time := 100 ms;
    
    -- Simulation Tick Counter
    constant TICK_MAX_COUNT : integer := 4999999;
    signal tick_counter : integer range 0 to TICK_MAX_COUNT := 0;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: controller_fsm
    Generic map (
        N_FLOORS        => 8,
        TRAVEL_COUNT    => 1,
        DOOR_OPEN_COUNT => 2
    )
    Port map (
        clk           => clk_tb,
        tick_1hz      => tick_1hz_tb,
        rst_hard_n    => rst_hard_n_tb,
        rst_soft_n    => rst_soft_n_tb,
        estop_n       => estop_n_tb,
        pending       => pending_tb,
        current_floor => current_floor_out,
        direction     => direction_out,
        state_code    => state_code_out
    );

    -- Clock generation (50 MHz)
    clk_gen: process
    begin
        loop
            clk_tb <= '0';
            wait for CLK_PERIOD/2;
            clk_tb <= '1';
            wait for CLK_PERIOD/2;
        end loop;
    end process;
    
    -- 1 HZ tick pulse generation (Single-cycle pulse every 100 ms)
    tick_gen: process(clk_tb, rst_hard_n_tb)
    begin
        if rst_hard_n_tb = '0' then
            tick_counter <= 0;
            tick_1hz_tb <= '0';
        elsif rising_edge(clk_tb) then
            tick_1hz_tb <= '0'; -- Default low
            if tick_counter = TICK_MAX_COUNT then
                tick_counter <= 0;
                tick_1hz_tb <= '1'; -- Pulse high for one clock cycle
            else
                tick_counter <= tick_counter + 1;
            end if;
        end if;
    end process;

    stimulus: process
    begin
        -- 1. Initialization and hard reset
        rst_hard_n_tb <= '0';
        rst_soft_n_tb <= '1';
        estop_n_tb <= '1';
        pending_tb <= (others => '0');
        wait for 4 * CLK_PERIOD;

        rst_hard_n_tb <= '1';
        wait for 2 * CLK_PERIOD;

        -- 2. Test up travel and stops (F0 to F7)
        pending_tb(7) <= '1';
        wait for CLK_PERIOD;

        -- Wait for move to start (IDLE to MOVE_UP)
        wait until current_floor_out = 0 and state_code_out = "010";
        
        -- Travel from F0 to F7 (7 * 100ms = 700ms total travel)
        wait for 7 * TEST_TICK_PULSE_TIME;
        
        -- Wait until it arrives at F7
        wait until current_floor_out = 7;

        -- Wait for stop and door open (ARRIVE to DOOR_OPEN)
        wait until state_code_out = "101";
        
        -- Wait for door open time (2 ticks = 200 ms)
        wait for 2 * TEST_TICK_PULSE_TIME;
        
        -- Door should close and FSM go to IDLE (DOOR_CLOSE to IDLE)
        wait until state_code_out = "001";
        wait for 2 * CLK_PERIOD;
        
        -- 3. TEST DOWN TRAVEL AND STOP (F7 to F0)
        pending_tb(0) <= '1';
        wait for CLK_PERIOD;

        -- Wait for move to start (IDLE to MOVE_DOWN)
        wait until current_floor_out = 7 and state_code_out = "011";

        -- Travel from F7 to F0 (7 * 100ms = 700ms total travel)
        wait for 7 * TEST_TICK_PULSE_TIME;

        -- Wait until it arrives at F0
        wait until current_floor_out = 0;

        -- Wait for stop and door open (ARRIVE to DOOR_OPEN)
        wait until state_code_out = "101";

        -- Wait for door open time (2 ticks = 200 ms)
        wait for 2 * TEST_TICK_PULSE_TIME;

        -- Door should close and FSM go to IDLE (DOOR_CLOSE to IDLE)
        wait until state_code_out = "001";
        wait for 2 * CLK_PERIOD;

        -- 4. TEST EMERGENCY STOP & SOFT RESET
        pending_tb <= (others => '0');
        pending_tb(4) <= '1';
        -- FIX: Changed ** to *
        wait for 1 * CLK_PERIOD; 
        
        -- Wait for movement to start
        wait until state_code_out = "010";
        
        -- Let it move to F2 (2 ticks = 200 ms)
        wait for 2 * TEST_TICK_PULSE_TIME;
        wait until current_floor_out = 2;
        
        -- Assert Emergency Stop
        estop_n_tb <= '0';
        wait until state_code_out = "111";
        
        -- Assert Soft Reset
        rst_soft_n_tb <= '0';
        wait until state_code_out = "001";
        
        -- De-assert Soft Reset
        rst_soft_n_tb <= '1';
        estop_n_tb <= '1';
        wait for 1 * TEST_TICK_PULSE_TIME;
        
        -- 5. End sim
        wait;

    end process;

end Behavioral;