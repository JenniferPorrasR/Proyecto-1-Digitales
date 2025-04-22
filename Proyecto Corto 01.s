.data
player1: .word 0         #posición del primer jugador 
player2: .word 0         #posición del segundo jugador
old_player1: .word 0     #posición anterior de la primera barra
old_player2: .word 0     #posición anterior de la segunda barra
ballx: .word 17          #posición inicial de la pelota 
bally: .word 12          #posición inicial de la pelota 
x_direction: .word 1     #dirección X de la pelota (1=derecha, -1=izquierda)
y_direction: .word 1     #dirección Y de la pelota (1=abajo, -1=arriba)
score_player1: .word 0   #puntuación del jugador 1 
score_player2: .word 0   #puntuación del jugador 2 
.text
.globl main

main:
li s0, LED_MATRIX_0_BASE    # Dirección base de la matriz 
li s1, LED_MATRIX_0_WIDTH   # Ancho de la matriz 
li s2, LED_MATRIX_0_HEIGHT  # Alto de la matriz
li s4, D_PAD_0_UP           # Dirección para el botón ARRIBA 
li s5, D_PAD_0_LEFT         # Dirección para el botón IZQUIERDA 
li s6, D_PAD_0_DOWN         # Dirección para el botón ABAJO 
li s7, D_PAD_0_RIGHT        # Dirección para el botón DERECHA 
li s9, 0                    # Flag para indicar el cambio en la barra del primer jugador
li s10, 0                   # Flag para indicar el cambio en la barra del segundo jugador 

#posición del primer jugador
la t0, player1
lw s3, 0(t0)           
la t0, old_player1
sw s3, 0(t0)              

#posición del segundo jugador 
la t0, player2
lw s8, 0(t0)              
la t0, old_player2
sw s8, 0(t0)              

#posición inicial y movimiento de la pelota
la t0, ballx
lw a3, 0(t0)              
la t0, bally
lw a4, 0(t0)              
la t0, x_direction
lw a5, 0(t0)              
la t0, y_direction
lw a6, 0(t0)              

#Dibuja las barras de los jugadores y la pelota 
jal ra, display_leds
jal ra, score       
li a7, 0xF14E96           
jal ra, draw_ball

main_loop:
li s9, 0                  
li s10, 0       
          
#controles para el primer jugador
lw t0, 0(s4)
beqz t0, left_button   #si el botón izquierdo no está presionado comprueba el siguiente botón
la t0, old_player1
sw s3, 0(t0)              
addi s3, s3, -1            #si el boton hacia arriba está presionado, mover hacia arriba 
li s9, 1                  
j player1_parameter

left_button:
lw t0, 0(s5)
beqz t0, down_button       # si no está presionado, se comprueban los demas botones
la t0, old_player1
sw s3, 0(t0)          
addi s3, s3, 1             #si está presionado, mover hacia abajo
li s9, 1              
j player1_parameter

#controles para el segundo jugador
down_button:
lw t0, 0(s6)
beqz t0, right_button     #si no está presionado, se comprueba el botón de la derecha
la t0, old_player2
sw s8, 0(t0)              
addi s8, s8, 1            #si está presionado, mover hacia abajo 
li s10, 1                 
j player2_parameter

right_button:
lw t0, 0(s7)
beqz t0, update_display   
la t0, old_player2
sw s8, 0(t0)          
addi s8, s8, -1           #si está presionado, mover hacia arriba 
li s10, 1                 
j player2_parameter

player1_parameter:
li t0, 0
blt s3, t0, min_value_player1
li t0, 22                 
bgt s3, t0, max_value_player1
j player2_parameter      

min_value_player1:
li s3, 0                  
j player2_parameter

max_value_player1:
li s3, 22                 
j player2_parameter

player2_parameter:
li t0, 0
blt s8, t0, min_value_player2
li t0, 22                 
bgt s8, t0, max_value_player2
j update_display

min_value_player2:
li s8, 0              
j update_display

max_value_player2:
li s8, 22                 

update_display:
beqz s9, player2_change
la t0, player1
sw s3, 0(t0)              
jal ra, update_player1        

player2_change:
beqz s10, ball_position
la t0, player2
sw s8, 0(t0)              
jal ra, update_player2     

ball_position:
mul t0, a4, s1            
add t0, t0, a3            
slli t0, t0, 2            
add t0, t0, s0            
sw zero, 0(t0)            #borra la pelota de la posición actual 
add t1, a3, a5             
li t3, 0
bne t1, t3, player2_bar_position 
j player1_bar          

player2_bar_position:
li t3, 34
bne t1, t3, game_walls 
j player2_bar          

player1_bar:
sub t2, a4, s3         
bltz t2, player1_lost  
li t3, 3                  
bge t2, t3, player1_lost  
li a5, 1                  
j game_walls

player2_bar:
sub t2, a4, s8            
bltz t2, player2_lost     
li t3, 3                  
bge t2, t3, player2_lost  
li a5, -1                 
j game_walls

player1_lost:
la t0, score_player2
lw t1, 0(t0)         
addi t1, t1, 1       
sw t1, 0(t0)         
jal ra, score 
li a3, 17             
li a4, 12             
li a5, 1              
j reset_game_delay

player2_lost:
la t0, score_player1
lw t1, 0(t0)         
addi t1, t1, 1    
sw t1, 0(t0)      
jal ra, score 
li a3, 17             
li a4, 12         
li a5, -1             
j reset_game_delay

reset_game_delay:
li t1, 50
delay_after_reset:
addi t1, t1, -1
bnez t1, delay_after_reset

game_walls:
li t3, -1
beq t1, t3, player1_lost
beq t1, s1, player2_lost

add a3, a3, a5            

add t1, a4, a6            
bltz t1, move_ball_down 
li t2, 25      
bge t1, t2, move_ball_up  
j update_ball_movement       

move_ball_down:
li a6, 1                  
j update_ball_movement

move_ball_up:
li a6, -1                 

update_ball_movement:
add a4, a4, a6            
j draw_ball_new_position

draw_ball_new_position:
li a7, 0xF14E96           
jal ra, draw_ball
la t0, ballx
sw a3, 0(t0)              
la t0, bally
sw a4, 0(t0)              
la t0, x_direction
sw a5, 0(t0)              
la t0, y_direction
sw a6, 0(t0)              
j main_loop

update_player1:
la t0, old_player1
lw t0, 0(t0)              
li t1, 140                
mul t0, t0, t1            
add t1, s0, t0            
sw zero, 0(t1)            
sw zero, 140(t1)          
sw zero, 280(t1)          
li t1, 140                
mul t0, s3, t1            
add t1, s0, t0            
li t2, 0xFBABF5           
sw t2, 0(t1)              
sw t2, 140(t1)            
sw t2, 280(t1)            
ret

update_player2:
la t0, old_player2
lw t0, 0(t0)              
li t1, 140                
mul t0, t0, t1            
add t1, s0, t0            
addi t1, t1, 136          
sw zero, 0(t1)            
sw zero, 140(t1)          
sw zero, 280(t1)          
li t1, 140                
mul t0, s8, t1            
add t1, s0, t0            
addi t1, t1, 136          
li t2, 0xA3FDA8           
sw t2, 0(t1)              
sw t2, 140(t1)            
sw t2, 280(t1)            
ret

display_leds:
#dibuja la barra del jugador 1
li t1, 140                
mul t0, s3, t1            
add t1, s0, t0            
li t2, 0xFBABF5           
sw t2, 0(t1)              
sw t2, 140(t1)            
sw t2, 280(t1)            

#dibuja la barra del jugador 2
li t1, 140                
mul t0, s8, t1            
add t1, s0, t0            
addi t1, t1, 136          
li t2, 0xA3FDA8           
sw t2, 0(t1)              
sw t2, 140(t1)            
sw t2, 280(t1)            
ret

draw_ball:
mul t0, a4, s1            
add t0, t0, a3            
slli t0, t0, 2            
add t0, t0, s0            
sw a7, 0(t0)              
ret

score:
addi s11, s11, 0
sw ra, 0(s11)

la t0, score_player1
lw t1, 0(t0)      
li t2, 26            
li t3, 0xFBABF5  
li t0, 0   
jal ra, draw_score

la t0, score_player2
lw t1, 0(t0)         
li t2, 27            
li t3, 0xA3FDA8      
li t0, 0
jal ra, draw_score

lw ra, 0(s11)
addi s11, s11, 0
  
draw_score:
blez t1, end  
mul t4, t2, s1       
add t4, t4, t0       
slli t4, t4, 2       
add t4, t4, s0       
sw t3, 0(t4)         
addi t0, t0, 1       
addi t1, t1, -1      
j draw_score
    
end:
ret