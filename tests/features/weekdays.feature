Feature: The entry mask names the weekdays a trade may enter on

  An entry mask is a number whose digits name the weekdays an entry is
  allowed on, counting Sunday as 0: 2345 is Tuesday to Friday, 5 is
  Friday only.  A mask of 0 restricts nothing.

  Scenario Outline: A digit mask admits the days it spells
    Given the entry mask is <mask>
    And the date is <date>
    Then it is a <day>
    And entry is <verdict>

    Examples:
      | mask | date       | day      | verdict |
      | 0    | 2026-07-02 | Thursday | allowed |
      | 2345 | 2026-07-02 | Thursday | allowed |
      | 2345 | 2026-07-10 | Friday   | allowed |
      | 1234 | 2026-07-10 | Friday   | refused |
      | 5    | 2026-07-10 | Friday   | allowed |
      | 5    | 2026-07-02 | Thursday | refused |
