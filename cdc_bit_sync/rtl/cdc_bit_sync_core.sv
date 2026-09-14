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
// cdc_bit_sync_core
//
// One register in the source domain feeding a two-flop synchroniser in the
// destination domain.
//
// The source-side register matters as much as the pair after it: it gives the
// crossing a clean flop output to sample, so the destination samples a signal
// with a known driver rather than whatever combinational logic produced
// src_bit. The two destination flops are what resolve metastability -- the
// first may settle late, and the second gives it a full clock period to do so
// before anything downstream sees the value.
//
// Latency is therefore two destination clocks after the source register, and
// the value is only meaningful while it is held; see cdc_bit_sync.
//
////////////////////////////////////////////////////////////////////////////////

`default_nettype none

module cdc_bit_sync_core (

    input  wire  clk_src,
    input  wire  rst_src_n,
    input  wire  clk_dst,
    input  wire  rst_dst_n,

    input  wire  src_bit,
    output logic dst_bit
  );

  logic src_bit_d0;
  logic dst_bit_d0;

  always_ff @ (posedge clk_src or negedge rst_src_n) begin
    if (!rst_src_n) begin
      src_bit_d0 <= '0;
    end
    else begin
      src_bit_d0 <= src_bit;
    end
  end

  always_ff @ (posedge clk_dst or negedge rst_dst_n) begin
    if (!rst_dst_n) begin
      dst_bit_d0 <= '0;
      dst_bit    <= '0;
    end
    else begin
      dst_bit_d0 <= src_bit_d0;
      dst_bit    <= dst_bit_d0;
    end
  end

endmodule

`default_nettype wire
