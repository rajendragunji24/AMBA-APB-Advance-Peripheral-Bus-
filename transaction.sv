class apb_trans_cov;

    rand bit [31:0] addr;
    rand bit        write;
    rand bit [31:0] wdata;

    bit [31:0] rdata;
    bit        slverr;

    constraint addr_limit { addr < 32; }

    covergroup apb_cg;   // <-- FIXED: removed @(this)
        ADDR_CV : coverpoint addr {
            bins low  = {[0:7]};
            bins mid  = {[8:23]};
            bins high = {[24:31]};
        }
        RW_CV : coverpoint write {
            bins read  = {0};
            bins write = {1};
        }
        WDATA_CV : coverpoint wdata iff (write) {
            bins zero = {32'h0};
            bins ones = {32'hFFFF_FFFF};
        }
        ADDR_X_RW : cross ADDR_CV, RW_CV;
    endgroup

    function new();
        apb_cg = new();
    endfunction

    function void sample();
        apb_cg.sample();
    endfunction

endclass
