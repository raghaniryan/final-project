-- Ryan Raghani – 301623888; Danny Woo – 301613129; Mitchell Kieper – 301590274

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity controller_fsm is
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
end controller_fsm;

architecture Behavioral of controller_fsm is

    -- States
    type state_t is (
        INIT,
        IDLE,
        MOVE_UP,
        MOVE_DOWN,
        ARRIVE,
        DOOR_OPEN,
        DOOR_CLOSE,
        ESTOP
    );
    
    signal state, next_state : state_t;

    -- Registers 
    signal floor_reg     : integer range 0 to 7 := 0; -- Current floor register
    signal travel_timer  : integer := 0;              -- Timer used for both travel and door
    signal dir_reg       : std_logic_vector(1 downto 0) := "00"; -- Direction register

    signal pending_latched : std_logic_vector(N_FLOORS-1 downto 0) := (others => '0'); -- Latched requests
    
    -- Scheduler Logic Signals 
    signal req_above : std_logic;
    signal req_below : std_logic;
    signal req_here  : std_logic;
    
    -- Debounce and Timing Completion signals
    signal debounce_cnt : integer range 0 to 500000 := 0;
    signal sw_sampled   : std_logic_vector(N_FLOORS-1 downto 0) := (others => '0');
    signal sw_prev      : std_logic_vector(N_FLOORS-1 downto 0) := (others => '0');
    
    signal travel_done : boolean;
    signal door_done   : boolean;


begin

    current_floor <= floor_reg;
    direction     <= dir_reg;
    
    -- State Code Output Mapping (Used by the display_driver)
    process(state)
    begin
        case state is
            when INIT       => state_code <= "000";
            when IDLE       => state_code <= "001";
            when MOVE_UP    => state_code <= "010";
            when MOVE_DOWN  => state_code <= "011";
            when ARRIVE     => state_code <= "100";
            when DOOR_OPEN  => state_code <= "101";
            when DOOR_CLOSE => state_code <= "110";
            when ESTOP      => state_code <= "111";
        end case;
    end process;

    -- Scheduler logic (Combinational)
    process(pending_latched, floor_reg)
        variable v_above : boolean := false;
        variable v_below : boolean := false;
    begin
        v_above := false;
        v_below := false;
        for i in 0 to N_FLOORS-1 loop
            if pending_latched(i) = '1' then
                if i > floor_reg then v_above := true; end if;
                if i < floor_reg then v_below := true; end if;
            end if;
        end loop;
        if v_above then req_above <= '1'; else req_above <= '0'; end if;
        if v_below then req_below <= '1'; else req_below <= '0'; end if;
        req_here <= pending_latched(floor_reg);
    end process;

    -- Timing Completion Checks
    travel_done <= (travel_timer >= TRAVEL_COUNT);
    door_done   <= (travel_timer >= DOOR_OPEN_COUNT);
    
    -- Combinational state logic
    process(state, req_here, req_above, req_below, dir_reg, travel_done, door_done, tick_1hz, rst_soft_n)
    begin
        next_state <= state;
        
        case state is
            when INIT =>
                next_state <= IDLE;
            when IDLE =>
                if req_here = '1' then
                    next_state <= ARRIVE;
                elsif req_above = '1' then
                    next_state <= MOVE_UP;
                elsif req_below = '1' then
                    next_state <= MOVE_DOWN;
                end if;

            when MOVE_UP =>
                -- Stable transition based on timer completion gated by 1Hz tick
                if tick_1hz = '1' and travel_done then
                    next_state <= ARRIVE;
                end if;

            when MOVE_DOWN =>
                if tick_1hz = '1' and travel_done then
                     next_state <= ARRIVE;
                end if;

            when ARRIVE =>
                next_state <= DOOR_OPEN;

            when DOOR_OPEN =>
                if tick_1hz = '1' and door_done then
                    next_state <= DOOR_CLOSE;
                end if;

            when DOOR_CLOSE =>
                -- Scheduling policy
                if req_here = '1' then
                    next_state <= ARRIVE;
                else
                    if dir_reg = "01" then -- Moving UP
                        if req_above = '1' then next_state <= MOVE_UP;
                        elsif req_below = '1' then next_state <= MOVE_DOWN;
                        else next_state <= IDLE;
                        end if;
                    elsif dir_reg = "10" then -- Moving DOWN
                        if req_below = '1' then next_state <= MOVE_DOWN;
                        elsif req_above = '1' then next_state <= MOVE_UP;
                        else next_state <= IDLE;
                        end if;
                    else
                        next_state <= IDLE;
                    end if;
                end if;

            when ESTOP =>
                -- Exit ESTOP on Active Low Soft Reset
                if rst_soft_n = '0' then
                    next_state <= IDLE;
                end if;

            when others =>
                next_state <= INIT;
        end case;
    end process;

    -- Sequential logic (Updates on rising_edge(clk))
    process(clk, rst_hard_n)
    begin
        -- Hard Reset (Active Low)
        if rst_hard_n = '0' then
            state <= INIT;
            floor_reg <= 0;
            travel_timer <= 0;
            dir_reg <= "00";
            pending_latched <= (others => '0');
            sw_sampled <= (others => '0');
            sw_prev <= (others => '0');
            debounce_cnt <= 0;
            
        elsif rising_edge(clk) then
            
            -- ESTOP Priority (Active Low)
            if estop_n = '0' then
                state <= ESTOP;
            
            -- Soft Reset Priority (Active Low)
            elsif rst_soft_n = '0' then
                pending_latched <= (others => '0'); -- Clear requests
                travel_timer <= 0;
                state <= IDLE;

            -- Normal Operation
            else
                state <= next_state;
                
                -- Debouncer
                if debounce_cnt < 500000 then 
                    debounce_cnt <= debounce_cnt + 1;
                else
                    debounce_cnt <= 0;
                    sw_sampled <= pending;
                end if;
                
                -- Request latching/clearing logic
                for i in 0 to N_FLOORS-1 loop
                    -- Latching (TR-3)
                    if (sw_sampled(i) = '1' and sw_prev(i) = '0') then
                        pending_latched(i) <= '1';
                    end if;
                end loop;
                
                -- Request Clearing
                if state = DOOR_OPEN then
                    pending_latched(floor_reg) <= '0';
                end if;

                if debounce_cnt = 0 then
                    sw_prev <= sw_sampled;
                end if;
                
                -- Timer updates (Gated by 1Hz clock)
                if state /= next_state then
                    travel_timer <= 0;
                elsif tick_1hz = '1' then
                    travel_timer <= travel_timer + 1;
                end if;

                -- Floor updates (Gated by 1Hz clock and timer completion)
                if state = MOVE_UP and tick_1hz = '1' and travel_done then
                    if floor_reg < N_FLOORS-1 then
                        floor_reg <= floor_reg + 1;
                    end if;
                elsif state = MOVE_DOWN and tick_1hz = '1' and travel_done then
                    if floor_reg > 0 then
                        floor_reg <= floor_reg - 1;
                    end if;
                end if;

                -- Direction updates (Scheduled on state change or IDLE)
                if state = IDLE then
                    if req_above = '1' then dir_reg <= "01"; 
                    elsif req_below = '1' then dir_reg <= "10"; 
                    else dir_reg <= "00";
                    end if;
                elsif state = DOOR_CLOSE then
                    -- Re-evaluate direction based on scheduling policy
                    if req_here = '0' then
                        if dir_reg = "01" and req_above = '0' and req_below = '1' then
                            dir_reg <= "10";
                        elsif dir_reg = "10" and req_below = '0' and req_above = '1' then
                            dir_reg <= "01";
                        elsif req_above = '0' and req_below = '0' then
                            dir_reg <= "00";
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;