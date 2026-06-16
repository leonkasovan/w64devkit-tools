set pagination off
set logging file gdb.log
set logging on
set logging redirect on
handle SIGSEGV stop
handle SIGABRT stop
handle SIGFPE stop
run ssz/ikemen.ssz

# Only print crash diagnostics if the program stopped due to a signal
# $_exitsignal is an integer on signal, void on normal exit
# Compare against $_void to avoid "Invalid type combination" error
if $_exitsignal != $_void
  bt full
  info registers
  x/30i $pc-20
end
quit
