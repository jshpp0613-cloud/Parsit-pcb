module crown_controller (
    input  logic clk,          // System clock
    input  logic rst_n,        // Active low reset
    input  logic crown_press,  // Crown button press
    output logic gps_wake,     // Wake GPS module
    output logic beep,         // Trigger speaker beep
    output logic gps_sleep     // Sleep GPS module
);

    // States
    typedef enum logic [2:0] {
        IDLE       = 3'b000,
        WAKE_GPS   = 3'b001,
        SYNCING    = 3'b010,
        BEEP       = 3'b011,
        SLEEP_GPS  = 3'b100
    } state_t;

    state_t current_state, next_state;

    // Timer — 30 seconds at 32.768kHz = 983,040 cycles
    localparam SYNC_TIME = 983_040;
    localparam BEEP_TIME = 328;      // ~10ms beep
    
    logic [19:0] timer;
    logic timer_done;

    // State register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // Timer
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            timer <= 0;
        else if (current_state == IDLE)
            timer <= 0;
        else
            timer <= timer + 1;
    end

    assign timer_done = (current_state == SYNCING && timer >= SYNC_TIME) ||
                        (current_state == BEEP    && timer >= SYNC_TIME + BEEP_TIME);

    // Next state logic
    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE:      if (crown_press)        next_state = WAKE_GPS;
            WAKE_GPS:                           next_state = SYNCING;
            SYNCING:   if (timer >= SYNC_TIME)  next_state = BEEP;
            BEEP:      if (timer_done)          next_state = SLEEP_GPS;
            SLEEP_GPS:                          next_state = IDLE;
            default:                            next_state = IDLE;
        endcase
    end

    // Output logic
    assign gps_wake  = (current_state == WAKE_GPS || current_state == SYNCING);
    assign beep      = (current_state == BEEP);
    assign gps_sleep = (current_state == SLEEP_GPS);

endmodule
