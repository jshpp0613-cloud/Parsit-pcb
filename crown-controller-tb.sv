`timescale 1ns/1ps

module crown_controller_tb;

    // Inputs
    logic clk;
    logic rst_n;
    logic crown_press;

    // Outputs
    logic gps_wake;
    logic beep;
    logic gps_sleep;

    // Instantiate the Crown Controller
    crown_controller uut (
        .clk         (clk),
        .rst_n       (rst_n),
        .crown_press (crown_press),
        .gps_wake    (gps_wake),
        .beep        (beep),
        .gps_sleep   (gps_sleep)
    );

    // Clock — 32.768kHz = ~30517ns period
    initial clk = 0;
    always #15259 clk = ~clk;

    // Test sequence
    initial begin
        $dumpfile("crown_controller.vcd");
        $dumpvars(0, crown_controller_tb);

        // Reset
        rst_n = 0;
        crown_press = 0;
        #100000;
        rst_n = 1;
        #100000;

        // Simulate crown press
        $display("TEST: Crown pressed");
        crown_press = 1;
        #30517;  // one clock cycle
        crown_press = 0;

        // Wait for GPS wake
        @(posedge gps_wake);
        $display("PASS: GPS woke up at time %0t", $time);

        // Wait for beep
        @(posedge beep);
        $display("PASS: Beep triggered at time %0t", $time);

        // Wait for GPS sleep
        @(posedge gps_sleep);
        $display("PASS: GPS sleeping at time %0t", $time);

        // Back to idle
        #100000;
        $display("TEST COMPLETE — Crown Controller working");
        $finish;
    end

    // Monitor state changes
    initial begin
        $monitor("Time=%0t | gps_wake=%b | beep=%b | gps_sleep=%b",
                  $time, gps_wake, beep, gps_sleep);
    end

endmodule
