////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2026 Fredrik Åkerlund
// https://github.com/akerlund/rtl_common
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// Description:
// clock_enable
//
// Produces a one-cycle enable strobe every cr_enable_period clocks, from a
// free-running counter.
//
// An enable rather than a divided clock, deliberately: everything downstream
// stays in the one clock domain and is simply gated, so there is no second
// clock to constrain, no clock-domain crossing, and nothing for a synthesiser
// to route on a clock tree.
//
// The period is a register input, not a parameter, so the rate can change at
// run time. Pulling reset_counter_n low restarts the count, which is how
// several enables are brought into phase with each other.
//
////////////////////////////////////////////////////////////////////////////////

`default_nettype none

module clock_enable #(
    parameter int COUNTER_WIDTH_P = -1
  )(
    input  wire                          clk,
    input  wire                          rst_n,
    input  wire                          reset_counter_n,
    output logic                         enable,
    input  wire  [COUNTER_WIDTH_P-1 : 0] cr_enable_period
  );

  logic [COUNTER_WIDTH_P-1 : 0] clock_enable_counter;


  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      enable               <= '0;
      clock_enable_counter <= '0;
    end
    else begin

      enable               <= '0;
      clock_enable_counter <= clock_enable_counter + 1;

      if (!reset_counter_n) begin
        clock_enable_counter <= '0;
      end
      else if (clock_enable_counter >= cr_enable_period-1) begin
        enable               <= '1;
        clock_enable_counter <= '0;
      end

    end
  end

endmodule

`default_nettype wire
