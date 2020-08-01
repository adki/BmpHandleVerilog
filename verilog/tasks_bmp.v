`ifndef TASKS_BMP_V
`define TASKS_BMP_V
//------------------------------------------------------------------------------
// Copyright (c) 2018-2020 by Ando Ki.
// 3-clause BSD license.
//------------------------------------------------------------------------------
// bmp_handle.v
//------------------------------------------------------------------------------
// bmp_read(fd, code);
// bmp_read_file_header(width, height, code);
// bmp_read_img_header(width, height, code);
// bmp_read_rgb(fd, pos, sze, code);
// bmp_get_red();
// bmp_get_green();
// bmp_get_blue();
// bmp_gen_file_header(width, height);
// bmp_gen_img_header(width, height);
// bmp_write(fd, code);
//------------------------------------------------------------------------------
reg [7:0] bmp_file_header[0:13]; // 14-byte
reg [7:0] bmp_img_header [0:39]; // 40-byte
integer   bmp_code; // too handle return values
//------------------------------------------------------------------------------
integer   bfOffBits; // offset to bitmap data
integer   biWidth; // image width
integer   biHeight; // image heigh
integer   biBitCount; // num of bits per pixel
integer   biSizeImage; // size of image data
//------------------------------------------------------------------------------
// Blue comes first, then Green, and then Red for 24-bit pixel case.
reg [7:0] pBitMap     [0:(BMP_IMG_WIDTH*BMP_IMG_HEIGHT*3)-1]; // RGB
reg [7:0] pBitMapRed  [0:BMP_IMG_WIDTH*BMP_IMG_HEIGHT-1]; // RED
reg [7:0] pBitMapGreen[0:BMP_IMG_WIDTH*BMP_IMG_HEIGHT-1]; // GREEN
reg [7:0] pBitMapBlue [0:BMP_IMG_WIDTH*BMP_IMG_HEIGHT-1]; // BLUE

//------------------------------------------------------------------------------
// Return the number of bytes of bitmap.
function integer bmp_image_size;
     input dummy;
     bmp_image_size=biSizeImage; // size of image data
endfunction

//------------------------------------------------------------------------------
// Return the number of bytes of bitmap.
function integer bmp_image_width;
     input dummy;
     bmp_image_width=biWidth;
endfunction

//------------------------------------------------------------------------------
// Return the number of bytes of bitmap.
function integer bmp_image_height;
     input dummy;
     bmp_image_height=biHeight;
endfunction

//------------------------------------------------------------------------------
// It reads file and fills necessary information.
// - 'fd' BMP file descriptor.
// - 'code' returns error if any.
task bmp_read;
     input  integer fd;
     output integer code;
            integer num;
begin
     bmp_read_file_header(fd, code);
`ifdef DEBUG
     $write("bmp_file_header");
     for (num=0; num<14; num=num+1) begin
          $write(":%02x", bmp_file_header[num]);
     end
     $write("\n");
`endif
     bmp_read_img_header(fd, code);
`ifdef DEBUG
     $write("bmp_img_header");
     for (num=0; num<40; num=num+1) begin
          $write(":%02x", bmp_img_header[num]);
     end
     $write("\n");
`endif
`ifdef VERBOSE
     $display("bfOffBits  = %d offset to bitmap data",bfOffBits  );
     $display("biWidth    = %d image width          ",biWidth    );
     $display("biHeight   = %d image heigh          ",biHeight   );
     $display("biBitCount = %d num of bits per pixel",biBitCount );
     $display("biSizeImage= %d size of image data   ",biSizeImage);
`endif
`ifdef DEBUG
    $display("bmp_file_header[ 0]=%d", bmp_file_header[ 0]);
    $display("bmp_file_header[ 1]=%d", bmp_file_header[ 1]);
    $display("file_size=%d", {bmp_file_header[ 5]
                             ,bmp_file_header[ 4]
                             ,bmp_file_header[ 3]
                             ,bmp_file_header[ 2]});
    $display("reserved=0x%08X", {bmp_file_header[ 9]
                                ,bmp_file_header[ 8]
                                ,bmp_file_header[ 7]
                                ,bmp_file_header[ 6]});
    $display("offbits=%d", {bmp_file_header[13]
                           ,bmp_file_header[12]
                           ,bmp_file_header[11]
                           ,bmp_file_header[10]});
    $display("hsize=%d",    {bmp_img_header[ 3]
                            ,bmp_img_header[ 2]
                            ,bmp_img_header[ 1]
                            ,bmp_img_header[ 0]});
    $display("width=%d",    {bmp_img_header[ 7]
                            ,bmp_img_header[ 6]
                            ,bmp_img_header[ 5]
                            ,bmp_img_header[ 4]});
    $display("height=%d",   {bmp_img_header[11]
                            ,bmp_img_header[10]
                            ,bmp_img_header[ 9]
                            ,bmp_img_header[ 8]});
    $display("Plane=%d",    {bmp_img_header[13]
                            ,bmp_img_header[12]});
    $display("count=%d",    {bmp_img_header[15]
                            ,bmp_img_header[14]});
    $display("Compress=%d", {bmp_img_header[19]
                            ,bmp_img_header[18]
                            ,bmp_img_header[17]
                            ,bmp_img_header[16]});
    $display("size=%d",     {bmp_img_header[23]
                            ,bmp_img_header[22]
                            ,bmp_img_header[21]
                            ,bmp_img_header[20]});
    $display("x=%d",        {bmp_img_header[27]
                            ,bmp_img_header[26]
                            ,bmp_img_header[25]
                            ,bmp_img_header[24]});
    $display("y=%d",        {bmp_img_header[31]
                            ,bmp_img_header[30]
                            ,bmp_img_header[29]
                            ,bmp_img_header[28]});
    $display("clrU=%d",     {bmp_img_header[35]
                            ,bmp_img_header[34]
                            ,bmp_img_header[33]
                            ,bmp_img_header[32]});
    $display("clrI=%d",     {bmp_img_header[39]
                            ,bmp_img_header[38]
                            ,bmp_img_header[37]
                            ,bmp_img_header[36]});
`endif
     bmp_read_rgb(fd, bfOffBits, biSizeImage, code);
end
endtask

//------------------------------------------------------------------------------
// It reads file and fills BMP file header.
// Note that the file header should be 14-byte.
// - 'fd' BMP file descriptor.
// - 'code' returns error if any.
task bmp_read_file_header;
     input  integer fd;
     output integer code;
begin
    code = $fseek(fd, 0, 0); // $frewind(fp);
  //code = $fread(bmp_file_header, fd, 0, 14);
    code = $fread(bmp_file_header, fd);
    if ((bmp_file_header[0]!=8'h42)|| // 'B'
        (bmp_file_header[1]!=8'h4d)) begin // 'M'
        $display("%m not BMP file");
        code = -1;
        disable bmp_read_file_header;
    end
    bfOffBits = {bmp_file_header[13]
                ,bmp_file_header[12]
                ,bmp_file_header[11]
                ,bmp_file_header[10]};
end
endtask

//------------------------------------------------------------------------------
// It reads file and fills BMP image header.
// It reads 40-bytes from position 14.
// Note that the image header will be 40 or 124 depending on version.
// - 'fd' BMP file descriptor.
// - 'code' returns error if any.
task bmp_read_img_header;
     input  integer fd;
     output integer code;
            integer pos;
            integer header_size;
     reg [7:0] value[0:3];
     integer offset; // file offset to PixelArray
begin
    code = $fseek(fd, 0, 0); // $frewind(fp);
    code = $fseek(fd, 10, 0);
    code = $fread(value, fd, 0, 4);
    offset = {value[3]
             ,value[2]
             ,value[1]
             ,value[0]};
    pos  = $ftell(fd);
    if (pos!=14) code = $fseek(fd, 14, 0);
    code = $fread(bmp_img_header, fd);
    header_size = {bmp_img_header[3]
                  ,bmp_img_header[2]
                  ,bmp_img_header[1]
                  ,bmp_img_header[0]};
    if (header_size!=(offset-14)) begin
        $display("%m BMP image header size mis-match %d, but %d expected",
                  header_size, offset-14);
        code = -1;
        disable bmp_read_img_header;
    end
    biWidth     = {bmp_img_header[ 7]
                  ,bmp_img_header[ 6]
                  ,bmp_img_header[ 5]
                  ,bmp_img_header[ 4]};
    biHeight    = {bmp_img_header[11]
                  ,bmp_img_header[10]
                  ,bmp_img_header[ 9]
                  ,bmp_img_header[ 8]};
    biBitCount  = {bmp_img_header[15]
                  ,bmp_img_header[14]};
    biSizeImage = {bmp_img_header[23]
                  ,bmp_img_header[22]
                  ,bmp_img_header[21]
                  ,bmp_img_header[20]};
    if (biBitCount!=24) begin
        $display("%m %d-bpp, but 24-bpp expected", biBitCount);
        code = -1;
        disable bmp_read_img_header;
    end
    if ((biWidth*biHeight*(biBitCount/8))!=biSizeImage) begin
        $display("%m image size mis-match %d, but %d expected",
                biSizeImage, (biWidth*biHeight*(biBitCount/8)));
        if (biSizeImage==0) begin
           biSizeImage = (biWidth*biHeight*(biBitCount/8));
        end else begin
           code = -1;
           disable bmp_read_img_header;
        end
    end
    if (biSizeImage>(BMP_IMG_WIDTH*BMP_IMG_HEIGHT*3)) begin
        $display("%m image size exceed the buffer size");
        code = -1;
        disable bmp_read_img_header;
    end
end
endtask

//------------------------------------------------------------------------------
// It reads pixel data.
// - 'fd' BMP file descriptor.
// - 'pos' offset to bitmap data
// - 'sze' bitmap (rgb) size in bytes
// - 'code' returns error if any.
task bmp_read_rgb;
     input  integer fd;
     input  integer pos;
     input  integer sze;
     output integer code;
begin
    if (biSizeImage>(BMP_IMG_WIDTH*BMP_IMG_HEIGHT*3)) begin
        code = -1;
        disable bmp_read_rgb;
    end
    code = $fseek(fd, pos, 0);
    code = $fread(pBitMap, fd, 0, sze);
end
endtask

//------------------------------------------------------------------------------
// It fills Red components to 'pBitMapRed[]' from 'pBitMap[]'.
// It should be called after 'bmp_read()' or 'bmp_read_rgb()'.
task bmp_get_red;
     integer idx, idy, idz;
begin
   if (biBitCount!=24) begin
       $display("%m only 24-bpp supported");
       $finish(2);
   end
   idz = 0;
   for (idy=0; idy<biHeight; idy=idy+1) begin
       for (idx=0; idx<biWidth; idx=idx+1) begin
            pBitMapRed[idz] = pBitMap[idz*3+2];
            idz = idz+1;
       end // idx
   end // idy
end
endtask

//------------------------------------------------------------------------------
// It fills Green components to 'pBitMapGreen[]' from 'pBitMap[]'.
// It should be called after 'bmp_read()' or 'bmp_read_rgb()'.
task bmp_get_green;
     integer idx, idy, idz;
begin
   if (biBitCount!=24) begin
       $display("%m only 24-bpp supported");
       $finish(2);
   end
   idz = 0;
   for (idy=0; idy<biHeight; idy=idy+1) begin
       for (idx=0; idx<biWidth; idx=idx+1) begin
            pBitMapGreen[idz] = pBitMap[idz*3+1];
            idz = idz+1;
       end // idx
   end // idy
end
endtask

//------------------------------------------------------------------------------
// It fills Blue components to 'pBitMapBlue[]' from 'pBitMap[]'.
// It should be called after 'bmp_read()' or 'bmp_read_rgb()'.
task bmp_get_blue;
     integer idx, idy, idz;
begin
   if (biBitCount!=24) begin
       $display("%m only 24-bpp supported");
       $finish(2);
   end
   idz = 0;
   for (idy=0; idy<biHeight; idy=idy+1) begin
       for (idx=0; idx<biWidth; idx=idx+1) begin
            pBitMapBlue[idz] = pBitMap[idz*3];
            idz = idz+1;
       end // idx
   end // idy
end
endtask

//------------------------------------------------------------------------------
// It fills BMP file header.
task bmp_gen_file_header;
     input  integer width;
     input  integer height;
            integer file_size;
begin
    file_size = width*height*3+54;
    bmp_file_header[ 0] = 8'h42; // 'B'
    bmp_file_header[ 1] = 8'h4d; // 'M'
   {bmp_file_header[ 5]
   ,bmp_file_header[ 4]
   ,bmp_file_header[ 3]
   ,bmp_file_header[ 2]} = file_size;
   {bmp_file_header[ 9]
   ,bmp_file_header[ 8]
   ,bmp_file_header[ 7]
   ,bmp_file_header[ 6]} = 0; // reserved
   {bmp_file_header[13]
   ,bmp_file_header[12]
   ,bmp_file_header[11]
   ,bmp_file_header[10]} = 54;
end
endtask

//------------------------------------------------------------------------------
// It fills BMP image header.
task bmp_gen_img_header;
     input  integer width;
     input  integer height;
            integer BitCount;
begin
   BitCount = 24;
   {bmp_img_header[ 3]
   ,bmp_img_header[ 2]
   ,bmp_img_header[ 1]
   ,bmp_img_header[ 0]} = 40;
   {bmp_img_header[ 7]
   ,bmp_img_header[ 6]
   ,bmp_img_header[ 5]
   ,bmp_img_header[ 4]} = width;
   {bmp_img_header[11]
   ,bmp_img_header[10]
   ,bmp_img_header[ 9]
   ,bmp_img_header[ 8]} = height;
   {bmp_img_header[13]
   ,bmp_img_header[12]} = 1; // biPlanes
   {bmp_img_header[15]
   ,bmp_img_header[14]} = BitCount;
   {bmp_img_header[19]
   ,bmp_img_header[18]
   ,bmp_img_header[17]
   ,bmp_img_header[16]} = 0; // biCompression
   {bmp_img_header[23]
   ,bmp_img_header[22]
   ,bmp_img_header[21]
   ,bmp_img_header[20]} = (width*height*(BitCount/8));// biSizeImage
   {bmp_img_header[27]
   ,bmp_img_header[26]
   ,bmp_img_header[25]
   ,bmp_img_header[24]} = 3780; // biXPelsPerMeter
   {bmp_img_header[31]
   ,bmp_img_header[30]
   ,bmp_img_header[29]
   ,bmp_img_header[28]} = 3780; // biYPelsPerMeter
   {bmp_img_header[35]
   ,bmp_img_header[34]
   ,bmp_img_header[33]
   ,bmp_img_header[32]} = 0; // biClrUsed
   {bmp_img_header[39]
   ,bmp_img_header[38]
   ,bmp_img_header[37]
   ,bmp_img_header[36]} = 0; // biClrImportant
end
endtask

//------------------------------------------------------------------------------
// It writes a new bmp file.
// 'bmp_file_header', 'bmp_img_header', 'pBitMap' should have proper data.
// - 'fd' BMP file descriptor.
// - 'code' returns error if any.
// Note 1:
// The output file may lose 1~3 bytes, when the file size is not a multiple of 4.
// The reason comes from "%u", which can only handle 4-bytes and "%c" will not
// write with value 0.
// Note 2:
// BMP with extra bitmap may not cause any problem.
// BMP with less than expected bitmap may cause problem.
task bmp_write;
     input  integer fd;
     output integer code;
            integer num;
            integer pos;
begin
    `ifdef XILINX_SIMULATOR
    $display("%m XSIM does have bug of $fwrite() and $fwriteb()!");
    $finish(2);
    `else
    $fwriteb(fd, "%u", {bmp_file_header[ 3],
                        bmp_file_header[ 2],
                        bmp_file_header[ 1],
                        bmp_file_header[ 0]});
    $fwriteb(fd, "%u", {bmp_file_header[ 7],
                        bmp_file_header[ 6],
                        bmp_file_header[ 5],
                        bmp_file_header[ 4]});
    $fwriteb(fd, "%u", {bmp_file_header[11],
                        bmp_file_header[10],
                        bmp_file_header[ 9],
                        bmp_file_header[ 8]});
    $fwriteb(fd, "%u", {bmp_img_header [ 1],
                        bmp_img_header [ 0],
                        bmp_file_header[13],
                        bmp_file_header[12]});
    for (num=2; num<38; num=num+4) begin
         $fwriteb(fd, "%u", {bmp_img_header [num+3],
                             bmp_img_header [num+2],
                             bmp_img_header [num+1],
                             bmp_img_header [num  ]});
    end
    $fwriteb(fd, "%u", {pBitMap [ 1],
                        pBitMap [ 0],
                        bmp_img_header [39],
                        bmp_img_header [38]});
    for (num=2; (num+4)<biSizeImage; num=num+4) begin
         $fwriteb(fd, "%u", {pBitMap [num+3],
                             pBitMap [num+2],
                             pBitMap [num+1],
                             pBitMap [num  ]});
    end
    for (num=num; num<biSizeImage; num=num+1) begin
         if (pBitMap[num]==8'h00) $fwriteb(fd, "%c", 8'h01);
         else $fwriteb(fd, "%c", pBitMap[num]); // this may not write 0x00.
    end
    `endif
end
endtask
//------------------------------------------------------------------------------
// Revision history:
//
// 2020.07.31: 'pBitMapRed/Green/Blue' added and 'bmp_get_red/green/blue' added.
// 2018.08.03: 'bmp_read_img_header' bug-fixed to handle ImageHeader Version 4.
// 2018.04.08: Started by Ando Ki (adki@future-ds.com, andoki@gmail.com)
//------------------------------------------------------------------------------
`endif
