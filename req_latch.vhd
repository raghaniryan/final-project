-- Ryan Raghani – 301623888; Danny Woo – 301613129; Mitchell Kieper – 301590274;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.elevator_types.all;


entity req_latch is
    port(
        clk        : in  std_logic;                      -- 50 MHz clock
        reset_soft : in  std_logic;                      -- clears pending requests only
        reset_hard : in  std_logic;                      -- clears everything
        key0       : in  std_logic;                      -- active high (note: to debug potentially)
        floor_bin  : in  std_logic_vector(2 downto 0);   -- from SW2 to SW0
        clear_floor: in  std_logic_vector(7 downto 0);    -- from FSM when serving a floor
        pending    : out std_logic_vector(7 downto 0)     -- latched requests
    );
end req_latch;

architecture rtl of req_latch is

    signal pending_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal key0_prev   : std_logic := '0';   -- active high
    signal key0_edge   : std_logic := '0';   -- detect falling edge

begin

    -- Output assignment
    pending <= pending_reg;

    -- Detect falling edge of KEY0 because it is active low

    process(clk)
    begin
        if rising_edge(clk) then
            key0_edge <= '0';

            if key0_prev = '0' and key0 = '1' then
					key0_edge <= '1';     -- rising edge detect
				end if;

				key0_prev <= key0;
        end if;
    end process;

    -- Request latching and clearing logic
    process(clk)
        variable tmp : std_logic_vector(7 downto 0); -- temp storage to prevent overwrite
		  variable floor_index : integer range 0 to 7;
    begin
        if rising_edge(clk) then

            -- Hard reset
            if reset_hard = '1' then
                pending_reg <= (others => '0');

            -- Soft reset
            elsif reset_soft = '1' then
                pending_reg <= (others => '0');

            else
                -- Convert SW2..SW0 to floor index
                floor_index := to_integer(unsigned(floor_bin));
					 
					 -- Start with pending register
					 tmp := pending_reg;
					 
					 -- Clear floor first
					 tmp := tmp and (not clear_floor);
					 
                -- Add new request after clear
                if key0_edge = '1' then
                    tmp(floor_index) := '1';
                end if;

                
                -- Store result back to register
                pending_reg <= tmp;

            end if;
        end if;
    end process;

end rtl;