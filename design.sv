module APB_memory (
    input  logic        Pclk,
    input  logic        Prst,        // active-low reset
    input  logic [31:0] Paddr,
    input  logic        Pselx,
    input  logic        Penable,
    input  logic        Pwrite,
    input  logic [31:0] Pwdata,

    output logic        Pready,
    output logic        Pslverr,
    output logic [31:0] Prdata,
    output logic [31:0] temp
);

    // parameters for easy change
    parameter ADDR_WIDTH = 5;
    parameter DEPTH = (1 << ADDR_WIDTH);

    // memory and internal registers
    logic [31:0] mem [0:DEPTH-1];
    logic [ADDR_WIDTH-1:0] addr_reg;
    logic [31:0] read_data;

    typedef enum logic [1:0] {
        IDLE,
        SETUP,
        ACCESS
    } apb_state_t;

    apb_state_t present_state, next_state;

    //-----------------------------------------
    // STATE REGISTER
    //-----------------------------------------
    always_ff @(posedge Pclk or negedge Prst) begin
        if (!Prst)
            present_state <= IDLE;
        else
            present_state <= next_state;
    end

    //-----------------------------------------
    // NEXT STATE LOGIC (combinational)
    //-----------------------------------------
    always_comb begin
        next_state = present_state;
        case (present_state)
            IDLE:  if (Pselx)       next_state = SETUP;
            SETUP:                   next_state = ACCESS;
            ACCESS: if (!Pselx)     next_state = IDLE;
                    else             next_state = SETUP;
        endcase
    end

    //-----------------------------------------
    // OUTPUT + MEMORY BEHAVIOR (clocked)
    //-----------------------------------------
    always_ff @(posedge Pclk or negedge Prst) begin
        if (!Prst) begin
            Pready   <= 1'b0;
            Pslverr  <= 1'b0;
            Prdata   <= 32'd0;
            temp     <= 32'd0;
            addr_reg <= {ADDR_WIDTH{1'b0}};
            read_data<= 32'd0;
        end else begin
            // default: keep ready low unless in ACCESS
            Pready <= 1'b0;
            Pslverr <= 1'b0; // clear by default; set in ACCESS if needed

            case (present_state)
                IDLE: begin
                    // keep read_data stable (do not change)
                end

                SETUP: begin
                    addr_reg <= Paddr[ADDR_WIDTH-1:0]; // latch address
                end

                ACCESS: begin
                    Pready <= 1'b1;

                    if (Pwrite) begin
                        // write happens in ACCESS (using latched addr)
                        mem[addr_reg] <= Pwdata;
                        temp <= Pwdata;
                    end else begin
                        // capture read data into internal register
                        read_data <= mem[addr_reg];
                        temp <= mem[addr_reg];
                    end
                end
            endcase

            // Drive outward read data from internal register so Prdata never floats.
            Prdata <= read_data;
        end
    end

endmodule



          
  
        
