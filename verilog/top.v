//------------------------------------------------------------------------------
// Copyright (c) 2018 by Ando Ki
// 3-clause BSD license.
//------------------------------------------------------------------------------
`ifndef BMP_INPUT_FILE
`define BMP_INPUT_FILE "images/lenna_320x240.bmp"
`endif
`ifndef BMP_OUTPUT_FILE
`define BMP_OUTPUT_FILE "result.bmp"
`endif
`ifndef BMP_IMG_WIDTH
`define BMP_IMG_WIDTH  640  // maximum size of image to handle
`endif
`ifndef BMP_IMG_HEIGHT
`define BMP_IMG_HEIGHT 480  // maximum size of image to handle
`endif
`ifndef BMP_FILE_NAME
`define BMP_FILE_NAME 128
`endif

module top;
  //----------------------------------------------------------------------------
  reg   [0:8*`BMP_FILE_NAME-1] bmp_input_file_name ;
  reg   [31:0]                 bmp_input_address   =32'h0;
  reg                          bmp_input_start     = 1'b0;
  wire                         bmp_input_done      ;
  reg   [0:8*`BMP_FILE_NAME-1] bmp_output_file_name;
  reg   [31:0]                 bmp_output_address  =32'h0;
  reg                          bmp_output_start    = 1'b0;
  wire                         bmp_output_done     ;
  wire  [31:0]                 bmp_width;
  wire  [31:0]                 bmp_height;
  //----------------------------------------------------------------------------
  mod_bmp #(.BMP_IMG_WIDTH (`BMP_IMG_WIDTH ) // need to prepare pixel buffer
           ,.BMP_IMG_HEIGHT(`BMP_IMG_HEIGHT) // need to prepare pixel buffer
           ,.BMP_FILE_NAME (`BMP_FILE_NAME ))// num of character of file name
  u_bmp (
       .bmp_input_file_name  ( bmp_input_file_name  )
     , .bmp_input_address    ( bmp_input_address    )
     , .bmp_input_start      ( bmp_input_start      )
     , .bmp_input_done       ( bmp_input_done       )
     , .bmp_output_file_name ( bmp_output_file_name )
     , .bmp_output_address   ( bmp_output_address   )
     , .bmp_output_start     ( bmp_output_start     )
     , .bmp_output_done      ( bmp_output_done      )
     , .bmp_width            ( bmp_width            )
     , .bmp_height           ( bmp_height           )
  );
  //----------------------------------------------------------------------------
  mod_mem #(.SIZE(`BMP_IMG_WIDTH*`BMP_IMG_HEIGHT*3*4))
  u_frame_memory (
       .dummy()
  );
  //----------------------------------------------------------------------------
  reg  edge_start=1'b0;
  wire edge_done;
  //----------------------------------------------------------------------------
  mod_edge
  u_edge (
       .addr_in  (bmp_input_address )
     , .addr_out (bmp_output_address)
     , .width    (bmp_width         )
     , .height   (bmp_height        )
     , .start    (edge_start        )
     , .done     (edge_done         )
  );
  //----------------------------------------------------------------------------
  initial begin
$display("%m bmp read");
      // let mod_bmp read source image
      bmp_input_file_name = `BMP_INPUT_FILE;
      bmp_input_address   =32'h0;
      bmp_input_start     = 1'b1;
      wait (bmp_input_done==1'b1);
      bmp_input_start     = 1'b0;

$display("%m edge detection");
      // let mod_edge perform edge detection
      bmp_input_address   =32'h0;
      bmp_output_address  = `BMP_IMG_WIDTH*`BMP_IMG_HEIGHT*3;
      edge_start = 1'b1;
      wait (edge_done==1'b1);
      edge_start = 1'b0;

$display("%m bmp write");
      // let mod_bmp write destination image
      bmp_output_file_name = `BMP_OUTPUT_FILE;
      bmp_output_address   = `BMP_IMG_WIDTH*`BMP_IMG_HEIGHT*3;
      bmp_output_start     = 1'b1;
      wait (bmp_output_done==1'b1);
      bmp_output_start     = 1'b0;

      $finish(2);
  end
  //----------------------------------------------------------------------------
  // Below may not useless since clock does not exist.
`ifdef VCD
  initial begin
      $dumpfile("wave.vcd");
      $dumpvars(0);
  end
`endif
  //----------------------------------------------------------------------------
endmodule
//------------------------------------------------------------------------------
// Revision history
//
// 2018.04.08: Re-written by Ando Ki (adki@future-ds.com, andoki@gmail.com)
//------------------------------------------------------------------------------
