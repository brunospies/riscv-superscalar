-------------------------------------------------------------------------
-- Design unit: Hazard Detection Unit
-- Description: Detect data dependency with lw and the next instruction and
-- generates a bubble.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 


entity HazardDetection_unit is
    generic (
        ISSUE_WIDTH         : natural := 2
    );
    port ( 
        rs2_ID                : in  Reg_array;
        rs1_ID                : in  Reg_array;
        rd_EX                 : in  Reg_array; -- Hazard [ID] add x3, x3, x4; [EX] lw x4, 0(x6) -> stall ID creates bubble EX
        rd_MEM                : in  Reg_array; -- Hazard [ID] beq x3, x4, END; [MEM] lw x4, 0(x6) -> stall ID creates bubble EX
        format_INS_ID_0       : in  Instruction_format;
        format_INS_ID_1       : in  Instruction_format;
        MemToReg_EX_0         : in  std_logic;
        MemToReg_EX_1         : in  std_logic;
        MemToReg_MEM_0        : in  std_logic;
        MemToReg_MEM_0        : in  std_logic;
        ce_pc                 : out std_logic;
        ce_stage_ID           : out std_logic_vector(1 downto 0);
        bubble_hazard_EX      : out std_logic_vector(1 downto 0)
    );
end HazardDetection_unit;

architecture arch1 of HazardDetection_unit is

signal ce : std_logic_vector(1 downto 0);

begin

    
    ce <= '0' when (MemToReg_EX_0  = '1' and (rd_EX(0)  = rs1_ID(0) or rd_EX(0)  = rs2_ID(0))) or                            -- Hazard INS_ID[0] -> INS_EX[0]
                   (MemToReg_EX_1  = '1' and (rd_EX(1)  = rs1_ID(0) or rd_EX(1)  = rs2_ID(0))) or                            -- Hazard INS_ID[0] -> INS_EX[1]
                   (MemToReg_MEM_0 = '1' and (rd_MEM(0) = rs1_ID(0) or rd_MEM(0) = rs2_ID(0)) and format_INS_ID_0 = B) or    -- Hazard INS_ID[0] -> INS_MEM[0] [BRANCH]
                   (MemToReg_MEM_1 = '1' and (rd_MEM(1) = rs1_ID(0) or rd_MEM(1) = rs2_ID(0)) and format_INS_ID_0 = B) or    -- Hazard INS_ID[0] -> INS_MEM[1] [BRANCH]
                   (MemToReg_EX_0  = '1' and (rd_EX(0)  = rs1_ID(1) or rd_EX(0)  = rs2_ID(1))) or                            -- Hazard INS_ID[1] -> INS_EX[0]
                   (MemToReg_EX_1  = '1' and (rd_EX(1)  = rs1_ID(1) or rd_EX(1)  = rs2_ID(1))) or                            -- Hazard INS_ID[1] -> INS_EX[1]
                   (MemToReg_MEM_0 = '1' and (rd_MEM(0) = rs1_ID(1) or rd_MEM(0) = rs2_ID(1)) and format_INS_ID_1 = B) or    -- Hazard INS_ID[1] -> INS_MEM[0] [BRANCH]
                   (MemToReg_MEM_1 = '1' and (rd_MEM(1) = rs1_ID(1) or rd_MEM(1) = rs2_ID(1)) and format_INS_ID_1 = B) else  -- Hazard INS_ID[1] -> INS_MEM[1] [BRANCH]
          '1';
        
    ce_pc <= ce;
    ce_stage_ID <= ce;

    bubble_hazard_EX <= not ce;
            
end arch1;