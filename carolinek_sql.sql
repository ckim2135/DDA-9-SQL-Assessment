-- 1. The poetry in this database is the work of children in grades 1 through 5.  
--     a. How many poets from each grade are represented in the data?  
-- **Answer**
-- 1 - 623; 2 - 1,437; 3 - 2,344; 4 - 3,288; 5 - 3,464
SELECT grade_id, COUNT(id)
FROM author
GROUP BY grade_id
ORDER BY grade_id;


--     b. How many of the poets in each grade are Male and how many are Female?
-- Only return the poets identified as Male or Female.  
-- **Answer** Grade 1 - (F) 243, (M) 163; Grade 2 - (F) 605, (M) 412;
-- Grade 3 - (F) 948, (M) 577; Grade 4 - (F) 1,241, (M) 723; Grade 5 - (F) 1,294, (M) 757
SELECT grade_id, author.gender_id, gender.name AS gender, COUNT (author.id)
FROM author INNER JOIN gender
ON author.gender_id = gender.id
WHERE gender.name ILIKE '%male%'
GROUP BY grade_id, gender_id, gender.name
ORDER BY grade_id, gender_id;


--     c. Do you notice any trends across all grades?
-- **Answer** For Grades 1 - 5, females make-up more than half of the total male/female students (59.85% to 63.19%)
-- and males make-up less than half of the total male/female students (36.81% to 40.51%)
SELECT grade_id,
		SUM(CASE WHEN gender_id = 1 THEN 1 ELSE 0 END) AS female,
		ROUND((SUM(CASE WHEN gender_id = 1 THEN 1 ELSE 0 END)::numeric / COUNT (gender_id))*100,2) AS f_percent,
		SUM(CASE WHEN gender_id = 2 THEN 1 ELSE 0 END) AS male,
		ROUND((SUM(CASE WHEN gender_id = 2 THEN 1 ELSE 0 END)::numeric / COUNT (gender_id))*100,2) AS m_percent,
		COUNT (gender_id)
FROM author
WHERE gender_id = 1 OR gender_id = 2
GROUP BY grade_id;

-- 2. Two foods that are favorites of children are pizza and hamburgers.
-- Which of these things do children write about more often?
-- **Answer** There are 225 poems about pizza and 73 poems about burgers (28 of which are about 'hamburgers')
SELECT	SUM(CASE WHEN text ILIKE '%pizza%' THEN 1 ELSE 0 END) AS pizza_poems,
		SUM(CASE WHEN text ILIKE '%burger%' THEN 1 ELSE 0 END) AS burger_poems,
		SUM(CASE WHEN text ILIKE '%hamburger%' THEN 1 ELSE 0 END) AS hamburger_poems
FROM poem;

-- Which do they have the most to say about when they do?
-- Return the **total** number of poems, their **average character count** for poems that mention **pizza** and 
-- poems that mention the word **hamburger**. Do this in a single query.
-- **Answer** The average character count is 259 for hamburger poems and 241 for pizza poems.
SELECT	SUM(CASE WHEN text ILIKE '%pizza%' THEN char_count ELSE 0 END) / SUM(CASE WHEN text ILIKE '%pizza%' THEN 1 ELSE 0 END) AS pizza_chars,
		SUM(CASE WHEN text ILIKE '%hamburger%' THEN char_count ELSE 0 END) / SUM(CASE WHEN text ILIKE '%hamburger%' THEN 1 ELSE 0 END) AS hamburger_chars
FROM poem;


-- 3. Do longer poems have more emotional intensity compared to shorter poems?  
-- a. Start by writing a query to return each emotion in the database with its average intensity and character count.   
--      - Which emotion is associated the longest poems on average?  
-- **Answer** Angry poems tend to be the longest, with an avg character count of 261.
--      - Which emotion has the shortest?  
-- **Answer** Joyful poems tend to be the shortest, with an avg character count of 220.

SELECT emotion_id, e.name, ROUND(AVG(intensity_percent),2) AS avg_intensity,
		SUM(char_count) / COUNT(p.id) AS avg_char_count
FROM poem_emotion AS pe INNER JOIN poem AS p ON pe.poem_id = p.id
						INNER JOIN emotion AS e ON pe.emotion_id = e.id
GROUP BY emotion_id, e.name
ORDER BY emotion_id;

--     b. Convert the query you wrote in part a into a CTE. Then find the 5 most intense poems that express anger and whether they are to be longer or shorter than the average angry poem. 
--      -  What is the most angry poem about?  

-- ** Note: 9 poems are tied for the fifth angriest poem, so all have been included
-- **Answer** The two angriest poems are about a french horse with ants in his pants who outraged an audience,
-- and how summer is wickedly, outrageously hot, and also perfect. 

WITH avg_angry_poem AS (SELECT	emotion_id, e.name, ROUND(AVG(intensity_percent),2) AS avg_intensity,
								SUM(char_count) / COUNT(p.id) AS avg_char_count
						FROM poem_emotion AS pe INNER JOIN poem AS p ON pe.poem_id = p.id
												INNER JOIN emotion AS e ON pe.emotion_id = e.id
						WHERE emotion_id = 1
						GROUP BY emotion_id, e.name
						ORDER BY emotion_id)

SELECT e.name AS emotion, intensity_percent, char_count, avg_char_count, char_count > avg_char_count AS longer_than_avg, title, text
FROM poem_emotion AS pe INNER JOIN poem AS p ON pe.poem_id = p.id
						INNER JOIN emotion AS e ON pe.emotion_id = e.id
						INNER JOIN avg_angry_poem ON pe.emotion_id = avg_angry_poem.emotion_id AND e.id = avg_angry_poem.emotion_id
WHERE 	pe.emotion_id = 1
ORDER BY intensity_percent DESC
LIMIT 13;

--      -  Do you think these are all classified correctly?
-- **Answer** Based on keywords, I see how these poems were classified under "anger."
-- Some poems are anti-hate, or about intense moments.
-- However, the keyword "furious" seems to be the least accurately categorized as hate based on how it used in the poems.



-- 4. Compare the 5 most joyful poems by 1st graders to the 5 most joyful poems by 5th graders.  
-- ** Note: 7 poems tied for #5 among fifth graders, all included
(SELECT grade_id, gender.name AS gender, intensity_percent, emotion.name, title, text
FROM author INNER JOIN poem ON author.id = author_id
			INNER JOIN poem_emotion AS pe ON poem.id = pe.poem_id
			INNER JOIN emotion ON pe.emotion_id = emotion.id
			INNER JOIN gender ON author.gender_id = gender.id
WHERE grade_id = 1 AND emotion.name = 'Joy'
ORDER BY intensity_percent DESC
LIMIT 5)

UNION 

(SELECT grade_id, gender.name AS gender, intensity_percent, emotion.name, title, text
FROM author INNER JOIN poem ON author.id = author_id
			INNER JOIN poem_emotion AS pe ON poem.id = pe.poem_id
			INNER JOIN emotion ON pe.emotion_id = emotion.id
			INNER JOIN gender ON author.gender_id = gender.id
WHERE grade_id = 5 AND emotion.name = 'Joy'
ORDER BY intensity_percent DESC
LIMIT 11)
ORDER BY intensity_percent DESC, grade_id;

-- 	a. Which group writes the most joyful poems according to the intensity score?  
-- ** Answer ** Out of the top 12 most intense poems, 11 were written by 5th graders and only 1 by a first grader
--     b. Who shows up more in the top five for grades 1 and 5, males or females?  
-- ** Answer ** The 1st graders have 1 female and 2 males; the 5th graders have 5 females and 5 males.
WITH most_intense AS (	(SELECT grade_id, gender.name AS gender, intensity_percent, title, text
						FROM author INNER JOIN poem ON author.id = author_id
									INNER JOIN poem_emotion AS pe ON poem.id = pe.poem_id
									INNER JOIN emotion ON pe.emotion_id = emotion.id
									INNER JOIN gender ON author.gender_id = gender.id
						WHERE grade_id = 1 AND emotion.name = 'Joy'
						ORDER BY intensity_percent DESC
						LIMIT 5)

						UNION 

						(SELECT grade_id, gender.name AS gender, intensity_percent, title, text
						FROM author INNER JOIN poem ON author.id = author_id
									INNER JOIN poem_emotion AS pe ON poem.id = pe.poem_id
									INNER JOIN emotion ON pe.emotion_id = emotion.id
									INNER JOIN gender ON author.gender_id = gender.id
						WHERE grade_id = 5 AND emotion.name = 'Joy'
						ORDER BY intensity_percent DESC
						LIMIT 11)
						ORDER BY intensity_percent DESC, grade_id)
SELECT grade_id,
		SUM(CASE WHEN gender = 'Female' THEN 1 ELSE 0 END) AS female,
		SUM(CASE WHEN gender = 'Male' THEN 1 ELSE 0 END) AS male
FROM most_intense
GROUP BY grade_id;

--     c. Which of these do you like the best?
-- **Answer** "Tornados" is my favorite poem since I'm from Tornado Alley

-- 5. Robert Frost was a famous American poet. One of his most well-know poems, _The Road Not Taken_, starts with this stanza:

--     > Two roads diverged in a yellow wood,  
--     > And sorry I could not travel both  
--     > And be one traveler, long I stood  
--     > And looked down one as far as I could  
--     > To where it bent in the undergrowth;  

-- 	a. Examine the poets in the database with the name `robert`.
-- Create a report showing the count of Roberts by grade along with the distribution of emotions that characterize their work.  
-- **Answer** Each grade has one "Robert" and all Roberts write about anger, fear, joy and sadness.

SELECT grade_id, author.name AS author_name, COUNT(DISTINCT author.id) AS robert_count, emotion.name AS emotion
FROM author	INNER JOIN poem ON author.id = poem.author_id
			INNER JOIN poem_emotion AS pe ON poem.id = pe.poem_id
			INNER JOIN emotion ON pe.emotion_id = emotion_id
WHERE author.name ILIKE 'Robert'
GROUP BY grade_id, author.name, author.id, emotion.name


-- 	b. Export this report to Excel and create a visualization that shows what you have found.
