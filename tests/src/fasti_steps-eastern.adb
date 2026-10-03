with Fabula.Check.Longs;
with Fabula.Numbers;

with Fasti;

with Fasti_Steps.Dates;
with Fasti_Steps.Flows;

package body Fasti_Steps.Eastern is

   --  No instant until a step gives one; the checks read it then.
   type State is (No_Instant, Converted);

   type Guard_Kind is (Always, Instant_Read, Reading_Reads, Date_Unread);

   type Action_Kind is
     (A_Nothing,
      A_Convert,
      A_Refuse_Instant,
      A_Check_Eastern,
      A_Refuse_Date,
      A_Refuse_Time,
      A_Check_No_Eastern);

   Instant_Capture : constant := 1;
   Date_Capture    : constant := 1;
   Time_Capture    : constant := 2;

   function Reading_Reads (Ctx : Step_Context) return Boolean
   is (Dates.Date_Read (Ctx, Date_Capture)
       and then Dates.Time_Reads (Word (Ctx, Time_Capture)));

   function Evaluate
     (G : Guard_Kind; Ctx : Step_Context; Evt : Step_Kind) return Boolean
   is
      pragma Unreferenced (Evt);
   begin
      return
        (case G is
           when Always        => True,
           when Instant_Read  => Fabula.Args.Long (Ctx.A, Instant_Capture).Ok,
           when Reading_Reads => Reading_Reads (Ctx),
           when Date_Unread   => not Dates.Date_Read (Ctx, Date_Capture));
   end Evaluate;

   ---------------------------------------------------------------------
   --  Actions.
   ---------------------------------------------------------------------

   procedure Convert (Ctx : in out Step_Context) is
   begin
      Fasti.To_Eastern
        (Epoch_Ms => Fabula.Args.Long (Ctx.A, Instant_Capture).Value,
         D        => Ctx.W.Eastern.Day,
         Ms       => Ctx.W.Eastern.Ms,
         Ok       => Ctx.W.Eastern.Ok);
   end Convert;

   procedure Refuse_Instant (Ctx : in out Step_Context) is
      Read : constant Fabula.Numbers.Long_Reads.Read :=
        Fabula.Args.Long (Ctx.A, Instant_Capture);
   begin
      Fabula.Check.Longs.Fail_Read (Ctx.R, Read.Error, "the instant");
   end Refuse_Instant;

   --  What the instant reads as on the Eastern clock, as a feature says.
   function Reading (E : Eastern_Reading) return String
   is (if E.Ok
       then
         "in Eastern time it is "
         & Dates.Spelled (E.Day)
         & " at "
         & Dates.Clock_Spelled (E.Ms)
       else "it has no Eastern day");

   procedure Expect_Reading (Ctx : in out Step_Context) is
      E : constant Eastern_Reading := Ctx.W.Eastern;
   begin
      Fabula.Check.Is_True
        (Ctx.R,
         E.Ok
         and then E.Day = Dates.Date (Ctx, Date_Capture)
         and then E.Ms = Dates.Ms_Of (Word (Ctx, Time_Capture)),
         Reading (E));
   end Expect_Reading;

   procedure Execute
     (A : Action_Kind; Ctx : in out Step_Context; Evt : Step_Kind)
   is
      pragma Unreferenced (Evt);
   begin
      case A is
         when A_Nothing          =>
            null;

         when A_Convert          =>
            Convert (Ctx);

         when A_Refuse_Instant   =>
            Refuse_Instant (Ctx);

         when A_Check_Eastern    =>
            Expect_Reading (Ctx);

         when A_Refuse_Date      =>
            Dates.Refuse_Date (Ctx, Date_Capture);

         when A_Refuse_Time      =>
            Fabula.Check.Fail_Step
              (Ctx.R, "not a time of day: " & Word (Ctx, Time_Capture));

         when A_Check_No_Eastern =>
            Fabula.Check.Is_False
              (Ctx.R, Ctx.W.Eastern.Ok, Reading (Ctx.W.Eastern));
      end case;
   end Execute;

   ---------------------------------------------------------------------
   --  The table.
   ---------------------------------------------------------------------

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

   Instant_Given    : constant Ev := (Kind => E_Instant_Given);
   Check_Eastern    : constant Ev := (Kind => E_Check_Eastern);
   Check_No_Eastern : constant Ev := (Kind => E_Check_No_Eastern);

   --!format off
   Table : constant Transition_Table :=
     [No_Instant + Instant_Given    (Instant_Read)  / A_Convert          >= Converted,
      No_Instant + Instant_Given                    / A_Refuse_Instant   >= No_Instant,
      Converted  + Instant_Given    (Instant_Read)  / A_Convert          >= Converted,
      Converted  + Instant_Given                    / A_Refuse_Instant   >= No_Instant,
      Converted  + Check_Eastern    (Reading_Reads) / A_Check_Eastern    >= Converted,
      Converted  + Check_Eastern    (Date_Unread)   / A_Refuse_Date      >= Converted,
      Converted  + Check_Eastern                    / A_Refuse_Time      >= Converted,
      Converted  + Check_No_Eastern                 / A_Check_No_Eastern >= Converted];
   --!format on

   Current : State := No_Instant;

   procedure Offer
     (Ctx : in out Step_Context; Evt : Step_Kind; Handled : out Boolean) is
   begin
      Flow.Take (Table, Current, Ctx, Evt, Handled);
   end Offer;

   procedure Reset is
   begin
      Current := No_Instant;
   end Reset;

   function Phase return String
   is (Current'Image);

end Fasti_Steps.Eastern;
