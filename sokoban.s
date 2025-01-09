.data
gridsize:   .byte 8,8
character:  .byte 0,0
ogCharacter: .byte 0,0
box:        .byte 0,0
ogBox:      .byte 0,0
target:     .byte 0,0
ogTarget:   .byte 0,0

wallChar: 	.string "#"
floorChar: 	.string "_"
playerChar: .string "X"
boxChar: 	.string "B"
targetChar: .string "O"

up: 		.string "w"
down: 		.string "s"
left:		.string "a"
right:		.string "d"
reset: 		.string "r"

win: 		.string "Congratulations! You have completed your turn!"
playAgain:  .string "Would you like to play again? (yes = 1, no = 2)\n"
wallHit: 	.string "*bonk* you hit a wall! make a different move.\n"
numPlayers: .string "How many players?"
moves: 		.string "Moves Made: "
currplay:	.string "Now Playing: Player "
player: 	.string " Player "

newline: 	.string "\n"
newlines: 	.string "\n\n\n\n"
.text
.globl _start
# Reference for psuedorandom number generator
# [1] Linear congruential generator. 1958. W. E. Thomson and A. Rotenberg
# [2] Tony Zhang. 2021. How computers generate RANDOMNESS from math. Video. (25 August 2021).
# Retrieved April 18, 2024 from https://www.youtube.com/watch?v=nBq4sFg3at0

# partial implenentation of the multiplayer is inside WHILE and an attempt of printing a leaderboard is
# at the bottom. Also, there is a regen function to restore the board for the next player down there.
#IMPLEMENTATIONL: basically, there is a counter that is the number of players in the game. Additionally,
#there is a move counter. once a turn is complete, the moves is stored into the stack and the current turn
#is incresed. this repeates until all players have played.

_start:
    # TODO: Generate locations for the character, box, and target. Static
    # locations in memory have been provided for the (x, y) coordinates 
    # of each of these elements.
    # 
    # There is a notrand function that you can use to start with. It's 
    # really not very good; you will replace it with your own rand function
    # later. Regardless of the source of your "random" locations, make 
    # sure that none of the items are on top of each other and that the 
    # board is solvable.
	
	# TODO: check if not in corner 
	# IDEA: check if box is spawned on wall, if so, place target along 
	# same wall so only generate one coord
	
	# SEMI PERMANANT COORDS 
	# a5, a6, is grid size
	# t1, t2, is player coords
	# t3, t4, is box coods
	# t5, t6 is target coords
	
	li sp, 0x80000000
	
	#seed = sys time = a1
	# s11 will be used to keep the current score
	li s11, 0

	li a7, 30
    ecall
	mv a1, a0
	
	#load max coords
	la s1, gridsize
	lb a5, 0(s1)
	lb a6, 1(s1)
	addi s4, a5, -1
	addi s5, a5, -1
	
	#ask player for how many people will be playing
	la a0, numPlayers
	li a7, 4
	ecall
	
	li a7, 5
	ecall
	mv s10, a0
	li s9, 1
	
	
	generate:
	# Load coords for character
   	la s1, character
    
	mv a0, a5
	jal prng
    sb a0, 0(s1)
	mv t1, a0
	mv a0, a6
	jal prng
	sb a0, 1(s1)
	mv t2, a0
	
	# Load coords for 
	genbox:
	la s1, box
	mv a0, a5
	jal prng
	sb a0, 0(s1)
	mv t3, a0
	mv a0, a6
	jal prng
	sb a0, 1(s1)
	mv t4, a0
	
	#check if box is on top of player regen appropriately
	bne t1, t3, gentarget
	beq t2, t4, genbox
	
	#check if box is in a corner:
	# 0, 0
	bne t3, zero, c2
	beq t4, zero, genbox
	# 0, a6
	beq t4, s5, genbox
	j gentarget
	# a5, 0
	c2:
	bne t3, s4, gentarget
	beq t4, s5, genbox
	beq t4, zero, genbox
	
	# Load coords for target
	gentarget:
	la s1, target
	mv a0, a5
	jal prng
	sb a0, 0(s1)
	mv t5, a0
	mv a0, a6
	jal prng
	sb a0, 1(s1)
	mv t6, a0
	
	# check if target is on player
	bne t5, t1, check
	beq t6, t2, gentarget
	check:
	# check if target is on box
	bne t5, t3, n
	beq t6, t4, gentarget
	
	n:
	#check if box is on wall
	beq t3, zero, wallTop
	beq t4, zero, wallLeft
	beq t3, s4, wallBottom
	beq t4, s5, wallRight
	jal store
	j WHILE
	#if box is on wall and target is not reload the spawn
	wallLeft:
	bne t6, zero, gentarget
	jal store
	j WHILE
	wallTop:
	bne t5, zero, gentarget
	jal store
	j WHILE
	wallRight:
	bne t6, s5, gentarget
	jal store
	j WHILE
	wallBottom:
	bne t5, s4, gentarget
	jal store
	j WHILE
   
    # TODO: Now, print the gameboard. Select symbols to represent the walls,
    # character, box, and target. Write a function that uses the location of
    # the various elements (in memory) to construct a gameboard and that 
    # prints that board one character at a time.
    # HINT: You may wish to construct the string that represents the board
    # and then print that string with a single syscall. If you do this, 
    # consider whether you want to place this string in static memory or 
    # on the stack. 
	jal store
	j WHILE
	printBoard:
		mv t1, a5
		mv t4, a6
		li t2, 0
		li t3, 0
		
		jal placewall
		topwall:
			jal placewall
			addi t2, t2, 1
			bne t2, t1, topwall
			jal placewall
			# place a new line
			la a0, newline
			ecall
		
		topish:
		jal placewall
		mv t2, zero
		inside:
		#load coords of player
		la s1, character
		
		lb a1, 0(s1)
		lb a2, 1(s1)
		bne a1, t2, checkbox
		bne a2, t3, checkbox
		la a0, playerChar
		ecall
		j otherplaced
		
		#load coords of box
		checkbox:
		la s1, box
		
		lb a1, 0(s1)
		lb a2, 1(s1)
		bne a1, t2, checktarget
		bne a2, t3, checktarget
		la a0, boxChar
		ecall
		j otherplaced
		
		#load coords of target
		checktarget:
		la s1, target
		
		lb a1, 0(s1)
		lb a2, 1(s1)
		bne a1, t2, placefloor
		bne a2, t3, placefloor
		la a0, targetChar
		ecall
		j otherplaced
		
			placefloor:
			la a0, floorChar
			li a7, 4
			ecall
			otherplaced:
			addi t2, t2, 1
			bne t2, t1, inside
			jal placewall
			addi t3, t3, 1
			la a0, newline
			ecall
			bne t3, t4, topish
			
			
			
		jal placewall
		mv t2, zero
		bottomwall:
			jal placewall
			addi t2, t2, 1
			bne t2, t1, bottomwall
			jal placewall
			# place a new line
			la a0, newline
			ecall
		jr t6
		
		
		
    # TODO: Enter a loop and wait for user input. Whenever user input is
    # received, update the gameboard state with the new location of the 
    # player (and if applicable, box and target). Print a message if the 
    # input received is invalid or if it results in no change to the game 
    # state. Otherwise, print the updated game state. 
    #
    # You will also need to restart the game if the user requests it and 
    # indicate when the box is located in the same position as the target.
    # For the former, it may be useful for this loop to exist in a function,
    # to make it cleaner to exit the game loop.	
	
	WHILE:	
	li a7, 4
	la a0, currplay
	ecall
	#addi s9, s9, 1
	mv a0, s9
	li a7, 1
	ecall
	la a0, newline
	li a7, 4
	ecall
	jal t6, printBoard
	lb t1, up
	lb t2, down
	lb t3, left
	lb t4, right
	lb t5, reset
	li a7, 12
	ecall
	mv t0, a0
	li a7, 4
	la a0, newlines
	ecall
	
	
	#a1 and a2 will store row/col direction
	
	beq t0, t1, moveUp
	beq t0, t2, moveDown
	beq t0, t3, moveLeft
	beq t0, t4, moveRight
	beq t0, t5, regen
	j exit
	
	moveUp:
	li a1, 0
	li a2, -1
	j performMove
	moveDown:
	li a1, 0
	li a2, 1
	j performMove
	moveLeft:
	li a1, -1
	li a2, 0
	j performMove
	moveRight:
	li a1, 1
	li a2, 0
	j performMove
	regen:
	j _start
	
	performMove:
	la s1, character
	la s2, box
	addi s11, s11, 1
	
	# move row for character
	lb t1, 0(s1)
	add t1, t1, a1
	sb t1, 0(s1)
	
	#move col for character
	lb t2, 1(s1)
	add t2, a2, t2
	sb t2, 1(s1)
	
	#load coords of box into temps
	lb t3, 0(s2)
	lb t4, 1(s2)
	
	bne t3, t1, checkCollision
	bne t4, t2, checkCollision
	
	#move box in same direction
	add t3, t3, a1
	add t4, t4, a2
	sb t3, 0(s2)
	sb t4, 1(s2)
	
	#revert move if inside wall player only
	la a0, wallHit
	li a7, 4
	checkCollision:
	# row -1
	li s5, -1
	bne t1, s5, checkCol
	sub t1, t1, a1
	sb t1, 0(s1)
	addi s11, s11, -1
	la a0, wallHit
	li a7, 4
	ecall
	checkCol:
	bne t2, s5, max
	sub t2, t2, a2
	sb t2, 1(s1)
	addi s11, s11, -1
	la a0, wallHit
	li a7, 4
	ecall
	
	max:
	bne t1, a5, checkMaxCol
	sub t1, t1, a1
	sb t1, 0(s1)
	addi s11, s11, -1
	la a0, wallHit
	li a7, 4
	ecall
	checkMaxCol:
	bne t2, a6, checkBoxCollision
	sub t2, t2, a2
	sb t2, 1(s1)
	addi s11, s11, -1
	la a0, wallHit
	li a7, 4
	ecall
	
	checkBoxCollision:
	#revert both player and box
	bne t3, s5, checkBoxCol
	sub t1, t1, a1
	sb t1, 0(s1)
	sub t3, t3, a1
	sb t3, 0(s2)
	addi s11, s11, -1
	ecall
	
	checkBoxCol:
	bne t4, s5, max2
	sub t2, t2, a2
	sb t2, 1(s1)
	sub t4, t4, a2
	sb t4, 1(s2)
	addi s11, s11, -1
	ecall
	
	max2:
	bne t3, a5, checkBoxMaxCol
	sub t1, t1, a1
	sb t1, 0(s1)
	sub t3, t3, a1
	sb t3, 0(s2)
	addi s11, s11, -1
	ecall
	
	checkBoxMaxCol:
	bne t4, a6, next
	sub t2, t2, a2
	sb t2, 1(s1)
	sub t4, t4, a2
	sb t4, 1(s2)
	addi s11, s11, -1
	ecall
	
	
	next:
	#check if coords of box == coords of target then display win if so.
	la s3, target
	lb t1, 0(s3)
	lb t2, 1(s3)
	bne t1, t3, reloop
	bne t2, t4, reloop
	
	# display win message
	jal t6, printBoard
	li a7, 4
	la a0, win
	ecall
	la a0, newline
	ecall
	# display how many moves it took and whos turn is next
	la a0, moves
	ecall
	li a7, 1
	mv a0, s11
	ecall
	li a7, 4
	la a0, newlines
	ecall
	
	#cycle back to give next player a chance to play
	beq s9, s10, endGame
	#store score in stack
	#increment player number
	
	addi sp, sp, -8
	sw s11, 0(sp)
	sw s9, 4(sp)
	addi s9, s9, 1
	li s11, 0
	j regenerate
	
	
	endGame:
	#jal printLeaderboard
	la a0, playAgain
	ecall
	li a7, 5
	ecall
	
	li s7, 1
	beq a0, s7, _start
	
	j exit
	
	reloop:
	j WHILE
    # TODO: That's the base game! Now, pick a pair of enhancements and
    # consider how to implement them.
	
exit:
    li a7, 10
    ecall
    
    
# --- HELPER FUNCTIONS ---
# Feel free to use, modify, or add to them however you see fit.
     
# Arguments: an integer MAX in a0
# Return: A number from 0 (inclusive) to MAX (exclusive)
notrand:
	li a0, 8
    mv t0, a0
    li a7, 30
    ecall             # time syscall (returns milliseconds)
    remu a0, a0, t0   # modulus on bottom bits 
    li a7, 32
    ecall             # sleeping to try to generate a different number
    jr s9

prng:
	mv a2, a0
	#addi a2, a2, 1
	li t0, 65537
	li a3, 75
	mv a0, a1
	mul a0, a0, a3
	addi a0, a0, 74
	remu a0, a0, t0
	mv a1, a0
	remu a0, a0, a2
	jr ra

placewall:
	la a0, wallChar
	li a7, 4
	ecall
	jr ra
	
regenerate: 
	la s1, ogBox
	la s2, box
	lb t1, 0(s1)
	lb t2, 1(s1)
	sb t1, 0(s2)
	sb t2, 1(s2)
	
	la s1, ogCharacter
	la s2, character
	lb t1, 0(s1)
	lb t2, 1(s1)
	sb t1, 0(s2)
	sb t2, 1(s2)
	
	la s1, ogTarget
	la s2, target
	lb t1, 0(s1)
	lb t2, 1(s1)
	sb t1, 0(s2)
	sb t2, 1(s2)
	j WHILE
	
store:
	#store og coords before any moves are made
	la a1, box
	la a2, ogBox
	lb t1, 0(a1)
	lb t2, 1(a1)
	sb t1, 0(a2)
	sb t2, 1(a2)
	
	la a1, character
	la a2, ogCharacter
	lb t1, 0(a1)
	lb t2, 1(a1)
	sb t1, 0(a2)
	sb t2, 1(a2)
	
	la a1, target
	la a2, ogTarget
	lb t1, 0(a1)
	lb t2, 1(a1)
	sb t1, 0(a2)
	sb t2, 1(a2)
	ret

printLeaderboard:
	# a1 is the maxscore
	# a2 is the player asociated
	# t0 is the loop variable
	# a3 holds the og sp
	# a4 holds outer loop variable
	li t0, 1
	li a4, 1
	li a1, 0
	li a2, 0
	mv a3, sp
	lop:
	mv sp, a3
	li t0, 0
	bne a4, s10, loopy
	ret
	loopy:
		#load score
		lw t1, 0(sp)
		#check if bigger than max
		bge t1, a1, replacemax
		after:
		addi t0, t0, 1
		addi sp, sp, 8
		beq t0, s10, printname
		j loopy
		
	printname:
		la a0, moves
		li a7, 4
		ecall
	    li a7, 1
		mv a0, a1
		ecall
		la a0, moves
		li a7, 4
		ecall
		mv a0, a2
		li a7, 1
		ecall
		la a0, newline
		li a7, 4
		ecall
		addi a4, a4, 1
		j lop
	
	replacemax:
		mv a1, t1
		lw a2, 0(sp)
		sw zero, 0(sp)
		sw zero, 0(sp)
		j after
