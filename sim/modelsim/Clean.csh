#!/bin/csh -f

if ( -d work                 ) /bin/rm -rf work    
if ( -d lib                  ) /bin/rm -rf lib     
if ( -e transcript           ) /bin/rm -f transcript    
if ( -e wave.vcd             ) /bin/rm -f wave.vcd    
if ( -e vish_stacktrace.vstf ) /bin/rm -f vish_stacktrace.vstf    
if ( -e vsim.wlf             ) /bin/rm -f vsim.wlf    
if ( -e result.bmp           ) /bin/rm -f result.bmp

\rm -f wlf??*
