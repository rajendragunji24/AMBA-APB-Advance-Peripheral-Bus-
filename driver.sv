class apb_driver;

    virtual apb_if.master vif;
    mailbox #(apb_trans_cov) gen2drv;
    mailbox #(apb_trans_cov) drv2sb;

    function new(virtual apb_if.master vif,
                 mailbox #(apb_trans_cov) gen2drv,
                 mailbox #(apb_trans_cov) drv2sb);
        this.vif     = vif;
        this.gen2drv = gen2drv;
        this.drv2sb  = drv2sb;
    endfunction

    task drive_one(apb_trans_cov tr);
        // SETUP
        vif.Paddr  <= tr.addr;
        vif.Pwrite <= tr.write;
        vif.Pselx  <= 1;
        vif.Penable<= 0;
        vif.Pwdata <= tr.wdata;
        @(posedge vif.Pclk);

        // ACCESS
        vif.Penable <= 1;
        @(posedge vif.Pclk);

        // capture read data (from slave)
        if (!tr.write)
            tr.rdata = vif.Prdata;

        tr.slverr = vif.Pslverr;

        // END
        vif.Pselx   <= 0;
        vif.Penable <= 0;

        drv2sb.put(tr);
    endtask

    task start();
        apb_trans_cov tr;
        forever begin
            gen2drv.get(tr);
            drive_one(tr);
        end
    endtask

endclass
