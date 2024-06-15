.data
    # program inputs: matricule & received data
    matricule: .word 1825641         # limit 24 bits
    received_data: .word 0x00000077
    #=============================================================

    r: .word 7

    intro: .string "votre matricule est :"
    out1: .string "message a envoyer = "
    out2: .string "message mappe = "
    out3: .string "Donnees envoyees = "
    rec: .string "Donnees recues = "
    out4: .string "Donnees corrigees = "
    out5: .string "Message envoye = "

.text
    main:
        # Load the value of matricule into register a0
        la a0, matricule
        lw a0, 0(a0)

        # Copy the value of matricule into register t3
        add t3, x0, a0

        # Print the intro message with matricule
        matricule_output:
            la a1, intro
            li a0, 4
            ecall
            mv a1, t3
            li a0, 1
            ecall
            li a1, 10
            li a0, 11
            ecall

        # Load value of r into register a1
        mv a0, t3
        la a1, r
        lw a1, 0(a1)

        # Call function to get the message
        jal get_message_asm
        add t3, x0, a0

        # Print the message to be sent
        output1:
            la a1, out1
            li a0, 4
            ecall
            add a1, t3, x0
            li a0, 34
            ecall
            li a1, 10
            li a0, 11
            ecall

        # Map the message using Hamming code
        mv a0, t3
        jal hamming_map_asm
        add t3, x0, a0

        # Print the mapped message
        output2:
            la a1, out2
            li a0, 4
            ecall
            add a1, t3, x0
            li a0, 34
            ecall
            li a1, 10
            li a0, 11
            ecall

        # Encode the mapped message using Hamming code
        mv a0, t3
        jal hamming_encode_asm
        add t3, x0, a0

        # Print the encoded message
        output3:
            la a1, out3
            li a0, 4
            ecall
            add a1, t3, x0
            li a0, 34
            ecall
            li a1, 10
            li a0, 11
            ecall

        # Print the received data
        received_data_output:
            la a0, received_data
            lw a0, 0(a0)

            add t3, x0, a0

            la a1, rec
            li a0, 4
            ecall
            add a1, t3, x0
            li a0, 34
            ecall
            li a1, 10
            li a0, 11
            ecall

        # Decode the received data (correct errors)
        mv a0, t3
        jal hamming_decode_asm
        add t3, x0, a0

        # Print the corrected data
        output4:
            la a1, out4
            li a0, 4
            ecall
            add a1, t3, x0
            li a0, 34
            ecall
            li a1, 10
            li a0, 11
            ecall

        # Unmap the corrected data
        mv a0, t3
        jal hamming_unmap_asm
        add t3, x0, a0

        # Print the final message to be sent
        output5:
            la a1, out5
            li a0, 4
            ecall
            add a1, t3, x0
            li a0, 34
            ecall
            li a1, 10
            li a0, 11
            ecall

        # End program
        li a0, 10
        ecall



    
    # functions used in the main      : 
    
    get_message_asm: 
        addi sp, sp, -12

        sw t0,8(sp)
        sw t1,4(sp)
        sw t2,0(sp)

        mv t1,a1
        not t0, a0
        not t2,a0
        sll t0,t0,t1

        neg t1, t1 
        addi t1, t1, 32  
        srl t2,t2,t1 

        or t0,t0,t2

        li t2, 0xFFFFFF
        and t0,t0,t2

        mv a0,t0

        lw t0,8(sp)
        lw t1,4(sp)
        lw t2,0(sp)

        addi sp, sp , 12
        jr ra

    hamming_map_asm:
        addi sp,sp, -12

        sw t0,8(sp)
        sw t1, 4(sp)
        sw t2, 0(sp)

        andi t0,a0,1 
        slli t0,t0,2  


        andi t1,a0,14 
        slli t1,t1,3    

        xor t0, t0, t1  

        li t2,0x7F0
        and t1, a0, t2
        slli t1,t1,4    

        xor t0,t0,t1    # half of the number is complete now (2 octs)

        li t2 , 0xFFF800
        and t1,a0,t2 
        slli t1,t1,5

        xor t0,t0,t1     #number is complete

        mv a0,t0

        lw t0,8(sp)
        lw t1,4(sp)
        lw t2,0(sp)

        addi sp, sp , 12

        jr ra

    parity:
        addi sp,sp, -12

        sw t0,8(sp)
        sw t1, 4(sp)
        sw t2, 0(sp)


        mv t0,a1
        li t1,0 
        loop : 
            beqz t0, exit 
            
            andi t2,t0,1    
            add t1,t2,t1

            srli t0,t0,1
            j loop 
        exit :
            mv a1,t1

            lw t0,8(sp)
            lw t1,4(sp)
            lw t2,0(sp)

            addi sp, sp , 12

            jr ra


    hamming_encode_asm: 
        addi sp,sp, -12

        sw t1,8(sp)
        sw t0, 4(sp)
        sw t2, 0(sp)

        mv t1,ra  #save the return adress to the caller

        add t0,x0,a0

        li t2,0x55555554 
        and a1,t2,a0 
        jal parity
        andi a1,a1,1
        or t0,t0,a1 


        li t2, 0x66666664
        and a1,t2,a0
        jal parity
        andi a1,a1,1
        slli a1,a1,1
        or t0,t0,a1
    
        li t2, 0x78787870
        and a1,t2,a0
        jal parity
        andi a1,a1,1
        slli a1,a1,3
        or t0,t0,a1

        li t2, 0x7F807F00
        and a1,t2,a0
        jal parity
        andi a1,a1,1
        slli a1,a1,7
        or t0,t0,a1

        li t2, 0x7FFF0000
        and a1,t2,a0
        jal parity
        andi a1,a1,1
        slli a1,a1,15
        or t0,t0,a1


        mv ra,t1
        mv a0,t0

        lw t1,8(sp)
        lw t0,4(sp)
        lw t2,0(sp)

        addi sp, sp , 12

        jr ra
    
    hamming_decode_asm:

        addi sp,sp, -12

        sw t1,8(sp)
        sw t0, 4(sp)
        sw t2, 0(sp)

        mv t1,ra  #save the return adress to the caller

        li t0,0

        li t2,0x55555555
        and a1,t2,a0
        jal parity
        andi a1,a1,1
        or t0,t0,a1          #c0

        li t2,0x66666666
        and a1,t2,a0
        jal parity
        andi a1,a1,1
        slli a1,a1,1
        or t0,t0,a1          #c1

        li t2,0x78787878
        and a1,t2,a0
        jal parity
        andi a1,a1,1
        slli a1,a1,2
        or t0,t0,a1        #c2

        li t2,0x7F807F80
        and a1,t2,a0
        jal parity
        andi a1,a1,1
        slli a1,a1,3
        or t0,t0,a1          #c3

        li t2,0x7FFF8000
        and a1,t2,a0
        jal parity
        andi a1,a1,1
        slli a1,a1,4
        or t0,t0,a1          #c4

        beqz t0,correct 
        correct : 
            li t2,1
            sll t2,t2,t0
            srli t2,t2,1
            xor t0,a0,t2

        mv ra,t1
        mv a0,t0

        lw t1,8(sp)
        lw t0,4(sp)
        lw t2,0(sp)

        addi sp, sp , 12

        jr ra
    
    hamming_unmap_asm: 
        addi sp,sp, -8

        sw t0, 4(sp)
        sw t1, 0(sp)

        add t0,x0,a0

        andi t1,t0,4
        srli t1,t1,2
        
        srli t0,t0,3
        or t0,t0,t1

        andi t1,t0,0xF
        srli t0,t0,5
        slli t0,t0,4
        or t0,t1,t0

        andi t1,t0,0x7FF
        srli t0,t0,12
        slli t0,t0,11
        or t0,t1,t0

        slli t0,t0, 3
        srli t0,t0,3

        mv a0, t0
        
        lw t0,4(sp)
        lw t1,0(sp)

        addi sp,sp ,8
        jr ra
    

















