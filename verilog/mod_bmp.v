//------------------------------------------------------------------------------
// Copyright (c) 2018 by Ando Ki.
// 3-clause BSD license.
//------------------------------------------------------------------------------
module mod_bmp
     #(parameter BMP_IMG_WIDTH=640 // image width in pixels
               , BMP_IMG_HEIGHT=480 // image height in pixels
               , BMP_FILE_NAME=128 // filename length
       )
(
       input   wire  [0:8*BMP_FILE_NAME-1] bmp_input_file_name
     , input   wire  [31:0]      bmp_input_address
     , input   wire              bmp_input_start
     , output  reg               bmp_input_done=1'b0
     , input   wire  [0:8*BMP_FILE_NAME-1] bmp_output_file_name
     , input   wire  [31:0]      bmp_output_address
     , input   wire              bmp_output_start
     , output  reg               bmp_output_done=1'b0
     , output  reg   [31:0]      bmp_width=32'h0
     , output  reg   [31:0]      bmp_height=32'h0
);
    //--------------------------------------------------------------------------
    `include "tasks_bmp.v"
    //--------------------------------------------------------------------------
    integer fd_input;
    integer fd_output;
    integer code;
    integer idx, idy;
    reg [31:0] dummy;
    //--------------------------------------------------------------------------
    // 1) wait for 'bmp_input_start' asserted
    // 2) open BMP file
    // 3) write bitmap data to frame memory
    // 4) drive done
    // 5) wait for 'bmp_input_start' de-asserted
    // 6) deassert done
    always begin
        #1;
        wait (bmp_input_start==1'b1);
        fd_input = $fopen(bmp_input_file_name, "rb");
        if (fd_input==0) begin
            $display("%m %s cannot open", bmp_input_file_name);
            $finish(2);
        end
        bmp_read(fd_input, code);
        bmp_width = bmp_image_width(0);
        bmp_height = bmp_image_height(0);
        $fclose(fd_input);
        //----------------------------------------------------------------------
        // write bitmap to frame memory
        for (idx=0; idx<bmp_image_size(0); idx=idx+1) begin
             dummy = u_frame_memory.write(bmp_input_address+idx, pBitMap[idx]);
        end
        //----------------------------------------------------------------------
        // handshake
        bmp_input_done = 1'b1;
        wait (bmp_input_start==1'b0);
        bmp_input_done = 1'b0;
    end
    //--------------------------------------------------------------------------
    // 1) wait for 'bmp_output_start' asserted
    // 2) open BMP file
    // 3) read bitmap data from frame memory
    // 4) drive done
    // 5) wait for 'bmp_output_start' de-asserted
    // 6) deassert done
    always begin
        #1;
        wait (bmp_output_start==1'b1);
        fd_output = $fopen(bmp_output_file_name, "wb");
        if (fd_output==0) begin
            $display("%m %s cannot open", bmp_output_file_name);
            $finish(2);
        end
        //----------------------------------------------------------------------
        // read bitmap from frame memory
        for (idy=0; idy<bmp_image_size(0); idy=idy+1) begin
             pBitMap[idy] = u_frame_memory.read(bmp_output_address+idy);
        end
        //----------------------------------------------------------------------
        // prepare file and image header
        bmp_gen_file_header(bmp_width, bmp_height);
        bmp_gen_img_header(bmp_width, bmp_height);
        //----------------------------------------------------------------------
        bmp_write(fd_output, code);
        $fclose(fd_output);
        //----------------------------------------------------------------------
        // handshake
        bmp_output_done = 1'b1;
        wait (bmp_output_start==1'b0);
        bmp_output_done = 1'b0;
    end
endmodule
//------------------------------------------------------------------------------
// Revision history:
//
// 2018.04.08: Started by Ando Ki (adki@future-ds.com, andoki@gmail.com)
//------------------------------------------------------------------------------
