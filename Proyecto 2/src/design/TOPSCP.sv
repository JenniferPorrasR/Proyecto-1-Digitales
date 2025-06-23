module TOPSCP #(parameter WIDTH=32, parameter DEPTH_IMEM=64, parameter DEPTH_DMEM=12) (
    input logic clk, rst
);

    // Señales internas
    logic [WIDTH-1:0] PC_current, PC_next;
    logic [WIDTH-1:0] PC_plus4;
    logic [WIDTH-1:0] PC_branch_target;
    logic [WIDTH-1:0] PC_jump_target;
    logic [WIDTH-1:0] instruction;
    
    logic RegWrite, ALUSrc, MemRead, MemWrite, MemtoReg;
    logic Branch, Jump;
    logic [1:0] ALUOp;
    logic one_byte, two_byte, four_bytes, unsigned_load;
    
    logic [4:0] Rs1, Rs2, Rd;
    logic [WIDTH-1:0] ReadData1, ReadData2, WriteData;
    logic [WIDTH-1:0] ImmExt;
    logic [3:0] ALUCtrl;
    logic [WIDTH-1:0] ALU_a, ALU_b, ALUResult;
    logic Zero, Comparison;
    logic [WIDTH-1:0] MemReadData;
    
    logic PCSrc_Branch, PCSrc_Jump;
    logic PCSrc;
    logic [6:0] opcode;
    logic [2:0] func3;
    logic [6:0] func7;
    
    // Extracción de campos de la instrucción
    assign opcode = instruction[6:0];
    assign Rd = instruction[11:7];
    assign func3 = instruction[14:12];
    assign Rs1 = instruction[19:15];
    assign Rs2 = instruction[24:20];
    assign func7 = instruction[31:25];
    
    // Program Counter
    PC #(.WIDTH(WIDTH)) pc_unit (
        .clk(clk),
        .rst(rst),
        .PC_in(PC_next),
        .PC_out(PC_current)
    );
    
    // Sumadores
    adder #(.WIDTH(WIDTH)) pc_adder (
        .a(PC_current),
        .b(32'd4),
        .out(PC_plus4)
    );
    
    adder #(.WIDTH(WIDTH)) branch_adder (
        .a(PC_current),
        .b(ImmExt),
        .out(PC_branch_target)
    );
    
    adder #(.WIDTH(WIDTH)) jump_adder (
        .a((opcode == 7'b1100111) ? ReadData1 : PC_current),
        .b(ImmExt),
        .out(PC_jump_target)
    );
    
    // Instruction Memory
    InstructionMemoryF #(.WIDTH(WIDTH), .DEPTH(DEPTH_IMEM)) instruction_memory (
        .rst(rst),
        .readAddress(PC_current),
        .instructionOut(instruction)
    );
    
    // Control Unit
    Control control_unit (
        .opcode(opcode),
        .func3(func3),
        .RegWrite(RegWrite),
        .ALUSrc(ALUSrc),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .MemtoReg(MemtoReg),
        .Branch(Branch),
        .Jump(Jump),
        .ALUOp(ALUOp),
        .one_byte(one_byte),
        .two_byte(two_byte),
        .four_bytes(four_bytes),
        .unsigned_load(unsigned_load)
    );
    
    // Register File
    RegisterFile #(.WIDTH(WIDTH), .ADDR_WIDTH(5)) register_file (
        .clk(clk),
        .rst(rst),
        .RegWrite(RegWrite),
        .Rs1(Rs1),
        .Rs2(Rs2),
        .Rd(Rd),
        .WriteData(WriteData),
        .ReadData1(ReadData1),
        .ReadData2(ReadData2)
    );
    
    // Immediate Generator
    ImmediateGenerator #(.WIDTH(WIDTH)) imm_gen (
        .Opcode(opcode),
        .instruction(instruction),
        .ImmExt(ImmExt)
    );
    
    // ALU Control
    ALUControl alu_control (
        .ALUOp(ALUOp),
        .func3(func3),
        .func7(func7),
        .ALUCtrl(ALUCtrl)
    );
    
    // ALU
    assign ALU_a = ReadData1;
    
    Mux #(.WIDTH(WIDTH)) alu_src_mux (
        .a(ReadData2),
        .b(ImmExt),
        .sel(ALUSrc),
        .out(ALU_b)
    );
    
    RVALU #(.WIDTH(WIDTH)) alu (
        .a(ALU_a),
        .b(ALU_b),
        .ALUCtrl(ALUCtrl),
        .ALUResult(ALUResult),
        .Zero(Zero),
        .Comparison(Comparison)
    );
    
    // Data Memory
    DataMemory #(.WIDTH(WIDTH), .DEPTH(DEPTH_DMEM)) data_memory (
        .clk(clk),
        .rst(rst),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .Address(ALUResult[DEPTH_DMEM-1:0]),
        .WriteData(ReadData2),
        .one_byte(one_byte),
        .two_byte(two_byte),
        .four_bytes(four_bytes),
        .unsigned_load(unsigned_load),
        .ReadData(MemReadData)
    );
    
    // Write Back Mux
    logic [WIDTH-1:0] WriteData_temp1, WriteData_temp2;
    
    Mux #(.WIDTH(WIDTH)) writeback_mux1 (
        .a(ALUResult),
        .b(MemReadData),
        .sel(MemtoReg),
        .out(WriteData_temp1)
    );
    
    Mux #(.WIDTH(WIDTH)) writeback_mux2 (
        .a(WriteData_temp1),
        .b(PC_plus4),
        .sel(Jump),
        .out(WriteData)
    );
    
    // Control de flujo
    assign PCSrc_Branch = Branch & Comparison;
    assign PCSrc_Jump = Jump;
    assign PCSrc = PCSrc_Jump | PCSrc_Branch;
    
    logic [WIDTH-1:0] PC_temp;
    Mux #(.WIDTH(WIDTH)) pc_branch_mux (
        .a(PC_plus4),
        .b(PC_branch_target),
        .sel(PCSrc_Branch),
        .out(PC_temp)
    );
    
    Mux #(.WIDTH(WIDTH)) pc_jump_mux (
        .a(PC_temp),
        .b(PC_jump_target),
        .sel(PCSrc_Jump),
        .out(PC_next)
    );

endmodule