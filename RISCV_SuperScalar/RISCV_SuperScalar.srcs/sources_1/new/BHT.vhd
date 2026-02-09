library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity BHT is
    generic (
        BHT_BITS : integer := 4  -- 2^4 = 16 inputs
    );
    port (
        clock        : in  std_logic;
        reset        : in  std_logic;
        pc           : in  std_logic_vector(31 downto 0);
        branch_taken : in  std_logic;
        update_en    : in  std_logic;
        prediction   : out std_logic
    );
end BHT;

architecture Behavioral of BHT is

    constant BHT_SIZE : integer := 2**BHT_BITS;

    -- every input is a 2 bits counter
    type bht_array is array (0 to BHT_SIZE-1) of std_logic_vector(1 downto 0);
    signal BHT : bht_array;

    signal index : integer range 0 to BHT_SIZE-1;

begin

-- =========================
-- PC index
-- =========================
index <= to_integer(unsigned(pc(BHT_BITS+1 downto 2))); -- chaque 

-- =========================
-- PREDIÇÃO (COMBINACIONAL)
-- =========================
process(BHT, index)
begin
    -- MSB define the prediction
    prediction <= BHT(index)(1);
end process;

-- =========================
-- BHT Update
-- =========================
process(clock, reset)
begin
    if reset = '1' then
        -- Init is: Strongly Not Taken
        for i in 0 to BHT_SIZE-1 loop
            BHT(i) <= "00";
        end loop;

    elsif rising_edge(clock) then
        if update_en = '1' then
            case BHT(index) is

                when "00" =>
                    if branch_taken = '1' then
                        BHT(index) <= "01";
                    end if;

                when "01" =>
                    if branch_taken = '1' then
                        BHT(index) <= "10";
                    else
                        BHT(index) <= "00";
                    end if;

                when "10" =>
                    if branch_taken = '1' then
                        BHT(index) <= "11";
                    else
                        BHT(index) <= "01";
                    end if;

                when others =>  -- "11"
                    if branch_taken = '0' then
                        BHT(index) <= "10";
                    end if;

            end case;
        end if;
    end if;
end process;

end Behavioral;
