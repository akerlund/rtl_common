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
// frequency_enable
//
// Produces an enable strobe at a frequency given in HERTZ, rather than at a
// period given in clocks: write cr_enable_frequency and the module works out
// the counter value itself.
//
// It needs a divider to do that, and does not contain one. The period is
// SYS_CLK_FREQUENCY_P / cr_enable_frequency, so the module drives an EXTERNAL
// long-division unit over the AXI4-Stream ports -- dividend out, divisor out,
// quotient back -- and only then starts counting. The four-state sequence is
// visible in enable_state.
//
// That external divider is the thing to know before instantiating this: unlike
// the other enable generators here it is not self-contained, and with nothing
// answering on div_ing_* it will wait in WAIT_QUOTIENT_E forever and never
// assert enable. The divider is expected to be fixed point, which is what
// Q_BITS_P describes, and AXI4S_ID_P identifies this client if several share
// one divider through an arbiter.
//
// A new frequency written at run time re-runs the division.
//
////////////////////////////////////////////////////////////////////////////////

`default_nettype none

module frequency_enable #(
    parameter int SYS_CLK_FREQUENCY_P = -1,
    parameter int AXI_DATA_WIDTH_P    = -1,
    parameter int AXI_ID_WIDTH_P      = -1,
    parameter int Q_BITS_P            = -1,
    parameter int AXI4S_ID_P          = -1
  )(
    input  wire                                      clk,
    input  wire                                      rst_n,

    output logic                                     enable,
    input  wire  [$clog2(SYS_CLK_FREQUENCY_P)-1 : 0] cr_enable_frequency,

    // -------------------------------------------------------------------------
    // Long division interface
    // -------------------------------------------------------------------------

    output logic                                     div_egr_tvalid,
    input  wire                                      div_egr_tready,
    output logic            [AXI_DATA_WIDTH_P-1 : 0] div_egr_tdata,
    output logic                                     div_egr_tlast,
    output logic              [AXI_ID_WIDTH_P-1 : 0] div_egr_tid,

    input  wire                                      div_ing_tvalid,
    output logic                                     div_ing_tready,
    input  wire             [AXI_DATA_WIDTH_P-1 : 0] div_ing_tdata,  // Quotient
    input  wire                                      div_ing_tlast,
    input  wire               [AXI_ID_WIDTH_P-1 : 0] div_ing_tid,
    input  wire                                      div_ing_tuser   // Overflow
  );

  typedef enum {
    SEND_DIVIDEND_E,
    SEND_DIVISOR_E,
    WAIT_QUOTIENT_E,
    ENABLE_COUNTING_E
  } enable_state_t;

  enable_state_t enable_state;

  logic [$clog2(SYS_CLK_FREQUENCY_P)-1 : 0] counter;
  logic [$clog2(SYS_CLK_FREQUENCY_P)-1 : 0] enable_frequency;
  logic [$clog2(SYS_CLK_FREQUENCY_P)-1 : 0] frequency_as_sys_clks;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin

      // Ports
      enable                <= '0;
      div_egr_tvalid        <= '0;
      div_egr_tdata         <= '0;
      div_egr_tlast         <= '0;
      div_egr_tid           <= '0;
      div_ing_tready        <= '0;

      enable_state          <= SEND_DIVIDEND_E;
      counter               <= '0;
      enable_frequency      <= '0;
      frequency_as_sys_clks <= '0;
    end
    else begin

      div_egr_tid <= AXI4S_ID_P;

      case (enable_state)

        SEND_DIVIDEND_E: begin

          if (cr_enable_frequency) begin

            enable_frequency <= cr_enable_frequency;

            enable_state     <= SEND_DIVISOR_E;

            div_egr_tvalid   <= '1;
            div_egr_tdata    <= SYS_CLK_FREQUENCY_P << Q_BITS_P;
            div_egr_tlast    <= '0;
            div_egr_tid      <= AXI4S_ID_P;
          end
        end


        SEND_DIVISOR_E: begin

          if (div_egr_tready) begin

            // Dividend was sent
            if (!div_egr_tlast) begin
              div_egr_tdata  <= cr_enable_frequency << Q_BITS_P;
              div_egr_tlast  <= '1;
            end
            // Divisor was sent
            else begin
              div_egr_tvalid <= '0;
              div_egr_tlast  <= '0;
              enable_state   <= WAIT_QUOTIENT_E;
            end
          end
        end


        WAIT_QUOTIENT_E: begin
          div_ing_tready <= '1;
          if (div_ing_tvalid) begin
            div_ing_tready        <= '0;
            frequency_as_sys_clks <= div_ing_tdata >> Q_BITS_P;
            enable_state          <= ENABLE_COUNTING_E;
          end
        end


        ENABLE_COUNTING_E: begin

          enable  <= '0;
          counter <= counter + 1;

          if (counter >= frequency_as_sys_clks-1) begin
            enable  <= '1;
            counter <= '0;
          end

          if (enable_frequency != cr_enable_frequency) begin
            enable       <= '0;
            counter      <= '0;
            enable_state <= SEND_DIVIDEND_E;
          end

        end

      endcase

    end
  end

endmodule

`default_nettype wire
