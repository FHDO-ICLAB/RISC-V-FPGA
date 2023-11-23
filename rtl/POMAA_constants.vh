// POMAA constant definitions

// 1: states for FSM which handles the data from core
`define FSM_STATE_WIDTH 5

`define IDLE    `FSM_STATE_WIDTH'h0
`define WDA0    `FSM_STATE_WIDTH'h1
`define WDA1    `FSM_STATE_WIDTH'h2
`define CTRL    `FSM_STATE_WIDTH'h3
`define READ    `FSM_STATE_WIDTH'h4

// 2. States for data from dm directly
`define CTRL_DM `FSM_STATE_WIDTH'h5
`define WAIT_DM `FSM_STATE_WIDTH'h6
`define WDA0_DM `FSM_STATE_WIDTH'h7
`define WDA1_DM `FSM_STATE_WIDTH'h8

