library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.RISCV_package.all;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity BTB_superscalar is
    generic (
        BTB_BITS : integer := 4   -- 2^4 = 16 entradas
    );
    port (
        clock : in std_logic;
        reset : in std_logic;
        -- instruction : in  Instruction_type;
        -- ===== FETCH (IF) =====
        pc_in : in data_array;

        predict_taken : out std_logic_vector (1 downto 0);

        predict_pc : out data_array;

        -- ===== UPDATE (ID) =====
        update_en    : in  std_logic_vector(1 downto 0);
        pc_update    : in  data_array;
        target_real  : in  data_array;
        taken_real   : in  std_logic_vector(1 downto 0);
        
        -- ====== Signal Bubble ===
        bubble       : out std_logic
    );
end BTB_superscalar;

architecture Behavioral of BTB_superscalar is

    constant BTB_SIZE : integer := 2**BTB_BITS;

    type btb_entry is record
        valid  : std_logic;
        tag    : std_logic_vector(31 downto 0);
        target : std_logic_vector(31 downto 0);
        pred   : std_logic_vector(1 downto 0);
    end record;

    type btb_array is array (0 to BTB_SIZE-1) of btb_entry;
    signal BTB : btb_array;

    
    type index_array is array (0 to 1) of integer range 0 to BTB_SIZE-1;

    signal index_fetch : index_array;
    signal hit         : std_logic_vector(1 downto 0);
    
    -- signal Branch_inst: std_logic;
    
begin


-- Branch_inst <= '1' when instruction = JAL or instruction = JALR or 
--                             instruction = BEQ  or
--                             instruction = BNE  or
--                             instruction = BLT  or
--                             instruction = BGE  or
--                             instruction = BLTU or
--                             instruction = BGEU
--                else '0';



-- =========================================================
-- Index through PC
-- =========================================================
gen_index: for i in 0 to 1 generate
begin
    index_fetch(i) <= to_integer(unsigned(pc_in(i)(BTB_BITS+1 downto 2)));
end generate;

-- =========================================================
-- HIT / MISS
-- =========================================================
gen_hit: for i in 0 to 1 generate
begin
    hit(i) <= '1' when (BTB(index_fetch(i)).valid = '1' and
                        BTB(index_fetch(i)).tag = pc_in(i))
              else '0';
end generate;

-- =========================================================
-- Prediction (IF)
-- =========================================================

gen_predict: for i in 0 to 1 generate
begin

    predict_taken(i) <= BTB(index_fetch(i)).pred(1)
                        when hit(i) = '1'
                        else '0';

    predict_pc(i) <= BTB(index_fetch(i)).target ;
                    -- when hit(i) = '1'
                    -- else std_logic_vector(unsigned(pc_in(i)) + 4);

end generate;

-- ===== bubble generation ====
bubble <= '1' when (hit(0) = '1' and BTB(index_fetch(0)).pred(1)='1') else '0';



-- =========================================================
-- Table update (EX)
-- =========================================================
process(clock, reset)
    variable idx : integer;
begin
    if reset = '1' then

        for i in 0 to BTB_SIZE-1 loop
            BTB(i).valid  <= '0';
            BTB(i).pred   <= "00";
            BTB(i).tag    <= (others => '0');
            BTB(i).target <= (others => '0');
        end loop;

    elsif rising_edge(clock) then

        if update_en(0) = '1' then

            idx := to_integer(unsigned(pc_update(0)(BTB_BITS+1 downto 2)));

            BTB(idx).valid  <= '1';
            BTB(idx).tag    <= pc_update(0);
            BTB(idx).target <= target_real(0);

            case BTB(idx).pred is
                when "00" =>
                    if taken_real(0) = '1' then
                        BTB(idx).pred <= "01";
                    end if;

                when "01" =>
                    if taken_real(0) = '1' then
                        BTB(idx).pred <= "10";
                    else
                        BTB(idx).pred <= "00";
                    end if;

                when "10" =>
                    if taken_real(0) = '1' then
                        BTB(idx).pred <= "11";
                    else
                        BTB(idx).pred <= "01";
                    end if;

                when others =>
                    if taken_real(0) = '0' then
                        BTB(idx).pred <= "10";
                    end if;
            end case;

        elsif update_en(1) = '1' then

            idx := to_integer(unsigned(pc_update(1)(BTB_BITS+1 downto 2)));

            BTB(idx).valid  <= '1';
            BTB(idx).tag    <= pc_update(1);
            BTB(idx).target <= target_real(1);

            case BTB(idx).pred is
                when "00" =>
                    if taken_real(1) = '1' then
                        BTB(idx).pred <= "01";
                    end if;

                when "01" =>
                    if taken_real(1) = '1' then
                        BTB(idx).pred <= "10";
                    else
                        BTB(idx).pred <= "00";
                    end if;

                when "10" =>
                    if taken_real(1) = '1' then
                        BTB(idx).pred <= "11";
                    else
                        BTB(idx).pred <= "01";
                    end if;

                when others =>
                    if taken_real(1) = '0' then
                        BTB(idx).pred <= "10";
                    end if;
            end case;

        end if;

    end if;
end process;

end Behavioral;
