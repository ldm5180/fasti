package body Fasti_Steps.Dates is

   --  YYYY-MM-DD, as offsets from the word's first character: a capture
   --  does not start at index 1.
   Date_Length : constant := 10;
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
   is (Word'Length = Date_Length
       and then Word (Word'First + Year_Last + 1) = '-'
       and then Word (Word'First + Month_Last + 1) = '-'
       and then (for all C of Digits_Of (Word) => C in '0' .. '9'));

   function Value (Word : String) return Fasti.Day
   is (Fasti.Day'Value (Digits_Of (Word)))
   with Pre => Shaped (Word);

   function Reads (Word : String) return Boolean
   is (Shaped (Word) and then Fasti.Valid (Value (Word)));

   function Packed (Word : String) return Fasti.Day
   is (Value (Word));

end Fasti_Steps.Dates;
