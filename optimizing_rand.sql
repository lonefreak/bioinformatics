http://explainextended.com/2009/03/01/selecting-random-rows/

SELECT  *
FROM    (
        SELECT  @cnt := COUNT(*) + 1,
                @lim := 1000000
        FROM    dmel
        ) vars
STRAIGHT_JOIN
        (
        SELECT  d.seq_id, d.length,
                @lim := @lim - 1
        FROM    dmel d
        WHERE   (@cnt := @cnt - 1)
		AND d.length > 95
                AND RAND(20090301) < @lim / @cnt
        ) i;
