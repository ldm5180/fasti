with AUnit.Test_Cases;

--  The feature steps' own word parsers (Fasti_Steps.Dates): test code
--  with edges of its own -- a capture that does not start at index 1,
--  a word one character off the shape, a date outside the window.

package Fasti_Steps_Dates_Tests is

   type Test is new AUnit.Test_Cases.Test_Case with null record;

   overriding
   procedure Register_Tests (T : in out Test);

   overriding
   function Name (T : Test) return AUnit.Message_String;

end Fasti_Steps_Dates_Tests;
