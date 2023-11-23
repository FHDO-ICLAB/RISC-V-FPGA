use std::env;
use std::io::Read;
use std::io::Write;
use std::str;

fn main() {
    // getting input argument, which is the path to the selected mem file
    let args: Vec<String> = env::args().collect();
    // input file
    let path = &args[1].to_string();
    // output file
    let path_exp = &args[2].to_string();
    // opens the file
    let mut file = std::fs::File::open(path).unwrap();
    let mut contents = String::new();
    file.read_to_string(&mut contents).unwrap();
    
    let b = contents.as_bytes();
    // println!("{:?}", b);

    
    // write the header for new file
    let mut file_create = std::fs::File::create(path_exp).expect("create failed");
    file_create.write_all("memory_initialization_radix=16;\n".as_bytes()).expect("write failed");
    file_create.write_all("memory_initialization_vector=\n".as_bytes()).expect("write failed");

    // iter through the vector. switch capital to small letters. Add a , for seperating. Last sign mus be ;
    // get the @ Adress, since header can variate
    // let pos = b.iter().position(|&x| x == 64).unwrap();

    // iterate through the vector
    let mut filter : Vec<u8> = b
                                            .into_iter()
                                            .clone()
                                            .skip(10)
                                            .map(|mut x| {
                                                if *x == 65 {x = &97}
                                                else if *x == 66 {x = &98}
                                                else if *x == 67 {x = &99}
                                                else if *x == 68 {x = &100}
                                                else if *x == 69 {x = &101}
                                                else if *x == 70 {x = &102}
                                                else if *x == 10 {x = &44}
                                                else {x = x};
                                                *x
                                            })
                                            .collect();
    // instruction code only
    // println!("Filter is: {:?}", filter);
    // push a last sign for iterating
    filter.push(59);
    println!("Number of instructions {:?}", (filter.len() / 9));
    println!("Filter is: {:?}", filter);

    // getting the instruction numbber for iterating
    // let instructions_num_usize = filter.len().to_string();
    // let instructions_num = instructions_num_usize.parse::<i32>().unwrap();

    // getting all instructions
    // for i in  0..instructions_num{
    for i in  (0..filter.len()).step_by(9){
        // create the new instruction with colon
        let mut instruction:Vec<u8> = vec![0;9];
        instruction[0] = filter[i+0];
        instruction[1] = filter[i+1];
        instruction[2] = filter[i+2];
        instruction[3] = filter[i+3];
        instruction[4] = filter[i+4];
        instruction[5] = filter[i+5];
        instruction[6] = filter[i+6];
        instruction[7] = filter[i+7];
        instruction[8] = filter[i+8];

      
        file_create.write_all(&instruction).expect("write failed");
        file_create.write_all("\n".as_bytes()).expect("write failed");
    }
}
