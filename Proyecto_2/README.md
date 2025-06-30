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

<p align="center">
  <img src="./Imagenes/Imagen 1.png" alt="Imagen 2" width="750" height="450">
</p>

## Módulos Implementados y su Correspondencia en el Circuito

### `PC.sv`

Implementa el contador de programa (PC), que almacena y actualiza la dirección de la instrucción actual, sumando 4 o usando una dirección de salto.

### `InstructionMemory.sv`

Contiene las instrucciones del programa. Recibe la dirección del PC y entrega la instrucción de 32 bits junto con sus campos relevantes.

### `RegisterFile.sv`

Banco de 32 registros de 32 bits. Permite leer dos registros y escribir en uno. Entrega los datos leídos como salida.

### `RVALU.sv`

Unidad Aritmético-Lógica (ALU) que ejecuta operaciones como suma, resta, AND, OR, y genera una señal `Zero` para decisiones de control.

### `ALUcontrol.sv`

Determina la operación que debe ejecutar la ALU según señales de control y campos de la instrucción.

### `Control.sv`

Unidad de Control Principal que decodifica el `opcode` y genera señales para coordinar los demás módulos del datapath.

### `DataMemory.sv`

Memoria que permite leer y escribir datos. Controlada por las señales `MemRead` y `MemWrite`.

### `ImmediateGenerator.sv`

Extrae y extiende el valor inmediato de la instrucción según su tipo (I, S, B, etc.), realizando extensión de signo si es necesario.

### `Mux.sv`

Multiplexores que seleccionan entre diferentes fuentes de datos: operandos de la ALU, resultados de memoria o PC actualizado.

### `addersv`

Sumadores que calculan PC+4 para el flujo normal de instrucciones y PC + inmediato para saltos.

## Reporte de Ejecución del Testbench 

### Instrucciones Utilizadas

| Instrucción (Hex) | Tipo  | Descripción                                                      |
| ----------------- | ----- | ---------------------------------------------------------------- |
| 02000293          | ADDI  | x5 = x0 + 32 (cargar 32 en x5)                                   |
| 02a00313          | ADDI  | x6 = x0 + 42 (cargar 42 en x6)                                   |
| 0062a023          | SW    | MEM\[x5 + 0] = x6 (almacenar x6 en memoria)                      |
| ff600313          | ADDI  | x6 = x0 + (-10) (cargar -10 en x6)                               |
| 0062a223          | SW    | MEM\[x5 + 4] = x6 (almacenar x6 en memoria + 4)                  |
| 0002a383          | LW    | x7 = MEM\[x5 + 0] (cargar desde memoria a x7)                    |
| 0042ae03          | LW    | x28 = MEM\[x5 + 4] (cargar desde memoria a x28)                  |
| 00500513          | ADDI  | x10 = x0 + 5 (cargar 5 en x10)                                   |
| 40a385b3          | SUB   | x11 = x7 - x10 (restar x10 de x7)                                |
| 01c3c633          | XOR   | x12 = x7 XOR x28 (XOR lógico)                                    |
| 01c3f6b3          | AND   | x13 = x7 AND x28 (AND lógico)                                    |
| 01c3e733          | OR    | x14 = x7 OR x28 (OR lógico)                                      |
| 00239e93          | SLLI  | x29 = x7 << 2 (desplazamiento izquierda lógico)                  |
| 001e5f13          | SRLI  | x30 = x28 >> 1 (desplazamiento derecha lógico)                   |
| 401e5f93          | SRAI  | x31 = x28 >> 1 (desplazamiento derecha aritmético)               |
| 00a00413          | ADDI  | x8 = x0 + 10 (cargar 10 en x8)                                   |
| 00500493          | ADDI  | x9 = x0 + 5 (cargar 5 en x9)                                     |
| 00945463          | BNE   | Si x8 ≠ x9, saltar 8 posiciones (branch not equal)               |
| 06300913          | ADDI  | x18 = x0 + 99 (cargar 99 en x18)                                 |
| 03700913          | ADDI  | x18 = x0 + 55 (cargar 55 en x18)                                 |
| 0084a9b3          | SLT   | x19 = 1 si x9 < x8, si no 0                                      |
| 01442a13          | XORI  | x20 = x8 XOR 20 (XOR inmediato)                                  |
| 0084bab3          | SLTU  | x21 = 1 si x9 < x8 (sin signo)                                   |
| 01443b13          | SLTIU | x22 = 1 si x8 < 20 (sin signo inmediato)                         |
| 00000513          | ADDI  | x10 = x0 + 0 (limpiar x10)                                       |
| f8000ee3          | BEQ   | Si x0 = x0, saltar -16 posiciones (branch equal - loop infinito) |

### Resultado de la Ejecución del Testbench

El testbench ejecutó las siguientes instrucciones de manera secuencial:

| Ciclo | PC         | Instrucción | Tipo | Operación Realizada         |
| ----- | ---------- | ----------- | ---- | --------------------------- |
| 0     | 0x00000000 | 0x02000293  | ADDI | x5 ← 32                     |
| 1     | 0x00000004 | 0x02a00313  | ADDI | x6 ← 42                     |
| 2     | 0x00000008 | 0x0062a023  | SW   | MEM\[0x020] ← 42            |
| 3     | 0x0000000c | 0xff600313  | ADDI | x6 ← -10                    |
| 4     | 0x00000010 | 0x0062a223  | SW   | MEM\[0x024] ← -10           |
| 5     | 0x00000014 | 0x0002a383  | LW   | x7 ← MEM\[0x020] (42)       |
| 6     | 0x00000018 | 0x0042ae03  | LW   | x28 ← MEM\[0x024] (-10)     |
| 7     | 0x0000001c | 0x00500513  | ADDI | x10 ← 5                     |
| 8     | 0x00000020 | 0x40a385b3  | SUB  | x11 ← 42 - 5 = 37           |
| 9     | 0x00000024 | 0x01c3c633  | XOR  | x12 ← 42 XOR -10 = -36      |
| 10    | 0x00000028 | 0x01c3f6b3  | AND  | x13 ← 42 AND -10 = 34       |
| 11    | 0x0000002c | 0x01c3e733  | OR   | x14 ← 42 OR -10 = -2        |
| 12    | 0x00000030 | 0x00239e93  | SLLI | x29 ← 42 << 2 = 168         |
| 13    | 0x00000034 | 0x001e5f13  | SRLI | x30 ← -10 >> 1 = 2147483643 |
| 14    | 0x00000038 | 0x401e5f93  | SRAI | x31 ← -10 >> 1 = -5         |

### Estado Final de los Registros

| Registro | Valor Hexadecimal | Valor Decimal | Descripción              |
| -------- | ----------------- | ------------- | ------------------------ |
| x5       | 0x00000020        | 32            | Dirección base           |
| x6       | 0xfffffff6        | -10           | Valor inmediato          |
| x7       | 0x0000002a        | 42            | Valor cargado de memoria |
| x10      | 0x00000005        | 5             | Operando para SUB        |
| x11      | 0x00000025        | 37            | Resultado de SUB         |
| x12      | 0xffffffdc        | -36           | Resultado de XOR         |
| x13      | 0x00000022        | 34            | Resultado de AND         |
| x14      | 0xfffffffe        | -2            | Resultado de OR          |
| x28      | 0xfffffff6        | -10           | Valor cargado de memoria |
| x29      | 0x000000a8        | 168           | Resultado de SLLI        |
| x30      | 0x7ffffffb        | 2147483643    | Resultado de SRLI        |
| x31      | 0xfffffffb        | -5            | Resultado de SRAI        |

### Estado de la Memoria

Memoria de Datos (Por bytes - Solo posiciones no-cero)

| Dirección  | Byte (Hex) | Byte (Dec) |
| ---------- | ---------- | ---------- | 
| 0x00000020 | 0x2a       | 42         | 
| 0x00000024 | 0xf6       | 246        | 
| 0x00000025 | 0xff       | 255        | 
| 0x00000026 | 0xff       | 255        | 
| 0x00000027 | 0xff       | 255        | 

Memoria de Datos (Por palabras de 32 bits)

| Dirección  | Palabra (Hex) | Palabra (Dec) | 
| ---------- | ------------- | ------------- | 
| 0x00000020 | 0x0000002a    | 42            | 
| 0x00000024 | 0xfffffff6    | -10           | 

