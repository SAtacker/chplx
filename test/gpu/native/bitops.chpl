use GPUDiagnostics;
use BitOps;

config const verbose = false;

proc main() {

  const arg = 15;

  on here.gpus[0] {

    var R: [0..1] int;
    const r = 0..0;

    proc check(A, s) {
      if getGPUDiagnostics()[0].kernel_launch !=1 then
        writeln(s + " didn't result in kernel launch");
      else if verbose then
        writeln(s + " resulted in kernel launch");

      const isCorrect = if A.eltType == bool then A[0]==A[1] else isclose(A[0],A[1]);
      if !isCorrect then
        writeln(s + " computed wrong result. ("+A[0]:string+", "+A[1]:string+")");
      else if verbose then
        writeln(s + " computed right result. ("+A[0]:string+", "+A[1]:string+")");

      resetGPUDiagnostics();
    }

    startGPUDiagnostics();

    foreach i in r do R[0] = clz(arg); R[1] = clz(arg); check(R, "clz");
    foreach i in r do R[0] = ctz(arg); R[1] = ctz(arg); check(R, "ctz");

    foreach i in r do R[0] = popcount(arg); R[1] = popcount(arg); check(R, "popcount");
    foreach i in r do R[0] = parity(arg); R[1] = parity(arg); check(R, "parity");

    foreach i in r do R[0] = rotl(arg,2); R[1] = rotl(arg,2); check(R, "rotl");
    foreach i in r do R[0] = rotr(arg,2); R[1] = rotr(arg,2); check(R, "rotr");

    stopGPUDiagnostics();
  }
}
