`define JALR 3'd3
`define CALL 3'd4
`define RET 3'd5

module nbjProcessLogic (
    input rst,
    input i_fire,
    input [7:0] i_firstJTableEntry_8,
    input [3:0] i_alignedInstructionNumber_4,
    input [4:0] i_validSize_5,
    input [31:0] i_currentPc_32,
    input [35*10-1:0] i_typeAndAddressTableBus_350,
    input [64*10-1:0] i_alignedInstructionTableBus_640,
    input [31:0] i_correctPc_32,
    input [2:0] i_correctPcIndex_3,
    input i_type,
    output [31:0] o_nextPc_32,
    output [7:0] o_cutPosition_8
);
    wire [2:0] type;
    wire [31:0] jaddr;
    wire gotError;

    assign type = i_firstJTableEntry_8[0+:3]; //类型
    assign jaddr = i_typeAndAddressTableBus_350[i_firstJTableEntry_8[3+:5]*35+3+: 32]; //跳转PC
    assign gotError = i_correctPc_32 == 32'b0 ? 0 : 1; //后端是否报告错误
    
    assign o_cutPosition_8 = i_firstJTableEntry_8[3+:5];
    
    //JALR型指令处理
    reg [31:0] JALRBTB [7:0];
    wire [2:0] BTBIndex;
    
    assign BTBIndex = (i_alignedInstructionTableBus_640[i_firstJTableEntry_8[3+:5]*64+32+:32]) % 8; 

    reg [31:0] RAS [7:0];
    reg [2:0] pointer;

    always @(posedge i_fire or negedge rst) begin
        if(!rst) begin
            pointer <= 3'b0;
            RAS[0] <= 32'b0; JALRBTB[0] <= 32'b0;
            RAS[1] <= 32'b0; JALRBTB[1] <= 32'b0;
            RAS[2] <= 32'b0; JALRBTB[2] <= 32'b0;
            RAS[3] <= 32'b0; JALRBTB[3] <= 32'b0;
            RAS[4] <= 32'b0; JALRBTB[4] <= 32'b0;
            RAS[5] <= 32'b0; JALRBTB[5] <= 32'b0;
            RAS[6] <= 32'b0; JALRBTB[6] <= 32'b0;
            RAS[7] <= 32'b0; JALRBTB[7] <= 32'b0;
        end 
        else begin
        //更新
        JALRBTB[i_correctPcIndex_3] <= (gotError == 0 || i_type == 1) ? JALRBTB[i_correctPcIndex_3] : i_correctPc_32;
        pointer <= type == `RET ? (pointer-1) :type == `CALL?(pointer-1):pointer;
        RAS[pointer+1] <= type == `CALL ? 
                          i_firstJTableEntry_8[3+:5] + 1 == i_alignedInstructionNumber_4?
                          i_currentPc_32 + i_validSize_5 :
                          i_alignedInstructionTableBus_640[i_firstJTableEntry_8[3+:5]*64+64+32+:32] : 
                          RAS[pointer+1];
        end
    end
    
    assign o_nextPc_32 = gotError ? i_correctPc_32 :
    type == `RET ? RAS[pointer] :
    type == `JALR ? JALRBTB[BTBIndex] : jaddr;

endmodule