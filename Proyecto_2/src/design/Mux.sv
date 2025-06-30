//Mux multipropósito para el procesador, es un componente combinacional 

module Mux #(parameter WIDTH=32) (
// Señales de entrada y salida
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    input logic sel, //bit de selcción de, va a decir cual de las 2 entradas pasa a la salida
    output logic [WIDTH-1:0] out

);

always_comb begin 

if(sel==1) out=b;  // sel=1 selecciona entrada b
else out=a;        // sel=0 selecciona entrada a

end

endmodule