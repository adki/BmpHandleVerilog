//------------------------------------------------------------------------------
// Copyright (c) 2018 by Ando Ki.
// 3-clause BSD license.
//------------------------------------------------------------------------------
// This module applies filter operations on the frame memory starting 'addr_in',
// and writes the result to the frame memory starting 'addr_out'.
module mod_edge
(
       input   wire  [31:0] addr_in   // frame memory address
     , input   wire  [31:0] addr_out  // frame memory address
     , input   wire  [31:0] width  // image width in pixels
     , input   wire  [31:0] height // image height in pixels
     , input   wire         start
     , output  reg          done=1'b0
);
    //--------------------------------------------------------------------------
    localparam FSIZE=7;
    localparam HF=FSIZE/2;
    integer filter[0:6][0:6]; // up to 7x7
    integer ida, idb;
    initial begin
       if (FSIZE==3) begin // 3x3 Laplacian edge detection
            filter[0][0]=-1; filter[0][1]=-1; filter[0][2]=-1;
            filter[1][0]=-1; filter[1][1]= 8; filter[1][2]=-1;
            filter[2][0]=-1; filter[2][1]=-1; filter[2][2]=-1;
       end
       if (FSIZE==5) begin // 5x5 Laplacian edge detection
            filter[0][0]=-1; filter[0][1]=-1; filter[0][2]=-1; filter[0][3]=-1; filter[0][4]=-1;
            filter[1][0]=-1; filter[1][1]=-1; filter[1][2]=-1; filter[1][3]=-1; filter[1][4]=-1;
            filter[2][0]=-1; filter[2][1]=-1; filter[2][2]=24; filter[2][3]=-1; filter[2][4]=-1;
            filter[3][0]=-1; filter[3][1]=-1; filter[3][2]=-1; filter[3][3]=-1; filter[3][4]=-1;
            filter[4][0]=-1; filter[4][1]=-1; filter[4][2]=-1; filter[4][3]=-1; filter[4][4]=-1;
       end
       if (FSIZE==7) begin // 7 x 7 Laplacian edge detection
           for (ida=0; ida<7; ida=ida+1)
           for (idb=0; idb<7; idb=idb+1)
                filter[ida][idb] = -1;
           filter[3][3] = 48;
        end
    end
    //--------------------------------------------------------------------------
    integer idx, idy, idz, idw;
    //--------------------------------------------------------------------------
    integer sumB, sumG, sumR;
    always begin
      wait (start==1'b0);
      wait (start==1'b1);
`ifdef aabbcc
      // bypass for debugging
      for (idy=0; idy<height; idy=idy+1) begin
           for (idx=0; idx<width; idx=idx+1) begin
                put_pixel(idy, idx, get_pixel(idy, idx, 0), 0);
                put_pixel(idy, idx, get_pixel(idy, idx, 1), 1);
                put_pixel(idy, idx, get_pixel(idy, idx, 2), 2);
           end
      end
`else
      for (idy=0; idy<HF; idy=idy+1) begin // boundary
           for (idx=0; idx<width; idx=idx+1) begin
                put_pixel(idy, idx, 8'h00, 0);
                put_pixel(idy, idx, 8'h00, 1);
                put_pixel(idy, idx, 8'h00, 2);
           end
      end
      for (idy=HF; idy<height-HF; idy=idy+1) begin
           for (idx=0; idx<width; idx=idx+1) begin
                if ((idx<HF)||(idx>=(width-HF))) begin // boundary
                    put_pixel(idy, idx, 8'h00, 0);
                    put_pixel(idy, idx, 8'h00, 1);
                    put_pixel(idy, idx, 8'h00, 2);
                end else begin
                    sumB = 0; sumG = 0; sumR = 0;
                    for (idz=0; idz<FSIZE; idz=idz+1) begin
                         for (idw=0; idw<FSIZE; idw=idw+1) begin
                              sumB = sumB + get_pixel(idy-HF+idz, idx-HF+idw, 0)*filter[idz][idw];
                              sumG = sumG + get_pixel(idy-HF+idz, idx-HF+idw, 1)*filter[idz][idw];
                              sumR = sumR + get_pixel(idy-HF+idz, idx-HF+idw, 2)*filter[idz][idw];
                         end
                    end
                    sumB = (sumB<0) ? 0 : (sumB>255) ? 255 : sumB; // clamping
                    sumG = (sumG<0) ? 0 : (sumG>255) ? 255 : sumG; // clamping
                    sumR = (sumR<0) ? 0 : (sumR>255) ? 255 : sumR; // clamping
                    put_pixel(idy, idx, sumB, 0);
                    put_pixel(idy, idx, sumG, 1);
                    put_pixel(idy, idx, sumR, 2);
                end
           end
      end
      for (idy=(height-HF); idy<height; idy=idy+1) begin // boundary
           for (idx=0; idx<width; idx=idx+1) begin
                put_pixel(idy, idx, 8'h00, 0);
                put_pixel(idy, idx, 8'h00, 1);
                put_pixel(idy, idx, 8'h00, 2);
           end
      end
`endif
      done = 1'b1;
      wait (start==1'b0);
      done = 1'b0;
    end
    //--------------------------------------------------------------------------
    function [7:0] get_pixel;
         input integer y;
         input integer x;
         input integer c; // 0=B, 1=G, 2=R
         reg [31:0] adx;
    begin
         adx = addr_in + (width*y*3) + x*3 + c;
         get_pixel = u_frame_memory.read(adx);
    end
    endfunction
    //--------------------------------------------------------------------------
    task put_pixel;
         input integer y;
         input integer x;
         input [7:0]   data;
         input integer c; // 0=B, 1=G, 2=R
         reg [31:0] adx;
         reg [ 7:0] dummy;
    begin
         adx = addr_out + (width*y*3) + x*3 + c;
         dummy = u_frame_memory.write(adx,data);
    end
    endtask
    //--------------------------------------------------------------------------
endmodule
//------------------------------------------------------------------------------
// Revision history:
//
// 2018.04.08: Started by Ando Ki (adki@future-ds.com, andoki@gmail.com)
//------------------------------------------------------------------------------
