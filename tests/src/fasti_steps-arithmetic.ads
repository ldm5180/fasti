--  Civil days between two dates (arithmetic.feature): one step that
--  names both dates and the count.  A region of the registry: Offer
--  takes this feature's steps, Reset starts a scenario, Phase names
--  its state.

package Fasti_Steps.Arithmetic is

   procedure Offer
     (Ctx : in out Step_Context; Evt : Step_Kind; Handled : out Boolean);

   procedure Reset;

   function Phase return String;

end Fasti_Steps.Arithmetic;
