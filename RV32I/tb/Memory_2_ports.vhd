-------------------------------------------------------------------------
-- Design unit: Memory
-- Description: Parametrizable 32 bits word memory
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all; 
use std.textio.all;
use work.Util_package.all;


entity Memory_2_ports is
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
end Memory_2_ports;


architecture behavioral of Memory_2_ports is

    -- Word addressed memory
    type Memory is array (0 to SIZE) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal memoryArray: Memory;
        
    
    ----------------------------------------------------------------------------
    -- This procedure loads the memory array with the specified file in 
    -- the following format
    --
    --
    --      Address    Code        Basic                  Source
    --
    --    0x00400000  0x014b4820  add $9,$10,$11    4  add $t1, $t2, $t3
    --    0x00400004  0x016a4822  sub $9,$11,$10    5  sub $t1, $t3, $t2    
    --    0x00400008  0x014b4824  and $9,$10,$11    6  and $t1, $t2, $t3
    --    0x0040000c  0x014b4825  or $9,$10,$11     7  or  $t1, $t2, $t3
    --    ...
    ----------------------------------------------------------------------------


    function MemoryLoad(imageFileName: in string) return Memory is
        
        file imageFile : TEXT open READ_MODE is imageFileName;
        variable memoryArray: Memory;
        variable fileLine    : line;                -- Stores a read line from a text file
        variable str         : string(1 to 8);      -- Stores an 8 characters string
        variable char        : character;           -- Stores a single character
        variable bool        : boolean;             
        variable address     : std_logic_vector(31 downto 0);
        variable data        : std_logic_vector(DATA_WIDTH-1 downto 0);
                
        begin
        
            while NOT (endfile(imageFile)) loop    -- Main loop to read the file
                
                -- Read a file line into 'fileLine'
                readline(imageFile, fileLine);    
                
                -- Verifies if the line contains address and code.
                -- Such lines start with "0x"
                if fileLine'length > 2 and fileLine(1 to 2) = "0x" then
                
                    -- Read '0' and 'x'
                    read(fileLine, char, bool);
                    read(fileLine, char, bool);
                    
                    -- Read the address character by character and stores in 'str'
                    for i in 1 to 8 loop
                        read(fileLine, char, bool);
                        str(i) := char;
                    end loop;
                    
                    
                    -- Converts the string address 'str' to std_logic_vector
                    address := StringToStdLogicVector(str);
                    
                    -- Sets the real address
                    address := STD_LOGIC_VECTOR(UNSIGNED(address) - UNSIGNED(START_ADDRESS));
                    
                                    
                    -- Read the 2 blanks between address and code
                    read(fileLine, char, bool);
                    read(fileLine, char, bool);
                    
                    
                    -- Read '0' and 'x'
                    read(fileLine, char, bool);
                    read(fileLine, char, bool);
                    
                    -- Read the code/data character by character and stores in 'str'
                    for i in 1 to 8 loop
                        read(fileLine, char, bool);
                        str(i) := char;
                    end loop;
                    
                    -- Converts the string code/data 'str' to std_logic_vector
                    data := StringToStdLogicVector(str);
                    
                    -- Converts the byte address to word address
                    address := "00" & address(31 downto 2);
                    
                    -- Stores the 'data' into the memoryArray
                    memoryArray(TO_INTEGER(UNSIGNED(address))) := data;
                    
                end if;
            end loop;
            
            return memoryArray;
            
    end MemoryLoad;
    
    signal wordAddress, mappedAddress: Data_array;

begin
        
    mappedAddress(0) <= STD_LOGIC_VECTOR(UNSIGNED(address(0)) - UNSIGNED(START_ADDRESS));
    mappedAddress(1) <= STD_LOGIC_VECTOR(UNSIGNED(address(1)) - UNSIGNED(START_ADDRESS));
    
    -- Converts byte address in word address
    --wordAddress <= "00" & address(31 downto 2);
    wordAddress(0) <= "00" & mappedAddress(0)(31 downto 2);
    wordAddress(1) <= "00" & mappedAddress(1)(31 downto 2);
        
    -- Memory read
    data_o(0) <= memoryArray(TO_INTEGER(UNSIGNED(wordAddress(0)))) when UNSIGNED(wordAddress(0)) < SIZE else (others=>'U');
    data_o(1) <= memoryArray(TO_INTEGER(UNSIGNED(wordAddress(1)))) when UNSIGNED(wordAddress(1)) < SIZE else (others=>'U');

    -- Process to load the memory array and control the memory writing
    process(clock)
        variable memoryLoaded: boolean := false;    -- Indicates if the memory was already loaded
    begin        
        if not memoryLoaded then
            if imageFileName /= "UNUSED" then                
                memoryArray <= MemoryLoad(imageFileName);
            end if;
             
             memoryLoaded := true;
        end if;
        
        if rising_edge(clock) then    -- Memory writing        
            if MemWrite(0)(0) = '1' and MemWrite(1)(0) = '1' then
                if UNSIGNED(wordAddress(0)) < SIZE and UNSIGNED(wordAddress(1)) < SIZE then
                    memoryArray(TO_INTEGER(UNSIGNED(wordAddress(0)))) <= data_i(0);
                    memoryArray(TO_INTEGER(UNSIGNED(wordAddress(1)))) <= data_i(1);

                else
                    report "******************* MEMORY WRITE (0 OR 1) OUT OF BOUNDS *************"
                    severity error;
                end if;
            elsif MemWrite(0)(0) = '1' and MemWrite(1)(0) = '0' then
                if UNSIGNED(wordAddress(0)) < SIZE then
                    memoryArray(TO_INTEGER(UNSIGNED(wordAddress(0)))) <= data_i(0);

                else
                    report "******************* MEMORY WRITE (0) OUT OF BOUNDS *************"
                    severity error;
                end if;
            elsif MemWrite(0)(0) = '0' and MemWrite(1)(0) = '1' then
                if UNSIGNED(wordAddress(1)) < SIZE then
                    memoryArray(TO_INTEGER(UNSIGNED(wordAddress(1)))) <= data_i(1);

                else
                    report "******************* MEMORY WRITE (1) OUT OF BOUNDS *************"
                    severity error;
                end if;
            end if;
        end if;
        
    end process;
        
end behavioral;