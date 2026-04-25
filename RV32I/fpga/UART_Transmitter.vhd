library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity UART_Transmitter is
    generic (
        CLK_FREQ  : integer := 50000000;
        BAUD_RATE : integer := 115200
    );
    port (
        clk      : in  std_logic;
        reset    : in  std_logic;
        data_in  : in  std_logic_vector(7 downto 0);
        send     : in  std_logic;
        tx       : out std_logic;
        busy     : out std_logic
    );
end UART_Transmitter;

architecture behavioral of UART_Transmitter is

    constant BAUD_TICKS : integer := CLK_FREQ / BAUD_RATE;

    type state_type is (IDLE, TRANSMIT);
    signal state      : state_type := IDLE;
    signal baud_cnt   : integer range 0 to BAUD_TICKS-1 := 0;
    signal bit_cnt    : integer range 0 to 9 := 0;
    signal shift_reg  : std_logic_vector(7 downto 0);
    signal tx_reg     : std_logic := '1';

begin

    tx <= tx_reg;
    busy <= '1' when state = TRANSMIT else '0';

    process(clk, reset)
    begin
        if reset = '1' then
            state <= IDLE;
            baud_cnt <= 0;
            bit_cnt <= 0;
            shift_reg <= (others => '1');
            tx_reg <= '1';
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    tx_reg <= '1';
                    baud_cnt <= 0;
                    bit_cnt <= 0;

                    if send = '1' then
                        shift_reg <= data_in; -- data 
                        state <= TRANSMIT;
                        tx_reg <= '0'; -- Start bit
                        baud_cnt <= 0;
                        bit_cnt <= 0;
                    end if;

                when TRANSMIT =>
                    if baud_cnt = BAUD_TICKS - 1 then
                        baud_cnt <= 0;

                        if bit_cnt = 8 then
                            tx_reg <= '1'; -- Stop bit
                            bit_cnt <= bit_cnt + 1; -- increment to garantee stop bit is received with correct timing
                            
                        elsif bit_cnt = 9 then
                            state <= IDLE;
                        else
                            bit_cnt <= bit_cnt + 1;
                            tx_reg <= shift_reg(bit_cnt);
                        end if;
                    else
                        baud_cnt <= baud_cnt + 1;
                    end if;
            end case;
        end if;
    end process;

end behavioral;