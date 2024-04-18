/*
Question #1: 
Vibestream is designed for users to share brief updates about 
how they are feeling, as such the platform enforces a character limit of 25. 
How many posts are exactly 25 characters long?

Expected column names: char_limit_posts
*/

-- q1 solution:

SELECT COUNT(content) AS char_limit_posts 
FROM posts
WHERE LENGTH(content) = 25;


/*

Question #2: 
Users JamesTiger8285 and RobertMermaid7605 are Vibestream’s most active posters.

Find the difference in the number of posts these two users made on each day 
that at least one of them made a post. Return dates where the absolute value of 
the difference between posts made is greater than 2 
(i.e dates where JamesTiger8285 made at least 3 more posts than RobertMermaid7605 or vice versa).

Expected column names: post_date
*/

-- q2 solution:

WITH user_James AS(
SELECT * 
FROM posts
LEFT JOIN users ON posts.user_id = users.user_id
WHERE users.user_name = 'JamesTiger8285'
),
User_Robert AS(
SELECT * 
FROM posts
LEFT JOIN users ON posts.user_id = users.user_id
WHERE users.user_name = 'RobertMermaid7605'
),
Abs_diff AS(
  SELECT COUNT(user_James.post_date) AS James_count, COUNT(User_Robert.post_date) AS Robert_count, 
  user_James.post_date AS James_post_date, coalesce(User_Robert.post_date, User_James.post_date)
  AS Robert_post_date
  FROM user_James
  FULL JOIN User_Robert ON User_James.Post_date = User_Robert.post_date
  GROUP BY  user_James.post_date, user_Robert.post_date
  )
  SELECT 
  Robert_post_date AS post_date
  FROM Abs_diff
  WHERE ABS(James_count - Robert_count) > 2;

/*
Question #3: 
Most users have relatively low engagement and few connections. 
User WilliamEagle6815, for example, has only 2 followers.

Network Analysts would say this user has two **1-step path** relationships. 
Having 2 followers doesn’t mean WilliamEagle6815 is isolated, however. 
Through his followers, he is indirectly connected to the larger Vibestream network.  

Consider all users up to 3 steps away from this user:

- 1-step path (X → WilliamEagle6815)
- 2-step path (Y → X → WilliamEagle6815)
- 3-step path (Z → Y → X → WilliamEagle6815)

Write a query to find follower_id of all users within 4 steps of WilliamEagle6815. 
Order by follower_id and return the top 10 records.

Expected column names: follower_id

*/

-- q3 solution:

WITH CTE_X AS(
SELECT *
FROM users
JOIN follows ON users.user_id = follows.followee_id
where users.user_name = 'WilliamEagle6815'
),
CTE_Y AS(
SELECT *
FROM users
JOIN follows ON users.user_id = follows.followee_id
WHERE user_id IN(SELECT CTE_X.follower_id FROM CTE_X)
), 
CTE_Z AS(
SELECT *
FROM users
JOIN follows on users.user_id = follows.followee_id
WHERE user_id in(SELECT CTE_Y.follower_id FROM CTE_Y)
),
final_result AS(
SELECT *
FROM users
JOIN follows ON users.user_id = follows.followee_id
WHERE user_id IN(SELECT CTE_Z.follower_id FROM CTE_Z)
)
SELECT DISTINCT follower_id
FROM final_result 
ORDER BY  follower_id 
LIMIT 10;
/*
Question #4: 
Return top posters for 2023-11-30 and 2023-12-01. 
A top poster is a user who has the most OR second most number of posts 
in a given day. Include the number of posts in the result and 
order the result by post_date and user_id.

Expected column names: post_date, user_id, posts

</aside>
*/

-- q4 solution:

WITH user_post_counts  AS(
SELECT post_date, users.user_id, COUNT(*) AS n_posts 
FROM posts
JOIN users ON posts.user_id = users.user_id
WHERE post_date IN('2023-11-30', '2023-12-01')
GROUP BY users.user_id, post_date
)
SELECT post_date, user_id, n_posts 
FROM user_post_counts 
WHERE n_posts > 2 
OR n_posts = 2
ORDER BY  post_date, user_id;

