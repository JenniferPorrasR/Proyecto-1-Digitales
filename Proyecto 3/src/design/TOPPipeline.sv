module TOPPipeline #(parameter WIDTH=32, parameter DEPTH_IMEM=64, parameter DEPTH_DMEM=12) (
    input logic clk, rst
);

    // Etapa IF
    logic [WIDTH-1:0] PC_current, PC_next;
    logic [WIDTH-1:0] PC_plus4;
    logic [WIDTH-1:0] instruction_IF;
    
    // Pipeline IF/ID
    logic [WIDTH-1:0] instruction_ID, PC_ID;
    
    // Etapa ID
    logic [6:0] opcode;
    logic [2:0] func3;
    logic [6:0] func7;
    logic [4:0] Rs1, Rs2, Rd_ID;
    logic [WIDTH-1:0] ReadData1, ReadData2;
    logic [WIDTH-1:0] ImmExt_ID;
    logic [3:0] ALUCtrl_ID;
    
    // Señales de control ID
    logic RegWrite_ID, ALUSrc_ID, MemRead_ID, MemWrite_ID, MemtoReg_ID;
    logic Branch_ID, Jump_ID;
    logic [1:0] ALUOp_ID;
    logic one_byte_ID, two_byte_ID, four_bytes_ID, unsigned_load_ID;
    
    // Pipeline ID/EX
    logic [WIDTH-1:0] PC_EX, ReadData1_EX, ReadData2_EX, ImmExt_EX;
    logic [4:0] Rd_EX;
    logic [3:0] ALUCtrl_EX;
    logic RegWrite_EX, ALUSrc_EX, MemRead_EX, MemWrite_EX, MemtoReg_EX;
    logic Branch_EX, Jump_EX;
    logic [1:0] ALUOp_EX;
    logic one_byte_EX, two_byte_EX, four_bytes_EX, unsigned_load_EX;
    
    // Etapa EX
    logic [WIDTH-1:0] ALU_a, ALU_b, ALUResult_EX;
    logic [WIDTH-1:0] PC_branch_target, PC_jump_target;
    logic Zero_EX, Comparison_EX;
    logic PCSrc_Branch, PCSrc_Jump, PCSrc;
    
    // Pipeline EX/MEM
    logic [WIDTH-1:0] PC_branch_MEM, ALUResult_MEM, WriteData_MEM;
    logic [4:0] Rd_MEM;
    logic Branch_MEM, Jump_MEM, MemRead_MEM, MemWrite_MEM;
    logic RegWrite_MEM, MemtoReg_MEM;
    logic one_byte_MEM, two_byte_MEM, four_bytes_MEM, unsigned_load_MEM;
    logic Comparison_MEM;
    
    // Etapa MEM
    logic [WIDTH-1:0] MemReadData_MEM;
    
    // Pipeline MEM/WB
    logic [WIDTH-1:0] MemReadData_WB, ALUResult_WB;
    logic [4:0] Rd_WB;
    logic RegWrite_WB, MemtoReg_WB, unsigned_load_WB;
    
    // Etapa WB
    logic [WIDTH-1:0] WriteData_WB;
    
    // Extracción campos instrucción
    assign opcode = instruction_ID[6:0];
    assign Rd_ID = instruction_ID[11:7];
    assign func3 = instruction_ID[14:12];
    assign Rs1 = instruction_ID[19:15];
    assign Rs2 = instruction_ID[24:20];
    assign func7 = instruction_ID[31:25];
    
    // Etapa IF - Instruction Fetch
    
    // Contador de programa
    PC #(.WIDTH(WIDTH)) pc_unit (
        .clk(clk),
        .rst(rst),
        .PC_in(PC_next),
        .PC_out(PC_current)
    );
    
    // PC + 4
    adder #(.WIDTH(WIDTH)) pc_adder (
        .a(PC_current),
        .b(32'd4),
        .out(PC_plus4)
    );
    
    // Memoria de instrucciones
    InstructionMemoryF #(.WIDTH(WIDTH), .DEPTH(DEPTH_IMEM)) instruction_memory (
        .rst(rst),
        .readAddress(PC_current),
        .instructionOut(instruction_IF)
    );
    
    // Registro IF/ID
    RegisterIF #(.WIDTH(WIDTH)) reg_if_id (
        .clk(clk),
        .rst(rst),
        .inst(instruction_IF),
        .pc(PC_plus4),
        .inst_out(instruction_ID),
        .pc_out(PC_ID)
    );
    
    // Etapa ID - Instruction Decode
    
    // Unidad de control
    Control control_unit (
        .opcode(opcode),
        .func3(func3),
        .RegWrite(RegWrite_ID),
        .ALUSrc(ALUSrc_ID),
        .MemRead(MemRead_ID),
        .MemWrite(MemWrite_ID),
        .MemtoReg(MemtoReg_ID),
        .Branch(Branch_ID),
        .Jump(Jump_ID),
        .ALUOp(ALUOp_ID),
        .one_byte(one_byte_ID),
        .two_byte(two_byte_ID),
        .four_bytes(four_bytes_ID),
        .unsigned_load(unsigned_load_ID)
    );
    
    // Banco de registros
    RegisterFile #(.WIDTH(WIDTH), .ADDR_WIDTH(5)) register_file (
        .clk(clk),
        .rst(rst),
        .RegWrite(RegWrite_WB), // Desde etapa WB
        .Rs1(Rs1),
        .Rs2(Rs2),
        .Rd(Rd_WB),             // Desde etapa WB
        .WriteData(WriteData_WB), // Desde etapa WB
        .ReadData1(ReadData1),
        .ReadData2(ReadData2)
    );
    
    // Generador de inmediatos
    ImmediateGenerator #(.WIDTH(WIDTH)) imm_gen (
        .Opcode(opcode),
        .instruction(instruction_ID),
        .ImmExt(ImmExt_ID)
    );
    
    // Control ALU
    ALUControl alu_control (
        .ALUOp(ALUOp_ID),
        .func3(func3),
        .func7(func7),
        .ALUCtrl(ALUCtrl_ID)
    );
    
    // Registro ID/EX
    RegisterID #(.WIDTH(WIDTH), .ADDR_WIDTH(5)) reg_id_ex (
        .clk(clk),
        .rst(rst),
        // PC
        .pc(PC_ID),
        .pc_out(PC_EX),
        // Control signals
        .ALUOp_in(ALUOp_ID),
        .ALUOp(ALUOp_EX),
        .ALUSrc_in(ALUSrc_ID),
        .ALUSrc_out(ALUSrc_EX),
        .Branch_in(Branch_ID),
        .Branch(Branch_EX),
        .Jump_in(Jump_ID),
        .Jump(Jump_EX),
        .one_byte_in(one_byte_ID),
        .one_byte(one_byte_EX),
        .two_byte_in(two_byte_ID),
        .two_byte(two_byte_EX),
        .four_bytes_in(four_bytes_ID),
        .four_bytes(four_bytes_EX),
        .MemRead_in(MemRead_ID),
        .MemRead(MemRead_EX),
        .MemWrite_in(MemWrite_ID),
        .MemWrite(MemWrite_EX),
        .RegWrite_in(RegWrite_ID),
        .RegWrite(RegWrite_EX),
        .MemtoReg_in(MemtoReg_ID),
        .MemtoReg(MemtoReg_EX),
        .unsigned_load_in(unsigned_load_ID),
        .unsigned_load(unsigned_load_EX),
        // Data
        .data1_in(ReadData1),
        .data1(ReadData1_EX),
        .data2_in(ReadData2),
        .data2(ReadData2_EX),
        .Imm_in(ImmExt_ID),
        .Imm(ImmExt_EX),
        .ALUCtrl_in(ALUCtrl_ID),
        .ALUCtrl(ALUCtrl_EX),
        .Rd_in(Rd_ID),
        .Rd(Rd_EX)
    );
    
    // Etapa EX - Execute
    
    // Mux fuente ALU
    assign ALU_a = ReadData1_EX;
    
    Mux #(.WIDTH(WIDTH)) alu_src_mux (
        .a(ReadData2_EX),
        .b(ImmExt_EX),
        .sel(ALUSrc_EX),
        .out(ALU_b)
    );
    
    // ALU
    RVALU #(.WIDTH(WIDTH)) alu (
        .a(ALU_a),
        .b(ALU_b),
        .ALUCtrl(ALUCtrl_EX),
        .ALUResult(ALUResult_EX),
        .Zero(Zero_EX),
        .Comparison(Comparison_EX)
    );
    
    // Dirección branch
    adder #(.WIDTH(WIDTH)) branch_adder (
        .a(PC_EX),
        .b(ImmExt_EX),
        .out(PC_branch_target)
    );
    
    // Dirección jump
    adder #(.WIDTH(WIDTH)) jump_adder (
        .a((opcode == 7'b1100111) ? ReadData1_EX : PC_EX), // JALR vs JAL
        .b(ImmExt_EX),
        .out(PC_jump_target)
    );
    
    // Registro EX/MEM
    RegisterEx #(.WIDTH(WIDTH), .ADDR_WIDTH(5)) reg_ex_mem (
        .clk(clk),
        .rst(rst),
        // PC Branch
        .pcBranch(PC_branch_target),
        .pcBranch_out(PC_branch_MEM),
        // Control signals
        .Branch_in(Branch_EX),
        .Branch(Branch_MEM),
        .Jump_in(Jump_EX),
        .Jump(Jump_MEM),
        .one_byte_in(one_byte_EX),
        .one_byte(one_byte_MEM),
        .two_byte_in(two_byte_EX),
        .two_byte(two_byte_MEM),
        .four_bytes_in(four_bytes_EX),
        .four_bytes(four_bytes_MEM),
        .MemRead_in(MemRead_EX),
        .MemRead(MemRead_MEM),
        .MemWrite_in(MemWrite_EX),
        .MemWrite(MemWrite_MEM),
        .RegWrite_in(RegWrite_EX),
        .RegWrite(RegWrite_MEM),
        .MemtoReg_in(MemtoReg_EX),
        .MemtoReg(MemtoReg_MEM),
        .unsigned_load_in(unsigned_load_EX),
        .unsigned_load(unsigned_load_MEM),
        // Data
        .ALUResult_in(ALUResult_EX),
        .ALUResult(ALUResult_MEM),
        .Rd_in(Rd_EX),
        .Rd(Rd_MEM),
        .WriteData_in(ReadData2_EX),
        .WriteData(WriteData_MEM),
        .Comparison_in(Comparison_EX),
        .Comparison(Comparison_MEM)
    );
    
    // Etapa MEM - Memory Access
    
    // Memoria de datos
    DataMemory #(.WIDTH(WIDTH), .DEPTH(DEPTH_DMEM)) data_memory (
        .clk(clk),
        .rst(rst),
        .MemWrite(MemWrite_MEM),
        .MemRead(MemRead_MEM),
        .Address(ALUResult_MEM[DEPTH_DMEM-1:0]),
        .WriteData(WriteData_MEM),
        .one_byte(one_byte_MEM),
        .two_byte(two_byte_MEM),
        .four_bytes(four_bytes_MEM),
        .unsigned_load(unsigned_load_MEM),
        .ReadData(MemReadData_MEM)
    );
    
    // Registro MEM/WB
    RegisterWb #(.WIDTH(WIDTH), .ADDR_WIDTH(5)) reg_mem_wb (
        .clk(clk),
        .rst(rst),
        // Control signals
        .RegWrite_in(RegWrite_MEM),
        .RegWrite(RegWrite_WB),
        .MemtoReg_in(MemtoReg_MEM),
        .MemtoReg(MemtoReg_WB),
        .unsigned_load_in(unsigned_load_MEM),
        .unsigned_load(unsigned_load_WB),
        // Data
        .data_in(MemReadData_MEM),
        .data(MemReadData_WB),
        .ALUResult_in(ALUResult_MEM),
        .ALUResult(ALUResult_WB),
        .Rd_in(Rd_MEM),
        .Rd(Rd_WB)
    );
    
    // Etapa WB - Write Back
    
    // Mux Write Back
    logic [WIDTH-1:0] WriteData_temp1, WriteData_temp2;
    
    Mux #(.WIDTH(WIDTH)) writeback_mux1 (
        .a(ALUResult_WB),
        .b(MemReadData_WB),
        .sel(MemtoReg_WB),
        .out(WriteData_temp1)
    );
    
    Mux #(.WIDTH(WIDTH)) writeback_mux2 (
        .a(WriteData_temp1),
        .b(PC_ID), // PC+4 para JAL/JALR
        .sel(Jump_MEM), // Jump desde etapa MEM
        .out(WriteData_WB)
    );
    
    // Control PC
    
    // Control branch
    assign PCSrc_Branch = Branch_MEM & Comparison_MEM;
    assign PCSrc_Jump = Jump_MEM;
    assign PCSrc = PCSrc_Jump | PCSrc_Branch;
    
    // Selección PC
    logic [WIDTH-1:0] PC_temp;
    Mux #(.WIDTH(WIDTH)) pc_branch_mux (
        .a(PC_plus4),
        .b(PC_branch_MEM),
        .sel(PCSrc_Branch),
        .out(PC_temp)
    );
    
    Mux #(.WIDTH(WIDTH)) pc_jump_mux (
        .a(PC_temp),
        .b(PC_jump_target), // Debe venir de etapa MEM para timing correcto
        .sel(PCSrc_Jump),
        .out(PC_next)
    );
    
endmodule