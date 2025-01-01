`timescale 1ns / 1ps
`include "MIPS.sv"
`define PATNUM   32
`define INSTRNUM 32
`define MEM_NUM  128
`define REG_NUM  32


module PATTERN;

integer patcount;
integer input_gap;
integer i;

integer FILE_IN;
integer FILE_TMP;

parameter OP_JAL  = 6'b001111;
parameter OP_JR   = 6'b000000;
parameter func_JR = 6'b000001;


logic clk;
logic rst_n;

always #5 clk = ~clk;


// Pattern Answer
reg [32-1:0] reg_file  [`REG_NUM-1:0];
reg [ 8-1:0] mem_file  [`MEM_NUM-1:0];

reg [32-1:0] instruction;
reg [32-1:0] program_cnt;
reg [32-1:0] RegDst_addr;
reg [32-1:0] RegDst_data;

reg [32-1:0] pc_jump_dst;

// CPU Answer
reg [32-1:0] cpu_instruction;
reg [32-1:0] cpu_program_cnt;
reg [32-1:0] cpu_RegDst_addr;
reg [32-1:0] cpu_RegDst_data;


// Temporary
reg [32-1:0] Reg_Rand;


MIPS CPU(
    .clk_i(clk),
    .rst_n(rst_n)
);


initial begin

    reset_task;
    init_RF;

    for(patcount = 1; patcount < `PATNUM; patcount += 1) begin
        get_output;
        check_ans;
        pass_ans;
    end

    YOU_PASS_task;
    $finish;

end



task reset_task; begin

    // reset with reset rst_n
	// force clk = 0;
	// #(0.5); rst_n = 0;
	// #(1.0); rst_n = 1;
	// #(3.0); release clk;

    // sychronize reset ??
	force clk = 0; #(1); release clk;
	input_gap = $urandom_range(1,4); 
    repeat(input_gap) @(negedge clk);
    @(negedge clk); rst_n = 0; 
    @(negedge clk); rst_n = 1;


    // reset answer
    for (i = 0; i < `MEM_NUM ; i = i + 1)  CPU.DM.Mem[i] = 8'b0;
    for (i = 0; i < `MEM_NUM ; i = i + 1)  mem_file[i] = 8'b0;
    for (i = 0; i < `REG_NUM ; i = i + 1)  reg_file[i] = $urandom_range(0, ~32'd0);

    reg_file[29] = 32'd128;  //stack pointer
    reg_file[31] = 32'd0;
    reg_file[ 0] = 32'd0;

    // read instructions 
    $readmemb("../00_TESTBED/testcases/test_5.txt", CPU.IM.Instr_Mem);

end endtask


task init_RF; begin

    // Update CPU's register file with random
    force CPU.PC.pc_out_o = 4; @(negedge clk);

    for(i = 1; i < `REG_NUM-1; i += 1) begin
        force CPU.RF.RDdata_i = reg_file[i];
        force CPU.RF.RDaddr_i = i;
        force CPU.RF.RegWrite_i = 1;

        @(negedge clk);
        release CPU.RF.RegWrite_i;
        release CPU.RF.RDdata_i;
        release CPU.RF.RDaddr_i;
    end

    @(negedge clk);
    release CPU.PC.pc_out_o;

end endtask


task get_output; begin

    program_cnt = patcount << 2;
    instruction = CPU.IM.Instr_Mem[patcount];

    cpu_instruction = CPU.IM.instr_o;
    cpu_program_cnt = CPU.PC.pc_in_i;
    cpu_RegDst_addr = CPU.RF.RDaddr_i;
    cpu_RegDst_data = CPU.RF.RDdata_i;

end endtask


task check_ans; begin

    if(instruction !== cpu_instruction) begin
        fail;
        $display ("-------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                         Instruction fail!                						                    ");
        $display ("                                                    CPU gets wrong instruction !         						                    ");
        $display ("-------------------------------------------------------------------------------------------------------------------------------------");
        $finish;
    end

    else if(instruction[31:26] == OP_JR & instruction[5:0] == func_JR) check_jr;
    else if(instruction[31:26] == OP_JAL) check_jal;

    else begin
        fail;
        $display ("-------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                         Instruction fail!                						                    ");
        $display ("                                                    Wrong input format of Testcases !         						                ");
        $display ("-------------------------------------------------------------------------------------------------------------------------------------");
        $finish;
    end


end endtask


task check_jal; begin

    pc_jump_dst = {program_cnt[31:28], instruction[25:0], 2'd0};

    if(cpu_program_cnt !== pc_jump_dst | cpu_RegDst_data !== (program_cnt + 4) | cpu_RegDst_addr !== 31) begin
        fail;
        $display ("-------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                         Instruction Jal fail!                						                ");
        $display ("                                                                                                             						");
        $display ("                                Pattern ans                                                   						                ");
        $display ("                                    Instruction: %b {%b, %d}                                                   						", instruction, instruction[31:26], instruction[25:0]);
        $display ("                                    jump destination: %b (%d)                                                   						", pc_jump_dst, $signed(pc_jump_dst));
        $display ("                                    saved PC: %d                                                             						", program_cnt + 4);
        $display ("                                                                                                             						");
        $display ("                                Your ans                                                       						                ");
        $display ("                                    jump destination: %b (%d)                                                   						", cpu_program_cnt, $signed(cpu_program_cnt));
        $display ("                                    saved PC addr: $%d                                                          						", cpu_RegDst_addr);
        $display ("                                    saved PC data:  %d                                                          						", cpu_RegDst_data);
        $display ("                                                                                                             						");
        $display ("-------------------------------------------------------------------------------------------------------------------------------------");
        $finish;
    end

    @(negedge clk);
    reg_file[31] = program_cnt + 4;
    force CPU.PC.pc_out_o = program_cnt + 4;

    @(negedge clk);
    release CPU.PC.pc_out_o;

end endtask


task check_jr; begin

    pc_jump_dst = reg_file[instruction[25:21]];

    if(cpu_program_cnt !== pc_jump_dst) begin
        fail;
        $display ("-------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                         Instruction Jr fail!                                                        ");
        $display ("                                                                                                             						");
        $display ("                                Instruction:   %b {%b, %d, %b} ", instruction, instruction[31:26], instruction[25:21], instruction[5:0]);
        $display ("                                Pattern Dst:   %b (%d)       ", pc_jump_dst, $signed(pc_jump_dst));
        $display ("                                Your    Dst:   %b (%d)       ", cpu_program_cnt, $signed(cpu_program_cnt));
        $display ("-------------------------------------------------------------------------------------------------------------------------------------");
        $finish;
    end

    @(negedge clk);
    force CPU.PC.pc_out_o = program_cnt + 4;

    @(negedge clk);
    release CPU.PC.pc_out_o;

end endtask




task YOU_PASS_task;begin
$display("\033[31m                                                                                                                                          ");        
$display("\033[31m                                                                                \033[36m      :BBQvi.                                              ");        
$display("\033[31m                                                              .i7ssrvs7         \033[36m     BBBBBBBBQi                                           ");        
$display("\033[31m                        .:r7rrrr:::.        .::::::...   .i7vr:.      .B:       \033[36m    :BBBP :7BBBB.                                         ");        
$display("\033[31m                      .Kv.........:rrvYr7v7rr:.....:rrirJr.   .rgBBBBg  Bi      \033[36m    BBBB     BBBB                                         ");        
$display("\033[31m                     7Q  :rubEPUri:.       ..:irrii:..    :bBBBBBBBBBBB  B      \033[36m   iBBBv     BBBB       vBr                               ");        
$display("\033[31m                    7B  BBBBBBBBBBBBBBB::BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB :R     \033[36m   BBBBBKrirBBBB.     :BBBBBB:                            ");        
$display("\033[31m                   Jd .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: Bi    \033[36m  rBBBBBBBBBBBR.    .BBBM:BBB                             ");        
$display("\033[31m                  uZ .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB .B    \033[36m  BBBB   .::.      EBBBi :BBU                             ");        
$display("\033[31m                 7B .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  B    \033[36m MBBBr           vBBBu   BBB.                             ");        
$display("\033[31m                .B  BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: JJ   \033[36m i7PB          iBBBBB.  iBBB                              ");        
$display("\033[31m                B. BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  Lu             \033[36m  vBBBBPBBBBPBBB7       .7QBB5i                ");        
$display("\033[33m               Y1 KBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBi XBBBBBBBi :B            \033[36m :RBBB.  .rBBBBB.      rBBBBBBBB7              ");        
$display("\033[33m              :B .BBBBBBBBBBBBBsRBBBBBBBBBBBrQBBBBB. UBBBRrBBBBBBr 1BBBBBBBBB  B.          \033[36m    .       BBBB       BBBB  :BBBB             ");        
$display("\033[33m              Bi BBBBBBBBBBBBBi :BBBBBBBBBBE .BBK.  .  .   QBBBBBBBBBBBBBBBBBB  Bi         \033[36m           rBBBr       BBBB    BBBU            ");        
$display("\033[33m             .B .BBBBBBBBBBBBBBQBBBBBBBBBBBB       \033[38;2;242;172;172mBBv \033[33m.LBBBBBBBBBBBBBBBBBBBBBB. B7.:ii:   \033[36m           vBBB        .BBBB   :7i.            ");        
$display("\033[33m            .B  PBBBBBBBBBBBBBBBBBBBBBBBBBBBBbYQB. \033[38;2;242;172;172mBB: \033[33mBBBBBBBBBBBBBBBBBBBBBBBBB  Jr:::rK7 \033[36m             .7  BBB7   iBBBg                  ");        
$display("\033[33m           7M  PBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  \033[38;2;242;172;172mBB. \033[33mBBBBBBBBBBBBBBBBBBBBBBB..i   .   v1                  \033[36mdBBB.   5BBBr                 ");        
$display("\033[33m          sZ .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  \033[38;2;242;172;172mBB. \033[33mBBBBBBBBBBBBBBBBBBBBBBBBBBB iD2BBQL.                 \033[36m ZBBBr  EBBBv     YBBBBQi     ");        
$display("\033[33m  .7YYUSIX5 .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  \033[38;2;242;172;172mBB. \033[33mBBBBBBBBBBBBBBBBBBBBBBBBY.:.      :B                 \033[36m  iBBBBBBBBD     BBBBBBBBB.   ");        
$display("\033[33m LB.        ..BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB. \033[38;2;242;172;172mBB: \033[33mBBBBBBBBBBBBBBBBBBBBBBBBMBBB. BP17si                 \033[36m    :LBBBr      vBBBi  5BBB   ");        
$display("\033[33m  KvJPBBB :BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: \033[38;2;242;172;172mZB: \033[33mBBBBBBBBBBBBBBBBBBBBBBBBBsiJr .i7ssr:                \033[36m          ...   :BBB:   BBBu  ");        
$display("\033[33m i7ii:.   ::BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBj \033[38;2;242;172;172muBi \033[33mQBBBBBBBBBBBBBBBBBBBBBBBBi.ir      iB                \033[36m         .BBBi   BBBB   iMBu  ");        
$display("\033[32mDB    .  vBdBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBg \033[38;2;242;172;172m7Bi \033[32mBBBBBBBBBBBBBBBBBBBBBBBBBBBBB rBrXPv.                \033[36m          BBBX   :BBBr        ");        
$display("\033[32m :vQBBB. BQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQ \033[38;2;242;172;172miB: \033[32mBBBBBBBBBBBBBBBBBBBBBBBBBBBBB .L:ii::irrrrrrrr7jIr   \033[36m          .BBBv  :BBBQ        ");        
$display("\033[32m :7:.   .. 5BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  \033[38;2;242;172;172mBr \033[32mBBBBBBBBBBBBBBBBBBBBBBBBBBBB:            ..... ..YB. \033[36m           .BBBBBBBBB:        ");        
$display("\033[32mBU  .:. BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  \033[38;2;242;172;172mB7 \033[32mgBBBBBBBBBBBBBBBBBBBBBBBBBB. gBBBBBBBBBBBBBBBBBB. BL \033[36m             rBBBBB1.         ");        
$display("\033[32m rY7iB: BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: \033[38;2;242;172;172mB7 \033[32mBBBBBBBBBBBBBBBBBBBBBBBBBB. QBBBBBBBBBBBBBBBBBi  v5                                ");        
$display("\033[32m     us EBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB \033[38;2;242;172;172mIr \033[32mBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBgu7i.:BBBBBBBr Bu                                 ");        
$display("\033[32m      B  7BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB.\033[38;2;242;172;172m:i \033[32mBBBBBBBBBBBBBBBBBBBBBBBBBBBv:.  .. :::  .rr    rB                                  ");        
$display("\033[32m      us  .BBBBBBBBBBBBBQLXBBBBBBBBBBBBBBBBBBBBBBBBq  .BBBBBBBBBBBBBBBBBBBBBBBBBv  :iJ7vri:::1Jr..isJYr                                   ");        
$display("\033[32m      B  BBBBBBB  MBBBM      qBBBBBBBBBBBBBBBBBBBBBB: BBBBBBBBBBBBBBBBBBBBBBBBBB  B:           iir:                                       ");        
$display("\033[34m     iB iBBBBBBBL       BBBP. :BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  B.                                                       ");        
$display("\033[34m     P: BBBBBBBBBBB5v7gBBBBBB  BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: Br                                                        ");        
$display("\033[34m     B  BBBs 7BBBBBBBBBBBBBB7 :BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB .B                                                         ");        
$display("\033[34m    .B :BBBB.  EBBBBBQBBBBBJ .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB. B.                                                         ");        
$display("\033[34m    ij qBBBBBg          ..  .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB .B                                                          ");        
$display("\033[34m    UY QBBBBBBBBSUSPDQL...iBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBK EL                                                          ");        
$display("\033[34m    B7 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: B:                                                          ");        
$display("\033[34m    B  BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBYrBB vBBBBBBBBBBBBBBBBBBBBBBBB. Ls                                                          ");        
$display("\033[34m    B  BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBi_  /UBBBBBBBBBBBBBBBBBBBBBBBBB. :B:                                                        ");        
$display("\033[35m   rM .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  ..IBBBBBBBBBBBBBBBBQBBBBBBBBBB  B                                                        ");        
$display("\033[35m   B  BBBBBBBBBdZBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBPBBBBBBBBBBBBEji:..     sBBBBBBBr Br                                                       ");        
$display("\033[35m  7B 7BBBBBBBr     .:vXQBBBBBBBBBBBBBBBBBBBBBBBBBQqui::..  ...i:i7777vi  BBBBBBr Bi                                                       ");        
$display("\033[35m  Ki BBBBBBB  rY7vr:i....  .............:.....  ...:rii7vrr7r:..      7B  BBBBB  Bi                                                       ");        
$display("\033[35m  B. BBBBBB  B:    .::ir77rrYLvvriiiiiiirvvY7rr77ri:..                 bU  iQBB:..rI                                                      ");        
$display("\033[35m.S: 7BBBBP  B.                                                          vI7.  .:.  B.                                                     ");        
$display("\033[35mB: ir:.   :B.                                                             :rvsUjUgU.                                                      ");        
$display("\033[35mrMvrrirJKur                                                                                                                               \033[m");
$display ("-------------------------------------------------------------------------------------------------------------------------------------");
$display ("                                                         Congratulations!                						                    ");
$display ("                                                   You have passed all patterns!          						                    ");
$display ("-------------------------------------------------------------------------------------------------------------------------------------");

end endtask

task fail; begin
$display("\033[38;2;252;238;238m                                                                                                                                           ");      
$display("\033[38;2;252;238;238m                                                                                                :L777777v7.                                ");
$display("\033[31m  i:..::::::i.      :::::         ::::    .:::.       \033[38;2;252;238;238m                                       .vYr::::::::i7Lvi                             ");
$display("\033[31m  BBBBBBBBBBBi     iBBBBBL       .BBBB    7BBB7       \033[38;2;252;238;238m                                      JL..\033[38;2;252;172;172m:r777v777i::\033[38;2;252;238;238m.ijL                           ");
$display("\033[31m  BBBB.::::ir.     BBB:BBB.      .BBBv    iBBB:       \033[38;2;252;238;238m                                    :K: \033[38;2;252;172;172miv777rrrrr777v7:.\033[38;2;252;238;238m:J7                         ");
$display("\033[31m  BBBQ            :BBY iBB7       BBB7    :BBB:       \033[38;2;252;238;238m                                   :d \033[38;2;252;172;172m.L7rrrrrrrrrrrrr77v: \033[38;2;252;238;238miI.                       ");
$display("\033[31m  BBBB            BBB. .BBB.      BBB7    :BBB:       \033[38;2;252;238;238m                                  .B \033[38;2;252;172;172m.L7rrrrrrrrrrrrrrrrr7v..\033[38;2;252;238;238mBr                      ");
$display("\033[31m  BBBB:r7vvj:    :BBB   gBBs      BBB7    :BBB:       \033[38;2;252;238;238m                                  S:\033[38;2;252;172;172m v7rrrrrrrrrrrrrrrrrrr7v. \033[38;2;252;238;238mB:                     ");
$display("\033[31m  BBBBBBBBBB7    BBB:   .BBB.     BBB7    :BBB:       \033[38;2;252;238;238m                                 .D \033[38;2;252;172;172mi7rrrrrrr777rrrrrrrrrrr7v. \033[38;2;252;238;238mB.                    ");
$display("\033[31m  BBBB    ..    iBBBBBBBBBBBP     BBB7    :BBB:       \033[38;2;252;238;238m                                 rv\033[38;2;252;172;172m v7rrrrrr7rirv7rrrrrrrrrr7v \033[38;2;252;238;238m:I                    ");
$display("\033[31m  BBBB          BBBBi7vviQBBB.    BBB7    :BBB.       \033[38;2;252;238;238m                                 2i\033[38;2;252;172;172m.v7rrrrrr7i  :v7rrrrrrrrrrvi \033[38;2;252;238;238mB:                   ");
$display("\033[31m  BBBB         rBBB.      BBBQ   .BBBv    iBBB2ir777L7\033[38;2;252;238;238m                                 2i.\033[38;2;252;172;172mv7rrrrrr7v \033[38;2;252;238;238m:..\033[38;2;252;172;172mv7rrrrrrrrr77 \033[38;2;252;238;238mrX                   ");
$display("\033[31m .BBBB        :BBBB       BBBB7  .BBBB    7BBBBBBBBBBB\033[38;2;252;238;238m                                 Yv \033[38;2;252;172;172mv7rrrrrrrv.\033[38;2;252;238;238m.B \033[38;2;252;172;172m.vrrrrrrrrrrL.\033[38;2;252;238;238m:5                   ");
$display("\033[31m  . ..        ....         ...:   ....    ..   .......\033[38;2;252;238;238m                                 .q \033[38;2;252;172;172mr7rrrrrrr7i \033[38;2;252;238;238mPv \033[38;2;252;172;172mi7rrrrrrrrrv.\033[38;2;252;238;238m:S                   ");
$display("\033[38;2;252;238;238m                                                                                        Lr \033[38;2;252;172;172m77rrrrrr77 \033[38;2;252;238;238m:B. \033[38;2;252;172;172mv7rrrrrrrrv.\033[38;2;252;238;238m:S                   ");
$display("\033[38;2;252;238;238m                                                                                         B: \033[38;2;252;172;172m7v7rrrrrv. \033[38;2;252;238;238mBY \033[38;2;252;172;172mi7rrrrrrr7v \033[38;2;252;238;238miK                   ");
$display("\033[38;2;252;238;238m                                                                              .::rriii7rir7. \033[38;2;252;172;172m.r77777vi \033[38;2;252;238;238m7B  \033[38;2;252;172;172mvrrrrrrr7r \033[38;2;252;238;238m2r                   ");
$display("\033[38;2;252;238;238m                                                                       .:rr7rri::......    .     \033[38;2;252;172;172m.:i7s \033[38;2;252;238;238m.B. \033[38;2;252;172;172mv7rrrrr7L..\033[38;2;252;238;238mB                    ");
$display("\033[38;2;252;238;238m                                                        .::7L7rriiiirr77rrrrrrrr72BBBBBBBBBBBBvi:..  \033[38;2;252;172;172m.  \033[38;2;252;238;238mBr \033[38;2;252;172;172m77rrrrrvi \033[38;2;252;238;238mKi                    ");
$display("\033[38;2;252;238;238m                                                    :rv7i::...........    .:i7BBBBQbPPPqPPPdEZQBBBBBr:.\033[38;2;252;238;238m ii \033[38;2;252;172;172mvvrrrrvr \033[38;2;252;238;238mvs                     ");
$display("\033[38;2;252;238;238m                    .S77L.                      .rvi:. ..:r7QBBBBBBBBBBBgri.    .:BBBPqqKKqqqqPPPPPEQBBBZi  \033[38;2;252;172;172m:777vi \033[38;2;252;238;238mvI                      ");
$display("\033[38;2;252;238;238m                    B: ..Jv                   isi. .:rBBBBBQZPPPPqqqPPdERBBBBBi.    :BBRKqqqqqqqqqqqqPKDDBB:  \033[38;2;252;172;172m:7. \033[38;2;252;238;238mJr                       ");
$display("\033[38;2;252;238;238m                   vv SB: iu                rL: .iBBBQEPqqPPqqqqqqqqqqqqqPPPPbQBBB:   .EBQKqqqqqqPPPqqKqPPgBB:  .B:                        ");
$display("\033[38;2;252;238;238m                  :R  BgBL..s7            rU: .qBBEKPqqqqqqqqqqqqqqqqqqqqqqqqqPPPEBBB:   EBEPPPEgQBBQEPqqqqKEBB: .s                        ");
$display("\033[38;2;252;238;238m               .U7.  iBZBBBi :ji         5r .MBQqPqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPKgBB:  .BBBBBdJrrSBBQKqqqqKZB7  I:                      ");
$display("\033[38;2;252;238;238m              v2. :rBBBB: .BB:.ru7:    :5. rBQqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPPBB:  :.        .5BKqqqqqqBB. Kr                     ");
$display("\033[38;2;252;238;238m             .B .BBQBB.   .RBBr  :L77ri2  BBqPqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPbBB   \033[38;2;252;172;172m.irrrrri  \033[38;2;252;238;238mQQqqqqqqKRB. 2i                    ");
$display("\033[38;2;252;238;238m              27 :BBU  rBBBdB \033[38;2;252;172;172m iri::::: \033[38;2;252;238;238m.BQKqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqKRBs\033[38;2;252;172;172mirrr7777L: \033[38;2;252;238;238m7BqqqqqqqXZB. BLv772i              ");
$display("\033[38;2;252;238;238m               rY  PK  .:dPMB \033[38;2;252;172;172m.Y77777r.\033[38;2;252;238;238m:BEqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPPBqi\033[38;2;252;172;172mirrrrrv: \033[38;2;252;238;238muBqqqqqqqqqgB  :.:. B:             ");
$display("\033[38;2;252;238;238m                iu 7BBi  rMgB \033[38;2;252;172;172m.vrrrrri\033[38;2;252;238;238mrBEqKqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPQgi\033[38;2;252;172;172mirrrrv. \033[38;2;252;238;238mQQqqqqqqqqqXBb .BBB .s:.           ");
$display("\033[38;2;252;238;238m                i7 BBdBBBPqbB \033[38;2;252;172;172m.vrrrri\033[38;2;252;238;238miDgPPbPqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPQDi\033[38;2;252;172;172mirr77 \033[38;2;252;238;238m:BdqqqqqqqqqqPB. rBB. .:iu7         ");
$display("\033[38;2;252;238;238m                iX.:iBRKPqKXB.\033[38;2;252;172;172m 77rrr\033[38;2;252;238;238mi7QPBBBBPqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPB7i\033[38;2;252;172;172mrr7r \033[38;2;252;238;238m.vBBPPqqqqqqKqBZ  BPBgri: 1B        ");
$display("\033[38;2;252;238;238m                 ivr .BBqqKXBi \033[38;2;252;172;172mr7rri\033[38;2;252;238;238miQgQi   QZKqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPEQi\033[38;2;252;172;172mirr7r.  \033[38;2;252;238;238miBBqPqqqqqqPB:.QPPRBBB LK        ");
$display("\033[38;2;252;238;238m                   :I. iBgqgBZ \033[38;2;252;172;172m:7rr\033[38;2;252;238;238miJQPB.   gRqqqqqqqqPPPPPPPPqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPQ7\033[38;2;252;172;172mirrr7vr.  \033[38;2;252;238;238mUBqqPPgBBQPBBKqqqKB  B         ");
$display("\033[38;2;252;238;238m                     v7 .BBR: \033[38;2;252;172;172m.r7ri\033[38;2;252;238;238miggqPBrrBBBBBBBBBBBBBBBBBBQEPPqqPPPqqqqqqqqqqqqqqqqqqqqqqqqqPgPi\033[38;2;252;172;172mirrrr7v7  \033[38;2;252;238;238mrBPBBP:.LBbPqqqqqB. u.        ");
$display("\033[38;2;252;238;238m                      .j. . \033[38;2;252;172;172m :77rr\033[38;2;252;238;238miiBPqPbBB::::::.....:::iirrSBBBBBBBQZPPPPPqqqqqqqqqqqqqqqqqqqqEQi\033[38;2;252;172;172mirrrrrr7v \033[38;2;252;238;238m.BB:     :BPqqqqqDB .B        ");
$display("\033[38;2;252;238;238m                       YL \033[38;2;252;172;172m.i77rrrr\033[38;2;252;238;238miLQPqqKQJ. \033[38;2;252;172;172m ............       \033[38;2;252;238;238m..:irBBBBBBZPPPqqqqqqqPPBBEPqqqdRr\033[38;2;252;172;172mirrrrrr7v \033[38;2;252;238;238m.B  .iBB  dQPqqqqPBi Y:       ");
$display("\033[38;2;252;238;238m                     :U:.\033[38;2;252;172;172mrv7rrrrri\033[38;2;252;238;238miPgqqqqKZB.\033[38;2;252;172;172m.v77777777777777ri::..   \033[38;2;252;238;238m  ..:rBBBBQPPqqqqPBUvBEqqqPRr\033[38;2;252;172;172mirrrrrrvi\033[38;2;252;238;238m iB:RBBbB7 :BQqPqKqBR r7       ");
$display("\033[38;2;252;238;238m                    iI.\033[38;2;252;172;172m.v7rrrrrrri\033[38;2;252;238;238midgqqqqqKB:\033[38;2;252;172;172m 77rrrrrrrrrrrrr77777777ri:..   \033[38;2;252;238;238m .:1BBBEPPB:   BbqqPQr\033[38;2;252;172;172mirrrr7vr\033[38;2;252;238;238m .BBBZPqqDB  .JBbqKPBi vi       ");
$display("\033[38;2;252;238;238m                   :B \033[38;2;252;172;172miL7rrrrrrrri\033[38;2;252;238;238mibgqqqqqqBr\033[38;2;252;172;172m r7rrrrrrrrrrrrrrrrrrrrr777777ri:.  \033[38;2;252;238;238m .iBBBBi  .BbqqdRr\033[38;2;252;172;172mirr7v7: \033[38;2;252;238;238m.Bi.dBBPqqgB:  :BPqgB  B        ");
$display("\033[38;2;252;238;238m                   .K.i\033[38;2;252;172;172mv7rrrrrrrri\033[38;2;252;238;238miZgqqqqqqEB \033[38;2;252;172;172m.vrrrrrrrrrrrrrrrrrrrrrrrrrrr777vv7i.  \033[38;2;252;238;238m :PBBBBPqqqEQ\033[38;2;252;172;172miir77:  \033[38;2;252;238;238m:BB:  .rBPqqEBB. iBZB. Rr        ");
$display("\033[38;2;252;238;238m                    iM.:\033[38;2;252;172;172mv7rrrrrrrri\033[38;2;252;238;238mUQPqqqqqPBi\033[38;2;252;172;172m i7rrrrrrrrrrrrrrrrrrrrrrrrr77777i.   \033[38;2;252;238;238m.  :BddPqqqqEg\033[38;2;252;172;172miir7. \033[38;2;252;238;238mrBBPqBBP. :BXKqgB  BBB. 2r         ");
$display("\033[38;2;252;238;238m                     :U:.\033[38;2;252;172;172miv77rrrrri\033[38;2;252;238;238mrBPqqqqqqPB: \033[38;2;252;172;172m:7777rrrrrrrrrrrrrrr777777ri.   \033[38;2;252;238;238m.:uBBBBZPqqqqqqPQL\033[38;2;252;172;172mirr77 \033[38;2;252;238;238m.BZqqPB:  qMqqPB. Yv:  Ur          ");
$display("\033[38;2;252;238;238m                       1L:.\033[38;2;252;172;172m:77v77rii\033[38;2;252;238;238mqQPqqqqqPbBi \033[38;2;252;172;172m .ir777777777777777ri:..   \033[38;2;252;238;238m.:rBBBRPPPPPqqqqqqqgQ\033[38;2;252;172;172miirr7vr \033[38;2;252;238;238m:BqXQ: .BQPZBBq ...:vv.           ");
$display("\033[38;2;252;238;238m                         LJi..\033[38;2;252;172;172m::r7rii\033[38;2;252;238;238mRgKPPPPqPqBB:.  \033[38;2;252;172;172m ............     \033[38;2;252;238;238m..:rBBBBPPqqKKKKqqqPPqPbB1\033[38;2;252;172;172mrvvvvvr  \033[38;2;252;238;238mBEEDQBBBBBRri. 7JLi              ");
$display("\033[38;2;252;238;238m                           .jL\033[38;2;252;172;172m  777rrr\033[38;2;252;238;238mBBBBBBgEPPEBBBvri:::::::::irrrbBBBBBBDPPPPqqqqqqXPPZQBBBBr\033[38;2;252;172;172m.......\033[38;2;252;238;238m.:BBBBg1ri:....:rIr                 ");
$display("\033[38;2;252;238;238m                            vI \033[38;2;252;172;172m:irrr:....\033[38;2;252;238;238m:rrEBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQQBBBBBBBBBBBBBQr\033[38;2;252;172;172mi:...:.   \033[38;2;252;238;238m.:ii:.. .:.:irri::                    ");
$display("\033[38;2;252;238;238m                             71vi\033[38;2;252;172;172m:::irrr::....\033[38;2;252;238;238m    ...:..::::irrr7777777777777rrii::....  ..::irvrr7sUJYv7777v7ii..                         ");
$display("\033[38;2;252;238;238m                               .i777i. ..:rrri77rriiiiiii:::::::...............:::iiirr7vrrr:.                                             ");
$display("\033[38;2;252;238;238m                                                      .::::::::::::::::::::::::::::::                                                      \033[m");
end endtask


task pass_ans; begin
	if      ((patcount / 3) % 7 == 0)  $display("\033[0;31mPASS PATTERN NO.%4d, \033[m",patcount) ;
	else if ((patcount / 3) % 7 == 1)  $display("\033[1;31mPASS PATTERN NO.%4d, \033[m",patcount) ;
	else if ((patcount / 3) % 7 == 2)  $display("\033[1;33mPASS PATTERN NO.%4d, \033[m",patcount) ;
	else if ((patcount / 3) % 7 == 3)  $display("\033[0;32mPASS PATTERN NO.%4d, \033[m",patcount) ;
	else if ((patcount / 3) % 7 == 4)  $display("\033[0;36mPASS PATTERN NO.%4d, \033[m",patcount) ;
	else if ((patcount / 3) % 7 == 5)  $display("\033[0;34mPASS PATTERN NO.%4d, \033[m",patcount) ;
	else if ((patcount / 3) % 7 == 6)  $display("\033[0;35mPASS PATTERN NO.%4d, \033[m",patcount) ;
end endtask


endmodule