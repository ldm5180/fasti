with Ada.Text_IO;

with AUnit.Assertions; use AUnit.Assertions;

with Fasti;

package body Fasti_Tests is

   use AUnit.Test_Cases.Registration;
   use Fasti;

   --  The characterization centerpiece: every date in 2026-2028 must get
   --  the exact business-day verdict options_bot trades by (fixture
   --  dumped from its IsCboeBusinessDay / rickar/cal calendar).  This
   --  covers all ten holidays, three Easters, weekend observances both
   --  directions, and the next-year's-New-Year-on-Dec-31 case.
   procedure Test_Cboe_Fixture (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      use Ada.Text_IO;
      File    : File_Type;
      Checked : Natural := 0;
   begin
      Open (File, In_File, "tests/data/cboe_business_days_2026_2028.csv");
      declare
         Header : constant String := Get_Line (File);
      begin
         Assert (Header = "date,is_business_day", "fixture header");
      end;
      while not End_Of_File (File) loop
         declare
            Line : constant String := Get_Line (File);
         begin
            if Line'Length >= 10 then
               declare
                  Date    : constant Day :=
                    Day'Value (Line (Line'First .. Line'First + 7));
                  Verdict : constant Boolean :=
                    Line (Line'First + 9 .. Line'Last) = "true";
               begin
                  Assert (Valid (Date), "fixture date is valid");
                  if Date = 20_271_231 then
                     --  The ONE known deviation from options_bot: NYSE
                     --  Rule 7.2's accounting-period exception keeps the
                     --  market OPEN when New Year's falls on a Saturday
                     --  (Dec 31 ends the year -- 2011, 2022, next 2028);
                     --  rickar/cal closes it.  Both facts are pinned: if
                     --  a regenerated fixture ever agrees with us, this
                     --  special case must go.
                     Assert
                       (Is_Trading_Day (Date) and then not Verdict,
                        "2027-12-31 trades (NYSE) though options_bot"
                        & " disagrees");
                  else
                     Assert
                       (Is_Trading_Day (Date) = Verdict,
                        "trading-day verdict for" & Date'Image);
                  end if;
                  Checked := Checked + 1;
               end;
            end if;
         end;
      end loop;
      Close (File);
      Assert
        (Checked = 1_096, "all three years checked (2028 is a leap year)");
   end Test_Cboe_Fixture;

   --  NYSE Rule 7.2's New Year's quirk, matched exactly: on a SATURDAY
   --  the holiday goes unobserved (Dec 31 ends a yearly accounting
   --  period, so the preceding Friday stays open, and Monday needs no
   --  observance either); on a SUNDAY it moves to Monday as usual.
   procedure Test_New_Years_Rule (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Is_Trading_Day (20_271_231),
         "Fri 2027-12-31 trades (Sat New Year's is not observed)");
      Assert
        (Is_Trading_Day (20_280_103),
         "Mon 2028-01-03 trades (no Monday observance either)");
      Assert
        (Is_Market_Holiday (20_230_102),
         "Mon 2023-01-02 was the observed Sunday New Year's");
   end Test_New_Years_Rule;

   --  Weekday numbering matches Go's (Sunday = 0), which is what the
   --  entry_weekday digit masks are written in.
   procedure Test_Weekdays (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Weekday_Of (20_260_702) = 4, "2026-07-02 is a Thursday");
      Assert (Weekday_Of (20_260_704) = 6, "2026-07-04 is a Saturday");
      Assert (Weekday_Of (20_260_705) = 0, "2026-07-05 is a Sunday (0)");
      Assert (Weekday_Of (20_260_706) = 1, "2026-07-06 is a Monday");
   end Test_Weekdays;

   --  The DTE enumeration: the next N expiration days from AND INCLUDING
   --  From (DTE 0 = today when today trades).  Pinned over the July 4th
   --  2026 weekend: Sat-observed holiday closes Friday the 3rd, Monday
   --  the 6th TRADES (td_broker's Sat->Monday rule gets this wrong; we
   --  follow options_bot / the real CBOE calendar).
   procedure Test_Expirations (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      List  : Day_List;
      Count : Expiration_Count;
   begin
      Expirations
        (From => 20_260_702, Wanted => 4, List => List, Count => Count);
      Assert (Count = 4, "four expirations found");
      Assert
        (List (1) = 20_260_702
         and then List (2) = 20_260_706
         and then List (3) = 20_260_707
         and then List (4) = 20_260_708,
         "the holiday weekend is skipped: Thu, then Mon-Wed");

      --  From a Saturday: the span starts at the next trading day.
      Expirations
        (From => 20_260_704, Wanted => 1, List => List, Count => Count);
      Assert
        (Count = 1 and then List (1) = 20_260_706,
         "a non-trading From starts at the next trading day");
   end Test_Expirations;

   --  UTC epoch milliseconds -> the US/Eastern wall-clock day + ms (the
   --  frame every US-market stamp lives in: the Terminal emits ET
   --  text; Schwab emits epoch ms).  DST by our own calendar math (2nd
   --  Sunday of March to 1st of November); pinned against Python's
   --  zoneinfo for a summer instant, a winter one, and a UTC-midnight
   --  crossing that lands the previous ET day.
   procedure Test_To_Eastern (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      D  : Day;
      Ms : Day_Milliseconds;
      Ok : Boolean;
   begin
      To_Eastern (1_720_038_191_998, D, Ms, Ok);
      Assert
        (Ok and then D = 20_240_703 and then Ms = 58_991_998,
         "summer (EDT -4): 2024-07-03 16:23:11.998");

      To_Eastern (1_768_478_400_000, D, Ms, Ok);
      Assert
        (Ok and then D = 20_260_115 and then Ms = 25_200_000,
         "winter (EST -5): 2026-01-15 07:00:00");

      To_Eastern (1_767_225_600_000, D, Ms, Ok);
      Assert
        (Ok and then D = 20_251_231 and then Ms = 68_400_000,
         "a UTC midnight lands the PREVIOUS Eastern day (19:00)");

      --  The same UTC hour either side of the 2nd Sunday of March 2026
      --  (March 8): EST on the Saturday, EDT on the Monday.
      To_Eastern (1_772_877_600_000, D, Ms, Ok);
      Assert
        (Ok and then D = 20_260_307 and then Ms = 18_000_000,
         "the Saturday before DST (EST -5): 2026-03-07 05:00");

      To_Eastern (1_773_050_400_000, D, Ms, Ok);
      Assert
        (Ok and then D = 20_260_309 and then Ms = 21_600_000,
         "the Monday after DST begins (EDT -4): 2026-03-09 06:00");

      To_Eastern (-5, D, Ms, Ok);
      Assert (not Ok, "pre-epoch instants are refused");
   end Test_To_Eastern;

   --  options_bot's entry_weekday digit mask: 0 (or absent) means
   --  unrestricted; otherwise today's Go weekday digit must appear in
   --  the mask's decimal spelling.
   procedure Test_Weekday_Mask (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Thursday : constant Day := 20_260_702;
      Friday   : constant Day := 20_260_710;
   begin
      Assert (Weekday_Allowed (0, Thursday), "0 is unrestricted");
      Assert
        (Weekday_Allowed (2_345, Thursday), "mask 2345 admits a Thursday (4)");
      Assert
        (Weekday_Allowed (2_345, Friday), "mask 2345 admits a Friday (5)");
      Assert
        (not Weekday_Allowed (1_234, Friday), "mask 1234 refuses a Friday");
      Assert (Weekday_Allowed (5, Friday), "mask 5 is Friday-only");
      Assert (not Weekday_Allowed (5, Thursday), "mask 5 refuses a Thursday");
   end Test_Weekday_Mask;

   --  The previous trading day (the prior close's session): weekends
   --  and holidays are stepped over.
   procedure Test_Prior_Day (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Prior : Day;
      Ok    : Boolean;
   begin
      Prior_Trading_Day (20_260_710, Prior, Ok);
      Assert (Ok and then Prior = 20_260_709, "Friday looks back to Thursday");

      Prior_Trading_Day (20_260_713, Prior, Ok);
      Assert
        (Ok and then Prior = 20_260_710, "Monday looks back over the weekend");

      --  July 4th 2026 is a Saturday, observed Friday July 3rd.
      Prior_Trading_Day (20_260_706, Prior, Ok);
      Assert
        (Ok and then Prior = 20_260_702,
         "the Monday after July 4th looks back over the observance");
   end Test_Prior_Day;

   --  Civil day differences (DTE math and a greeks year fraction).
   procedure Test_Days_Between (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Days_Between (20_260_710, 20_260_710) = 0, "same day is zero");
      Assert
        (Days_Between (20_260_710, 20_260_713) = 3,
         "Friday to Monday is three civil days");
      Assert
        (Days_Between (20_260_228, 20_260_301) = 1,
         "across a non-leap February");
      Assert
        (Days_Between (20_260_713, 20_260_710) = -3, "a past To is negative");
   end Test_Days_Between;

   overriding
   procedure Register_Tests (T : in out Test) is
   begin
      Register_Routine
        (T,
         Test_Cboe_Fixture'Access,
         "1096 days match options_bot's CBOE calendar exactly");
      Register_Routine
        (T, Test_Weekdays'Access, "Go weekday numbering (Sunday = 0)");
      Register_Routine
        (T, Test_Expirations'Access, "DTE enumeration over July 4th 2026");
      Register_Routine
        (T, Test_New_Years_Rule'Access, "NYSE Rule 7.2 New Year's quirk");
      Register_Routine
        (T, Test_To_Eastern'Access, "UTC epoch ms -> Eastern wall clock");
      Register_Routine (T, Test_Days_Between'Access, "civil day differences");
      Register_Routine (T, Test_Prior_Day'Access, "the previous trading day");
      Register_Routine
        (T, Test_Weekday_Mask'Access, "entry_weekday digit masks");
   end Register_Tests;

   overriding
   function Name (T : Test) return AUnit.Message_String
   is (AUnit.Format ("Fasti (CBOE trading days)"));

end Fasti_Tests;
