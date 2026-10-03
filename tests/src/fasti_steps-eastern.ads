--  An instant on the Eastern wall clock (eastern.feature): an epoch
--  instant is given, then its Eastern date and time.  A region of the
--  registry: Offer takes this feature's steps, Reset starts a scenario,
--  Phase names its state.

package Fasti_Steps.Eastern is

   procedure Offer
     (Ctx : in out Step_Context; Evt : Step_Kind; Handled : out Boolean);

   procedure Reset;

   function Phase return String;

end Fasti_Steps.Eastern;
