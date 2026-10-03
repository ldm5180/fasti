with Fasti;

with Fabula.Args;
with Fabula.Check;
with Fabula.Frames;
with Fabula.Registry;

--  The step registry the feature runner dispatches on: one Step_Kind
--  per pattern, one table that reads like the features, and one Execute
--  that offers each step to every feature's state machine.

package Fasti_Steps is

   --  The steps, grouped by the feature that reads them.  Each is an
   --  event of that feature's state machine, in its own child package.
   type Step_Kind is
     (E_Day_Given,
      E_Check_Weekday,
      E_Check_Trades,
      E_Check_Closed,
      E_Check_Holiday,
      E_Check_No_Holiday,
      E_Fetch,
      E_Check_Count,
      E_Check_List,
      E_Check_Prior);

   type Hook_Kind is (Fresh_World);

   --  What a chain fetch found: the expirations, in order, and how many.
   type Fetch_Reading is record
      List  : Fasti.Day_List := [others => 0];
      Count : Fasti.Expiration_Count := 0;
   end record;

   --  What one scenario reads back: the date the steps are about, and
   --  what a chain fetch found.
   type World is record
      Day   : Fasti.Day := 0;
      Fetch : Fetch_Reading;
   end record;

   --  One step as a machine sees it: the scenario, the step's arguments,
   --  frame and outcome, and the event an action asks to be taken next
   --  (Then_Take), which the runner posts before the step returns.
   type Step_Context is record
      W        : World;
      A        : Fabula.Args.List;
      Info     : Fabula.Frames.Frame;
      R        : Fabula.Check.Outcome;
      Has_Next : Boolean := False;
      Next     : Step_Kind := Step_Kind'First;
   end record;

   procedure Then_Take (Ctx : in out Step_Context; Evt : Step_Kind);

   --  Capture N of the step, as written.
   function Word (Ctx : Step_Context; N : Positive := 1) return String;

   --  Whether capture N reads as a whole number of zero or more: the
   --  guard every counting step's rows share.
   function Count_Read (Ctx : Step_Context; N : Positive := 1) return Boolean;

   --  Capture N, which Count_Read said reads.
   function Count (Ctx : Step_Context; N : Positive := 1) return Natural
   with Pre => Count_Read (Ctx, N);

   --  Fail the step for capture N: why it does not read as a count.
   procedure Refuse_Count (Ctx : in out Step_Context; N : Positive := 1);

   package Steps is new
     Fabula.Registry
       (Step_Kind => Step_Kind,
        Hook_Kind => Hook_Kind,
        Context   => World);
   use Steps;

   --!format off
   Step_Defs : constant Steps.Step_Table :=
     [Step ("the date is {word}")         >= E_Day_Given,
      Step ("it is a trading day")        >= E_Check_Trades,
      Step ("the market is closed")       >= E_Check_Closed,
      Step ("it is a market holiday")     >= E_Check_Holiday,
      Step ("it is not a market holiday") >= E_Check_No_Holiday,
      Step ("it is a {word}")             >= E_Check_Weekday,
      Step ("a chain fetch on {word} wants {int} expiration(s)")
                                          >= E_Fetch,
      Step ("it finds {int}")             >= E_Check_Count,
      Step ("the expirations are:")       >= E_Check_List,
      Step ("the prior trading day of {word} is {word}")
                                          >= E_Check_Prior];
   --!format on

   Hook_Defs : constant Steps.Hook_Table := [Before >= Fresh_World];

   procedure Execute
     (S    : Step_Kind;
      Ctx  : in out World;
      A    : Fabula.Args.List;
      Info : Fabula.Frames.Frame;
      R    : in out Fabula.Check.Outcome);

   procedure Run_Hook
     (H    : Hook_Kind;
      Ctx  : in out World;
      Info : Fabula.Frames.Frame;
      R    : in out Fabula.Check.Outcome);

end Fasti_Steps;
