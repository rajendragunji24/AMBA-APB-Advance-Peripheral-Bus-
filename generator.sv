class apb_generator;

    mailbox #(apb_trans_cov) gen2drv;

    function new(mailbox #(apb_trans_cov) gen2drv);
        this.gen2drv = gen2drv;
    endfunction

    task start();
        apb_trans_cov tr;
        repeat (30) begin
            tr = new();
            if (tr.randomize())
                gen2drv.put(tr);
            else
                $display("Randomization failed!");
        end
    endtask

endclass
