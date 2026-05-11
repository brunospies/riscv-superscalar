-------------------------------------------------------------------------
-- Design unit: Memory 2 ports
-- Description: Parametrizable 32 bits word memory
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all; 
use std.textio.all;


entity Memory_2_ports is
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
end Memory_2_ports;


architecture behavioral of Memory_2_ports is

    -- Word addressed memory
    type Memory is array (0 to SIZE) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal memoryArray: Memory;
    
    signal wordAddress_0, wordAddress_1, mappedAddress_0, mappedAddress_1: std_logic_vector(31 downto 0);

begin
        
    mappedAddress_0 <= STD_LOGIC_VECTOR(UNSIGNED(address_0) - UNSIGNED(START_ADDRESS));
    mappedAddress_1 <= STD_LOGIC_VECTOR(UNSIGNED(address_1) - UNSIGNED(START_ADDRESS));
    
    -- Converts byte address in word address
    --wordAddress <= "00" & address(31 downto 2);
    wordAddress_0 <= "00" & mappedAddress_0(31 downto 2);
    wordAddress_1 <= "00" & mappedAddress_1(31 downto 2);
        
    -- Memory read
    data_o_0 <= memoryArray(TO_INTEGER(UNSIGNED(wordAddress_0))) when UNSIGNED(wordAddress_0) < SIZE else (others=>'U');
    data_o_1 <= memoryArray(TO_INTEGER(UNSIGNED(wordAddress_1))) when UNSIGNED(wordAddress_1) < SIZE else (others=>'U');

    -- Process to load the memory array and control the memory writing
    process(clock)
        variable memoryLoaded: boolean := false;    -- Indicates if the memory was already loaded
    begin      
        if rising_edge(clock) then    -- Memory writing        
            if MemWrite_0(0) = '1' and MemWrite_1(0) = '1' then
                if UNSIGNED(wordAddress_0) < SIZE and UNSIGNED(wordAddress_1) < SIZE then
                    memoryArray(TO_INTEGER(UNSIGNED(wordAddress_0))) <= data_i_0;
                    memoryArray(TO_INTEGER(UNSIGNED(wordAddress_1))) <= data_i_1;

                else
                    report "******************* MEMORY WRITE (0 OR 1) OUT OF BOUNDS *************"
                    severity error;
                end if;
            elsif MemWrite_0(0) = '1' and MemWrite_1(0) = '0' then
                if UNSIGNED(wordAddress_0) < SIZE then
                    memoryArray(TO_INTEGER(UNSIGNED(wordAddress_0))) <= data_i_0;

                else
                    report "******************* MEMORY WRITE 0 OUT OF BOUNDS *************"
                    severity error;
                end if;
            elsif MemWrite_0(0) = '0' and MemWrite_1(0) = '1' then
                if UNSIGNED(wordAddress_1) < SIZE then
                    memoryArray(TO_INTEGER(UNSIGNED(wordAddress_1))) <= data_i_1;

                else
                    report "******************* MEMORY WRITE 1 OUT OF BOUNDS *************"
                    severity error;
                end if;
            end if;
        end if;
        
    end process;
        
end behavioral;