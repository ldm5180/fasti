with Fasti;

--  The words a feature writes a date in, and what the API takes: a date
--  is YYYY-MM-DD, packed into Fasti's YYYYMMDD.  Guards ask whether a
--  word reads; actions convert it once a guard said it does.

package Fasti_Steps.Dates is

   --  Whether Word is a YYYY-MM-DD date inside Fasti's supported window.
   function Reads (Word : String) return Boolean;

   --  Word, which Reads said is a date, as Fasti takes it.
   function Packed (Word : String) return Fasti.Day
   with Pre => Reads (Word);

end Fasti_Steps.Dates;
