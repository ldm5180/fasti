with Tempus.Calendar;

package body Fasti
  with SPARK_Mode
is

   subtype LLI is Long_Long_Integer;

   function Year_Of (D : Day) return Natural
   is (D / 10_000);

   function Month_Of (D : Day) return Natural
   is (D / 100 mod 100);

   function Dom_Of (D : Day) return Natural
   is (D mod 100);

   subtype Year_Number is Natural range First_Year .. Last_Year;
   subtype Month_Number is Natural range 1 .. 12;
   subtype Dom_Number is Natural range 1 .. 31;

   function Pack
     (Y : Year_Number; M : Month_Number; Dd : Dom_Number) return Day
   is (Y * 10_000 + M * 100 + Dd);

   --  The loose structural bound the epoch arithmetic needs (Tempus'
   --  To_Epoch accepts any two-digit month/day fields); the semantic
   --  Valid_Date check matters only at the public API, where the caller's
   --  date is data, not one of our own constructions.
   function In_Window (D : Day) return Boolean
   is (Year_Of (D) in Year_Number);

   function Valid (D : Day) return Boolean
   is (In_Window (D)
       and then Tempus.Calendar.Valid_Date
                  (Year  => LLI (Year_Of (D)),
                   Month => LLI (Month_Of (D)),
                   Day   => LLI (Dom_Of (D)),
                   Hour  => 0,
                   Min   => 0,
                   Sec   => 0));

   --  Epoch days for a windowed date: the supported window keeps the
   --  count in 0 .. ~84_000, far inside Tempus' proven bounds.
   Max_Epoch_Day : constant := 84_100;

   subtype Epoch_Day is Natural range 0 .. Max_Epoch_Day;

   function Days_Of (D : Day) return Epoch_Day with Pre => In_Window (D) is
      Secs : constant LLI :=
        Tempus.Calendar.To_Epoch
          (Year           => LLI (Year_Of (D)),
           Month          => LLI (Month_Of (D)),
           Day            => LLI (Dom_Of (D)),
           Hour           => 0,
           Min            => 0,
           Sec            => 0,
           Offset_Seconds => 0);
   begin
      if Secs >= 0 and then Secs / 86_400 <= LLI (Max_Epoch_Day) then
         return Natural (Secs / 86_400);
      end if;
      return 0;  --  unreachable inside the supported window
   end Days_Of;

   function Day_Of_Epoch (Days : Epoch_Day) return Day is
      Y, M, Dd : LLI;
   begin
      Tempus.Calendar.Civil_From_Days (LLI (Days), Y, M, Dd);
      if Y in LLI (Year_Number'First) .. LLI (Year_Number'Last)
        and then M in 1 .. 12
        and then Dd in 1 .. 31
      then
         return Pack (Natural (Y), Natural (M), Natural (Dd));
      end if;
      return 0;  --  unreachable inside the supported window
   end Day_Of_Epoch;

   --  1970-01-01 was a Thursday (4 in Go's Sunday = 0 numbering).
   function Weekday_Of_Days (Days : Epoch_Day) return Weekday_Number
   is (Weekday_Number ((Days + 4) mod 7));

   function Weekday_Of (D : Day) return Weekday_Number
   is (Weekday_Of_Days (Days_Of (D)));

   --  The nth occurrence of a weekday in a month (MLK, Presidents,
   --  Labor, Thanksgiving).
   function Nth_Weekday
     (Y : Year_Number; M : Month_Number; W : Weekday_Number; N : Positive)
      return Day
   with Pre => N <= 4
   is
      First_Wd : constant Weekday_Number :=
        Weekday_Of_Days (Days_Of (Pack (Y, M, 1)));
      Offset   : constant Natural := Natural ((W - First_Wd + 7) mod 7);
   begin
      return Pack (Y, M, 1 + Offset + (N - 1) * 7);
   end Nth_Weekday;

   function Is_Leap (Y : Year_Number) return Boolean
   is ((Y mod 4 = 0 and then Y mod 100 /= 0) or else Y mod 400 = 0);

   function Days_In_Month (Y : Year_Number; M : Month_Number) return Dom_Number
   is (case M is
         when 1 | 3 | 5 | 7 | 8 | 10 | 12 => 31,
         when 4 | 6 | 9 | 11              => 30,
         when 2                           => (if Is_Leap (Y) then 29 else 28));

   --  The last occurrence of a weekday in a month (Memorial Day).
   function Last_Weekday
     (Y : Year_Number; M : Month_Number; W : Weekday_Number) return Day
   is
      Last    : constant Dom_Number := Days_In_Month (Y, M);
      Last_Wd : constant Weekday_Number :=
        Weekday_Of_Days (Days_Of (Pack (Y, M, Last)));
      Back    : constant Natural := Natural ((Last_Wd - W + 7) mod 7);
   begin
      return Pack (Y, M, Last - Back);
   end Last_Weekday;

   --  Weekend observance: Saturday -> the preceding Friday, Sunday ->
   --  the following Monday (options_bot's rule; td_broker's Saturday ->
   --  Monday is its bug, not ported).
   function Observed
     (Y : Year_Number; M : Month_Number; Dd : Dom_Number) return Day
   is
      H    : constant Day := Pack (Y, M, Dd);
      Days : constant Epoch_Day := Days_Of (H);
   begin
      case Weekday_Of_Days (Days) is
         when 6      =>
            return (if Days >= 1 then Day_Of_Epoch (Days - 1) else H);

         when 0      =>
            return
              (if Days < Max_Epoch_Day then Day_Of_Epoch (Days + 1) else H);

         when others =>
            return H;
      end case;
   end Observed;

   --  New Year's Day carries NYSE Rule 7.2's quirk: on a SATURDAY the
   --  holiday goes unobserved entirely -- Dec 31 ends a yearly
   --  accounting period, so the preceding Friday stays open (2011,
   --  2022, next 2027-12-31), and Monday needs no observance either.
   --  On a Sunday it moves to Monday like any other holiday.  Returns
   --  0 ("no such holiday this year") for the Saturday case -- no real
   --  date is ever 0.
   function New_Years_Holiday (Y : Year_Number) return Day is
      H    : constant Day := Pack (Y, 1, 1);
      Days : constant Epoch_Day := Days_Of (H);
   begin
      case Weekday_Of_Days (Days) is
         when 6      =>
            return 0;

         when 0      =>
            return
              (if Days < Max_Epoch_Day then Day_Of_Epoch (Days + 1) else H);

         when others =>
            return H;
      end case;
   end New_Years_Holiday;

   --  Good Friday: two days before Easter Sunday, via the anonymous
   --  Gregorian (Meeus/Jones/Butcher) computus -- the same algorithm the
   --  Go references carry.
   function Good_Friday (Y : Year_Number) return Day is
      A      : constant Natural := Y mod 19;
      B      : constant Natural := Y / 100;
      C      : constant Natural := Y mod 100;
      D      : constant Natural := B / 4;
      E      : constant Natural := B mod 4;
      F      : constant Natural := (B + 8) / 25;
      G      : constant Natural := (B - F + 1) / 3;
      H      : constant Natural := (19 * A + B - D - G + 15) mod 30;
      I      : constant Natural := C / 4;
      K      : constant Natural := C mod 4;
      L      : constant Natural := (32 + 2 * E + 2 * I - H - K) mod 7;
      M      : constant Natural := (A + 11 * H + 22 * L) / 451;
      Month  : constant Natural := (H + L - 7 * M + 114) / 31;
      Dom    : constant Natural := (H + L - 7 * M + 114) mod 31 + 1;
      Easter : Day;
   begin
      if Month in 3 .. 4 and then Dom in 1 .. 31 then
         Easter := Pack (Y, Month, Dom);
         declare
            Days : constant Epoch_Day := Days_Of (Easter);
         begin
            if Days >= 2 then
               return Day_Of_Epoch (Days - 2);
            end if;
         end;
      end if;
      return 0;  --  unreachable: Easter is always in March or April
   end Good_Friday;

   function Is_Market_Holiday (D : Day) return Boolean is
      Y : constant Year_Number := Year_Of (D);
   begin
      --  A Saturday New Year's is not observed at all (Rule 7.2), so --
      --  unlike the other Saturday holidays -- it never reaches back
      --  into the prior year's December.
      return
        D = New_Years_Holiday (Y)
        or else D = Nth_Weekday (Y, 1, 1, 3)       --  MLK Day
        or else D = Nth_Weekday (Y, 2, 1, 3)       --  Presidents Day
        or else D = Good_Friday (Y)
        or else D = Last_Weekday (Y, 5, 1)         --  Memorial Day
        or else D = Observed (Y, 6, 19)            --  Juneteenth
        or else D = Observed (Y, 7, 4)             --  Independence Day
        or else D = Nth_Weekday (Y, 9, 1, 1)       --  Labor Day
        or else D = Nth_Weekday (Y, 11, 4, 4)      --  Thanksgiving
        or else D = Observed (Y, 12, 25);          --  Christmas
   end Is_Market_Holiday;

   function Is_Trading_Day (D : Day) return Boolean
   is (Weekday_Of (D) in 1 .. 5 and then not Is_Market_Holiday (D));

   procedure Expirations
     (From   : Day;
      Wanted : Expiration_Count;
      List   : out Day_List;
      Count  : out Expiration_Count)
   is
      --  Sixteen expirations never span more than ~26 calendar days
      --  (weekends + holidays); 64 is a proof-friendly hard ceiling.
      Days : Epoch_Day := Days_Of (From);
   begin
      List := [others => 0];
      Count := 0;
      for Step in 0 .. 63 loop
         pragma Loop_Invariant (Count <= Wanted);
         pragma Loop_Invariant (Days = Days_Of (From) + Step);
         exit when Count = Wanted or else Days = Max_Epoch_Day;
         declare
            D : constant Day := Day_Of_Epoch (Days);
         begin
            if Valid (D) and then Is_Trading_Day (D) then
               Count := Count + 1;
               List (Count) := D;
            end if;
         end;
         Days := Days + 1;
      end loop;
   end Expirations;

   function Days_Between (From : Day; To : Day) return Integer
   is (Integer (Days_Of (To)) - Integer (Days_Of (From)));

   procedure Prior_Trading_Day (D : Day; Prior : out Day; Ok : out Boolean) is
      Days : Epoch_Day := Days_Of (D);
   begin
      Prior := D;
      Ok := False;
      for Back in 1 .. 14 loop
         exit when Days = 0;
         Days := Days - 1;
         declare
            C : constant Day := Day_Of_Epoch (Days);
         begin
            if Valid (C) and then Is_Trading_Day (C) then
               Prior := C;
               Ok := True;
               return;
            end if;
         end;
      end loop;
   end Prior_Trading_Day;

   --  DST is active from the 2nd Sunday of March through the day before
   --  the 1st Sunday of November.
   function In_Dst (D : Day) return Boolean with Pre => In_Window (D) is
      Y : constant Year_Number := Year_Of (D);
   begin
      return
        D >= Nth_Weekday (Y, 3, 0, 2) and then D < Nth_Weekday (Y, 11, 0, 1);
   end In_Dst;

   procedure To_Eastern
     (Epoch_Ms : Long_Long_Integer;
      D        : out Day;
      Ms       : out Day_Milliseconds;
      Ok       : out Boolean)
   is
      Day_Ms : constant := 86_400_000;

      Utc_Days : LLI;
      Ms_Rem   : LLI;

      --  Subtract an offset of whole hours, borrowing a day across the
      --  Eastern midnight.
      procedure Shift (Hours : LLI; Days_Out : out LLI; Ms_Out : out LLI) is
      begin
         Ms_Out := Ms_Rem - Hours * 3_600_000;
         Days_Out := Utc_Days;
         if Ms_Out < 0 then
            Ms_Out := Ms_Out + Day_Ms;
            Days_Out := Days_Out - 1;
         end if;
      end Shift;

      T_Days, T_Ms : LLI;
      E_Days, E_Ms : LLI;
      Tentative    : Day;
   begin
      D := 0;
      Ms := 0;
      Ok := False;

      if Epoch_Ms < 0 or else Epoch_Ms / Day_Ms > LLI (Max_Epoch_Day) then
         return;
      end if;
      Utc_Days := Epoch_Ms / Day_Ms;
      Ms_Rem := Epoch_Ms mod Day_Ms;

      --  Tentative EST (-5 h); the resulting EASTERN date picks the real
      --  offset and the shift is redone.  The two passes only disagree
      --  in the pre-dawn hours around the transition Sundays, which
      --  never stamp market data.
      Shift (5, T_Days, T_Ms);
      if T_Days < 0 or else T_Days > LLI (Max_Epoch_Day) then
         return;
      end if;
      Tentative := Day_Of_Epoch (Epoch_Day (T_Days));
      if Tentative = 0 then
         return;
      end if;

      if In_Dst (Tentative) then
         Shift (4, E_Days, E_Ms);
      else
         E_Days := T_Days;
         E_Ms := T_Ms;
      end if;
      if E_Days < 0 or else E_Days > LLI (Max_Epoch_Day) then
         return;
      end if;

      D := Day_Of_Epoch (Epoch_Day (E_Days));
      if D = 0 then
         return;
      end if;
      Ms := Natural (E_Ms);
      Ok := True;
   end To_Eastern;

   function Weekday_Allowed (Mask : Natural; D : Day) return Boolean is
      W    : constant Natural := Natural (Weekday_Of (D));
      Rest : Natural := Mask;
   begin
      if Mask = 0 then
         return True;
      end if;
      while Rest > 0 loop
         pragma Loop_Variant (Decreases => Rest);
         if Rest mod 10 = W then
            return True;
         end if;
         Rest := Rest / 10;
      end loop;
      return False;
   end Weekday_Allowed;

end Fasti;
