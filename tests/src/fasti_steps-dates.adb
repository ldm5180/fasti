package body Fasti_Steps.Dates is

   --  Whether Word is spelled as Template is: a 'd' there stands for any
   --  digit, every other character for itself.  Word is compared from its
   --  own 'First, since a capture does not start at index 1.
   function Fits (Word, Template : String) return Boolean
   is (Word'Length = Template'Length
       and then (for all K in 0 .. Template'Length - 1 =>
                   (if Template (Template'First + K) = 'd'
                    then Word (Word'First + K) in '0' .. '9'
                    else
                      Word (Word'First + K) = Template (Template'First + K))));

   --  YYYY-MM-DD, as offsets from the word's first character.
   Year_Last   : constant := 3;
   Month_First : constant := 5;
   Month_Last  : constant := 6;
   Day_First   : constant := 8;
   Day_Last    : constant := 9;

   function Part (Word : String; First, Last : Natural) return String
   is (Word (Word'First + First .. Word'First + Last));

   --  The year, month and day digits run together: YYYYMMDD.
   function Digits_Of (Word : String) return String
   is (Part (Word, 0, Year_Last)
       & Part (Word, Month_First, Month_Last)
       & Part (Word, Day_First, Day_Last));

   function Shaped (Word : String) return Boolean
   is (Fits (Word, "dddd-dd-dd"));

   function Value (Word : String) return Fasti.Day
   is (Fasti.Day'Value (Digits_Of (Word)))
   with Pre => Shaped (Word);

   function Reads (Word : String) return Boolean
   is (Shaped (Word) and then Fasti.Valid (Value (Word)));

   function Packed (Word : String) return Fasti.Day
   is (Value (Word));

   function Date (Ctx : Step_Context; N : Positive := 1) return Fasti.Day
   is (Packed (Word (Ctx, N)));

   procedure Refuse_Date (Ctx : in out Step_Context; N : Positive := 1) is
   begin
      Fabula.Check.Fail_Step (Ctx.R, "not a calendar date: " & Word (Ctx, N));
   end Refuse_Date;

   --  N in Width digits, leading zeros kept.
   function Padded (N : Natural; Width : Positive) return String
   is (if Width = 1
       then [Character'Val (Character'Pos ('0') + N mod 10)]
       else Padded (N / 10, Width - 1) & Padded (N mod 10, 1));

   Year_Digits : constant := 4;
   Two_Digits  : constant := 2;
   Year_Shift  : constant := 10_000;
   Month_Shift : constant := 100;

   function Spelled (D : Fasti.Day) return String
   is (Padded (D / Year_Shift, Year_Digits)
       & "-"
       & Padded (D / Month_Shift mod Month_Shift, Two_Digits)
       & "-"
       & Padded (D mod Month_Shift, Two_Digits));

   function Name_Of (N : Fasti.Weekday_Number) return String
   is (case N is
         when 0 => "Sunday",
         when 1 => "Monday",
         when 2 => "Tuesday",
         when 3 => "Wednesday",
         when 4 => "Thursday",
         when 5 => "Friday",
         when 6 => "Saturday");

   function Is_Day_Name (Word : String) return Boolean
   is (for some N in Fasti.Weekday_Number => Name_Of (N) = Word);

   --  HH:MM:SS.mmm, as offsets from the word's first character.
   Minute_First : constant := 3;
   Second_First : constant := 6;
   Milli_First  : constant := 9;
   Milli_Last   : constant := 11;
   Pair         : constant := 2;
   Hours_A_Day  : constant := 24;
   Sixty        : constant := 60;
   Ms_A_Second  : constant := 1_000;

   function Field (Word : String; First, Last : Natural) return Natural
   is (Natural'Value (Part (Word, First, Last)));

   function Hours (Word : String) return Natural
   is (Field (Word, 0, Pair - 1));

   function Minutes (Word : String) return Natural
   is (Field (Word, Minute_First, Minute_First + Pair - 1));

   function Seconds (Word : String) return Natural
   is (Field (Word, Second_First, Second_First + Pair - 1));

   function Millis (Word : String) return Natural
   is (Field (Word, Milli_First, Milli_Last));

   function Time_Shaped (Word : String) return Boolean
   is (Fits (Word, "dd:dd:dd.ddd"));

   function Time_Reads (Word : String) return Boolean
   is (Time_Shaped (Word)
       and then Hours (Word) < Hours_A_Day
       and then Minutes (Word) < Sixty
       and then Seconds (Word) < Sixty);

   function Ms_Of (Word : String) return Fasti.Day_Milliseconds
   is (((Hours (Word) * Sixty + Minutes (Word)) * Sixty + Seconds (Word))
       * Ms_A_Second
       + Millis (Word));

end Fasti_Steps.Dates;
