# Procesador Uniciclo RISC-V

Este proyecto implementa un procesador uniciclo basado en la arquitectura RISC-V de 32 bits. El diseño permite la ejecución de cada instrucción en un solo ciclo de reloj. 

## Unidades Principales del Sistema

### 1. Instruction Fetch

* Contador de Programa (PC)
* Memoria de Instrucciones
* Sumador para PC+4

### 2. Instruction Decode

* Banco de Registros
* Unidad de Control Principal
* Generador de Inmediatos

### 3. Executeion

* Unidad Aritmético-Lógica (ALU)
* ALU control
* Sumador para cálculo de direcciones de salto (PC + inmediato)
* Multiplexor de selección de operandos

### 4. Memory 

* Memoria de Datos
* Control de lectura/escritura de memoria

### 5. Write Back

* Multiplexor para selección de datos de escritura

(imagen )

## Módulos Implementados y su Correspondencia en el Circuito
