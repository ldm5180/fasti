with Ada.Strings.Unbounded;

with Fasti;

with Fasti_Steps.Dates;
with Fasti_Steps.Flows;

package body Fasti_Steps.Expirations is

   use Ada.Strings.Unbounded;

   --  Unfetched until a chain fetch runs; its checks read it then.
   type State is (Unfetched, Fetched);

   type Guard_Kind is
     (Always,
      Fetch_Reads,
      First_Unread,
      Wanted_Unread,
      Found_Read,
      Rows_Read,
      Pair_Reads);

   type Action_Kind is
     (A_Nothing,
      A_Fetch,
      A_Refuse_First,
      A_Refuse_Second,
      A_Refuse_Wanted,
      A_Refuse_Span,
      A_Check_Count,
      A_Refuse_Found,
      A_Check_List,
      A_Refuse_Row,
      A_Check_Prior);

   First_Capture  : constant := 1;
   Second_Capture : constant := 2;
   Only_Column    : constant := 1;

   function Fetch_Words_Read (Ctx : Step_Context) return Boolean
   is (Dates.Date_Read (Ctx, First_Capture)
       and then Count_Read (Ctx, Second_Capture)
       and then Count (Ctx, Second_Capture) <= Fasti.Max_Span);

   ---------------------------------------------------------------------
   --  The expirations table: one date a row.
   ---------------------------------------------------------------------

   function Rows (Ctx : Step_Context) return Natural
   is (Fabula.Args.Row_Count (Ctx.A));

   function Row (Ctx : Step_Context; R : Positive) return String
   is (Fabula.Args.Cell (Ctx.A, R, Only_Column));

   --  The first row that is no date, or 0 when every row is one.
   function First_Bad_Row (Ctx : Step_Context) return Natural is
   begin
      for R in 1 .. Rows (Ctx) loop
         if not Dates.Reads (Row (Ctx, R)) then
            return R;
         end if;
      end loop;
      return 0;
   end First_Bad_Row;

   function Table_Words_Read (Ctx : Step_Context) return Boolean
   is (Fabula.Args.Has_Table (Ctx.A)
       and then Fabula.Args.Col_Count (Ctx.A) = Only_Column
       and then First_Bad_Row (Ctx) = 0);

   function Evaluate
     (G : Guard_Kind; Ctx : Step_Context; Evt : Step_Kind) return Boolean
   is
      pragma Unreferenced (Evt);
   begin
      return
        (case G is
           when Always        => True,
           when Fetch_Reads   => Fetch_Words_Read (Ctx),
           when First_Unread  => not Dates.Date_Read (Ctx, First_Capture),
           when Wanted_Unread => not Count_Read (Ctx, Second_Capture),
           when Found_Read    => Count_Read (Ctx),
           when Rows_Read     => Table_Words_Read (Ctx),
           when Pair_Reads    =>
             Dates.Date_Read (Ctx, First_Capture)
             and then Dates.Date_Read (Ctx, Second_Capture));
   end Evaluate;

   ---------------------------------------------------------------------
   --  Actions.
   ---------------------------------------------------------------------

   procedure Run_Fetch (Ctx : in out Step_Context) is
   begin
      Fasti.Expirations
        (From   => Dates.Date (Ctx, First_Capture),
         Wanted => Count (Ctx, Second_Capture),
         List   => Ctx.W.Fetch.List,
         Count  => Ctx.W.Fetch.Count);
   end Run_Fetch;

   --  What the fetch found, as the feature writes it.
   function Found (F : Fetch_Reading) return String is
      Text : Unbounded_String;
   begin
      for K in 1 .. F.Count loop
         Append (Text, " " & Dates.Spelled (F.List (K)));
      end loop;
      return "the expirations are" & To_String (Text);
   end Found;

   function List_Matches (Ctx : Step_Context) return Boolean
   is (Rows (Ctx) = Ctx.W.Fetch.Count
       and then (for all R in 1 .. Rows (Ctx) =>
                   Dates.Packed (Row (Ctx, R)) = Ctx.W.Fetch.List (R)));

   procedure Refuse_Row (Ctx : in out Step_Context) is
      Bad : constant Natural := First_Bad_Row (Ctx);
   begin
      Fabula.Check.Fail_Step
        (Ctx.R,
         (if Bad = 0
          then "list the expirations as a one-column table"
          else
            "row" & Bad'Image & ": not a calendar date: " & Row (Ctx, Bad)));
   end Refuse_Row;

   procedure Compare_Prior (Ctx : in out Step_Context) is
      Prior : Fasti.Day;
      Ok    : Boolean;
   begin
      Fasti.Prior_Trading_Day (Dates.Date (Ctx, First_Capture), Prior, Ok);
      Fabula.Check.Is_True
        (Ctx.R,
         Ok and then Prior = Dates.Date (Ctx, Second_Capture),
         (if Ok
          then "the prior trading day is " & Dates.Spelled (Prior)
          else "there is no prior trading day"));
   end Compare_Prior;

   procedure Execute
     (A : Action_Kind; Ctx : in out Step_Context; Evt : Step_Kind)
   is
      pragma Unreferenced (Evt);
   begin
      case A is
         when A_Nothing       =>
            null;

         when A_Fetch         =>
            Run_Fetch (Ctx);

         when A_Refuse_First  =>
            Dates.Refuse_Date (Ctx, First_Capture);

         when A_Refuse_Second =>
            Dates.Refuse_Date (Ctx, Second_Capture);

         when A_Refuse_Wanted =>
            Refuse_Count (Ctx, Second_Capture);

         when A_Refuse_Span   =>
            Fabula.Check.Fail_Step
              (Ctx.R,
               "a fetch wants at most"
               & Fasti.Max_Span'Image
               & " expirations");

         when A_Check_Count   =>
            Fabula.Check.Is_True
              (Ctx.R,
               Ctx.W.Fetch.Count = Count (Ctx),
               "it finds" & Ctx.W.Fetch.Count'Image);

         when A_Refuse_Found  =>
            Refuse_Count (Ctx);

         when A_Check_List    =>
            Fabula.Check.Is_True
              (Ctx.R, List_Matches (Ctx), Found (Ctx.W.Fetch));

         when A_Refuse_Row    =>
            Refuse_Row (Ctx);

         when A_Check_Prior   =>
            Compare_Prior (Ctx);
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

   Fetch       : constant Ev := (Kind => E_Fetch);
   Check_Count : constant Ev := (Kind => E_Check_Count);
   Check_List  : constant Ev := (Kind => E_Check_List);
   Check_Prior : constant Ev := (Kind => E_Check_Prior);

   --!format off
   Table : constant Transition_Table :=
     [Unfetched + Fetch (Fetch_Reads)   / A_Fetch         >= Fetched,
      Unfetched + Fetch (First_Unread)  / A_Refuse_First  >= Unfetched,
      Unfetched + Fetch (Wanted_Unread) / A_Refuse_Wanted >= Unfetched,
      Unfetched + Fetch                 / A_Refuse_Span   >= Unfetched,
      Fetched   + Fetch (Fetch_Reads)   / A_Fetch         >= Fetched,
      Fetched   + Fetch (First_Unread)  / A_Refuse_First  >= Unfetched,
      Fetched   + Fetch (Wanted_Unread) / A_Refuse_Wanted >= Unfetched,
      Fetched   + Fetch                 / A_Refuse_Span   >= Unfetched,
      Fetched   + Check_Count (Found_Read)    / A_Check_Count   >= Fetched,
      Fetched   + Check_Count                 / A_Refuse_Found  >= Fetched,
      Fetched   + Check_List  (Rows_Read)     / A_Check_List    >= Fetched,
      Fetched   + Check_List                  / A_Refuse_Row    >= Fetched,
      Unfetched + Check_Prior (Pair_Reads)    / A_Check_Prior   >= Unfetched,
      Unfetched + Check_Prior (First_Unread)  / A_Refuse_First  >= Unfetched,
      Unfetched + Check_Prior                 / A_Refuse_Second >= Unfetched,
      Fetched   + Check_Prior (Pair_Reads)    / A_Check_Prior   >= Fetched,
      Fetched   + Check_Prior (First_Unread)  / A_Refuse_First  >= Fetched,
      Fetched   + Check_Prior                 / A_Refuse_Second >= Fetched];
   --!format on

   Current : State := Unfetched;

   procedure Offer
     (Ctx : in out Step_Context; Evt : Step_Kind; Handled : out Boolean) is
   begin
      Flow.Take (Table, Current, Ctx, Evt, Handled);
   end Offer;

   procedure Reset is
   begin
      Current := Unfetched;
   end Reset;

   function Phase return String
   is (Current'Image);

end Fasti_Steps.Expirations;
