use std::env;
use std::io::Read;
use std::io::Write;
use std::str;

fn main() {
    // getting input argument, which is the path to the selected mem file
    let args: Vec<String> = env::args().collect();
    let path = &args[1].to_string();
    let path_exp = &args[2].to_string();
    // opens the file
    let mut file = std::fs::File::open(path).unwrap();
    let mut contents = String::new();
    file.read_to_string(&mut contents).unwrap();
    
    let b = contents.as_bytes();
     println!("{:?}", b);
    // get the @ Adress, since header can variate
    let pos = b.iter().position(|&x| x == 64).unwrap();
    println!("{:?}", pos);
    // iterate through the vector
    let filter : Vec<u8> = b
                                            .iter()
                                            .clone()
                                            .skip(pos + 10)
                                            .filter(|x| {
                                                // 0-9
                                                **x == 48 || 
                                                **x == 49 || 
                                                **x == 50 ||
                                                **x == 51 || 
                                                **x == 52 ||
                                                **x == 53 || 
                                                **x == 54 || 
                                                **x == 55 ||
                                                **x == 56 || 
                                                **x == 57 ||
                                                // a-f
                                                **x == 65 || 
                                                **x == 66 || 
                                                **x == 67 ||
                                                **x == 68 || 
                                                **x == 69 ||
                                                **x == 70} )
                                            .map(|x| *x)
                                            .collect();
    // instruction code only
    // println!("{:?}", filter);
    println!("Number of instructions {:?}", (filter.len() / 8));
    //
    // let instructions_num_usize = filter.len().to_string();
    // let instructions_num = instructions_num_usize.parse::<i32>().unwrap();

    // creates a new file
    let mut file_create = std::fs::File::create(path_exp).expect("create failed");
    // write start address @00000000
    file_create.write_all("@00000000".as_bytes()).expect("write failed");
    // getting all instructions
    // for i in  0..instructions_num{
    for _i in  (0..filter.len()).step_by(8){
        // debug
        //println!("i is {}", _i);
        // vector which holds the instruction
        let mut empty: Vec<u8> = vec![0;8];
        // creating the vector new for every instruction
        for j in 0..8{
            // debug
            //println!("j is {}", j);

            empty[7-j] = filter[j+_i];
        }
        // println!("After Loop: {:?}",&empty);
        // swaping bytes
        let mut instruction:Vec<u8> = vec![0;8];
        instruction[0] = empty[1];
        instruction[1] = empty[0];
        instruction[2] = empty[3];
        instruction[3] = empty[2];
        instruction[4] = empty[5];
        instruction[5] = empty[4];
        instruction[6] = empty[7];
        instruction[7] = empty[6];
        // debug
        // println!("Writing {:?} the mem file", str::from_utf8(&instruction).unwrap());

        file_create.write_all("\n".as_bytes()).expect("write failed");
        file_create.write_all(&instruction).expect("write failed");
    }
}
