with Ada.Strings.Unbounded;

with Fabula.Check.Ints;
with Fabula.Numbers;

with Fasti_Steps.Arithmetic;
with Fasti_Steps.Eastern;
with Fasti_Steps.Expirations;
with Fasti_Steps.Trading;
with Fasti_Steps.Weekdays;

package body Fasti_Steps is

   use Ada.Strings.Unbounded;

   procedure Then_Take (Ctx : in out Step_Context; Evt : Step_Kind) is
   begin
      Ctx.Has_Next := True;
      Ctx.Next := Evt;
   end Then_Take;

   function Word (Ctx : Step_Context; N : Positive := 1) return String
   is (Fabula.Args.Word (Ctx.A, N));

   function Count_Read (Ctx : Step_Context; N : Positive := 1) return Boolean
   is (N <= Fabula.Args.Count (Ctx.A)
       and then Fabula.Args.Int (Ctx.A, N).Ok
       and then Fabula.Args.Int (Ctx.A, N).Value >= 0);

   function Count (Ctx : Step_Context; N : Positive := 1) return Natural
   is (Fabula.Args.Int (Ctx.A, N).Value);

   procedure Refuse_Count (Ctx : in out Step_Context; N : Positive := 1) is
      Read : constant Fabula.Numbers.Integer_Reads.Read :=
        Fabula.Args.Int (Ctx.A, N);
   begin
      if Read.Ok then
         Fabula.Check.Fail_Step (Ctx.R, "a count cannot be negative");
      else
         Fabula.Check.Ints.Fail_Read (Ctx.R, Read.Error);
      end if;
   end Refuse_Count;

   ---------------------------------------------------------------------
   --  The features as orthogonal regions: every step is offered to each,
   --  and each takes only its own.
   ---------------------------------------------------------------------

   type Offer_Access is
     access procedure
       (Ctx : in out Step_Context; Evt : Step_Kind; Handled : out Boolean);
   type Reset_Access is access procedure;
   type Phase_Access is access function return String;
   type Name_Access is access constant String;

   type Region is record
      Name  : Name_Access;
      Offer : Offer_Access;
      Reset : Reset_Access;
      Phase : Phase_Access;
   end record;

   Trading_Name     : aliased constant String := "trading days";
   Expirations_Name : aliased constant String := "expirations";
   Eastern_Name     : aliased constant String := "eastern";
   Weekdays_Name    : aliased constant String := "weekdays";
   Arithmetic_Name  : aliased constant String := "arithmetic";

   --!format off
   Regions : constant array (Positive range <>) of Region :=
     [(Trading_Name'Access,     Trading.Offer'Access,     Trading.Reset'Access,     Trading.Phase'Access),
      (Expirations_Name'Access, Expirations.Offer'Access, Expirations.Reset'Access, Expirations.Phase'Access),
      (Eastern_Name'Access,     Eastern.Offer'Access,     Eastern.Reset'Access,     Eastern.Phase'Access),
      (Weekdays_Name'Access,    Weekdays.Offer'Access,    Weekdays.Reset'Access,    Weekdays.Phase'Access),
      (Arithmetic_Name'Access,  Arithmetic.Offer'Access,  Arithmetic.Reset'Access,  Arithmetic.Phase'Access)];
   --!format on

   --  Every region's state, for the step no region would take.
   function Phases return String is
      Text : Unbounded_String;
   begin
      for G of Regions loop
         Append (Text, " " & G.Name.all & "=" & G.Phase.all);
      end loop;
      return To_String (Text);
   end Phases;

   procedure Execute
     (S    : Step_Kind;
      Ctx  : in out World;
      A    : Fabula.Args.List;
      Info : Fabula.Frames.Frame;
      R    : in out Fabula.Check.Outcome)
   is
      Step    : Step_Context :=
        (W => Ctx, A => A, Info => Info, R => R, others => <>);
      Taken   : Boolean := False;
      Handled : Boolean;
   begin
      for G of Regions loop
         G.Offer (Step, S, Handled);
         Taken := Taken or else Handled;
      end loop;
      Ctx := Step.W;
      R := Step.R;
      if not Taken then
         Fabula.Check.Fail_Step
           (R,
            S'Image & " is not a step this scenario can take now:" & Phases);
      end if;
   end Execute;

   procedure Run_Hook
     (H    : Hook_Kind;
      Ctx  : in out World;
      Info : Fabula.Frames.Frame;
      R    : in out Fabula.Check.Outcome)
   is
      pragma Unreferenced (Info, R);
   begin
      case H is
         when Fresh_World =>
            Ctx := (others => <>);
            for G of Regions loop
               G.Reset.all;
            end loop;
      end case;
   end Run_Hook;

end Fasti_Steps;
