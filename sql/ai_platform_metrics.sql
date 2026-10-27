-- Creating the users table
CREATE TABLE users (
	user_id TEXT PRIMARY KEY,
	subscription_tier TEXT DEFAULT 'Free',
	country TEXT NOT NULL,
	sign_up_date TIMESTAMPTZ NOT NULL,
	CONSTRAINT chk_subtier CHECK (subscription_tier IN ('Free', 'Pro', 'Enterprise'))
);

-- Creating the models table
CREATE TABLE models (
	model_id TEXT PRIMARY KEY,
	model_name TEXT UNIQUE,
	model_type TEXT,
	cost_per_1k_tokens NUMERIC(8,4),
	CONSTRAINT chk_model_type CHECK (model_type IN ('Text', 'Code', 'Image', 'Data'))
);

-- Creating the api_logs table
CREATE TABLE api_logs (
	log_id TEXT PRIMARY KEY,
	user_id TEXT,
	model_id TEXT,
	timestamp TIMESTAMPTZ NOT NULL,
	prompt_tokens INT NOT NULL,
	completion_tokens INT NOT NULL,
	latency_ms INT NOT NULL,
	FOREIGN KEY (user_id) REFERENCES users(user_id),
	FOREIGN KEY (model_id) REFERENCES models(model_id)
);

-- Copying data into users
COPY users 
FROM 'C:\SQLData\users.csv'
WITH (FORMAT CSV, HEADER);

-- Copying data into models
COPY models 
FROM 'C:\SQLData\models.csv'
WITH (FORMAT CSV, HEADER);

-- Copying data into api_logs
COPY api_logs
FROM 'C:\SQLData\api_logs.csv'
WITH (FORMAT CSV, HEADER);

-- Verifying completeness of api_logs data
SELECT COUNT(*) FROM api_logs;
-- Inspecting data quality
SELECT * FROM api_logs LIMIT 10;

-- User distribution across subscription tiers
SELECT COUNT(user_id) AS Users, subscription_tier AS Tier
FROM users
GROUP BY subscription_tier;

-- Model perfomance profiling
SELECT model_id, AVG(latency_ms) AS "Average Latency (ms)"
FROM api_logs
GROUP BY model_id
ORDER BY "Average Latency (ms)" DESC;

-- Enterprise Usage - Total no. of prompt tokens consumed by Enterprise-tier users
SELECT SUM(prompt_tokens)
FROM api_logs
WHERE user_id IN (
	SELECT user_id
	FROM users
	WHERE subscription_tier = 'Enterprise'
);

-- Traffic based on subscription tier
SELECT u.subscription_tier, COUNT(a.log_id) AS "No. of API requests"
FROM users u JOIN api_logs a
ON u.user_id = a.user_id
GROUP BY u.subscription_tier;

-- Usage cost by country
SELECT u.country, SUM((a.prompt_tokens + a.completion_tokens)*m.cost_per_1k_tokens/1000.0) AS "Cost"
FROM users u
JOIN api_logs a ON u.user_id = a.user_id
JOIN models m ON a.model_id = m.model_id
GROUP BY u.country
ORDER BY "Cost" DESC;

-- Performance monitoring based on model type
SELECT m.model_type, AVG(a.latency_ms) AS "Average Latency (ms)"
FROM models m JOIN api_logs a
ON m.model_id = a.model_id
GROUP BY m.model_type
ORDER BY "Average Latency (ms)" DESC;

-- Identifying users with more than 35 API requests
SELECT user_id, COUNT(log_id) AS "API requests"
FROM api_logs a
GROUP BY user_id 
HAVING COUNT(log_id) >= 35
ORDER BY "API requests" DESC;

-- Daily logs
SELECT timestamp::DATE AS "Day", COUNT(log_id) AS "Amount of logs"
FROM api_logs
GROUP BY "Day"
ORDER BY "Amount of logs" DESC;

-- Identifying heavy-lifting models
SELECT m.model_name AS "Model Name", SUM(a.prompt_tokens + a.completion_tokens) AS "Token Consumption"
FROM models m JOIN api_logs a
ON m.model_id = a.model_id
GROUP BY "Model Name"
HAVING SUM(a.prompt_tokens + a.completion_tokens) > 10000000
ORDER BY "Token Consumption" DESC;

-- Perfomance bucketing
SELECT
CASE
	WHEN latency_ms < 200 THEN 'Fast'
	WHEN latency_ms BETWEEN 200 AND 500 THEN 'Normal'
	WHEN latency_ms > 500 THEN 'Slow'
END AS "Performance", COUNT(log_id) AS "No. of API requests"
FROM api_logs
GROUP BY "Performance";

/*SELECT * FROM users;
SELECT * FROM models;
SELECT * FROM api_logs;*/