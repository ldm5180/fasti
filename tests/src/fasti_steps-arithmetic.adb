with Fabula.Check.Ints;

with Fasti;

with Fasti_Steps.Dates;
with Fasti_Steps.Flows;

package body Fasti_Steps.Arithmetic is

   --  One step holds the whole question, so there is one state.
   type State is (Ready);

   type Guard_Kind is (Always, Question_Reads, From_Unread, Days_Unread);

   type Action_Kind is
     (A_Nothing, A_Check_Between, A_Refuse_From, A_Refuse_To, A_Refuse_Days);

   Days_Capture : constant := 1;
   From_Capture : constant := 2;
   To_Capture   : constant := 3;

   function Question_Reads (Ctx : Step_Context) return Boolean
   is (Fabula.Args.Int (Ctx.A, Days_Capture).Ok
       and then Dates.Date_Read (Ctx, From_Capture)
       and then Dates.Date_Read (Ctx, To_Capture));

   function Evaluate
     (G : Guard_Kind; Ctx : Step_Context; Evt : Step_Kind) return Boolean
   is
      pragma Unreferenced (Evt);
   begin
      return
        (case G is
           when Always         => True,
           when Question_Reads => Question_Reads (Ctx),
           when From_Unread    => not Dates.Date_Read (Ctx, From_Capture),
           when Days_Unread    =>
             not Fabula.Args.Int (Ctx.A, Days_Capture).Ok);
   end Evaluate;

   procedure Compare_Days (Ctx : in out Step_Context) is
      Days : constant Integer :=
        Fasti.Days_Between
          (Dates.Date (Ctx, From_Capture), Dates.Date (Ctx, To_Capture));
   begin
      Fabula.Check.Is_True
        (Ctx.R,
         Days = Fabula.Args.Int (Ctx.A, Days_Capture).Value,
         "there are" & Days'Image & " days");
   end Compare_Days;

   procedure Execute
     (A : Action_Kind; Ctx : in out Step_Context; Evt : Step_Kind)
   is
      pragma Unreferenced (Evt);
   begin
      case A is
         when A_Nothing       =>
            null;

         when A_Check_Between =>
            Compare_Days (Ctx);

         when A_Refuse_From   =>
            Dates.Refuse_Date (Ctx, From_Capture);

         when A_Refuse_To     =>
            Dates.Refuse_Date (Ctx, To_Capture);

         when A_Refuse_Days   =>
            Fabula.Check.Ints.Fail_Read
              (Ctx.R, Fabula.Args.Int (Ctx.A, Days_Capture).Error, "days");
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

   Check_Between : constant Ev := (Kind => E_Check_Between);

   --!format off
   Table : constant Transition_Table :=
     [Ready + Check_Between (Question_Reads) / A_Check_Between >= Ready,
      Ready + Check_Between (Days_Unread)    / A_Refuse_Days   >= Ready,
      Ready + Check_Between (From_Unread)    / A_Refuse_From   >= Ready,
      Ready + Check_Between                  / A_Refuse_To     >= Ready];
   --!format on

   Current : State := Ready;

   procedure Offer
     (Ctx : in out Step_Context; Evt : Step_Kind; Handled : out Boolean) is
   begin
      Flow.Take (Table, Current, Ctx, Evt, Handled);
   end Offer;

   procedure Reset is
   begin
      Current := Ready;
   end Reset;

   function Phase return String
   is (Current'Image);

end Fasti_Steps.Arithmetic;
