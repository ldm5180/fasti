--  A chain fetch and the prior session (expirations.feature): the
--  trading days a fetch counts.  A region of the registry:
--  Offer takes this feature's steps, Reset starts a scenario, Phase
--  names its state.

package Fasti_Steps.Expirations is

   procedure Offer
     (Ctx : in out Step_Context; Evt : Step_Kind; Handled : out Boolean);

   procedure Reset;

   function Phase return String;

end Fasti_Steps.Expirations;
