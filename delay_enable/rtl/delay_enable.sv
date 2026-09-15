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
// delay_enable
//
// One-shot timer: on a start pulse, counts cr_delay_period clocks and then
// emits a single-cycle delay_out.
//
// Unlike clock_enable this does not free-run -- it fires once per start and
// then idles, which is what a timeout or a settling delay needs rather than a
// periodic strobe.
//
// A start arriving while a delay is already running is IGNORED, not queued and
// not restarting the count, so back-to-back starts cannot shorten a delay
// already in progress.
//
////////////////////////////////////////////////////////////////////////////////

`default_nettype none

module delay_enable #(
    parameter int COUNTER_WIDTH_P = -1
  )(
    input  wire                          clk,
    input  wire                          rst_n,
    input  wire                          reset_counter_n,
    input  wire                          start,
    output logic                         delay_out,
    input  wire  [COUNTER_WIDTH_P-1 : 0] cr_delay_period
  );

  logic [COUNTER_WIDTH_P-1 : 0] delay_counter;
  logic                         delaying;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      delay_out     <= '0;
      delaying      <= '0;
      delay_counter <= '0;
    end
    else begin

      delay_out <= '0;

      if (!reset_counter_n) begin
        delay_counter <= '0;
      end
      else if (delaying == '0 && start == '1) begin
        delaying      <= '1;
        delay_counter <= '0;
      end
      else begin
        if (delaying == '1) begin
          if (delay_counter >= cr_delay_period-1) begin
            delaying      <= '0;
            delay_counter <= '0;
            delay_out     <= '1;
          end
          else begin
            delay_counter <= delay_counter + 1;
          end
        end
      end
    end
  end

endmodule

`default_nettype wire
