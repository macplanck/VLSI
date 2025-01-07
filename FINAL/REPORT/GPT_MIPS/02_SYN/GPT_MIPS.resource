 
****************************************
Report : resources
Design : GPT_MIPS
Version: R-2020.09
Date   : Tue Jan  7 20:39:55 2025
****************************************


Resource Report for this hierarchy in file
        /mnt/newNAS/home/UnderGraduate2/2024/macplanck/VLSI/GPT_MIPS_V2/02_SYN/GPT_MIPS.sv
=============================================================================
| Cell           | Module         | Parameters | Contained Operations       |
=============================================================================
| add_x_2        | DW01_add       | width=32   | m_Adder_1/add_11 (Adder.sv:11) |
| ne_x_20        | DW_cmp         | width=32   | m_ALU/ne_43 (ALU.sv:43)    |
| gte_x_21       | DW_cmp         | width=32   | m_ALU/gte_53 (ALU.sv:53)   |
| add_x_24       | DW01_add       | width=32   | m_Adder_2/add_11 (Adder.sv:11) |
| eq_x_26        | DW_cmp         | width=32   | m_ALU/eq_18 (ALU.sv:18)    |
|                |                |            | m_ALU/eq_23 (ALU.sv:23)    |
|                |                |            | m_ALU/eq_28 (ALU.sv:28)    |
|                |                |            | m_ALU/eq_33 (ALU.sv:33)    |
|                |                |            | m_ALU/eq_38 (ALU.sv:38)    |
| lt_x_27        | DW_cmp         | width=32   | m_ALU/lt_37 (ALU.sv:37)    |
|                |                |            | m_ALU/lt_48 (ALU.sv:48)    |
| DP_OP_70_125_5391               |            |                            |
|                | DP_OP_70_125_5391 |         |                            |
=============================================================================

Datapath Report for DP_OP_70_125_5391
==============================================================================
| Cell                 | Contained Operations                                |
==============================================================================
| DP_OP_70_125_5391    | m_ALU/add_27 (ALU.sv:27) m_ALU/add_42 (ALU.sv:42)   |
|                      | m_ALU/add_47 (ALU.sv:47) m_ALU/add_52 (ALU.sv:52)   |
|                      | m_ALU/add_57 (ALU.sv:57) m_ALU/sub_32 (ALU.sv:32)   |
==============================================================================

==============================================================================
|       |      | Data     |       |                                          |
| Var   | Type | Class    | Width | Expression                               |
==============================================================================
| I1    | PI   | Signed   | 32    |                                          |
| I2    | PI   | Signed   | 32    |                                          |
| I3    | PI   | Unsigned | 1     |                                          |
| O1    | PO   | Signed   | 32    | addsub(I1,I2,I3) ( ALU.sv:27 ALU.sv:32 ALU.sv:42 ALU.sv:47 ALU.sv:52 ALU.sv:57 ) |
==============================================================================


Implementation Report
===============================================================================
|                    |                  | Current            | Set            |
| Cell               | Module           | Implementation     | Implementation |
===============================================================================
| add_x_2            | DW01_add         | pparch (area,speed)                 |
| ne_x_20            | DW_cmp           | apparch (area)     |                |
| gte_x_21           | DW_cmp           | pparch (area,speed)                 |
| add_x_24           | DW01_add         | pparch (area,speed)                 |
| eq_x_26            | DW_cmp           | apparch (area)     |                |
| lt_x_27            | DW_cmp           | pparch (area,speed)                 |
| DP_OP_70_125_5391  | DP_OP_70_125_5391 | str (area,speed)  |                |
===============================================================================

1
