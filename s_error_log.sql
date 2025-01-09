-- Not recommen to use WHERE TO_CHAR(
SELECT ERROR_LOG_ID,CREATE_DATE, ERR_DESC FROM S_ERROR_LOG WHERE TO_CHAR(CREATE_DATE,'MM/DD/YYYY')  =  '07/19/2010' ORDER BY CREATE_DATE DESC;

SELECT count(*) FROM S_ERROR_LOG WHERE TO_CHAR(CREATE_DATE,'MM/DD/YYYY')  =  '07/19/2010' ORDER BY CREATE_DATE DESC;

SELECT count(*)  FROM S_ERROR_LOG WHERE CREATE_DATE =  to_date('2007', 'YYYY');
  
 
-- This is more efficient way
SELECT ERROR_LOG_ID,TO_CHAR(CREATE_DATE,'MM/DD/YYYY'), ERR_DESC  FROM S_ERROR_LOG
 WHERE CREATE_DATE =  to_date('12/22/2011', 'MM/DD/YYYY')  and ERR_DESC like '%WVMQWKTIS20%'


--For the last 2 day. Today and yester.
select create_date, error_log_id, err_desc from s_error_log where err_desc like '%Server%'
and create_date > trunc(sysdate)


--More examples for date usage

-- Uses ship_date index 

where ship_date >= trunc(sysdate-7) + 1;


-- Uses ship_date index

where ship_date = to_date(‘2004-01-04’,’YYYY-MM-DD’);




--EXAMPLES
--Error In BusinessEntities/TimeEntities.Schedule.DecompressAllTimeSpan || Err.Desc = Employee ID: 193500, StartDate = 1/3/2043 9:00:00 AM, EndDate = 1/3/2043 5:00:00 PM

--App error: Server Name : ADDWEB15
--; System error: Invalid viewstate. 
--	Client IP: 10.140.20.201
--	Port: 21034
--	User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322; InfoPath.1; .NET CLR 2.0.50727)
--	ViewState: SAZS5l2/CnYIbmfy5tnPoPbNfyaAG3ZFXPQvHdXprIVVkxIAKPVEE4f2uMk7vypy61PX9jXAqJEwbqNSHaYj5LtYU8w8KCjQ0piM7QIYbQNR6+J6dbfqtsqfquUY7VpzZ+Uj8AfJgfx3G/I1M7Kp7/bwsJeTnhdvEp5vGtmwo9Jh6tDiRrAIVpGNRTkvCHj4sB+sdQNowRn03ovDyPHl1q7nh8T0niRWmJW+cWdHH5eCp6okd7y4ar+rAO8RzS63ZtR9VZe6HRwhJYHNUe6xRmke/bfTSWJz38jF+6ZCo8zKQoqb7j2fxP/nVZrXg0C7NAN4BuPrS2sqVyaAUxbExLpn+AtF6EkHoDf298OvJ3YTBy9Gm3a5HjO341quZk3ZWoLk1kE5ygdL5b8QJmt9c7I4p/9cq7zpZjlm7kTWqhYiuoJyUGZC957OMs6nzdD49UOsXGtsF2WsNNhUuiz2dvAavxoG26GPGjB5FvFGKi8K6ln+qyidomsfrpuG59wM2AGkfP1axxPc8wIQZK5cRlvs7blClo+zTuSBFDosKA1plzQBnH3bE9+q8JhlCwE3dBzI5aHHVOb5BwcdhhFk3Box2k+uopHH69CPmGsrpeJQwHcot7EyQYFBVqH1cdf2i/eQGdIX7P06A20Ts7/OjT0FfN1tetD8MGs+VwQ0E/Njua77u3fwI+j4lJWbI74ssYiekq9Jr3qBT4pKu06zJHK+3tiUtqARRpXRqo6xb1N2WTepXsSEKuVmqBvEx64KTeeizWETnv/k81CBIgrJW+LeKbH57BMJIOG2lQVm9Wfg1GQ3TAyUsz7J4+NCXgDNST6/rCzGTQNws...; 