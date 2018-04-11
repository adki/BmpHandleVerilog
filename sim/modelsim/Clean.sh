#!/bin/sh -f

MODELSIMWORK=work

if [ -d ${MODELSIMWORK}      ]; then /bin/rm -fr ${MODELSIMWORK}; fi
if [ -f transcript           ]; then /bin/rm -f  transcript; fi
if [ -f wave.vcd             ]; then /bin/rm -f  wave.vcd; fi
if [ -f vsim.wlf             ]; then /bin/rm -f  vsim.wlf; fi
if [ -f vish_stacktrace.vstf ]; then /bin/rm -f  vish_stacktrace.vstf; fi
if [ -f result.bmp           ]; then /bin/rm -f  result.bmp; fi

