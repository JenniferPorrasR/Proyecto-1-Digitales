// Testbench para el procesador RISC-V de ciclo único TOPSCP
`timescale 1ns / 1ps

module TOPSCP_tb;
    // Parámetros del testbench
    parameter WIDTH = 32;
    parameter DEPTH_IMEM = 64;
    parameter DEPTH_DMEM = 12;
    parameter PERIOD = 10; // 10ns = 100MHz
    
    // Señales del testbench
    logic clk;
    logic rst;
    
    // Instanciación del DUT (Device Under Test)
    TOPSCP #(
        .WIDTH(WIDTH),
        .DEPTH_IMEM(DEPTH_IMEM),
        .DEPTH_DMEM(DEPTH_DMEM)
    ) dut (
        .clk(clk),
        .rst(rst)
    );
    
    // Generación del reloj
    initial begin
        clk = 0;
        forever #(PERIOD/2) clk = ~clk;
    end
    
    // Variables para monitoreo
    logic [WIDTH-1:0] prev_pc;
    logic [WIDTH-1:0] current_instruction;
    logic [6:0] opcode;
    logic [4:0] rd, rs1, rs2;
    logic [2:0] func3;
    logic [6:0] func7;
    
    // Asignaciones para monitoreo
    assign current_instruction = dut.instruction;
    assign opcode = current_instruction[6:0];
    assign rd = current_instruction[11:7];
    assign func3 = current_instruction[14:12];
    assign rs1 = current_instruction[19:15];
    assign rs2 = current_instruction[24:20];
    assign func7 = current_instruction[31:25];
    
    // Función para decodificar el nombre de la instrucción
    function string get_instruction_name(logic [6:0] op, logic [2:0] f3, logic [6:0] f7);
        case (op)
            7'b0110011: begin // R-type
                case (f3)
                    3'b000: return (f7 == 7'b0100000) ? "SUB" : "ADD";
                    3'b001: return "SLL";
                    3'b010: return "SLT";
                    3'b011: return "SLTU";
                    3'b100: return "XOR";
                    3'b101: return (f7 == 7'b0100000) ? "SRA" : "SRL";
                    3'b110: return "OR";
                    3'b111: return "AND";
                    default: return "R-UNK";
                endcase
            end
            7'b0010011: begin // I-type immediate
                case (f3)
                    3'b000: return "ADDI";
                    3'b001: return "SLLI";
                    3'b010: return "SLTI";
                    3'b011: return "SLTIU";
                    3'b100: return "XORI";
                    3'b101: return (f7 == 7'b0100000) ? "SRAI" : "SRLI";
                    3'b110: return "ORI";
                    3'b111: return "ANDI";
                    default: return "I-UNK";
                endcase
            end
            7'b0000011: begin // Load
                case (f3)
                    3'b000: return "LB";
                    3'b001: return "LH";
                    3'b010: return "LW";
                    3'b100: return "LBU";
                    3'b101: return "LHU";
                    default: return "LOAD-UNK";
                endcase
            end
            7'b0100011: begin // Store
                case (f3)
                    3'b000: return "SB";
                    3'b001: return "SH";
                    3'b010: return "SW";
                    default: return "STORE-UNK";
                endcase
            end
            7'b1100011: begin // Branch
                case (f3)
                    3'b000: return "BEQ";
                    3'b001: return "BNE";
                    3'b100: return "BLT";
                    3'b101: return "BGE";
                    3'b110: return "BLTU";
                    3'b111: return "BGEU";
                    default: return "BRANCH-UNK";
                endcase
            end
            7'b0110111: return "LUI";
            7'b0010111: return "AUIPC";
            7'b1101111: return "JAL";
            7'b1100111: return "JALR";
            default: return "UNKNOWN";
        endcase
    endfunction
    
    // Monitor detallado para seguimiento de la ejecución
    always @(posedge clk) begin
        if (!rst) begin
            $display("=== Ciclo %0d (Tiempo: %0t) ===", ($time/PERIOD) - 2, $time);
            $display("PC: 0x%08h (Decimal: %0d)", dut.PC_current, dut.PC_current);
            $display("Instrucción: 0x%08h (%s)", current_instruction, 
                    get_instruction_name(opcode, func3, func7));
            
            // Mostrar campos de la instrucción detalladamente
            $display("  Campos: Opcode=0x%02h, Rd=x%0d, Rs1=x%0d, Rs2=x%0d, Func3=0x%01h, Func7=0x%02h", 
                    opcode, rd, rs1, rs2, func3, func7);
            
            // Mostrar señales de control principales
            $display("  Control: RegWrite=%b, ALUSrc=%b, MemRead=%b, MemWrite=%b, Branch=%b, Jump=%b, MemtoReg=%b", 
                    dut.RegWrite, dut.ALUSrc, dut.MemRead, dut.MemWrite, dut.Branch, dut.Jump, dut.MemtoReg);
            
            // Mostrar datos leídos de registros
            $display("  Registros leídos: Rs1(x%0d)=0x%08h, Rs2(x%0d)=0x%08h", 
                    rs1, dut.ReadData1, rs2, dut.ReadData2);
            
            // Mostrar inmediato si se usa
            if (dut.ALUSrc) begin
                $display("  Inmediato: 0x%08h (%0d)", dut.ImmExt, $signed(dut.ImmExt));
            end
            
            // Mostrar operación de ALU
            if (dut.ALUSrc) begin
                $display("  ALU: 0x%08h (%s) 0x%08h = 0x%08h (Zero=%b, Comp=%b)", 
                        dut.ALU_a, get_alu_op_name(dut.ALUCtrl), dut.ImmExt, 
                        dut.ALUResult, dut.Zero, dut.Comparison);
            end else begin
                $display("  ALU: 0x%08h (%s) 0x%08h = 0x%08h (Zero=%b, Comp=%b)", 
                        dut.ALU_a, get_alu_op_name(dut.ALUCtrl), dut.ALU_b, 
                        dut.ALUResult, dut.Zero, dut.Comparison);
            end
            
            // Mostrar accesos a memoria detalladamente
            if (dut.MemRead || dut.MemWrite) begin
                $display("  Memoria: %s Addr=0x%03h, Data=0x%08h", 
                        dut.MemWrite ? "WRITE" : "READ", 
                        dut.data_memory.Address,
                        dut.MemWrite ? dut.ReadData2 : dut.MemReadData);
            end
            
            // Mostrar datos escritos al registro
            if (dut.RegWrite && rd != 0) begin
                $display("  Escritura registro: x%0d <= 0x%08h (%0d)", 
                        rd, dut.WriteData, $signed(dut.WriteData));
            end
            
            // Mostrar información de saltos
            if (dut.Jump || (dut.Branch && dut.Comparison)) begin
                $display("  SALTO a PC: 0x%08h", dut.Jump ? dut.PC_jump_target : dut.PC_branch_target);
            end
            
            $display("  Próximo PC: 0x%08h", dut.PC_next);
            $display("");
        end
    end
    
    // Función para obtener nombre de operación ALU
    function string get_alu_op_name(logic [3:0] ctrl);
        case (ctrl)
            4'b0000: return "AND";
            4'b0001: return "OR";
            4'b0010: return "ADD";
            4'b0011: return "SLTU";
            4'b0100: return "SLT";
            4'b0110: return "SUB";
            4'b1000: return "SLL";
            4'b1001: return "XOR";
            4'b1010: return "SRL";
            4'b1011: return "SRA";
            4'b1100: return "BEQ";
            4'b1101: return "BNE";
            4'b1110: return "BLT";
            4'b1111: return "BGE";
            4'b0101: return "BLTU";
            4'b0111: return "BGEU";
            default: return "UNK";
        endcase
    endfunction
    

    
    // Variables para los bucles de visualización
    integer i;
    logic [31:0] reg_val;
    logic [31:0] instr;
    logic [6:0] op;
    logic [2:0] f3;
    logic [6:0] f7;
    logic [7:0] mem_byte;
    logic [31:0] word;
    
    // Secuencia principal de prueba
    initial begin
        $display("=== Iniciando testbench TOPSCP ===");
        $display("Parámetros: WIDTH=%0d, DEPTH_IMEM=%0d, DEPTH_DMEM=%0d", 
                WIDTH, DEPTH_IMEM, DEPTH_DMEM);
        
        // Reset inicial
        rst = 1;
        #(PERIOD * 2);
        rst = 0;
        
        $display("\n=== Reset completado, iniciando ejecución ===\n");
        
        // Ejecutar varios ciclos para ver el comportamiento
        #(PERIOD * 15);
        
        $display("\n=== ESTADO COMPLETO DE REGISTROS ===");
        $display("Registro |   Hexadecimal   |    Decimal    | Binario");
        $display("---------|-----------------|---------------|----------------------------------");
        for (i = 0; i < 32; i = i + 1) begin
            reg_val = dut.register_file.Registers[i];
            if (reg_val != 0 || i < 8) begin // Mostrar registros no-cero y primeros 8
                $display("   x%2d   |   0x%08h   |   %10d   | %b", 
                        i, reg_val, $signed(reg_val), reg_val);
            end
        end
        
        $display("\n=== MEMORIA DE INSTRUCCIONES (Primeras 16 posiciones) ===");
        $display("Dirección |   Hexadecimal   | Instrucción Decodificada");
        $display("----------|-----------------|---------------------------");
        for (i = 0; i < 16; i = i + 1) begin
            instr = dut.instruction_memory.Memory[i];
            op = instr[6:0];
            f3 = instr[14:12];
            f7 = instr[31:25];
            $display("  0x%02h    |   0x%08h   | %s", 
                    i*4, instr, get_instruction_name(op, f3, f7));
        end
        
        $display("\n=== MEMORIA DE DATOS (Solo posiciones no-cero) ===");
        $display("Dirección | Byte (Hex) | Byte (Dec)");
        $display("----------|------------|------------");
        for (i = 0; i < 2**DEPTH_DMEM; i = i + 1) begin
            mem_byte = dut.data_memory.DataMem[i];
            if (mem_byte != 0) begin
                $display("  0x%03h   |    0x%02h    |     %3d", i, mem_byte, mem_byte);
            end
        end
        
        // Mostrar también palabras de 32 bits si hay datos
        $display("\n=== MEMORIA DE DATOS (Por palabras de 32 bits) ===");
        $display("Dirección |   Palabra (Hex)   |  Palabra (Dec)");
        $display("----------|-------------------|----------------");
        for (i = 0; i < 2**(DEPTH_DMEM-2); i = i + 1) begin
            word = {dut.data_memory.DataMem[i*4+3], 
                    dut.data_memory.DataMem[i*4+2],
                    dut.data_memory.DataMem[i*4+1], 
                    dut.data_memory.DataMem[i*4]};
            if (word != 0) begin
                $display("  0x%03h   |     0x%08h     |   %10d", i*4, word, $signed(word));
            end
        end
        
        $display("\n=== Testbench completado ===");
        $finish;
    end
    
    
    // Timeout de seguridad - ajustado para el programa más corto
    initial begin
        #(PERIOD * 50);
        $display("TIMEOUT: Testbench terminado por límite de tiempo");
        $display("El programa entró en un bucle infinito como era esperado");
        $finish;
    end
    
    // Sistema de guardado mejorado
    initial begin
        $dumpfile("TOPSCP_tb.vcd");
        $dumpvars(0, TOPSCP_tb);
    end 
    
endmodule