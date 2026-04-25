-------------------------------------------------------------------------
-- Design unit: UART_Receiver
-- Description: UART Receiver module for receiving serial data
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity UART_Receiver is
    generic (
        CLK_FREQ  : integer := 50000000;  -- Clock frequency in Hz
        BAUD_RATE : integer := 115200     -- UART baud rate
    );
    port (
        clk       : in  std_logic;
        reset     : in  std_logic;
        rx        : in  std_logic;
        data_out  : out std_logic_vector(7 downto 0);
        data_rdy  : out std_logic
    );
end UART_Receiver;

architecture behavioral of UART_Receiver is

    constant CLK_PER_BIT : integer := CLK_FREQ / BAUD_RATE;

    type state_type is (IDLE, START, DATA, STOP);
    signal state : state_type := IDLE;

    signal clk_count : integer range 0 to CLK_PER_BIT-1 := 0;
    signal bit_index : integer range 0 to 7 := 0;
    signal rx_data   : std_logic_vector(7 downto 0);
    signal data_rdy_int : std_logic;
    signal rx_sync : std_logic_vector(1 downto 0);

begin

    data_out <= rx_data;
    data_rdy <= data_rdy_int;

    process (clk, reset)
    begin
        if reset = '1' then
            state <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            rx_data <= (others => '0');
            data_rdy_int <= '0';
            rx_sync <= "00";
        elsif rising_edge(clk) then

            rx_sync <= rx_sync(0) & rx;

            case state is
                when IDLE =>
                    data_rdy_int <= '0';
                    if rx_sync(1) = '0' then  -- Start bit detected
                        state <= START;
                        clk_count <= 0;
                    end if;

                when START =>
                    if clk_count = (CLK_PER_BIT-1)/2 then  -- Sample in middle of start bit
                        if rx_sync(1) = '0' then
                            state <= DATA;
                            clk_count <= 0;
                            bit_index <= 0;
                        else
                            state <= IDLE;  -- False start
                        end if;
                    else
                        clk_count <= clk_count + 1;
                    end if;

                when DATA =>
                    if clk_count = (CLK_PER_BIT-1)/2 then
                        rx_data(bit_index) <= rx_sync(1);
                    end if;

                    if clk_count = CLK_PER_BIT-1 then
                        -- rx_data(bit_index) <= rx_sync(1);
                        clk_count <= 0;
                        if bit_index = 7 then
                            state <= STOP;
                        else
                            bit_index <= bit_index + 1;
                        end if;
                    else
                        clk_count <= clk_count + 1;
                    end if;

                when STOP =>

                    if clk_count = CLK_PER_BIT-1 then
                        if rx_sync(1) = '1' then  -- Valid stop bit
                            data_rdy_int <= '1'; -- Data is ready
                        end if;
                        state <= IDLE;
                        clk_count <= 0;
                    else
                        clk_count <= clk_count + 1;
                    end if;

                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;

end behavioral;