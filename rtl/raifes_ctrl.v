`include "raifes_ctrl_constants.vh"
`include "raifes_alu_ops.vh"
`include "rv32_opcodes.vh"
`include "raifes_csr_addr_map.vh"

module raifes_ctrl(
                   input                              clk,
                   input                              reset,
                   input [`INST_WIDTH-1:0]            inst_DX,
                   input                              imem_wait,
                   input                              imem_badmem_e,        // hardwired to 0
                   input                              dmem_wait,
                   input                              dmem_badmem_e,        // hardwired to 0    
                   input                              cmp_true,
		   input			      pcpi_ready,
		   input			      pcpi_wait,
		   output reg			      pcpi_valid,
                   input [`PRV_WIDTH-1:0]             prv,
                   output reg [`PC_SRC_SEL_WIDTH-1:0] PC_src_sel,
                   output reg [`IMM_TYPE_WIDTH-1:0]   imm_type,
                   output                             bypass_rs1,
                   output                             bypass_rs2,
                   output reg [`SRC_A_SEL_WIDTH-1:0]  src_a_sel,
                   output reg [`SRC_B_SEL_WIDTH-1:0]  src_b_sel,
                   output reg [`ALU_OP_WIDTH-1:0]     alu_op,
                   output wire                        dmem_en,
                   output wire                        dmem_wen,
                   output wire [2:0]                  dmem_size,
                   output wire [`MEM_TYPE_WIDTH-1:0]  dmem_type,
                   output wire                        eret,
		   output wire			      dret, 
		   output wire			      redirect,	// 06.08.19 - forward redirect information to WB for dpc handling.
                   output [`CSR_CMD_WIDTH-1:0]        csr_cmd,
                   output reg                         csr_imm_sel,
                   input                              illegal_csr_access,
		   input                              interrupt_pending,
		   input                              interrupt_taken,
		   input			      stepmode,
		   input                  dmode_WB,
                   output wire                        wr_reg_WB,
                   output reg [`REG_ADDR_WIDTH-1:0]   reg_to_wr_WB,
                   output reg [`WB_SRC_SEL_WIDTH-1:0] wb_src_sel_WB,
                   output wire                        stall_IF,
                   output wire                        kill_IF,
                   output wire                        stall_DX,
                   output wire                        kill_DX,
                   output wire                        stall_WB,
                   output wire                        kill_WB,
                   output wire                        exception_WB,
                   output wire [`MCAUSE_WIDTH-1:0]    exception_code_WB,
                   output wire                        retire_WB
                   );

   // IF stage ctrl pipeline registers
   reg                                                replay_IF;

   // IF stage ctrl signals
   wire                                               ex_IF;

   // DX stage ctrl pipeline registers
   reg                                                had_ex_DX;
   reg                                                prev_killed_DX;

   // DX stage ctrl signals
   wire [6:0]                                         opcode = inst_DX[6:0];
   wire [6:0]                                         funct7 = inst_DX[31:25];
   wire [11:0]                                        funct12 = inst_DX[31:20];
   wire [2:0]                                         funct3 = inst_DX[14:12];
   wire [`REG_ADDR_WIDTH-1:0]                         rs1_addr = inst_DX[19:15];
   wire [`REG_ADDR_WIDTH-1:0]                         rs2_addr = inst_DX[24:20];
   wire [`REG_ADDR_WIDTH-1:0]                         reg_to_wr_DX = inst_DX[11:7];
   reg                                                illegal_instruction;
   reg                                                ebreak;
   reg                                                ecall;
   reg                                                eret_unkilled;
   reg                                                dret_unkilled;
   reg                                                fence_i;
   wire [`ALU_OP_WIDTH-1:0]                           add_or_sub;
   wire [`ALU_OP_WIDTH-1:0]                           srl_or_sra;
   reg [`ALU_OP_WIDTH-1:0]                            alu_op_arith;
   reg                                                branch_taken_unkilled;
   wire                                               branch_taken;
   reg                                                dmem_en_unkilled;
   reg                                                dmem_wen_unkilled;
   wire						      uses_pcpi;
   reg						      uses_pcpi_unkilled;
   reg	[3:0]					      pcpi_timeout_counter_r;	
   wire						      pcpi_timeout;
   reg                                                jal_unkilled;
   wire                                               jal;
   reg                                                jalr_unkilled;
   wire                                               jalr;
//   wire                                               redirect;	// 06.08.19, ASt - moved to port list (see above)
   reg                                                wr_reg_unkilled_DX;
   wire                                               wr_reg_DX;
   reg [`WB_SRC_SEL_WIDTH-1:0]                        wb_src_sel_DX;
   wire                                               new_ex_DX;
   wire                                               ex_DX;
   reg [`MCAUSE_WIDTH-1:0]                             ex_code_DX;
   wire                                               killed_DX;
   reg 						      wfi_unkilled_DX;
   wire 					      wfi_DX;
   reg [`CSR_CMD_WIDTH-1:0]                           csr_cmd_unkilled;
   
   // WB stage ctrl pipeline registers
   reg                                                wr_reg_unkilled_WB;
   reg                                                had_ex_WB;
   reg [`MCAUSE_WIDTH-1:0]                             prev_ex_code_WB;
   reg                                                store_in_WB;
   reg                                                dmem_en_WB;
   reg                                                prev_killed_WB;
   reg 						      wfi_unkilled_WB;
   reg						      uses_pcpi_WB;
   
   // WB stage ctrl signals
   wire                                               ex_WB;
   reg [`MCAUSE_WIDTH-1:0]                             ex_code_WB;
   wire                                               dmem_access_exception;
   wire                                               exception = ex_WB;
   wire                                               killed_WB;
   wire                                               load_in_WB;
   wire 					      active_wfi_WB;
   
   // Hazard signals
   wire                                               load_use;
   reg                                                uses_rs1;
   reg                                                uses_rs2;
   wire                                               raw_rs1;
   wire                                               raw_rs2;
   wire						      raw_on_busy_pcpi;

   // IF stage ctrl

   always @(posedge clk) begin
      if (reset) begin
         replay_IF <= 1'b1;
      end else begin
         replay_IF <= (redirect && imem_wait) || (fence_i && store_in_WB);
      end
   end

   // interrupts kill IF, DX instructions -- WB may commit
   assign kill_IF = stall_IF || ex_IF || ex_DX || ex_WB || redirect || replay_IF || interrupt_taken;
   assign stall_IF = stall_DX ||
                     ((imem_wait && !redirect) && !(ex_WB || interrupt_taken));
   assign ex_IF = imem_badmem_e && !imem_wait && !redirect && !replay_IF;

   // DX stage ctrl

   always @(posedge clk) begin
      if (reset) begin
         had_ex_DX <= 0;
         prev_killed_DX <= 0;
      end else if (!stall_DX) begin
         had_ex_DX <= ex_IF;
         prev_killed_DX <= kill_IF;
      end
   end

   // PCPI timeout counter
   // ====================

   always @(posedge clk) begin
	if(reset) begin
		pcpi_timeout_counter_r <= 4'd15;
	end else begin
		if(uses_pcpi_unkilled && ~pcpi_ready && ~pcpi_wait)
			pcpi_timeout_counter_r <= (pcpi_timeout_counter_r == 0) ? 0 : pcpi_timeout_counter_r - 1;
		else 
			pcpi_timeout_counter_r <= 4'd15;
	end
   end

   assign pcpi_timeout = (pcpi_timeout_counter_r == 0) ? 1'b1 : 1'b0;

   // interrupts kill IF, DX instructions -- WB may commit
   // Exceptions never show up falsely due to hazards -- don't get exceptions on stall
   assign kill_DX = stall_DX || ex_DX || ex_WB || interrupt_taken;
   assign stall_DX = stall_WB || ((load_use || raw_on_busy_pcpi || (fence_i && store_in_WB) || (uses_pcpi_unkilled && ~pcpi_ready && ~pcpi_timeout)) && !(ex_DX || ex_WB || interrupt_taken));
   assign new_ex_DX = ebreak || ecall || illegal_instruction || illegal_csr_access || (stepmode && retire_WB && ~dmode_WB);
   assign ex_DX = had_ex_DX || new_ex_DX; // TODO: add causes
   assign killed_DX = prev_killed_DX || kill_DX;

   always @(*) begin
      ex_code_DX = `MCAUSE_INST_ADDR_MISALIGNED;
      if (had_ex_DX) begin
         ex_code_DX = `MCAUSE_INST_ADDR_MISALIGNED;
      end else if (illegal_instruction) begin
         ex_code_DX = `MCAUSE_ILLEGAL_INST;
      end else if (illegal_csr_access) begin
         ex_code_DX = `MCAUSE_ILLEGAL_INST;
      end else if (ebreak) begin
         ex_code_DX = `MCAUSE_BREAKPOINT;
      end else if (ecall) begin
         ex_code_DX = `MCAUSE_ECALL_FROM_U + prv;
      end
   end // always @ begin


   /*
    Note: the convention is to use an initial default
    assignment for all control signals (except for
    illegal instructions) and override the default
    values when appropriate, rather than using the
    default keyword. The exception is for illegal
    instructions; in the interest of brevity, this
    signal is set in the default case of any case
    statement after initially being zero.
    */

   assign dmem_size = {1'b0,funct3[1:0]};
   assign dmem_type = funct3;

   wire alu_op_invalid; assign alu_op_invalid = ~((funct7 == 0) || (funct7 == 7'h20));// RV32I only knows these to variants.

   always @(*) begin
      illegal_instruction = 1'b0;
      csr_cmd_unkilled = `CSR_IDLE;
      csr_imm_sel = funct3[2];
      ecall = 1'b0;
      ebreak = 1'b0;
      eret_unkilled = 1'b0;
      dret_unkilled = 1'b0;
      fence_i = 1'b0;
      branch_taken_unkilled = 1'b0;
      jal_unkilled = 1'b0;
      jalr_unkilled = 1'b0;
      uses_rs1 = 1'b1;
      uses_rs2 = 1'b0;
      imm_type = `IMM_I;
      src_a_sel = `SRC_A_RS1;
      src_b_sel = `SRC_B_IMM;
      alu_op = `ALU_OP_ADD;
      dmem_en_unkilled = 1'b0;
      dmem_wen_unkilled = 1'b0;
      wr_reg_unkilled_DX = 1'b0;
      wb_src_sel_DX = `WB_SRC_ALU;
      wfi_unkilled_DX = 1'b0;
      uses_pcpi_unkilled = 1'b0;
      pcpi_valid = 1'b0;
      case (opcode)
        `RV32_LOAD : begin
           dmem_en_unkilled = 1'b1;
           wr_reg_unkilled_DX = 1'b1;
           wb_src_sel_DX = `WB_SRC_MEM;
        end
        `RV32_STORE : begin
           uses_rs2 = 1'b1;
           imm_type = `IMM_S;
           dmem_en_unkilled = 1'b1;
           dmem_wen_unkilled = 1'b1;
        end
        `RV32_BRANCH : begin
           uses_rs2 = 1'b1;
           branch_taken_unkilled = cmp_true;
           src_b_sel = `SRC_B_RS2;
           case (funct3)
             `RV32_FUNCT3_BEQ : alu_op = `ALU_OP_SEQ;
             `RV32_FUNCT3_BNE : alu_op = `ALU_OP_SNE;
             `RV32_FUNCT3_BLT : alu_op = `ALU_OP_SLT;
             `RV32_FUNCT3_BLTU : alu_op = `ALU_OP_SLTU;
             `RV32_FUNCT3_BGE : alu_op = `ALU_OP_SGE;
             `RV32_FUNCT3_BGEU : alu_op = `ALU_OP_SGEU;
             default : illegal_instruction = 1'b1;
           endcase // case (funct3)
        end
        `RV32_JAL : begin
           jal_unkilled = 1'b1;
           uses_rs1 = 1'b0;
           src_a_sel = `SRC_A_PC;
           src_b_sel = `SRC_B_FOUR;
           wr_reg_unkilled_DX = 1'b1;
        end
        `RV32_JALR : begin
           illegal_instruction = (funct3 != 0);
           jalr_unkilled = 1'b1;
           src_a_sel = `SRC_A_PC;
           src_b_sel = `SRC_B_FOUR;
           wr_reg_unkilled_DX = 1'b1;
        end
        `RV32_MISC_MEM : begin
           case (funct3)
             `RV32_FUNCT3_FENCE : begin
                if ((inst_DX[31:28] == 0) && (rs1_addr == 0) && (reg_to_wr_DX == 0))
                  ; // most fences are no-ops
                else
                  illegal_instruction = 1'b1;
             end
             `RV32_FUNCT3_FENCE_I : begin
                if ((inst_DX[31:20] == 0) && (rs1_addr == 0) && (reg_to_wr_DX == 0))
                  fence_i = 1'b1;
                else
                  illegal_instruction = 1'b1;
             end
             default : illegal_instruction = 1'b1;
           endcase // case (funct3)
        end
        `RV32_OP_IMM : begin
           alu_op = alu_op_arith;
           wr_reg_unkilled_DX = 1'b1;
        end
        `RV32_OP  : begin
           uses_rs2 = 1'b1;
           src_b_sel = `SRC_B_RS2;
           alu_op = alu_op_arith;
	   wr_reg_unkilled_DX = 1'b1;
	   if(alu_op_invalid) begin
		illegal_instruction = (pcpi_timeout_counter_r == 0) ? 1'b1 : 1'b0;
		uses_pcpi_unkilled = 1'b1;
	 	   pcpi_valid = 1'b1;
		   wb_src_sel_DX = `WB_SRC_PCPI;
	   end
       end
        `RV32_SYSTEM : begin
           wb_src_sel_DX = `WB_SRC_CSR;
           wr_reg_unkilled_DX = (funct3 != `RV32_FUNCT3_PRIV);
           case (funct3)
             `RV32_FUNCT3_PRIV : begin
                if ((rs1_addr == 0) && (reg_to_wr_DX == 0)) begin
                   case (funct12)
                     `RV32_FUNCT12_ECALL : ecall = 1'b1;
                     `RV32_FUNCT12_EBREAK : ebreak = 1'b1;
                     `RV32_FUNCT12_MRET : begin		
                        if (prv == 0)
                          illegal_instruction = 1'b1;
                        else
                          eret_unkilled = 1'b1;
                      end
                     `RV32_FUNCT12_DRET : begin						// 05.03.18, ASt: added dret-instruction
                          dret_unkilled = 1'b1;
                      end
		     `RV32_FUNCT12_WFI : wfi_unkilled_DX = 1'b1;	
                     default : illegal_instruction = 1'b1;
                   endcase // case (funct12)
                end // if ((rs1_addr == 0) && (reg_to_wr_DX == 0))
             end // case: `RV32_FUNCT3_PRIV
             `RV32_FUNCT3_CSRRW : csr_cmd_unkilled = (rs1_addr == 0) ? `CSR_READ : `CSR_WRITE;
             `RV32_FUNCT3_CSRRS : csr_cmd_unkilled = (rs1_addr == 0) ? `CSR_READ : `CSR_SET;
             `RV32_FUNCT3_CSRRC : csr_cmd_unkilled = (rs1_addr == 0) ? `CSR_READ : `CSR_CLEAR;
             `RV32_FUNCT3_CSRRWI : csr_cmd_unkilled = (rs1_addr == 0) ? `CSR_READ : `CSR_WRITE;
             `RV32_FUNCT3_CSRRSI : csr_cmd_unkilled = (rs1_addr == 0) ? `CSR_READ : `CSR_SET;
             `RV32_FUNCT3_CSRRCI : csr_cmd_unkilled = (rs1_addr == 0) ? `CSR_READ : `CSR_CLEAR;
             default : illegal_instruction = 1'b1;
           endcase // case (funct3)
        end
        `RV32_AUIPC : begin
           uses_rs1 = 1'b0;
           src_a_sel = `SRC_A_PC;
           imm_type = `IMM_U;
           wr_reg_unkilled_DX = 1'b1;
        end
        `RV32_LUI : begin
           uses_rs1 = 1'b0;
           src_a_sel = `SRC_A_ZERO;
           imm_type = `IMM_U;
           wr_reg_unkilled_DX = 1'b1;
        end
        default : begin
           illegal_instruction = (pcpi_timeout_counter_r == 0) ? 1'b1 : 1'b0;
           uses_pcpi_unkilled = 1'b1;
      	   pcpi_valid = 1'b1;
           wb_src_sel_DX = `WB_SRC_PCPI;
        end
      endcase // case (opcode)
   end // always @ (*)

   assign add_or_sub = ((opcode == `RV32_OP) && (funct7[5])) ? `ALU_OP_SUB : `ALU_OP_ADD;
   assign srl_or_sra = (funct7[5]) ? `ALU_OP_SRA : `ALU_OP_SRL;

   always @(*) begin
      case (funct3)
        `RV32_FUNCT3_ADD_SUB : alu_op_arith = add_or_sub;
        `RV32_FUNCT3_SLL : alu_op_arith = `ALU_OP_SLL;
        `RV32_FUNCT3_SLT : alu_op_arith = `ALU_OP_SLT;
        `RV32_FUNCT3_SLTU : alu_op_arith = `ALU_OP_SLTU;
        `RV32_FUNCT3_XOR : alu_op_arith = `ALU_OP_XOR;
        `RV32_FUNCT3_SRA_SRL : alu_op_arith = srl_or_sra;
        `RV32_FUNCT3_OR : alu_op_arith = `ALU_OP_OR;
        `RV32_FUNCT3_AND : alu_op_arith = `ALU_OP_AND;
        //default : alu_op_arith = `ALU_OP_ADD; - synthesis says this is unreachable.
      endcase // case (funct3)
   end // always @ begin

   assign branch_taken = branch_taken_unkilled && !kill_DX;
   assign jal = jal_unkilled && !kill_DX;
   assign jalr = jalr_unkilled && !kill_DX;
   assign eret = eret_unkilled && !kill_DX;
   assign dret = dret_unkilled && !kill_DX;
   assign dmem_en = dmem_en_unkilled && !kill_DX;                       // == 1, if store/load instruktion 
   assign dmem_wen = dmem_wen_unkilled && !kill_DX;
   assign wr_reg_DX = wr_reg_unkilled_DX && !kill_DX;
   assign wfi_DX = wfi_unkilled_DX && !kill_DX;
   assign uses_pcpi = uses_pcpi_unkilled && !kill_DX;
   assign csr_cmd = csr_cmd_unkilled;

   assign redirect = branch_taken || jal || jalr || eret || dret;

   always @(*) begin
      if (exception || interrupt_taken) begin
         PC_src_sel = `PC_HANDLER;
      end else if (replay_IF || (stall_IF && !imem_wait)) begin
         PC_src_sel = `PC_REPLAY;
      end else if (eret) begin
         PC_src_sel = `PC_EPC;
      end else if (dret) begin
         PC_src_sel = `PC_DPC;
      end else if (branch_taken) begin
         PC_src_sel = `PC_BRANCH_TARGET;
      end else if (jal) begin
         PC_src_sel = `PC_JAL_TARGET;
      end else if (jalr) begin
         PC_src_sel = `PC_JALR_TARGET;
      end else begin
         PC_src_sel = `PC_PLUS_FOUR;
      end
   end // always @ begin

   // WB stage ctrl

   always @(posedge clk) begin
      if (reset) begin
         prev_killed_WB <= 0;
         had_ex_WB <= 0;
         wr_reg_unkilled_WB <= 0;
         store_in_WB <= 0;
         dmem_en_WB <= 0;
	 wfi_unkilled_WB <= 0;
      end else if (!stall_WB) begin
         prev_killed_WB <= killed_DX;
         had_ex_WB <= ex_DX;
         wr_reg_unkilled_WB <= wr_reg_DX;
         wb_src_sel_WB <= wb_src_sel_DX;
         prev_ex_code_WB <= ex_code_DX;
         reg_to_wr_WB <= reg_to_wr_DX;
         store_in_WB <= dmem_wen;
         dmem_en_WB <= dmem_en;
	 wfi_unkilled_WB <= wfi_DX;
         uses_pcpi_WB <= uses_pcpi;
      end
	
   end

   // WFI handling
   // can't be killed while in WB stage
   assign active_wfi_WB = !prev_killed_WB && wfi_unkilled_WB 
			  && !(interrupt_taken || interrupt_pending);

   assign kill_WB = stall_WB || ex_WB;
   assign stall_WB = ((dmem_wait && dmem_en_WB) || active_wfi_WB) && !exception;
   assign dmem_access_exception = dmem_badmem_e;
   assign ex_WB = had_ex_WB || dmem_access_exception;	// ASt, 06.06.19 - if single step execution is requestet, generate an 
									// 		   exception in WB stage. As we have just returned from 
									//		   debug mode, the WB stage should be stalled until the 
									//	 	   next instruction finishes executing. Thus, an exception
									//		   is generated when the single instruction just finishes WB. (hopefully ;))
   assign killed_WB = prev_killed_WB || kill_WB;

   always @(*) begin
      ex_code_WB = prev_ex_code_WB;
      if (!had_ex_WB) begin
         if (dmem_access_exception) begin
            ex_code_WB = wr_reg_unkilled_WB ?
                         `MCAUSE_LOAD_ADDR_MISALIGNED :
                         `MCAUSE_STORE_AMO_ADDR_MISALIGNED;
         end else 
	 if (stepmode) begin
	    ex_code_WB = `MCAUSE_BREAKPOINT;
	 end
      end
   end

   assign exception_WB = ex_WB;
   assign exception_code_WB = ex_code_WB;
   assign wr_reg_WB = wr_reg_unkilled_WB && !kill_WB;
   assign retire_WB = !(kill_WB || killed_WB);

   // Hazard logic

   assign load_in_WB = dmem_en_WB && !store_in_WB;

   assign raw_rs1 = wr_reg_WB && (rs1_addr == reg_to_wr_WB)
     && (rs1_addr != 0) && uses_rs1;
   assign bypass_rs1 = !load_in_WB && raw_rs1;

   assign raw_rs2 = wr_reg_WB && (rs2_addr == reg_to_wr_WB)
     && (rs2_addr != 0) && uses_rs2;
   assign bypass_rs2 = !load_in_WB && raw_rs2;
   assign raw_on_busy_pcpi = uses_pcpi_WB && (raw_rs1 || raw_rs2) && !pcpi_ready;
   assign load_use = load_in_WB && (raw_rs1 || raw_rs2);

endmodule // raifes_ctrl
