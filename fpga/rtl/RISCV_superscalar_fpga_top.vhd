-------------------------------------------------------------------------
-- Design unit: RISCV superscalar test bench
-- Description: 
-------------------------------------------------------------------------

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.RISCV_package.all;


entity RISCV_superscalar_fpga_top is
    port (  
        clock           : in  std_logic;
        reset           : in  std_logic;
        tx              : out std_logic;
        rx              : in  std_logic;
        mem_scan        : in  std_logic;
        done_led        : out std_logic
    );
end RISCV_superscalar_fpga_top;


architecture structural of RISCV_superscalar_fpga_top is

    -- signals declaration
    signal MemWrite: MemWrite_array;
    signal instructionAddress : std_logic_vector(31 downto 0);
    signal dataAddress, data_i, data_o : Data_array;
    signal instruction : std_logic_vector(63 downto 0);
    
    constant INSTRUCTION_OFFSET    : std_logic_vector(31 downto 0) := x"00400000";
    constant DATA_OFFSET           : std_logic_vector(31 downto 0) := x"10010000";

    constant DATA_WIDTH : integer := 32;
    constant INST_WIDTH : integer := 64;
    
    -- component RISCV_SUPERSCALAR : DUV
    component RISCV_SUPERSCALAR
        generic (
            PC_START_ADDRESS    : integer := 4194304;
            DATA_WIDTH          : integer := 32;
            SYNTHESIS           : boolean := false;
            INST_WIDTH          : integer := 64     
        );
        port (
            clock               : in std_logic;
            reset               : in std_logic;
            
            -- instruction memory interface
            instructionAddress  : out std_logic_vector(DATA_WIDTH-1 downto 0);
            instruction         : in std_logic_vector(INST_WIDTH-1 downto 0);
            
            -- data memory interface
            dataAddress         : out Data_array;
            data_i              : in  Data_array;
            data_o              : out Data_array;
            MemWrite            : out MemWrite_array
        );
    end component;

    component Memory is
        generic (
            SIZE            : integer := 32;       -- Memory depth
            INST_WIDTH      : integer := 64;       -- Data size
            DATA_WIDTH      : integer := 32;
            START_ADDRESS   : std_logic_vector(31 downto 0) := (others=>'0')    -- Address to be mapped to address 0x00000000
        );
        port (  
            clock           : in std_logic;
            MemWrite        : in std_logic_vector(3 downto 0);
            address         : in std_logic_vector (31 downto 0);
            data_i          : in std_logic_vector (DATA_WIDTH-1 downto 0);
            data_o          : out std_logic_vector (INST_WIDTH-1 downto 0)
        );
    end component;

    component Memory_2_ports is
        generic (
            SIZE            : integer := 32;       -- Memory depth
            DATA_WIDTH      : integer := 32;
            START_ADDRESS   : std_logic_vector(31 downto 0) := (others=>'0')    -- Address to be mapped to address 0x00000000
        );
        port (  
            clock           : in std_logic;
            MemWrite_0      : in std_logic_vector(3 downto 0);
            MemWrite_1      : in std_logic_vector(3 downto 0);
            address_0       : in std_logic_vector(31 downto 0);
            address_1       : in std_logic_vector(31 downto 0);
            data_i_0        : in std_logic_vector(31 downto 0);
            data_i_1        : in std_logic_vector(31 downto 0);
            data_o_0        : out std_logic_vector(31 downto 0);
            data_o_1        : out std_logic_vector(31 downto 0)
        );
    end component;

    component UART_top is
        generic (
            CLK_FREQ    : integer := 40_000_000;  -- Clock frequency in Hz
            BAUD_RATE   : integer := 115200;    -- UART baud rate
            MEM_SIZE    : integer := 16384      -- Memory size in words
        );
        port (
            clk         : in  std_logic;
            reset       : in  std_logic;
            rx          : in  std_logic;         -- UART RX pin
            tx          : out std_logic;         -- UART TX pin (for ack)
            mem_scan    : in  std_logic;                     -- Memory scan mode (for debugging)
            mem_addr    : out std_logic_vector(31 downto 0);  -- Memory address
            mem_data_o  : out std_logic_vector(31 downto 0); -- Memory data output (for write)
            mem_data_i  : in  std_logic_vector(31 downto 0); -- Memory data input (for readback)
            mem_we      : out std_logic;         -- Memory write enable
            done        : out std_logic;         -- Bootload complete signal
            inst_data   : out std_logic          -- Inst or Data mem select
        );
    end component;
    
    component clk_wiz_0
    port (
      clk_in1  : in  std_logic;
      clk_out1 : out std_logic
    );
    end component;
    
    signal clk_40mhz : std_logic;

    signal MemWrite_uart : std_logic;
    signal data_uart : std_logic_vector(31 downto 0);
    signal addr_uart : std_logic_vector(31 downto 0);

    signal instructionAddress_mux : std_logic_vector(31 downto 0);
    signal MemWrite_data : std_logic_vector(3 downto 0);
    signal data_in_mux : std_logic_vector(31 downto 0);
    signal data_addr_mux : std_logic_vector(31 downto 0);
    signal mem_data_i_uart : std_logic_vector(31 downto 0);

    signal inst_data : std_logic;
    signal done : std_logic;
    signal reset_core : std_logic;
    signal MemWrite_inst : std_logic_vector(3 downto 0);


begin
    
    -- Clock Wizard 40Mhz
    PLL_inst : clk_wiz_0
        port map (
           clk_in1  => clock,      
           clk_out1 => clk_40mhz   
        );
        
    -- DUV component instance for RISCV_SUPERSCALAR
    DUV: RISCV_SUPERSCALAR
        generic map (
            PC_START_ADDRESS => TO_INTEGER(UNSIGNED(INSTRUCTION_OFFSET)),
            DATA_WIDTH => DATA_WIDTH,
            SYNTHESIS => true,
            INST_WIDTH => INST_WIDTH
        )
        port map (
            clock               => clk_40mhz,
            reset               => reset_core,
            
            -- instruction memory interface
            instructionAddress  => instructionAddress,    
            instruction         => instruction,        
                 
             -- data memory interface
            dataAddress         => dataAddress,
            data_i              => data_i,
            data_o              => data_o,
            MemWrite            => MemWrite
        );

    -- instruction memory instance
    INSTRUCTION_MEMORY: Memory
        generic map (
            SIZE            => 100,                       
            INST_WIDTH      => INST_WIDTH, -- 64 bits (2 instructions) 
            DATA_WIDTH      => DATA_WIDTH,
            START_ADDRESS   => INSTRUCTION_OFFSET
        )
        port map (
            clock           => clk_40mhz,
            MemWrite        => MemWrite_inst,
            address         => instructionAddress_mux,    
            data_i          => data_uart,
            data_o          => instruction
        );
        
    -- data memory instance
    DATA_MEMORY: Memory_2_ports
        generic map (
            SIZE            => 100,                 
            DATA_WIDTH      => DATA_WIDTH, -- 32 bits
            START_ADDRESS   => DATA_OFFSET
        )
        port map (
            clock           => clk_40mhz,
            MemWrite_0      => MemWrite_data, --MemWrite(0),
            MemWrite_1      => MemWrite(1),
            address_0       => data_addr_mux, --dataAddress(0),   
            address_1       => dataAddress(1),  
            data_i_0        => data_in_mux, --data_o(0),
            data_i_1        => data_o(1),
            data_o_0        => data_i(0),
            data_o_1        => data_i(1)
        );
    
    -- UART wrapper instance
    UART: UART_top
        generic map (
            CLK_FREQ    => 40_000_000,
            BAUD_RATE   => 115200,
            MEM_SIZE    => 16384
        )
        port map (
            clk         => clk_40mhz,
            reset       => reset,
            rx          => rx,
            tx          => tx,
            mem_scan    => mem_scan,
            mem_addr    => addr_uart, 
            mem_data_o  => data_uart, 
            mem_data_i  => mem_data_i_uart, 
            mem_we      => MemWrite_uart, 
            done        => done,  
            inst_data   => inst_data
        );

    reset_core <= reset or not done; -- reset the core if the memory is empty

    MemWrite_inst(0) <= MemWrite_uart when inst_data = '0' and done = '0' else
                        '0';
    
    instructionAddress_mux <= addr_uart when inst_data = '0' and done = '0' else
                              instructionAddress;

    data_in_mux <= data_uart when inst_data = '1' and done = '0' else 
                   data_o(0);
                     
    data_addr_mux <= addr_uart when (inst_data = '1' and done = '0') else 
                     dataAddress(0);

    MemWrite_data(0) <= MemWrite_uart when (inst_data = '1' and done = '0') else
                        MemWrite(0)(0);

    mem_data_i_uart <= data_i(0);
    
    MemWrite_data(3 downto 1) <= "000";
    MemWrite_inst(3 downto 1) <= "000";
    
    done_led <= done;
    
end structural;

