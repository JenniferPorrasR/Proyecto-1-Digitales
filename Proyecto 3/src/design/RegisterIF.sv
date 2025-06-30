module RegisterIF #(parameter WIDTH=32) (
    input clk, rst,                    // Señales de control
    input logic [WIDTH-1:0] inst,     // Entrada de instrucción 
    input logic [WIDTH-1:0] pc,       // Entrada de PC
    output logic [WIDTH-1:0] inst_out, // Salida de instrucción
    output logic [WIDTH-1:0] pc_out   // Salida de PC
);

always_ff @(posedge clk or posedge rst)
begin
    if(rst) begin
        inst_out <= 32'b0; 
        pc_out <= 32'b0; 
    end
    else begin
        inst_out <= inst;  
        pc_out <= pc;      
    end
end 

endmodule