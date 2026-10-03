--  The entry mask (weekdays.feature): a mask is given, then whether
--  it admits the scenario's date.  The date and its day name are the
--  trading region's steps.  A region of the registry: Offer takes this
--  feature's steps, Reset starts a scenario, Phase names its state.

package Fasti_Steps.Weekdays is

   procedure Offer
     (Ctx : in out Step_Context; Evt : Step_Kind; Handled : out Boolean);

   procedure Reset;

   function Phase return String;

end Fasti_Steps.Weekdays;
