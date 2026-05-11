-------------------------------------------------------------------------
-- Design unit: UART_top 
-- Description: UART-based bootloader for FPGA, loads data into memory
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity UART_top is
    generic (
        CLK_FREQ    : integer := 50000000;  -- Clock frequency in Hz
        BAUD_RATE   : integer := 115200;    -- UART baud rate
        MEM_SIZE    : integer := 16384      -- Memory size in words
    );
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        mem_scan    : in  std_logic;                     -- Memory scan mode (for debugging)
        rx          : in  std_logic;                     -- UART RX pin
        tx          : out std_logic;                     -- UART TX pin
        mem_addr    : out std_logic_vector(31 downto 0); -- Memory address
        mem_data_o  : out std_logic_vector(31 downto 0); -- Memory data output (for write)
        mem_data_i  : in  std_logic_vector(31 downto 0); -- Memory data input (for readback)
        mem_we      : out std_logic;                     -- Memory write enable
        done        : out std_logic;                     -- Bootload complete signal
        inst_data   : out std_logic                      -- Data or Instructions recive
    );
end UART_top;

architecture behavioral of UART_top is

    -- UART Receiver Component
    component UART_Receiver is
        generic (
            CLK_FREQ  : integer;
            BAUD_RATE : integer
        );
        port (
            clk       : in  std_logic;
            reset     : in  std_logic;
            rx        : in  std_logic;
            data_out  : out std_logic_vector(7 downto 0);
            data_rdy  : out std_logic
        );
    end component;

    -- UART Transmitter Component
    component UART_Transmitter is
        generic (
            CLK_FREQ  : integer;
            BAUD_RATE : integer
        );
        port (
            clk       : in  std_logic;
            reset     : in  std_logic;
            data_in   : in  std_logic_vector(7 downto 0);
            send      : in  std_logic;
            tx        : out std_logic;
            busy      : out std_logic
        );
    end component;

    signal rx_data     : std_logic_vector(7 downto 0);
    signal rx_rdy      : std_logic;
    signal tx_data     : std_logic_vector(7 downto 0);
    signal tx_send     : std_logic;
    signal tx_busy     : std_logic;

    type state_type is (IDLE, RECEIVE_ADDR, RECEIVE_DATA, WRITE_MEM, SEND_ACK, WAIT_ACK, SEND_ADDR, SEND_DATA, WAIT_SCAN_RELEASE, DONE_state);
    signal state       : state_type := IDLE;

    signal addr_reg     : std_logic_vector(31 downto 0);
    signal data_reg     : std_logic_vector(31 downto 0);
    signal byte_count   : integer range 0 to 3 := 0;
    signal word_count   : integer range 0 to MEM_SIZE-1;
    signal mem_addr_reg : std_logic_vector(31 downto 0);

    signal done_reg : std_logic;

begin

    -- UART Receiver Instance
    UART_RX: UART_Receiver
        generic map (
            CLK_FREQ  => CLK_FREQ,
            BAUD_RATE => BAUD_RATE
        )
        port map (
            clk       => clk,
            reset     => reset,
            rx        => rx,
            data_out  => rx_data,
            data_rdy  => rx_rdy
        );

    -- UART Transmitter Instance
    UART_TX: UART_Transmitter
        generic map (
            CLK_FREQ  => CLK_FREQ,
            BAUD_RATE => BAUD_RATE
        )
        port map (
            clk       => clk,
            reset     => reset,
            data_in   => tx_data,
            send      => tx_send,
            tx        => tx,
            busy      => tx_busy
        );

    -- Main UART Process
    process (clk, reset)
    begin
        if reset = '1' then
            state <= IDLE;
            addr_reg <= (others => '0');
            data_reg <= (others => '0');
            byte_count <= 0;
            word_count <= 0;
            mem_we <= '0';
            done_reg <= '0';
            tx_send <= '0';
            inst_data <= '0';

        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if rx_rdy = '1' then
                        state <= RECEIVE_ADDR;
                        addr_reg(7 downto 0) <= rx_data; 
                        byte_count <= 1;
                        
                    elsif mem_scan = '1' then
                        state <= SEND_DATA;
                        addr_reg <= x"10010000";
                        byte_count <= 0;
                        inst_data <= '1';
                        done_reg <= '0';
                    end if;

                when RECEIVE_ADDR =>
                    if rx_rdy = '1' then
                        if byte_count = 3 then
                            addr_reg(31 downto 24) <= rx_data;
                            byte_count <= 0;
                            
                            if addr_reg(23 downto 0) & rx_data = x"FFFFFFFF" then -- end pack
                                state <= DONE_state;
                            else
                                state <= RECEIVE_DATA;
                            end if;
                        elsif byte_count = 2 then
                            byte_count <= byte_count + 1;
                            addr_reg(23 downto 16) <= rx_data;
                        elsif byte_count = 1 then
                            byte_count <= byte_count + 1;
                            addr_reg(15 downto 8) <= rx_data;
                        else
                            byte_count <= byte_count + 1;
                            addr_reg(7 downto 0) <= rx_data;
                        end if;
                    end if;

                when RECEIVE_DATA =>
                    if rx_rdy = '1' then
                        if byte_count = 3 then
                            data_reg(31 downto 24) <= rx_data;
                            state <= WRITE_MEM;
                        elsif byte_count = 2 then
                            byte_count <= byte_count + 1;
                            data_reg(23 downto 16) <= rx_data;
                        elsif byte_count = 1 then
                            byte_count <= byte_count + 1;
                            data_reg(15 downto 8) <= rx_data;
                        else
                            data_reg(7 downto 0) <= rx_data;
                            byte_count <= byte_count + 1;
                        end if;
                    end if;
                
                when WRITE_MEM =>
                    mem_data_o <= data_reg;
                    mem_we <= '1';

                    if addr_reg(31 downto 24) = x"00" then 
                        inst_data <= '0'; -- if addr start with "00" (0x0040...), is instruction ('0')
                    else
                        inst_data <= '1'; -- if start with "10" (0x1001...), is data ('1')
                    end if;
                    
                    state <= SEND_ACK;
                    word_count <= word_count + 1;

                when SEND_ACK =>
                    mem_we <= '0';
                    
                    if tx_send = '0' and tx_busy = '0' then
                        tx_data <= x"01";
                        tx_send <= '1';
                    elsif tx_send = '1' then
                        tx_send <= '0'; 
                        state <= WAIT_ACK;
                    end if;

                when WAIT_ACK =>
                    if tx_busy = '0' then
                        state <= IDLE; 
                    end if;

                when DONE_state =>
                    done_reg <= '1';
                    state <= IDLE; 

                when SEND_DATA =>
                    
                    if tx_send = '0' and tx_busy = '0' then
                        if byte_count = 0 then
                            tx_data <= mem_data_i(7 downto 0);
                        elsif byte_count = 1 then
                            tx_data <= mem_data_i(15 downto 8);
                        elsif byte_count = 2 then
                            tx_data <= mem_data_i(23 downto 16);
                        elsif byte_count = 3 then
                            tx_data <= mem_data_i(31 downto 24);
                        end if;
                        tx_send <= '1';

                    elsif tx_send = '1' then
                        tx_send <= '0';

                        if byte_count = 3 then
                            byte_count <= 0;
                            
                            addr_reg <= std_logic_vector(unsigned(addr_reg) + 4);

                            if unsigned(addr_reg) >= x"10010034" then --(MEM_SIZE * 4) - 4 then 
                                state <= WAIT_SCAN_RELEASE;
                            end if;
                        else
                            byte_count <= byte_count + 1;
                        end if;
                    end if;
                
                when WAIT_SCAN_RELEASE =>
                    if mem_scan = '0' then
                        state <= IDLE;
                        done_reg <= '1';
                    end if;

                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;

    mem_addr <= addr_reg;
    done <= done_reg;

end behavioral;