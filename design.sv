module APB_memory (
    input  logic        Pclk,
    input  logic        Prst,        // active low reset
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

    // ------------------------------------------------------------
    // Memory Array: 32 x 32-bit
    // ------------------------------------------------------------
    logic [31:0] mem [0:31];

    // ------------------------------------------------------------
    // FSM State Declaration using enum
    // ------------------------------------------------------------
    typedef enum logic [1:0] {
        IDLE   = 2'b00,
        SETUP  = 2'b01,
        ACCESS = 2'b10
    } apb_state_t;

    apb_state_t present_state, next_state;

    // ------------------------------------------------------------
    // State Register
    // ------------------------------------------------------------
    always_ff @(posedge Pclk or negedge Prst) begin
        if (!Prst)
            present_state <= IDLE;
        else
            present_state <= next_state;
    end

    // ------------------------------------------------------------
    // Next State Logic
    // ------------------------------------------------------------
    always_comb begin
        next_state = present_state;

        unique case (present_state)

            IDLE: begin
                if (Pselx && !Penable)
                    next_state = SETUP;
            end

            SETUP: begin
                if (Pselx && Penable)
                    next_state = ACCESS;
                else
                    next_state = IDLE;
            end

            ACCESS: begin
                if (!Pselx)                     // end of transfer
                    next_state = IDLE;
                else if (Pselx && !Penable)     // next transfer
                    next_state = SETUP;
            end

        endcase
    end

    // ------------------------------------------------------------
    // Output & Memory Behavior (Clocked)
    // ------------------------------------------------------------
    always_ff @(posedge Pclk or negedge Prst) begin
        if (!Prst) begin
            Pready  <= 1'b0;
            Pslverr <= 1'b0;
            Prdata  <= 32'd0;
            temp    <= 32'd0;
        end else begin

            case (present_state)

                IDLE: begin
                    Pready <= 1'b0;
                end

                SETUP: begin
                    Pready <= 1'b0;
                end

                ACCESS: begin
                    Pready <= 1'b1;

                    if (Pwrite) begin
                        mem[Paddr[4:0]] <= Pwdata;
                        temp            <= Pwdata;
                        Pslverr         <= 1'b0;
                    end else begin
                        Prdata          <= mem[Paddr[4:0]];
                        temp            <= mem[Paddr[4:0]];
                        Pslverr         <= 1'b0;
                    end
                end

            endcase

        end
    end

endmodule
