// Constants for the Debug Module Interface (DMI)

`define	DMI_ADDR_WIDTH	7
`define	DMI_WIDTH	32


`define DMI_ADDR_DATA0		`DMI_ADDR_WIDTH'h04

`define DMI_ADDR_DMCONTROL	`DMI_ADDR_WIDTH'h10
`define DMI_ADDR_DMSTATUS	`DMI_ADDR_WIDTH'h11
`define DMI_ADDR_HARTINFO	`DMI_ADDR_WIDTH'h12
`define DMI_ADDR_HALTSUM	`DMI_ADDR_WIDTH'h13
`define DMI_ADDR_HAWINDOWSEL	`DMI_ADDR_WIDTH'h14
`define DMI_ADDR_HAWINDOW	`DMI_ADDR_WIDTH'h15
`define DMI_ADDR_ABSTRACTCS	`DMI_ADDR_WIDTH'h16
`define DMI_ADDR_COMMAND	`DMI_ADDR_WIDTH'h17
`define DMI_ADDR_ABSTRACTAUTO	`DMI_ADDR_WIDTH'h18
`define DMI_ADDR_DEVTREEADDR0	`DMI_ADDR_WIDTH'h19

`define DMI_ADDR_PROGBUF0	`DMI_ADDR_WIDTH'h20
`define DMI_ADDR_PROGBUF1	`DMI_ADDR_WIDTH'h21
// added for caeco
`define DMI_ADDR_CAECOWDATA	 `DMI_ADDR_WIDTH'h22  // write data through dm
`define DMI_ADDR_CAECOCMD	 `DMI_ADDR_WIDTH'h23  // write cmd though dm
`define DMI_ADDR_CAECORDATA	 `DMI_ADDR_WIDTH'h24  // read regcaeco register


`define DMI_ADDR_AUTHDATA	`DMI_ADDR_WIDTH'h30

`define DMI_ADDR_SBCS		`DMI_ADDR_WIDTH'h38
`define DMI_ADDR_SBADDRESS0	`DMI_ADDR_WIDTH'h39
`define DMI_ADDR_SBADDRESS1	`DMI_ADDR_WIDTH'h3A
`define DMI_ADDR_SBADDRESS2	`DMI_ADDR_WIDTH'h3B

`define DMI_ADDR_SBDATA0	`DMI_ADDR_WIDTH'h3C
`define DMI_ADDR_SBDATA1	`DMI_ADDR_WIDTH'h3D
`define DMI_ADDR_SBDATA2	`DMI_ADDR_WIDTH'h3E
`define DMI_ADDR_SBDATA3	`DMI_ADDR_WIDTH'h3F

`define DMI_STATE_IDLE		1				// DMI is idle
`define DMI_STATE_READ		2				// DMI received a read request from transport interface
`define DMI_STATE_WRITE		4				// DMI received a write request from transponder interface
`define DMI_STATE_WAITEND 	8				// DMI waits for deassertion of enable


// Constants for the Debug Module (DM)

`define DM_CMD_WIDTH	8
`define DM_CMD_ACCESSREG	`DM_CMD_WIDTH'h0
`define DM_CMD_QUICKACCESS	`DM_CMD_WIDTH'h1


// TODO: Kodierung ist dumm. Was schlaueres w�hlen!
`define	DM_STATE_IDLE		0				// DM is idle
`define DM_STATE_DECODE 	1
`define DM_STATE_ACCESSREG_R	2
`define DM_STATE_ACCESSREG_W	3				
`define DM_STATE_POSTEXEC	4
`define DM_STATE_ERROR_BUSY			5
`define DM_STATE_ERROR_NOTSUPP		6
`define DM_STATE_ERROR_EXCEPT			7
`define DM_STATE_ERROR_HALTRESUME	8
`define DM_STATE_ERROR_OTHER			9



