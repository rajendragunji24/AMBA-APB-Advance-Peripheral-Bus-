`include "transaction.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"

class apb_env;

    apb_generator  gen;
    apb_driver     drv;
    apb_monitor    mon;
    apb_scoreboard sb;

    mailbox #(apb_trans_cov) gen2drv = new();
    mailbox #(apb_trans_cov) drv2sb  = new();
    mailbox #(apb_trans_cov) mon2sb  = new();

    virtual apb_if vif;

    function new(virtual apb_if vif);
        this.vif = vif;

        gen = new(gen2drv);
        drv = new(vif.master, gen2drv, drv2sb);
        mon = new(vif, mon2sb);
        sb  = new(drv2sb, mon2sb);
    endfunction

    task start();
        fork
            gen.start();
            drv.start();
            mon.start();
            sb.start();
        join_none
    endtask

endclass
