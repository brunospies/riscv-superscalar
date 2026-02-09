library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FSM_BimodalPrediction is
    Port (
        clock        : in  std_logic;
        reset        : in  std_logic;
        branch_taken : in  std_logic;  -- '1' = taken, '0' = not taken
        prediction   : out std_logic   -- '1' = predict taken
    );
end FSM_BimodalPrediction;

architecture Behavioral of FSM_BimodalPrediction is

    type state_type is (N00, N01, T10, T11);
    -- N00: strong not taken
    -- N01: weak not taken
    -- T10: weak taken
    -- T11: strong taken
    signal current_state, next_state : state_type;

begin

-- =========================
-- NEXT STATE LOGIC
-- =========================
process(current_state, branch_taken)
begin
    case current_state is

        when N00 =>
            if branch_taken = '1' then
                next_state <= N01;
            else
                next_state <= N00;
            end if;

        when N01 =>
            if branch_taken = '1' then
                next_state <= T10;
            else
                next_state <= N00;
            end if;

        when T10 =>
            if branch_taken = '1' then
                next_state <= T11;
            else
                next_state <= N01;
            end if;

        when T11 =>
            if branch_taken = '1' then
                next_state <= T11;
            else
                next_state <= T10;
            end if;

    end case;
end process;

-- =========================
-- 
-- =========================
process(clock, reset)
begin
    if reset = '1' then
        current_state <= N00;
    elsif rising_edge(clock) then
        current_state <= next_state;
    end if;
end process;

-- =========================
-- OUTPUT LOGIC (synchronous)
-- =========================
--process(current_state)
--begin
--    case current_state is
--        when N00 | N01 =>
--            prediction <= '0'; -- predict NOT taken
--        when T10 | T11 =>
--            prediction <= '1'; -- predict taken
--    end case;
--end process;


-- =========================
-- OUTPUT LOGIC (asynchronous)
-- =========================
prediction <= '1' when current_state = T10 or current_state = T11 else '0';

end Behavioral;

