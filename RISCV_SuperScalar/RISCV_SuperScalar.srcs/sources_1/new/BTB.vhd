library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity BTB is
    generic (
        BTB_BITS : integer := 4   -- 2^4 = 16 entradas
    );
    port (
        clock : in std_logic;
        reset : in std_logic;

        -- ===== FETCH (IF) =====
        pc_in         : in  std_logic_vector(31 downto 0);
        predict_taken : out std_logic;
        predict_pc    : out std_logic_vector(31 downto 0);

        -- ===== UPDATE (EX) =====
        update_en    : in  std_logic;
        pc_update    : in  std_logic_vector(31 downto 0);
        target_real  : in  std_logic_vector(31 downto 0);
        taken_real   : in  std_logic
    );
end BTB;

architecture Behavioral of BTB is

    constant BTB_SIZE : integer := 2**BTB_BITS;

    -- ===== Estrutura de cada linha da tabela =====
    type btb_entry is record
        valid  : std_logic;
        tag    : std_logic_vector(31 downto 0);  -- endereço da instrução
        target : std_logic_vector(31 downto 0);  -- endereço de desvio
        pred   : std_logic_vector(1 downto 0);   -- contador 2 bits
    end record;

    type btb_array is array (0 to BTB_SIZE-1) of btb_entry;
    signal BTB : btb_array;

    -- índices
    signal index_fetch  : integer range 0 to BTB_SIZE-1;
    signal index_update : integer range 0 to BTB_SIZE-1;

    signal hit : std_logic;

begin

-- =========================================================
-- INDEXAÇÃO PELO PC
-- =========================================================
index_fetch  <= to_integer(unsigned(pc_in(BTB_BITS+1 downto 2)));
index_update <= to_integer(unsigned(pc_update(BTB_BITS+1 downto 2)));

-- =========================================================
-- HIT / MISS
-- =========================================================
hit <= '1' when (BTB(index_fetch).valid = '1' and
                 BTB(index_fetch).tag = pc_in)
       else '0';

-- =========================================================
-- PREDIÇÃO (FASE IF)
-- =========================================================
process(BTB, index_fetch, hit, pc_in)
begin
    if hit = '1' then
        -- MSB do contador define a predição
        predict_taken <= BTB(index_fetch).pred(1);
        predict_pc    <= BTB(index_fetch).target;
    else
        -- Miss → assume NOT TAKEN
        predict_taken <= '0';
        predict_pc    <= std_logic_vector(unsigned(pc_in) + 4);
    end if;
end process;

-- =========================================================
-- ATUALIZAÇÃO DA TABELA (FASE EX)
-- =========================================================
process(clock, reset)
begin
    if reset = '1' then
        -- Inicialização da tabela
        for i in 0 to BTB_SIZE-1 loop
            BTB(i).valid  <= '0';
            BTB(i).pred   <= "00";  -- Strongly Not Taken
            BTB(i).tag    <= (others => '0');
            BTB(i).target <= (others => '0');
        end loop;

    elsif rising_edge(clock) then
        if update_en = '1' then

            -- Cria ou atualiza entrada
            BTB(index_update).valid  <= '1';
            BTB(index_update).tag    <= pc_update;
            BTB(index_update).target <= target_real;

            -- Contador saturado de 2 bits
            case BTB(index_update).pred is

                when "00" =>
                    if taken_real = '1' then
                        BTB(index_update).pred <= "01";
                    end if;

                when "01" =>
                    if taken_real = '1' then
                        BTB(index_update).pred <= "10";
                    else
                        BTB(index_update).pred <= "00";
                    end if;

                when "10" =>
                    if taken_real = '1' then
                        BTB(index_update).pred <= "11";
                    else
                        BTB(index_update).pred <= "01";
                    end if;

                when others => -- "11"
                    if taken_real = '0' then
                        BTB(index_update).pred <= "10";
                    end if;

            end case;
        end if;
    end if;
end process;

end Behavioral;
