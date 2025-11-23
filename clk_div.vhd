library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clk_div is
    generic(DIVISOR : integer := 50_000_000);
    port(
        clk_in  : in  std_logic;
        clk_out : out std_logic
    );
end clk_div;

architecture rtl of clk_div is
    signal count : unsigned(31 downto 0) := (others => '0');
    signal clk_reg : std_logic := '0';
begin

    process(clk_in)
    begin
        if rising_edge(clk_in) then
            if count = DIVISOR/2-1 then
                clk_reg <= not clk_reg;
                count   <= (others => '0');
            else
                count <= count + 1;
            end if;
        end if;
    end process;

    clk_out <= clk_reg;

end rtl;
