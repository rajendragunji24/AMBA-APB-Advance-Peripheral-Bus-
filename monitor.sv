class apb_monitor;

    virtual apb_if vif;
    mailbox #(apb_trans_cov) mon2sb;

    function new(virtual apb_if vif, mailbox #(apb_trans_cov) mon2sb);
        this.vif = vif;
        this.mon2sb = mon2sb;
    endfunction

    task start();
        apb_trans_cov tr;   // <---- DECLARE HERE (LEGAL)

        forever begin
            // wait for ACCESS phase
            @(posedge vif.Pclk iff (vif.Pselx && vif.Penable));

            tr = new();      // <--- create each time

            tr.addr   = vif.Paddr;
            tr.write  = vif.Pwrite;
            tr.wdata  = vif.Pwdata;
            tr.rdata  = vif.Prdata;
            tr.slverr = vif.Pslverr;

            mon2sb.put(tr);
        end
    endtask

endclass
