set pagination off
set logging file gdb.log
set logging on
handle SIGSEGV stop print
handle SIGABRT stop print
handle SIGFPE stop print
handle SIGTRAP nostop noprint
run

if $_siginfo
  printf "\n=== CRASH DETECTED ===\n"
  printf "Signal: %d\n", $_siginfo.si_signo
  bt full
  info registers
  info threads
  x/30i $pc-20
else
  printf "\n=== Exit: code=%d ===\n", $_exitcode
end
quit
