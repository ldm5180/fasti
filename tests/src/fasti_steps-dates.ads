with Fasti;

--  The words a feature writes a date in, and what the API takes: a date
--  is YYYY-MM-DD, packed into Fasti's YYYYMMDD; a day is its English
--  name; a time of day is HH:MM:SS.mmm, as milliseconds.  Guards ask
--  whether a word reads; actions convert it once a guard said it does.

package Fasti_Steps.Dates is

   --  Whether Word is a YYYY-MM-DD date inside Fasti's supported window.
   function Reads (Word : String) return Boolean;

   --  Word, which Reads said is a date, as Fasti takes it.
   function Packed (Word : String) return Fasti.Day
   with Pre => Reads (Word);

   --  The English name of a weekday as Fasti numbers it.
   function Name_Of (N : Fasti.Weekday_Number) return String;

   --  Whether Word is one of the seven names Name_Of gives.
   function Is_Day_Name (Word : String) return Boolean;

   --  Whether Word is an HH:MM:SS.mmm time of day.
   function Time_Reads (Word : String) return Boolean;

   --  Word, which Time_Reads said is a time, as milliseconds of the day.
   function Ms_Of (Word : String) return Fasti.Day_Milliseconds
   with Pre => Time_Reads (Word);

end Fasti_Steps.Dates;
