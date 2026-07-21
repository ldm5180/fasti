--  Fasti (the Roman calendar of dies fasti -- the days on which business
--  could lawfully be conducted): the CBOE trading-day calendar, COMPUTED
--  (pinned by a 1096-day fixture dumped from options_bot's own
--  IsCboeBusinessDay): weekends plus ten US market holidays -- New
--  Year's, MLK, Presidents, Good Friday (Meeus Easter computus),
--  Memorial, Juneteenth, Independence, Labor, Thanksgiving, Christmas
--  -- with weekend observance shifted Saturday -> preceding Friday and
--  Sunday -> following Monday (td_broker's Saturday -> Monday rule is
--  a KNOWN BUG there, not ported).  One deliberate deviation from
--  options_bot, matching what NYSE actually does: a New Year's Day on
--  Saturday is NOT observed at all -- Rule 7.2's accounting-period
--  exception keeps the preceding Dec 31 open (2011, 2022, next
--  2027-12-31) -- where rickar/cal closes that Friday.  The fixture
--  test pins the deviation both ways.

package Fasti
  with SPARK_Mode
is

   --  The packed civil date (YYYYMMDD) and ET milliseconds-of-day these
   --  computations live in.  Plain Natural subtypes, so a consumer's own
   --  identically-shaped subtypes stay assignment-compatible.
   subtype Yyyymmdd is Natural range 0 .. 99_999_999;
   subtype Day_Milliseconds is Natural range 0 .. 86_400_000;

   subtype Day is Yyyymmdd;

   --  The supported window keeps every epoch-day computation trivially
   --  in Tempus.Calendar's proven bounds.
   First_Year : constant := 1_970;
   Last_Year  : constant := 2_199;

   --  A real proleptic-Gregorian date inside the supported window.
   function Valid (D : Day) return Boolean;

   --  Go's weekday numbering (Sunday = 0) -- what options_bot's
   --  entry_weekday digit masks are written in.
   type Weekday_Number is range 0 .. 6;

   function Weekday_Of (D : Day) return Weekday_Number
   with Pre => Valid (D);

   function Is_Market_Holiday (D : Day) return Boolean
   with Pre => Valid (D);

   function Is_Trading_Day (D : Day) return Boolean
   with Pre => Valid (D);

   --  The DTE enumeration a chain fetch schedules by: the next Wanted
   --  trading days from AND INCLUDING From (DTE 0 = today when today
   --  trades).  SPXW expires every trading day, so trading days ARE the
   --  expiration days; XSP takes a shorter span of the same list.
   Max_Span : constant := 16;

   subtype Expiration_Count is Natural range 0 .. Max_Span;
   subtype Span_Index is Expiration_Count range 1 .. Max_Span;

   type Day_List is array (Span_Index) of Day;

   procedure Expirations
     (From   : Day;
      Wanted : Expiration_Count;
      List   : out Day_List;
      Count  : out Expiration_Count)
   with Pre => Valid (From), Post => Count <= Wanted;

   --  options_bot's entry_weekday gate: 0 (or absent) is unrestricted;
   --  otherwise the date's weekday digit must appear in the mask's
   --  decimal spelling (2345 = Tue-Fri, 5 = Friday only).
   function Weekday_Allowed (Mask : Natural; D : Day) return Boolean
   with Pre => Valid (D);

   --  Civil days from From to To (negative when To is past): DTE
   --  arithmetic and a greeks year fraction both hang off this.
   function Days_Between (From : Day; To : Day) return Integer
   with Pre => Valid (From) and then Valid (To);

   --  The previous trading day strictly before D -- the session the
   --  prior close belongs to.  Steps over weekends and holidays; Ok
   --  is False only if two weeks back holds no trading day (never,
   --  in practice) or D sits at the window's edge.
   procedure Prior_Trading_Day (D : Day; Prior : out Day; Ok : out Boolean)
   with Pre => Valid (D), Post => (if Ok then Valid (Prior));

   --  UTC epoch milliseconds -> the US/Eastern wall-clock day + ms --
   --  the one frame every US-market stamp lives in (ThetaData's
   --  Terminal emits ET text; Schwab emits epoch ms; a local clock is
   --  epoch seconds).  DST by our own calendar math: EDT (-4 h) from
   --  the 2nd Sunday of March through the day before the 1st Sunday of
   --  November, EST (-5 h) otherwise, at DAY granularity -- the 2 a.m.
   --  transition hours land on Sundays, when no market data exists to
   --  stamp.  Ok is False outside the supported window (pre-epoch or
   --  past Last_Year).
   procedure To_Eastern
     (Epoch_Ms : Long_Long_Integer;
      D        : out Day;
      Ms       : out Day_Milliseconds;
      Ok       : out Boolean);

end Fasti;
