--  The trading calendar's verdicts on one date (trading-days.feature):
--  a date is given, then whether it trades.  A region of the registry:
--  Offer takes this feature's steps, Reset starts a scenario, Phase
--  names its state.

package Fasti_Steps.Trading is

   procedure Offer
     (Ctx : in out Step_Context; Evt : Step_Kind; Handled : out Boolean);

   procedure Reset;

   function Phase return String;

end Fasti_Steps.Trading;
