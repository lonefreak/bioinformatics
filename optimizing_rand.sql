http://explainextended.com/2009/03/01/selecting-random-rows/

SELECT  *
FROM    (
        SELECT  @cnt := COUNT(*) + 1,
                @lim := 10
        FROM    t_random
        ) vars
STRAIGHT_JOIN
        (
        SELECT  r.*,
                @lim := @lim - 1
        FROM    t_random r
        WHERE   (@cnt := @cnt - 1)
                AND RAND(20090301) < @lim / @cnt
        ) i
