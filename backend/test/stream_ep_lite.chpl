
const numVectors = 3;


config const m = 100000;
config const alpha = 3.0;

//
// Configuration constants to set the number of trials to run and the
// amount of error to permit in the verification
//
config const numTrials = 10;
config const epsilon = 1e-6;
config const useRandomSeed = true;

config const printParams = true;
config const printStats = true;

//
// The program entry point
//
proc chapel_main() {
  printConfiguration();   // print the problem size, number of trials, etc.
  //
  // *** Fragment control so that we have a single task running on
  // *** every locale.
  //
  coforall loc in Locales do on loc {

    var execTime: [1..numTrials] real;

    //
    // *** A, B, and C are the three local vectors
    //
    var A: [1..m] real;
    var B: [1..m] real;
    var C: [1..m] real;

    // Initialize the input vectors, B and C
    forall (b, c) in zip(B, C) do {
      b = 1.0;
      c = 1.0;
    }

    for trial in 1..numTrials {                        // loop over the trials

      //
      // *** The main loop looks identical to stream.chpl.  However,
      // *** in this version we are iterating over arrays that are
      // *** not distributed.
      //
      forall (a, b, c) in zip(A, B, C) do
        a = b + alpha * c;

    }

    if (printStats) {
      writeln("Execution done on locale ", here.id);
    }

 }

}

//
// Print the problem size and number of trials
//
proc printConfiguration() {
  if (printParams) {
    //
    // *** Here we multiply m by the number of locales so that we can
    // *** print out the global problem size.
    //
    writeln("Number of trials = ", numTrials);
    writeln("m = ", m);
  }
}

chapel_main();