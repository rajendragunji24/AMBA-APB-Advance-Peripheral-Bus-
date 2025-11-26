interface apb_if (input logic Pclk, input logic Prst);

    logic [31:0] Paddr;
    logic        Pselx;
    logic        Penable;
    logic        Pwrite;
    logic [31:0] Pwdata;
    logic        Pready;
    logic        Pslverr;
    logic [31:0] Prdata;

    // -------------------------------------------------------
    // Master modport
    // -------------------------------------------------------
    modport master (
        input  Pclk, Prst,
        input  Pready, Prdata, Pslverr,
        output Paddr, Pselx, Penable, Pwrite, Pwdata
    );

    // -------------------------------------------------------
    // Slave modport
    // -------------------------------------------------------
    modport slave (
        input  Pclk, Prst,
        input  Paddr, Pselx, Penable, Pwrite, Pwdata,
        output Pready, Pslverr, Prdata
    );

    // =======================================================
    //              APB ASSERTIONS INSIDE INTERFACE
    // =======================================================

    // -----------------------------
    // 1. PENABLE must only be 1 when PSEL == 1
    // -----------------------------
    property p_penable_requires_psel;
        @(posedge Pclk) disable iff (!Prst)
            Penable |-> Pselx;
    endproperty

    assert property (p_penable_requires_psel)
        else $error("APB PROTOCOL ERROR: PENABLE=1 while PSEL=0");


    // -----------------------------
    // 2. SETUP → ACCESS sequencing
    // PSEL=1 & PENABLE=0 must go to PENABLE=1 next
    // -----------------------------
    property p_setup_to_access;
        @(posedge Pclk) disable iff (!Prst)
            (Pselx && !Penable) |=> (Pselx && Penable);
    endproperty

    assert property (p_setup_to_access)
        else $error("APB PROTOCOL ERROR: ACCESS did not follow SETUP phase");


    // -----------------------------
    // 3. PREADY must be 1 only in ACCESS phase
    // -----------------------------
    property p_pready_only_in_access;
        @(posedge Pclk) disable iff (!Prst)
            Pready |-> (Pselx && Penable);
    endproperty

    assert property (p_pready_only_in_access)
        else $error("APB PROTOCOL ERROR: PREADY asserted outside ACCESS phase");


    // -----------------------------
    // 4. Address must remain stable during ACCESS
    // -----------------------------
    logic [31:0] addr_prev;

    always @(posedge Pclk)
        addr_prev <= Paddr;

    property p_addr_stable_access;
        @(posedge Pclk) disable iff (!Prst)
            (Pselx && Penable) |-> (Paddr == addr_prev);
    endproperty

    assert property (p_addr_stable_access)
        else $error("APB PROTOCOL ERROR: Address changed during ACCESS phase");


    // -----------------------------
    // 5. Pwdata stable during ACCESS when writing
    // -----------------------------
    logic [31:0] wdata_prev;

    always @(posedge Pclk)
        wdata_prev <= Pwdata;

    property p_wdata_stable_access;
        @(posedge Pclk) disable iff (!Prst)
            (Pselx && Penable && Pwrite) |-> (Pwdata == wdata_prev);
    endproperty

    assert property (p_wdata_stable_access)
        else $error("APB PROTOCOL ERROR: Pwdata changed during WRITE ACCESS");


    // -----------------------------
    // 6. Prdata stable during ACCESS when reading
    // -----------------------------
    logic [31:0] rdata_prev;

    always @(posedge Pclk)
        rdata_prev <= Prdata;

    property p_rdata_stable_access;
        @(posedge Pclk) disable iff (!Prst)
            (Pselx && Penable && !Pwrite) |-> (Prdata == rdata_prev);
    endproperty

    assert property (p_rdata_stable_access)
        else $error("APB PROTOCOL ERROR: Prdata changed during READ ACCESS");


    // -----------------------------
    // 7. No X/Z on control signals
    // -----------------------------
    property p_no_xz;
        @(posedge Pclk)
            !$isunknown({Pselx, Penable, Pwrite});
    endproperty

    assert property (p_no_xz)
        else $error("APB PROTOCOL ERROR: X/Z detected on control signals");


endinterface





