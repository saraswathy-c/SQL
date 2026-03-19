CREATE DATABASE ABC_case_study;

USE ABC_case_study;

CREATE TABLE gameplay (
	user_id INT,
    games_played INT,
    playdate datetime);

SET GLOBAL local_infile = 1;

/*
LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/ABC_gameplay.csv'
INTO TABLE gameplay
FIELDS TERMINATED BY ','
IGNORE 1 ROWS;

SET GLOBAL local_infile = 1;
*/

SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/ABC_gameplay.csv'
INTO TABLE gameplay
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM gameplay LIMIT 10;

SELECT COUNT(*) FROM gameplay;

CREATE TABLE deposit (
    user_id INT,
    amount DECIMAL(10,2)
);

ALTER TABLE deposit ADD deposit_date DATETIME;
DESC deposit;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/ABC_deposit.csv'
INTO TABLE deposit
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM deposit LIMIT 10;
SELECT COUNT(*) FROM deposit;

CREATE TABLE withdrawal (
    user_id INT,
    amount DECIMAL(10,2),
    withdrawal_date DATETIME
);
DESC withdrawal;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/ABC_withdrawal.csv'
INTO TABLE withdrawal
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM withdrawal LIMIT 10;
SELECT COUNT(*) FROM withdrawal;

-- final user summary table (Aggregating data)
SELECT 
    g.user_id,
    COUNT(g.games_played) AS total_games,
    IFNULL(SUM(d.amount),0) AS total_deposit,
    IFNULL(SUM(w.amount),0) AS total_withdrawal
FROM gameplay g
LEFT JOIN deposit d ON g.user_id = d.user_id
LEFT JOIN withdrawal w ON g.user_id = w.user_id
GROUP BY g.user_id;

-- Selecting all users (Aggregating data) - correct version
SELECT 
    u.user_id,
    g.total_games,
    d.total_deposit,
    w.total_withdrawal
FROM (
    SELECT user_id FROM gameplay
    UNION
    SELECT user_id FROM deposit
    UNION
    SELECT user_id FROM withdrawal
    )   u
    
LEFT JOIN 
    (SELECT user_id, COUNT(*) AS total_games 
     FROM gameplay 
     GROUP BY user_id) g
ON u.user_id = g.user_id

LEFT JOIN 
    (SELECT user_id, SUM(amount) AS total_deposit 
     FROM deposit 
     GROUP BY user_id) d
ON u.user_id = d.user_id

LEFT JOIN 
    (SELECT user_id, SUM(amount) AS total_withdrawal 
     FROM withdrawal 
     GROUP BY user_id) w
ON u.user_id = w.user_id;

-- Total amount deposited and count of deposits for each user
SELECT user_id, SUM(amount) as amt_deposited, count(*) as deposit_count
FROM deposit
GROUP BY user_id;

-- Total amount withdrawn and number of withdrawals per user
SELECT user_id, SUM(amount) as amt_withdrawn, count(*) as withdrawal_count
FROM withdrawal
GROUP BY user_id;

-- Total games played by each user
SELECT user_id, count(*) as total_games_played
FROM gameplay
GROUP BY user_id;

-- Combining all information of all kinds of players
SELECT 
    u.user_id,
    
    COALESCE(d.total_deposit,0) AS total_deposit,
    COALESCE(w.total_withdrawal,0) AS total_withdrawal,
    COALESCE(d.deposit_count,0) AS deposit_count,
    COALESCE(w.withdrawal_count,0) AS withdrawal_count,
    COALESCE(g.total_games,0) AS total_games_played

FROM (
    SELECT user_id FROM gameplay
    UNION
    SELECT user_id FROM deposit
    UNION
    SELECT user_id FROM withdrawal
) u

LEFT JOIN (
    SELECT user_id, SUM(amount) total_deposit, COUNT(*) deposit_count
    FROM deposit GROUP BY user_id
) d ON u.user_id = d.user_id

LEFT JOIN (
    SELECT user_id, SUM(amount) total_withdrawal, COUNT(*) withdrawal_count
    FROM withdrawal GROUP BY user_id
) w ON u.user_id = w.user_id

LEFT JOIN (
    SELECT user_id, COUNT(*) total_games
    FROM gameplay GROUP BY user_id
) g ON u.user_id = g.user_id;

-- Calculate Loyalty points of users on ABC platform
SELECT 
    *,
    ROUND(
    (0.01 * total_deposit) +
    (0.005 * total_withdrawal) +
    (0.001 * GREATEST(deposit_count - withdrawal_count, 0)) +
    (0.2 * total_games_played) ,
    2 )
    AS loyalty_points
    
FROM ( 
	SELECT 
    u.user_id,
    
    COALESCE(d.total_deposit,0) AS total_deposit,
    COALESCE(w.total_withdrawal,0) AS total_withdrawal,
    COALESCE(d.deposit_count,0) AS deposit_count,
    COALESCE(w.withdrawal_count,0) AS withdrawal_count,
    COALESCE(g.total_games,0) AS total_games_played

FROM (
    SELECT user_id FROM gameplay
    UNION
    SELECT user_id FROM deposit
    UNION
    SELECT user_id FROM withdrawal
) u

LEFT JOIN (
    SELECT user_id, SUM(amount) total_deposit, COUNT(*) deposit_count
    FROM deposit GROUP BY user_id
) d ON u.user_id = d.user_id

LEFT JOIN (
    SELECT user_id, SUM(amount) total_withdrawal, COUNT(*) withdrawal_count
    FROM withdrawal GROUP BY user_id
) w ON u.user_id = w.user_id

LEFT JOIN (
    SELECT user_id, COUNT(*) total_games
    FROM gameplay GROUP BY user_id
) g ON u.user_id = g.user_id

) users_summary;

-- Calculating Loyalty points in slot S1 on October 2nd
SELECT 
    u.user_id,

    COALESCE(d.total_deposit,0) AS total_deposit,
    COALESCE(w.total_withdrawal,0) AS total_withdrawal,
    COALESCE(d.deposit_count,0) AS deposit_count,
    COALESCE(w.withdrawal_count,0) AS withdrawal_count,
    COALESCE(g.total_games,0) AS total_games,

    ROUND(
        (0.01 * COALESCE(d.total_deposit,0)) +
        (0.005 * COALESCE(w.total_withdrawal,0)) +
        (0.001 * GREATEST(COALESCE(d.deposit_count,0) - COALESCE(w.withdrawal_count,0), 0)) +
        (0.2 * COALESCE(g.total_games,0)),
    2) AS loyalty_points

FROM (
    -- unified users
    SELECT user_id FROM gameplay
    UNION
    SELECT user_id FROM deposit
    UNION
    SELECT user_id FROM withdrawal
) u

LEFT JOIN (
    -- deposits in slot S1
    SELECT 
        user_id, 
        SUM(amount) AS total_deposit,
        COUNT(*) AS deposit_count
    FROM deposit
    WHERE deposit_date >= '2022-10-02 00:00:00'
      AND deposit_date <  '2022-10-02 12:00:00'
    GROUP BY user_id
) d ON u.user_id = d.user_id

LEFT JOIN (
    -- withdrawals in slot S1
    SELECT 
        user_id, 
        SUM(amount) AS total_withdrawal,
        COUNT(*) AS withdrawal_count
    FROM withdrawal
    WHERE withdrawal_date >= '2022-10-02 00:00:00'
      AND withdrawal_date <  '2022-10-02 12:00:00'
    GROUP BY user_id
) w ON u.user_id = w.user_id

LEFT JOIN (
    -- games played in slot S1
    SELECT 
        user_id, 
        COUNT(*) AS total_games
    FROM gameplay
    WHERE playdate >= '2022-10-02 00:00:00'
      AND playdate <  '2022-10-02 12:00:00'
    GROUP BY user_id
) g ON u.user_id = g.user_id;


-- Calculating Loyalty points in slot S2 on October 16th
SELECT 
    u.user_id,

    COALESCE(d.total_deposit,0) AS total_deposit,
    COALESCE(w.total_withdrawal,0) AS total_withdrawal,
    COALESCE(d.deposit_count,0) AS deposit_count,
    COALESCE(w.withdrawal_count,0) AS withdrawal_count,
    COALESCE(g.total_games,0) AS total_games,

    ROUND(
        (0.01 * COALESCE(d.total_deposit,0)) +
        (0.005 * COALESCE(w.total_withdrawal,0)) +
        (0.001 * GREATEST(COALESCE(d.deposit_count,0) - COALESCE(w.withdrawal_count,0), 0)) +
        (0.2 * COALESCE(g.total_games,0)),
    2) AS loyalty_points

FROM (
    -- unified users
    SELECT user_id FROM gameplay
    UNION
    SELECT user_id FROM deposit
    UNION
    SELECT user_id FROM withdrawal
) u

LEFT JOIN (
    -- deposits in slot S2
    SELECT 
        user_id, 
        SUM(amount) AS total_deposit,
        COUNT(*) AS deposit_count
    FROM deposit
    WHERE deposit_date >= '2022-10-16 12:00:00'
      AND deposit_date <  '2022-10-17 00:00:00'
    GROUP BY user_id
) d ON u.user_id = d.user_id

LEFT JOIN (
    -- withdrawals in slot S2
    SELECT 
        user_id, 
        SUM(amount) AS total_withdrawal,
        COUNT(*) AS withdrawal_count
    FROM withdrawal
    WHERE withdrawal_date >= '2022-10-16 12:00:00'
      AND withdrawal_date <  '2022-10-17 00:00:00'
    GROUP BY user_id
) w ON u.user_id = w.user_id

LEFT JOIN (
    -- games played in slot S2
    SELECT 
        user_id, 
        COUNT(*) AS total_games
    FROM gameplay
    WHERE playdate >= '2022-10-16 12:00:00'
      AND playdate <  '2022-10-17 00:00:00'
    GROUP BY user_id
) g ON u.user_id = g.user_id;

-- Calculating Loyalty points in slot S1 on October 18th
SELECT 
    u.user_id,

    COALESCE(d.total_deposit,0) AS total_deposit,
    COALESCE(w.total_withdrawal,0) AS total_withdrawal,
    COALESCE(d.deposit_count,0) AS deposit_count,
    COALESCE(w.withdrawal_count,0) AS withdrawal_count,
    COALESCE(g.total_games,0) AS total_games,

    ROUND(
        (0.01 * COALESCE(d.total_deposit,0)) +
        (0.005 * COALESCE(w.total_withdrawal,0)) +
        (0.001 * GREATEST(COALESCE(d.deposit_count,0) - COALESCE(w.withdrawal_count,0), 0)) +
        (0.2 * COALESCE(g.total_games,0)),
    2) AS loyalty_points

FROM (
    -- unified users
    SELECT user_id FROM gameplay
    UNION
    SELECT user_id FROM deposit
    UNION
    SELECT user_id FROM withdrawal
) u

LEFT JOIN (
    -- deposits in slot S1
    SELECT 
        user_id, 
        SUM(amount) AS total_deposit,
        COUNT(*) AS deposit_count
    FROM deposit
    WHERE deposit_date >= '2022-10-18 00:00:00'
      AND deposit_date <  '2022-10-18 12:00:00'
    GROUP BY user_id
) d ON u.user_id = d.user_id

LEFT JOIN (
    -- withdrawals in slot S1
    SELECT 
        user_id, 
        SUM(amount) AS total_withdrawal,
        COUNT(*) AS withdrawal_count
    FROM withdrawal
    WHERE withdrawal_date >= '2022-10-18 00:00:00'
      AND withdrawal_date <  '2022-10-18 12:00:00'
    GROUP BY user_id
) w ON u.user_id = w.user_id

LEFT JOIN (
    -- games played in slot S1
    SELECT 
        user_id, 
        COUNT(*) AS total_games
    FROM gameplay
    WHERE playdate >= '2022-10-18 00:00:00'
      AND playdate <  '2022-10-18 12:00:00'
    GROUP BY user_id
) g ON u.user_id = g.user_id;

-- Calculating Loyalty points in slot S2 on October 26th
SELECT 
    u.user_id,

    COALESCE(d.total_deposit,0) AS total_deposit,
    COALESCE(w.total_withdrawal,0) AS total_withdrawal,
    COALESCE(d.deposit_count,0) AS deposit_count,
    COALESCE(w.withdrawal_count,0) AS withdrawal_count,
    COALESCE(g.total_games,0) AS total_games,

    ROUND(
        (0.01 * COALESCE(d.total_deposit,0)) +
        (0.005 * COALESCE(w.total_withdrawal,0)) +
        (0.001 * GREATEST(COALESCE(d.deposit_count,0) - COALESCE(w.withdrawal_count,0), 0)) +
        (0.2 * COALESCE(g.total_games,0)),
    2) AS loyalty_points

FROM (
    -- unified users
    SELECT user_id FROM gameplay
    UNION
    SELECT user_id FROM deposit
    UNION
    SELECT user_id FROM withdrawal
) u

LEFT JOIN (
    -- deposits in slot S2
    SELECT 
        user_id, 
        SUM(amount) AS total_deposit,
        COUNT(*) AS deposit_count
    FROM deposit
    WHERE deposit_date >= '2022-10-26 12:00:00'
      AND deposit_date <  '2022-10-27 00:00:00'
    GROUP BY user_id
) d ON u.user_id = d.user_id

LEFT JOIN (
    -- withdrawals in slot S2
    SELECT 
        user_id, 
        SUM(amount) AS total_withdrawal,
        COUNT(*) AS withdrawal_count
    FROM withdrawal
    WHERE withdrawal_date >= '2022-10-26 12:00:00'
      AND withdrawal_date <  '2022-10-27 00:00:00'
    GROUP BY user_id
) w ON u.user_id = w.user_id

LEFT JOIN (
    -- games played in slot S2
    SELECT 
        user_id, 
        COUNT(*) AS total_games
    FROM gameplay
    WHERE playdate >= '2022-10-26 12:00:00'
      AND playdate <  '2022-10-27 00:00:00'
    GROUP BY user_id
) g ON u.user_id = g.user_id;

-- Ranking players based on: 1. Loyalty points and 2. Number of Games played
SELECT 
    *,
    
    RANK() OVER (
        ORDER BY loyalty_points DESC, total_games DESC
    ) AS user_rank

FROM (

    SELECT 
        u.user_id,

        COALESCE(d.total_deposit,0) AS total_deposit,
        COALESCE(w.total_withdrawal,0) AS total_withdrawal,
        COALESCE(d.deposit_count,0) AS deposit_count,
        COALESCE(w.withdrawal_count,0) AS withdrawal_count,
        COALESCE(g.total_games,0) AS total_games,

        ROUND(
            (0.01 * COALESCE(d.total_deposit,0)) +
            (0.005 * COALESCE(w.total_withdrawal,0)) +
            (0.001 * GREATEST(COALESCE(d.deposit_count,0) - COALESCE(w.withdrawal_count,0), 0)) +
            (0.2 * COALESCE(g.total_games,0)),
        2) AS loyalty_points

    FROM (
        -- Unified user list
        SELECT user_id FROM gameplay
        UNION
        SELECT user_id FROM deposit
        UNION
        SELECT user_id FROM withdrawal
    ) u

    LEFT JOIN (
        -- Deposits in October
        SELECT 
            user_id, 
            SUM(amount) AS total_deposit,
            COUNT(*) AS deposit_count
        FROM deposit
        WHERE deposit_date >= '2022-10-01 00:00:00'
          AND deposit_date <  '2022-11-01 00:00:00'
        GROUP BY user_id
    ) d ON u.user_id = d.user_id

    LEFT JOIN (
        -- Withdrawals in October
        SELECT 
            user_id, 
            SUM(amount) AS total_withdrawal,
            COUNT(*) AS withdrawal_count
        FROM withdrawal
        WHERE withdrawal_date >= '2022-10-01 00:00:00'
          AND withdrawal_date <  '2022-11-01 00:00:00'
        GROUP BY user_id
    ) w ON u.user_id = w.user_id

    LEFT JOIN (
        -- Games played in October
        SELECT 
            user_id, 
            COUNT(*) AS total_games
        FROM gameplay
        WHERE playdate >= '2022-10-01 00:00:00'
          AND playdate <  '2022-11-01 00:00:00'
        GROUP BY user_id
    ) g ON u.user_id = g.user_id

) final_data;

-- Top 50 Players from October based on their ranking criteria
SELECT * FROM
(
    SELECT 
    *,
    
    RANK() OVER (
        ORDER BY loyalty_points DESC, total_games DESC
    ) AS user_rank

FROM (

    SELECT 
        u.user_id,

        COALESCE(d.total_deposit,0) AS total_deposit,
        COALESCE(w.total_withdrawal,0) AS total_withdrawal,
        COALESCE(d.deposit_count,0) AS deposit_count,
        COALESCE(w.withdrawal_count,0) AS withdrawal_count,
        COALESCE(g.total_games,0) AS total_games,

        ROUND(
            (0.01 * COALESCE(d.total_deposit,0)) +
            (0.005 * COALESCE(w.total_withdrawal,0)) +
            (0.001 * GREATEST(COALESCE(d.deposit_count,0) - COALESCE(w.withdrawal_count,0), 0)) +
            (0.2 * COALESCE(g.total_games,0)),
        2) AS loyalty_points

    FROM (
        -- Unified user list
        SELECT user_id FROM gameplay
        UNION
        SELECT user_id FROM deposit
        UNION
        SELECT user_id FROM withdrawal
    ) u

    LEFT JOIN (
        -- October deposits
        SELECT 
            user_id, 
            SUM(amount) AS total_deposit,
            COUNT(*) AS deposit_count
        FROM deposit
        WHERE deposit_date >= '2022-10-01 00:00:00'
          AND deposit_date <  '2022-11-01 00:00:00'
        GROUP BY user_id
    ) d ON u.user_id = d.user_id

    LEFT JOIN (
        -- October withdrawals
        SELECT 
            user_id, 
            SUM(amount) AS total_withdrawal,
            COUNT(*) AS withdrawal_count
        FROM withdrawal
        WHERE withdrawal_date >= '2022-10-01 00:00:00'
          AND withdrawal_date <  '2022-11-01 00:00:00'
        GROUP BY user_id
    ) w ON u.user_id = w.user_id

    LEFT JOIN (
        -- October gameplay
        SELECT 
            user_id, 
            COUNT(*) AS total_games
        FROM gameplay
        WHERE playdate >= '2022-10-01 00:00:00'
          AND playdate <  '2022-11-01 00:00:00'
        GROUP BY user_id
    ) g ON u.user_id = g.user_id

) final_data
) players_info where user_rank <=50;

-- Average deposit amount
SELECT ROUND(avg(AMOUNT),2) FROM DEPOSIT;      -- 5492.19

-- AVERAGE DEPOSIT AMOUNT PER USER PER MONTH
SELECT 
    ROUND(AVG(total_deposit), 2)
FROM (
    SELECT user_id, SUM(amount) AS total_deposit
    FROM deposit
    WHERE deposit_date >= '2022-10-01'
      AND deposit_date <  '2022-11-01'
    GROUP BY user_id
) t;                                            -- 104669.65

SELECT * FROM GAMEPLAY LIMIT 10;

-- AVG NUMBER OF GAMES PLAYED PER USER
 SELECT ROUND(avg(GAMES_PLAYED),2) AS AVG_NUMBER_OF_GAMES_PER_USER
	FROM  (
			SELECT USER_ID, COUNT(*) GAMES_PLAYED
			FROM GAMEPLAY 
			 WHERE PLAYDATE >= '2022-10-01'
			 AND PLAYDATE <  '2022-11-01'
			GROUP BY USER_ID
            ) COUNT ;							-- 365.33
            

-- BONUS POINT CALCULATION FOR TOP 50 LOYAL PLAYERS
   
WITH ranked_players AS (
	SELECT 
    *,
    
    RANK() OVER (
        ORDER BY loyalty_points DESC, total_games DESC
    ) AS user_rank

FROM (

    SELECT 
        u.user_id,

        COALESCE(d.total_deposit,0) AS total_deposit,
        COALESCE(w.total_withdrawal,0) AS total_withdrawal,
        COALESCE(d.deposit_count,0) AS deposit_count,
        COALESCE(w.withdrawal_count,0) AS withdrawal_count,
        COALESCE(g.total_games,0) AS total_games,

        ROUND(
            (0.01 * COALESCE(d.total_deposit,0)) +
            (0.005 * COALESCE(w.total_withdrawal,0)) +
            (0.001 * GREATEST(COALESCE(d.deposit_count,0) - COALESCE(w.withdrawal_count,0), 0)) +
            (0.2 * COALESCE(g.total_games,0)),
        2) AS loyalty_points

    FROM (
        -- Unified user list
        SELECT user_id FROM gameplay
        UNION
        SELECT user_id FROM deposit
        UNION
        SELECT user_id FROM withdrawal
    ) u

    LEFT JOIN (
        -- Deposits in October
        SELECT 
            user_id, 
            SUM(amount) AS total_deposit,
            COUNT(*) AS deposit_count
        FROM deposit
        WHERE deposit_date >= '2022-10-01 00:00:00'
          AND deposit_date <  '2022-11-01 00:00:00'
        GROUP BY user_id
    ) d ON u.user_id = d.user_id

    LEFT JOIN (
        -- Withdrawals in October
        SELECT 
            user_id, 
            SUM(amount) AS total_withdrawal,
            COUNT(*) AS withdrawal_count
        FROM withdrawal
        WHERE withdrawal_date >= '2022-10-01 00:00:00'
          AND withdrawal_date <  '2022-11-01 00:00:00'
        GROUP BY user_id
    ) w ON u.user_id = w.user_id

    LEFT JOIN (
        -- Games played in October
        SELECT 
            user_id, 
            COUNT(*) AS total_games
        FROM gameplay
        WHERE playdate >= '2022-10-01 00:00:00'
          AND playdate <  '2022-11-01 00:00:00'
        GROUP BY user_id
    ) g ON u.user_id = g.user_id

) final_data
),
top_50_players AS (
	SELECT * FROM ranked_players WHERE user_rank <=50
)	 

SELECT user_id, loyalty_points, 
	ROUND(
			(loyalty_points/(SELECT sum(loyalty_points) FROM top_50_players)) * 50000 ,
            2) AS bonus_amount_allocated
FROM top_50_players; 	
             