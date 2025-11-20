class apb_scoreboard;

    mailbox #(apb_trans_cov) drv2sb;
    mailbox #(apb_trans_cov) mon2sb;

    bit [31:0] ref_mem [0:31];

    function new(mailbox #(apb_trans_cov) drv2sb,
                 mailbox #(apb_trans_cov) mon2sb);
        this.drv2sb = drv2sb;
        this.mon2sb = mon2sb;
    endfunction

    task start();
        apb_trans_cov drv_tr, mon_tr;
        forever begin
            drv2sb.get(drv_tr);
            mon2sb.get(mon_tr);

            // update model on write
            if (drv_tr.write)
                ref_mem[drv_tr.addr] = drv_tr.wdata;

            // check on read
            if (!drv_tr.write) begin
                if (mon_tr.rdata !== ref_mem[drv_tr.addr])
                    $error("Scoreboard mismatch: addr=%0d exp=%0h got=%0h",
                           drv_tr.addr, ref_mem[drv_tr.addr], mon_tr.rdata);
            end

            // sample coverage for the transaction
            drv_tr.sample();
        end
    endtask

endclass
