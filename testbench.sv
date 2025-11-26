`timescale 1ns/1ps

`include "interface.sv"
`include "environment.sv"

module tb;

    // clock/reset
    logic clk = 0;
    logic reset;

    always #5 clk = ~clk;

    // interface instance (Pclk connected to clk, Prst connected to reset)
    apb_if apb_intf(.Pclk(clk), .Prst(reset));

    // DUT temp signal (one output in APB_memory)
    logic [31:0] temp;

    // DUT (paste your APB_memory module file in the project and compile together)
    APB_memory dut (
        .Pclk(clk),
        .Prst(reset),
        .Paddr(apb_intf.Paddr),
        .Pselx(apb_intf.Pselx),
        .Penable(apb_intf.Penable),
        .Pwrite(apb_intf.Pwrite),
        .Pwdata(apb_intf.Pwdata),
        .Pready(apb_intf.Pready),
        .Pslverr(apb_intf.Pslverr),
        .Prdata(apb_intf.Prdata),
        .temp(temp)
    );

    // environment
    apb_env env = new(apb_intf);

    // testbench-level coverage (optional)
    covergroup tb_cg @(posedge clk);
        coverpoint apb_intf.Paddr {
            bins low  = {[0:7]};
            bins mid  = {[8:23]};
            bins high = {[24:31]};
        }
        coverpoint apb_intf.Pwrite {
            bins read  = {0};
            bins write = {1};
        }
        cross apb_intf.Paddr, apb_intf.Pwrite;
    endgroup
    tb_cg cg = new();

    // waveform dump (VCD)
    initial begin
        $dumpfile("apb_wave.vcd");
        $dumpvars(0, tb);
    end

    initial begin
        // reset sequence (active-low reset used in DUT)
        // assert reset (drive low), hold for a few cycles, then release (drive high)
        reset = 1;
        @(posedge clk);
        reset = 0;            // assert (active-low)
        repeat (3) @(posedge clk);
        reset = 1;            // deassert

        // run environment
        env.start();

        // run long enough for transactions to finish
        #2000;

        $display("Simulation finished");
        // ----------------------------------------
        // Coverage Report
        // ----------------------------------------
        $display("\n==============================");
        $display(" TOTAL COVERAGE = %0.2f%%", $get_coverage());
        $display("==============================\n");
        $finish;
    end

endmodule



