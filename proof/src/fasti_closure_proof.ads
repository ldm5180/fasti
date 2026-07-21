--  The proof closure: withs the library unit so the analysis entry point
--  is explicit (gnatprove analyses every source in the tree; fasti has no
--  generics needing concrete instances -- the tempus units in the tree are
--  proved in place, as in the consumer repos).

with Fasti;

package Fasti_Closure_Proof
  with SPARK_Mode
is

end Fasti_Closure_Proof;
