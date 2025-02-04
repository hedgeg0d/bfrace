module bfck

const tape_size = 20

pub struct Brainfuck {
pub mut:
    tape        []u8
    ptr         int
    code        string
    input       []u8
    input_ptr   int
    last        int
    out         string
}

pub fn new_brainfuck(code string) &Brainfuck {
    return &Brainfuck{
        tape: []u8{len: tape_size, init: 0}
        ptr: 0
        code: code
        input_ptr: 0
    }
}

pub fn (mut bf Brainfuck) add_command(com string) {
  if bf.code.len < 1 {bf.code += com; return}
    match com {
        '+' {if bf.code[bf.code.len-1] == `-` {bf.code = bf.code[0..bf.code.len-1]} else {bf.code += com}}
        '-' {if bf.code[bf.code.len-1] == `+` {bf.code = bf.code[0..bf.code.len-1]} else {bf.code += com}}
        '>' {if bf.code[bf.code.len-1] == `<` {bf.code = bf.code[0..bf.code.len-1]} else {bf.code += com}}
        '<' {if bf.code[bf.code.len-1] == `>` {bf.code = bf.code[0..bf.code.len-1]} else {bf.code += com}}
        ']' {if bf.code[bf.code.len-1] == `[` {bf.code = bf.code[0..bf.code.len-1]} else {bf.code += com}}
        else {bf.code += com}
    }
}

pub fn (mut bf Brainfuck) run()! {
    mut loop_stack := []int{}
    code_len := bf.code.len
    mut iterations := [][2]int{}

    for i := 0; i < code_len; i++ {
        cmd := bf.code[i]
        //bf.last = i + 1

        match cmd {
            `>` { if bf.ptr < tape_size-1 {bf.ptr++} }
            `<` { if bf.ptr > 0 {bf.ptr--} }
            `+` { bf.tape[bf.ptr] = (bf.tape[bf.ptr] + 1) % 256 }
            `-` { bf.tape[bf.ptr] = (bf.tape[bf.ptr] - 1) % 256 }
            `.` { bf.out += bf.tape[bf.ptr].ascii_str()}
            `[` {
              if bf.code.len < 2 {return}
                if bf.tape[bf.ptr] == 0 {
                    mut open_brackets := 1
                    for open_brackets > 0 && i + i < bf.code.len {
                        i++
                        if bf.code[i] == `[` {open_brackets++}
						else if bf.code[i] == `]` {open_brackets--}
                    }
                    if open_brackets != 0 {eprintln("invalid loop");return}
                } else {
                    mut found := -1
                    for n, j in iterations {if j[0] == i {found = n}}
                    if found != -1 {iterations[found][1]++; if iterations[found][1] > 257 {eprintln("endless loop"); return}}
                    else {iterations << [i, 0]!}
                    loop_stack << i
                }
            }
            `]` {
                if loop_stack.len > 0 && bf.tape[bf.ptr] != 0 {i = loop_stack.last() /* Jump back to the matching `[`*/}
				else if loop_stack.len > 0 {loop_stack.delete_last()}
            }
            else {}
        }
    }
}

/*fn main() {
    code := ">++++++++[<+++++++++++++>-]<.---.+++++++..+++.[-]" // Example Brainfuck code

    mut interpreter := new_brainfuck(code)
    interpreter.run()
}*/
