with Fasti;

with Fasti_Steps.Dates;
with Fasti_Steps.Flows;

package body Fasti_Steps.Trading is

   --  Undated until a step names the date; the checks read it then.
   type State is (Undated, Dated);

   type Guard_Kind is (Always, Date_Reads);

   type Action_Kind is
     (A_Nothing, A_Keep_Day, A_Refuse_Day, A_Check_Trades, A_Check_Closed);

   First_Capture : constant := 1;

   function Word (Ctx : Step_Context) return String
   is (Fabula.Args.Word (Ctx.A, First_Capture));

   function Evaluate
     (G : Guard_Kind; Ctx : Step_Context; Evt : Step_Kind) return Boolean
   is
      pragma Unreferenced (Evt);
   begin
      return
        (case G is
           when Always     => True,
           when Date_Reads => Dates.Reads (Word (Ctx)));
   end Evaluate;

   procedure Execute
     (A : Action_Kind; Ctx : in out Step_Context; Evt : Step_Kind)
   is
      pragma Unreferenced (Evt);
   begin
      case A is
         when A_Nothing      =>
            null;

         when A_Keep_Day     =>
            Ctx.W.Day := Dates.Packed (Word (Ctx));

         when A_Refuse_Day   =>
            Fabula.Check.Fail_Step
              (Ctx.R, "not a calendar date: " & Word (Ctx));

         when A_Check_Trades =>
            Fabula.Check.Is_True
              (Ctx.R,
               Fasti.Is_Trading_Day (Ctx.W.Day),
               "the market is closed");

         when A_Check_Closed =>
            Fabula.Check.Is_False
              (Ctx.R, Fasti.Is_Trading_Day (Ctx.W.Day), "the market trades");
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

   Day_Given    : constant Ev := (Kind => E_Day_Given);
   Check_Trades : constant Ev := (Kind => E_Check_Trades);
   Check_Closed : constant Ev := (Kind => E_Check_Closed);

   --!format off
   Table : constant Transition_Table :=
     [Undated + Day_Given (Date_Reads) / A_Keep_Day     >= Dated,
      Undated + Day_Given              / A_Refuse_Day   >= Undated,
      Dated   + Day_Given (Date_Reads) / A_Keep_Day     >= Dated,
      Dated   + Day_Given              / A_Refuse_Day   >= Undated,
      Dated   + Check_Trades           / A_Check_Trades >= Dated,
      Dated   + Check_Closed           / A_Check_Closed >= Dated];
   --!format on

   Current : State := Undated;

   procedure Offer
     (Ctx : in out Step_Context; Evt : Step_Kind; Handled : out Boolean) is
   begin
      Flow.Take (Table, Current, Ctx, Evt, Handled);
   end Offer;

   procedure Reset is
   begin
      Current := Undated;
   end Reset;

   function Phase return String
   is (Current'Image);

end Fasti_Steps.Trading;
