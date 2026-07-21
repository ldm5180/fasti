with Ada.Text_IO;

with Fasti;

--  Print the next ten 0-DTE expiration days (CBOE trading days) from a
--  date spanning the July 4th 2026 holiday weekend, showing the Saturday
--  observance closing Friday the 3rd while Monday the 6th trades.

procedure Next_Expirations is
   List  : Fasti.Day_List;
   Count : Fasti.Expiration_Count;
begin
   Fasti.Expirations
     (From => 20_260_702, Wanted => 10, List => List, Count => Count);
   for I in 1 .. Count loop
      Ada.Text_IO.Put_Line (List (I)'Image);
   end loop;
end Next_Expirations;
