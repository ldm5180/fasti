with Fasti;

with Fasti_Steps.Dates;
with Fasti_Steps.Flows;

package body Fasti_Steps.Trading is

   --  Undated until a step names the date; the checks read it then.
   type State is (Undated, Dated);

   type Guard_Kind is (Always, Date_Reads, Day_Name_Reads);

   type Action_Kind is
     (A_Nothing,
      A_Keep_Day,
      A_Refuse_Day,
      A_Check_Weekday,
      A_Refuse_Day_Name,
      A_Check_Trades,
      A_Check_Closed,
      A_Check_Holiday,
      A_Check_No_Holiday);

   function Evaluate
     (G : Guard_Kind; Ctx : Step_Context; Evt : Step_Kind) return Boolean
   is
      pragma Unreferenced (Evt);
   begin
      return
        (case G is
           when Always         => True,
           when Date_Reads     => Dates.Date_Read (Ctx),
           when Day_Name_Reads => Dates.Is_Day_Name (Word (Ctx)));
   end Evaluate;

   procedure Expect_Day (Ctx : in out Step_Context) is
      Day : constant String := Dates.Name_Of (Fasti.Weekday_Of (Ctx.W.Day));
   begin
      Fabula.Check.Is_True (Ctx.R, Day = Word (Ctx), "it is a " & Day);
   end Expect_Day;

   procedure Execute
     (A : Action_Kind; Ctx : in out Step_Context; Evt : Step_Kind)
   is
      pragma Unreferenced (Evt);
   begin
      case A is
         when A_Nothing          =>
            null;

         when A_Keep_Day         =>
            Ctx.W.Day := Dates.Date (Ctx);

         when A_Refuse_Day       =>
            Dates.Refuse_Date (Ctx);

         when A_Check_Weekday    =>
            Expect_Day (Ctx);

         when A_Refuse_Day_Name  =>
            Fabula.Check.Fail_Step
              (Ctx.R, "not a day of the week: " & Word (Ctx));

         when A_Check_Trades     =>
            Fabula.Check.Is_True
              (Ctx.R,
               Fasti.Is_Trading_Day (Ctx.W.Day),
               "the market is closed");

         when A_Check_Closed     =>
            Fabula.Check.Is_False
              (Ctx.R, Fasti.Is_Trading_Day (Ctx.W.Day), "the market trades");

         when A_Check_Holiday    =>
            Fabula.Check.Is_True
              (Ctx.R,
               Fasti.Is_Market_Holiday (Ctx.W.Day),
               "it is no market holiday");

         when A_Check_No_Holiday =>
            Fabula.Check.Is_False
              (Ctx.R,
               Fasti.Is_Market_Holiday (Ctx.W.Day),
               "it is a market holiday");
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

   Day_Given        : constant Ev := (Kind => E_Day_Given);
   Check_Weekday    : constant Ev := (Kind => E_Check_Weekday);
   Check_Trades     : constant Ev := (Kind => E_Check_Trades);
   Check_Closed     : constant Ev := (Kind => E_Check_Closed);
   Check_Holiday    : constant Ev := (Kind => E_Check_Holiday);
   Check_No_Holiday : constant Ev := (Kind => E_Check_No_Holiday);

   --!format off
   Table : constant Transition_Table :=
     [Undated + Day_Given        (Date_Reads)     / A_Keep_Day         >= Dated,
      Undated + Day_Given                         / A_Refuse_Day       >= Undated,
      Dated   + Day_Given        (Date_Reads)     / A_Keep_Day         >= Dated,
      Dated   + Day_Given                         / A_Refuse_Day       >= Undated,
      Dated   + Check_Weekday    (Day_Name_Reads) / A_Check_Weekday    >= Dated,
      Dated   + Check_Weekday                     / A_Refuse_Day_Name  >= Dated,
      Dated   + Check_Trades                      / A_Check_Trades     >= Dated,
      Dated   + Check_Closed                      / A_Check_Closed     >= Dated,
      Dated   + Check_Holiday                     / A_Check_Holiday    >= Dated,
      Dated   + Check_No_Holiday                  / A_Check_No_Holiday >= Dated];
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
