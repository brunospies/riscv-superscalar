-------------------------------------------------------------------------
-- Design unit: Memory
-- Description: Parametrizable 32 bits word memory
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all; 
use std.textio.all;


entity Memory is
    generic (
        SIZE            : integer := 32;       -- Memory depth
        DATA_WIDTH      : integer := 32;
        INST_WIDTH      : integer := 64;
        START_ADDRESS   : std_logic_vector(31 downto 0) := (others=>'0')    -- Address to be mapped to address 0x00000000
    );
    port (  
        clock           : in std_logic;
        MemWrite        : in std_logic_vector(3 downto 0);
        address         : in std_logic_vector  (31 downto 0);
        data_i          : in std_logic_vector  (DATA_WIDTH-1 downto 0);
        data_o          : out std_logic_vector (INST_WIDTH-1 downto 0)
    );
end Memory;


architecture behavioral of Memory is

    -- Word addressed memory
    type Memory is array (0 to SIZE) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal memoryArray: Memory;
   
    signal wordAddress, mappedAddress: std_logic_vector(31 downto 0);

begin
        
    mappedAddress <= STD_LOGIC_VECTOR(UNSIGNED(address) - UNSIGNED(START_ADDRESS));
    
    -- Converts byte address in word address
    --wordAddress <= "00" & address(31 downto 2);
    wordAddress <= "00" & mappedAddress(31 downto 2); -- word address = 32 bits = 4 bytes : mapped/4
        
    -- Memory read
    data_o(31 downto 0)  <= memoryArray(TO_INTEGER(UNSIGNED(wordAddress))) when UNSIGNED(wordAddress) < SIZE else (others=>'U');
    data_o(63 downto 32) <= memoryArray(TO_INTEGER(UNSIGNED(wordAddress) + TO_UNSIGNED(1,32))) when (UNSIGNED(wordAddress) + TO_UNSIGNED(1,32)) < SIZE else (others=>'U');

    -- Process to load the memory array and control the memory writing
    process(clock)
        --variable memoryLoaded: boolean := false;    -- Indicates if the memory was already loaded
    begin        
        
        if rising_edge(clock) then    -- Memory writing        
            if MemWrite(0) = '1' then
                if UNSIGNED(wordAddress) < SIZE then
                    memoryArray(TO_INTEGER(UNSIGNED(wordAddress))) <= data_i;
                else
                    report "******************* MEMORY WRITE OUT OF BOUNDS *************"
                    severity error;
                end if;
            end if;
        end if;
        
    end process;
        
end behavioral;