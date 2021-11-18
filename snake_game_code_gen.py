max_snake_size = 192

# CODE GEN 1
print("; CODE GEN 1")
for i in range(1, max_snake_size+1-1):
    print(f"""    LOAD NextX
    SUB Body{i}X
    JNEG EndBodyCheck{i}
    JPOS EndBodyCheck{i}
    LOAD NextY
    SUB Body{i}Y
    JZERO SnakeLose
    EndBodyCheck{i}:""")

print(f"""    LOAD EatingApple
    JPOS BodyCheck{max_snake_size} ; if eating apple, check last body part
    JUMP EndBodyCheck{max_snake_size}
    BodyCheck{max_snake_size}:
    LOAD NextX
    SUB Body{max_snake_size}X
    JNEG EndBodyCheck{max_snake_size}
    JPOS EndBodyCheck{max_snake_size}
    LOAD NextY
    SUB Body{max_snake_size}Y
    JNEG EndBodyCheck{max_snake_size}
    JPOS EndBodyCheck{max_snake_size}
    JUMP SnakeLose
    EndBodyCheck{max_snake_size}:""")

# LOAD NextX
# SUB Body1X
# JNEG EndBodyCheck1
# JPOS EndBodyCheck1
# LOAD NextY
# SUB Body1Y
# JNEG EndBodyCheck1
# JPOS EndBodyCheck1
# JUMP SnakeLose
# EndBodyCheck1:
# LOAD NextX
# SUB Body2X
# JNEG EndBodyCheck2
# JPOS EndBodyCheck2
# LOAD NextY
# SUB Body2Y
# JNEG EndBodyCheck2
# JPOS EndBodyCheck2
# JUMP SnakeLose
# EndBodyCheck2:
# LOAD NextX
# SUB Body3X
# JNEG EndBodyCheck3
# JPOS EndBodyCheck3
# LOAD NextY
# SUB Body3Y
# JNEG EndBodyCheck3
# JPOS EndBodyCheck3
# JUMP SnakeLose
# EndBodyCheck3:
# LOAD NextX
# SUB Body4X
# JNEG EndBodyCheck4
# JPOS EndBodyCheck4
# LOAD NextY
# SUB Body4Y
# JNEG EndBodyCheck4
# JPOS EndBodyCheck4
# JUMP SnakeLose
# EndBodyCheck4:

# LOAD EatingApple
# JPOS BodyCheck5 ; if eating apple, check last body part
# JUMP EndBodyCheck5
# BodyCheck5:
# LOAD NextX
# SUB Body5X
# JNEG EndBodyCheck5
# JPOS EndBodyCheck5
# LOAD NextY
# SUB Body5Y
# JNEG EndBodyCheck5
# JPOS EndBodyCheck5
# JUMP SnakeLose
# EndBodyCheck5:

# CODE GEN 2
print("\n\n\n\n\n    ; CODE GEN 2")
for i in range(max_snake_size, 2-1, -1):
    print(f"""    LOAD Body{i-1}X
    STORE Body{i}X
    LOAD Body{i-1}Y
    STORE Body{i}Y""")

print("""    ; now Body1 is open to fill in
    LOAD NextX
    STORE Body1X
    LOAD NextY
    STORE Body1Y""")

# LOAD Body4X
# STORE Body5X
# LOAD Body4Y
# STORE Body5Y
# LOAD Body3X
# STORE Body4X
# LOAD Body3Y
# STORE Body4Y
# LOAD Body2X
# STORE Body3X
# LOAD Body2Y
# STORE Body3Y
# LOAD Body1X
# STORE Body2X
# LOAD Body1Y
# STORE Body2Y
# ; now Body1 is open to fill in
# LOAD NextX
# STORE Body1X
# LOAD NextY
# STORE Body1Y

# CODE GEN 3
print("\n\n\n\n\n; CODE GEN 3")
print("""    EraseTail: ; only erase tail if we didnt eat an apple!
    ; erase tail - tail will be the (CurBodySize + 1)th body
    LOAD CurBodySize""")
for i in range(2, max_snake_size+1):
    print(f"""    ADDI -1
    JZERO EraseBody{i}""")
print()
for i in range(2, max_snake_size+1):
    print(f"""    EraseBody{i}:
        LOAD Body{i}X
        STORE   XYToIndexX
        LOAD Body{i}Y
        STORE   XYToIndexY
        JUMP EndEraseBody""")
print()
print("    EndEraseBody:")

# EraseTail: ; only erase tail if we didnt eat an apple!
#     ; erase tail - tail will be the (CurBodySize + 1)th body
#     LOAD CurBodySize
    # ADDI -1
    # JZERO EraseBody2
    # ADDI -1
    # JZERO EraseBody3
    # ADDI -1
    # JZERO EraseBody4
    # ADDI -1
    # JZERO EraseBody5
    
    # EraseBody2:
    #     LOAD Body2X
    #     STORE   XYToIndexX
    #     LOAD Body2Y
    #     STORE   XYToIndexY
    #     JUMP EndEraseBody
    # EraseBody3:
    #     LOAD Body3X
    #     STORE   XYToIndexX
    #     LOAD Body3Y
    #     STORE   XYToIndexY
    #     JUMP EndEraseBody
    # EraseBody4:
    #     LOAD Body4X
    #     STORE   XYToIndexX
    #     LOAD Body4Y
    #     STORE   XYToIndexY
    #     JUMP EndEraseBody
    # EraseBody5:
    #     LOAD Body5X
    #     STORE   XYToIndexX
    #     LOAD Body5Y
    #     STORE   XYToIndexY
    #     JUMP EndEraseBody

    # EndEraseBody:

# CODE GEN 4
print("\n\n\n\n\n; CODE GEN 4")
for i in range(1, max_snake_size+1):
    print(f"""Body{i}X:        DW 0
Body{i}Y:        DW 0""")

# Body1X:        DW 0
# Body1Y:        DW 0
# Body2X:        DW 0
# Body2Y:        DW 0
# Body3X:        DW 0
# Body3Y:        DW 0
# Body4X:        DW 0
# Body4Y:        DW 0
# Body5X:        DW 0
# Body5Y:        DW 0
