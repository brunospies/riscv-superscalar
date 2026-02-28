-------------------------------------------------------------------------
-- Design unit: RISCV superscalar test bench
-- Description: 
-------------------------------------------------------------------------

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.RISCV_package.all;


entity RISCV_superscalar_tb is
end RISCV_superscalar_tb;


architecture structural of RISCV_superscalar_tb is

    -- signals declaration
    signal clock: std_logic := '0';
    signal reset: std_logic;
    signal MemWrite: MemWrite_array;
    signal instructionAddress : std_logic_vector(31 downto 0);
    signal dataAddress, data_i, data_o : Data_array;
    signal instruction : std_logic_vector(63 downto 0);
    signal uins: Microinstruction;

    constant INSTRUCTION_OFFSET    : std_logic_vector(31 downto 0) := x"00400000";
    constant DATA_OFFSET           : std_logic_vector(31 downto 0) := x"10010000";

    constant DATA_WIDTH : integer := 32;
    constant INST_WIDTH : integer := 64;
    
    -- component RISCV_SUPERSCALAR : DUV
    component RISCV_SUPERSCALAR
        generic (
            PC_START_ADDRESS    : integer := 4194304;
            DATA_WIDTH          : integer := 32;
            INST_WIDTH          : integer := 64     
        );
        port (
            clock               : in std_logic;
            reset               : in std_logic;
            
            -- instruction memory interface
            instructionAddress  : out std_logic_vector(DATA_WIDTH-1 downto 0);
            instruction         : in std_logic_vector(INST_WIDTH-1 downto 0);
            
            -- data memory interface
            dataAddress         : out std_logic_vector(DATA_WIDTH-1 downto 0);
            data_i              : in  Data_array;
            data_o              : out Data_array;
            MemWrite            : out MemWrite_array
        );
    end component;

    component Memory is
        generic (
            SIZE            : integer := 32;       -- Memory depth
            DATA_WIDTH      : integer := 32;       -- Data size
            START_ADDRESS   : std_logic_vector(31 downto 0) := (others=>'0');    -- Address to be mapped to address 0x00000000
            imageFileName   : string := "UNUSED"   -- Memory content to be loaded
        );
        port (  
            clock           : in std_logic;
            MemWrite        : in std_logic;
            address         : in std_logic_vector (31 downto 0);
            data_i          : in std_logic_vector (DATA_WIDTH-1 downto 0);
            data_o          : out std_logic_vector (DATA_WIDTH-1 downto 0)
        );
    end component;

    component Memory_2_ports is
        generic (
            SIZE            : integer := 32;       -- Memory depth
            DATA_WIDTH      : integer := 32;
            START_ADDRESS   : std_logic_vector(31 downto 0) := (others=>'0');    -- Address to be mapped to address 0x00000000
            imageFileName   : string := "UNUSED"   -- Memory content to be loaded
        );
        port (  
            clock           : in std_logic;
            MemWrite        : in MemWrite_array;
            address         : in Data_array;
            data_i          : in Data_array;
            data_o          : out Data_array
        );
    end component;

begin

    clock <= not clock after 5 ns;
    
    reset <= '1', '0' after 7 ns;
                
    -- DUV component instance for RISCV_SUPERSCALAR
    DUV: RISCV_SUPERSCALAR
        generic map (
            PC_START_ADDRESS => TO_INTEGER(UNSIGNED(INSTRUCTION_OFFSET)),
            DATA_WIDTH => DATA_WIDTH,
            INST_WIDTH => INST_WIDTH
        )
        port map (
            clock               => clock,
            reset               => reset,
            
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
            DATA_WIDTH      => INST_WIDTH, -- 64 bits (2 instructions) 
            START_ADDRESS   => INSTRUCTION_OFFSET,         
            imageFileName   => "BubbleSort_code.txt"
        )
        port map (
            clock           => clock,
            MemWrite        => '0',
            address         => instructionAddress,    
            data_i          => (others=>'0'),
            data_o          => instruction
        );
        
    -- data memory instance
    DATA_MEMORY: Memory_2_ports
        generic map (
            SIZE            => 100,                 
            DATA_WIDTH      => DATA_WIDTH, -- 32 bits
            START_ADDRESS   => DATA_OFFSET,     
            imageFileName   => "BubbleSort_data.txt"
        )
        port map (
            clock           => clock,
            MemWrite        => MemWrite,
            address         => dataAddress,    
            data_i          => data_o,
            data_o          => data_i
        );  
    
end structural;

