module RVALU #(parameter WIDTH = 32) (
    input logic [WIDTH-1:0] a,          // Primer operando
    input logic [WIDTH-1:0] b,          // Segundo operando
    input logic [3:0] ALUCtrl,          // Control de operación
    output logic [WIDTH-1:0] ALUResult, // Resultado
    output logic Zero,                  // Flag zero
    output logic Comparison             // Resultado de comparación para branches
);

    // Señales intermedias para evitar selecciones constantes en always_comb
    logic [4:0] shift_amount;
    assign shift_amount = b[4:0];

    always_comb begin
        // Inicialización para evitar latches
        ALUResult = {WIDTH{1'b0}};
        Comparison = 1'b0;
        
        case (ALUCtrl)
            // Operaciones lógicas y aritméticas básicas
            4'b0000: ALUResult = a & b;                    // AND
            4'b0001: ALUResult = a | b;                    // OR
            4'b0010: ALUResult = $signed(a) + $signed(b);  // ADD
            4'b0011: ALUResult = (a < b) ? 32'd1 : 32'd0;  // SLTU (unsigned)
            4'b0100: ALUResult = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // SLT (signed)
            4'b0110: ALUResult = $signed(a) - $signed(b);  // SUB
            
            // Operaciones de shift
            4'b1000: ALUResult = a << shift_amount;        // SLL (shift left logical)
            4'b1001: ALUResult = a ^ b;                    // XOR
            4'b1010: ALUResult = a >> shift_amount;        // SRL (shift right logical)
            4'b1011: ALUResult = $signed(a) >>> shift_amount; // SRA (shift right arithmetic)
            
            // Operaciones de comparación para branches (solo afectan Comparison)
            4'b1100: begin // BEQ - Branch if Equal
                Comparison = ($signed(a) == $signed(b)) ? 1'b1 : 1'b0;
                ALUResult = {WIDTH{1'b0}}; // No se usa en branches
            end
            
            4'b1101: begin // BNE - Branch if Not Equal
                Comparison = ($signed(a) != $signed(b)) ? 1'b1 : 1'b0;
                ALUResult = {WIDTH{1'b0}};
            end
            
            4'b1110: begin // BLT - Branch if Less Than (signed)
                Comparison = ($signed(a) < $signed(b)) ? 1'b1 : 1'b0;
                ALUResult = {WIDTH{1'b0}};
            end
            
            4'b1111: begin // BGE - Branch if Greater or Equal (signed)
                Comparison = ($signed(a) >= $signed(b)) ? 1'b1 : 1'b0;
                ALUResult = {WIDTH{1'b0}};
            end
            
            4'b0101: begin // BLTU - Branch if Less Than Unsigned
                Comparison = (a < b) ? 1'b1 : 1'b0;
                ALUResult = {WIDTH{1'b0}};
            end
            
            4'b0111: begin // BGEU - Branch if Greater or Equal Unsigned
                Comparison = (a >= b) ? 1'b1 : 1'b0;
                ALUResult = {WIDTH{1'b0}};
            end
            
            default: begin
                ALUResult = $signed(a) + $signed(b); // Default: ADD
                Comparison = 1'b0;
            end
        endcase
        
        // Zero flag - para operaciones que requieran igualdad o desigualdad en operaciones
        Zero = (ALUResult ==0)?1:0;
    end
endmodule

