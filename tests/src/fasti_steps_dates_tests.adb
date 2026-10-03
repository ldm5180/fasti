with AUnit.Assertions; use AUnit.Assertions;

with Fasti;

with Fasti_Steps.Dates; use Fasti_Steps.Dates;

package body Fasti_Steps_Dates_Tests is

   use AUnit.Test_Cases.Registration;
   use type Fasti.Weekday_Number;

   --  Word, as a capture hands it over: a slice that starts past 1.
   function Captured (Word : String) return String is
      Line : constant String := "the date is " & Word & " today";
      From : constant Positive := Line'First + 12;
   begin
      return Line (From .. From + Word'Length - 1);
   end Captured;

   --  A YYYY-MM-DD word reads only when it is a real date in the
   --  window, and packs to YYYYMMDD wherever the capture starts.
   procedure Test_Date_Words (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Reads ("2026-07-03"), "a plain date reads");
      Assert (Packed ("2026-07-03") = 20_260_703, "and packs to YYYYMMDD");
      Assert (Captured ("2026-07-03")'First > 1, "the slice starts past 1");
      Assert
        (Reads (Captured ("2026-07-03"))
         and then Packed (Captured ("2026-07-03")) = 20_260_703,
         "a capture's slice reads and packs the same");
      Assert (Reads ("2028-02-29"), "a leap day reads");
      Assert (not Reads ("2026-02-29"), "a non-leap February 29 does not");
      Assert (not Reads ("2026-13-40"), "month 13 does not read");
      Assert (not Reads ("20260703"), "the packed spelling does not read");
      Assert (not Reads ("2026/07/03"), "slashes do not read");
      Assert (not Reads ("2026-7-03"), "a one-digit month does not read");
      Assert (not Reads ("2026-07-0x"), "a letter does not read");
      Assert (not Reads (""), "nothing does not read");
      Assert (Reads ("1970-01-01"), "the window's first day reads");
      Assert (not Reads ("1969-12-31"), "the day before the window does not");
      Assert (Reads ("2199-12-31"), "the window's last day reads");
      Assert (not Reads ("2200-01-01"), "the day after the window does not");
      Assert (Spelled (20_260_703) = "2026-07-03", "a day spells as it reads");
      Assert (Spelled (19_700_101) = "1970-01-01", "zeros are kept");
      Assert
        (Packed (Spelled (21_991_231)) = 21_991_231,
         "spelling then packing is the day again");
   end Test_Date_Words;

   --  The seven day names, as Fasti numbers them, and nothing else.
   procedure Test_Day_Names (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Name_Of (0) = "Sunday", "0 is Sunday");
      Assert (Name_Of (4) = "Thursday", "4 is Thursday");
      Assert (Name_Of (6) = "Saturday", "6 is Saturday");
      for N in Fasti.Weekday_Number loop
         Assert (Is_Day_Name (Name_Of (N)), Name_Of (N) & " is a day name");
      end loop;
      Assert
        (Is_Day_Name (Captured ("Friday")), "a captured day name is one too");
      Assert (not Is_Day_Name ("friday"), "names are capitalized");
      Assert (not Is_Day_Name ("Fri"), "names are not abbreviated");
      Assert (not Is_Day_Name ("5"), "a number is not a day name");
   end Test_Day_Names;

   --  An HH:MM:SS.mmm word reads only as a time of day, to the ms.
   procedure Test_Clock_Words (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert
        (Time_Reads ("16:23:11.998")
         and then Ms_Of ("16:23:11.998") = 58_991_998,
         "16:23:11.998 is 58,991,998 ms into the day");
      Assert
        (Time_Reads ("00:00:00.000") and then Ms_Of ("00:00:00.000") = 0,
         "midnight is 0");
      Assert
        (Time_Reads ("23:59:59.999")
         and then Ms_Of ("23:59:59.999") = 86_399_999,
         "the day's last millisecond");
      Assert
        (Ms_Of (Captured ("07:00:00.000")) = 25_200_000,
         "a captured time reads the same");
      Assert (not Time_Reads ("24:00:00.000"), "hour 24 does not read");
      Assert (not Time_Reads ("12:60:00.000"), "minute 60 does not read");
      Assert (not Time_Reads ("12:00:60.000"), "second 60 does not read");
      Assert (not Time_Reads ("12:00:00"), "a time without ms does not read");
      Assert (not Time_Reads ("12-00-00.000"), "dashes do not read");
      Assert (not Time_Reads ("12:00:00.00x"), "a letter does not read");
   end Test_Clock_Words;

   overriding
   procedure Register_Tests (T : in out Test) is
   begin
      Register_Routine
        (T, Test_Date_Words'Access, "a date word reads and packs");
      Register_Routine (T, Test_Day_Names'Access, "the seven day names");
      Register_Routine
        (T, Test_Clock_Words'Access, "a clock word reads to the ms");
   end Register_Tests;

   overriding
   function Name (T : Test) return AUnit.Message_String
   is (AUnit.Format ("Fasti_Steps.Dates (the features' date words)"));

end Fasti_Steps_Dates_Tests;
