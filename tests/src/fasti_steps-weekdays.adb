with Fasti;

with Fasti_Steps.Flows;

package body Fasti_Steps.Weekdays is

   --  Unmasked until a step names the mask; the entry check reads it.
   type State is (Unmasked, Masked);

   type Guard_Kind is (Always, Mask_Read, Says_Allowed, Says_Refused, Undated);

   type Action_Kind is
     (A_Nothing,
      A_Keep_Mask,
      A_Refuse_Mask,
      A_Expect_Allowed,
      A_Expect_Refused,
      A_Refuse_Undated,
      A_Refuse_Verdict);

   function Dated (Ctx : Step_Context) return Boolean
   is (Fasti.Valid (Ctx.W.Day));

   function Says (Ctx : Step_Context; Verdict : String) return Boolean
   is (Dated (Ctx) and then Word (Ctx) = Verdict);

   function Evaluate
     (G : Guard_Kind; Ctx : Step_Context; Evt : Step_Kind) return Boolean
   is
      pragma Unreferenced (Evt);
   begin
      return
        (case G is
           when Always       => True,
           when Mask_Read    => Count_Read (Ctx),
           when Says_Allowed => Says (Ctx, "allowed"),
           when Says_Refused => Says (Ctx, "refused"),
           when Undated      => not Dated (Ctx));
   end Evaluate;

   function Allowed (Ctx : Step_Context) return Boolean
   is (Fasti.Weekday_Allowed (Ctx.W.Mask, Ctx.W.Day))
   with Pre => Dated (Ctx);

   procedure Execute
     (A : Action_Kind; Ctx : in out Step_Context; Evt : Step_Kind)
   is
      pragma Unreferenced (Evt);
   begin
      case A is
         when A_Nothing        =>
            null;

         when A_Keep_Mask      =>
            Ctx.W.Mask := Count (Ctx);

         when A_Refuse_Mask    =>
            Refuse_Count (Ctx);

         when A_Expect_Allowed =>
            Fabula.Check.Is_True (Ctx.R, Allowed (Ctx), "entry is refused");

         when A_Expect_Refused =>
            Fabula.Check.Is_False (Ctx.R, Allowed (Ctx), "entry is allowed");

         when A_Refuse_Undated =>
            Fabula.Check.Fail_Step (Ctx.R, "name the date before the entry");

         when A_Refuse_Verdict =>
            Fabula.Check.Fail_Step
              (Ctx.R, "entry is allowed or refused, not " & Word (Ctx));
      end case;
   end Execute;

   package Flow is new
     Fasti_Steps.Flows
       (State       => State,
        Guard_Kind  => Guard_Kind,
        Action_Kind => Action_Kind,
        Evaluate    => Evaluate,
        Execute     => Execute,
        Always      => Always,
        Nothing     => A_Nothing);

   use Flow.Machines;
   use Flow.Op;

   Mask_Given  : constant Ev := (Kind => E_Mask_Given);
   Check_Entry : constant Ev := (Kind => E_Check_Entry);

   --!format off
   Table : constant Transition_Table :=
     [Unmasked + Mask_Given  (Mask_Read)    / A_Keep_Mask      >= Masked,
      Unmasked + Mask_Given                 / A_Refuse_Mask    >= Unmasked,
      Masked   + Mask_Given  (Mask_Read)    / A_Keep_Mask      >= Masked,
      Masked   + Mask_Given                 / A_Refuse_Mask    >= Unmasked,
      Masked   + Check_Entry (Says_Allowed) / A_Expect_Allowed >= Masked,
      Masked   + Check_Entry (Says_Refused) / A_Expect_Refused >= Masked,
      Masked   + Check_Entry (Undated)      / A_Refuse_Undated >= Masked,
      Masked   + Check_Entry                / A_Refuse_Verdict >= Masked];
   --!format on

   Current : State := Unmasked;

   procedure Offer
     (Ctx : in out Step_Context; Evt : Step_Kind; Handled : out Boolean) is
   begin
      Flow.Take (Table, Current, Ctx, Evt, Handled);
   end Offer;

   procedure Reset is
   begin
      Current := Unmasked;
   end Reset;

   function Phase return String
   is (Current'Image);

end Fasti_Steps.Weekdays;
