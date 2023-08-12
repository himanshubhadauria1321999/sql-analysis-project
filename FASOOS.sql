Q1-HOW MANY ROLLS WERE ORDERED?

SELECT COUNT(*) FROM driver_order;

Q2-HOW MANY UNIQUE CUSTOMER ORDERS WERE MADE?

SELECT COUNT(distinct customer_id) FROM customer_orders;

Q3-HOW MANY SUCCESSFUL ORDERS WERE DELIVERED BY EACH DRIVER?

SELECT driver_id,COUNT(*) FROM driver_order
WHERE  cancellation NOT IN ('CANCELLATION','CUSTOMER CANCELLATION') OR cancellation IS NULL
group by driver_id;

Q4-HOW MANY OF EACH TYPE OF ROLL WAS DELIVERED?

WITH T1 AS(SELECT DO.order_id,driver_id,cancellation,CO.customer_id,CO.roll_id FROM driver_order DO
JOIN customer_orders CO ON CO.order_id=DO.order_id),
T2 AS(SELECT ROLL_ID,COUNT(ORDER_ID) FR FROM T1 
WHERE CANCELLATION IS NULL OR CANCELLATION NOT IN ('CANCELLATION','CUSTOMER CANCELLATION')
GROUP BY ROLL_ID)
SELECT rolls.roll_name,T2.FR FROM T2
JOIN rolls ON ROLLS.ROLL_ID=T2.ROLL_ID;

Q5-HOW MANY VEG AND NON-VEG ROLLS WERE ORDERED BY EACH CUSTOMER?

SELECT CUSTOMER_ID,COUNT(*),ROLL_NAME FROM
(SELECT CO.customer_id,R.roll_name FROM customer_orders CO 
JOIN rolls R ON R.roll_id=CO.roll_id) PNG
group by customer_id,ROLL_NAME
ORDER BY customer_id;

Q6-WHAT WAS THE MAXIMUM NO OF ROLLS DELIVERED IN A SINGLE ORDER?

select count(*) t,order_id from customer_orders
where order_id in(
SELECT order_id FROM driver_order
WHERE cancellation IS  NULL OR cancellation not IN ('cancellation','customer cancellation')
) group by order_id
order by t desc
limit 1;

Q7-FOR EACH CUSTOMER,HOW MANY DELIVERED ROLLS HAD AT LEAST 1 CHANGE AND HOW MANY HAD NO CHANGES?

with t1 as(select *,case when not_include_items in ('') or not_include_items is null and( extra_items_included in ('') or extra_items_included is null) 
then 'nochange' else 'change' end as 'result'
 from customer_orders
 where order_id in(SELECT order_id FROM driver_order
WHERE cancellation IS  NULL OR cancellation not IN ('cancellation','customer cancellation')
 )
 )select customer_id,count(result) "no of rolls",result from t1
 group by customer_id,result
 order by customer_id;
 
 Q8-HOW MANY ROLLS WERE DELIVERD THAT HAD BOTH EXCLUSIONS AND EXTRAS?
 
 with t1 as(select * from customer_orders
 where extra_items_included<>'' and not_include_items<>'')
 select count(*) from t1
 where order_id in (SELECT order_id FROM driver_order
WHERE cancellation IS  NULL OR cancellation not IN ('cancellation','customer cancellation'));
 
 Q9-WHAT WAS THE TOTAL NUMBER OF ROLLS ORDERED FOR EACH HOUR OF THE DAY?
 
 with t1 as
(select  *,hour(order_date) tr,hour(order_date)+1 fr from customer_orders)
select count(*), concat(tr,-fr) pr from t1
group by pr;

Q10-WHAT WAS THE NO OF ORDERS FOR EACH DAY OF WEEK?

with t1 as(select *,dayname(order_date) days,week(order_date) weeks from customer_orders)
select count(distinct order_id) orders,days,weeks from t1
group by days,weeks
order by weeks;

NOW FOR DRIVER AND CUSTOMER EXPERIENCE;

Q1-WHAT IS THE AVG TIME IN MINUTES IT TOOK FOR EACH DRIVER TO ARRIVE AT FASOOS TO PICKUP ORDER?

select driver_id,round(avg(time_to_sec(timediff(pickup_time,order_date)))/60,2) time from customer_orders co 
join driver_order do on do.order_id=co.order_id and order_date<pickup_time
group by driver_id;

Q2-IS THERE ANY RELATION B/W THE NO OF ROLLS  AND HOW LONG ORDER TAKES TO PREPARE?

select driver_id,round(avg(fire),2) from(
select distinct order_id,driver_id,fire from (select co.order_id,do.driver_id,do.pickup_time,co.order_date,
time_to_sec(timediff(pickup_time,order_Date))/60 fire
 from customer_orders co
join driver_order do on do.order_id=co.order_id and pickup_time>order_date
where pickup_time is not null) pt
) ntr
group by driver_id;

Q3-WHAT WAS THE AVG DISTANCE TRAVELLED FOR EACH CUSTOMER?

select customer_id,avg(distance) from(select distinct order_id,customer_id,distance from (select co.order_id,do.driver_id,co.customer_id,do.distance
 from customer_orders co
join driver_order do on do.order_id=co.order_id 
where distance is not null) pt) ntr
group by customer_id;


Q4-WHAT WAS THE DIFFERNCE B/W LONGEST AND SHORTEST DELIVERY TIMES FOR ALL ORDERS?

with t1 as(select *,left(duration,2) mins,position('m'in duration) charindex from driver_order
where duration is not null)
,t2 as(select *,
max(mins) over(order by order_id rows between unbounded preceding and unbounded following) max,
min(mins) over(order by order_id rows between unbounded preceding and unbounded following) min
from t1)
select order_id,max-mins,mins-min,mins from t2;

Q5-WHAT WAS THE SPEED FOR EACH DRIVER FOR EACH DELIVERY ?

with t1 as(select *,left(trim(duration),2) 'time',replace(distance,'km','') istance from driver_order
where duration is not null and distance is not null)
,T2 AS(select *,ROUND((istance/time)*60,2) SPEED from t1)
SELECT DRIVER_ID,MAX(SPEED),AVG(SPEED),MIN(SPEED),ORDER_ID
 FROM T2
GROUP BY DRIVER_ID,ORDER_ID;


Q6-WHAT IS SUCCESFUL DELIVERY PERCENT FOR EACH DRIVER?

WITH T1 AS(SELECT * ,
CASE WHEN cancellation IS NULL THEN 'FAIL'
WHEN cancellation LIKE '%CANCEL%' THEN 'FAIL'
ELSE 'PASS'
END AS CHECKI
FROM driver_order)
,T2 AS(SELECT DRIVER_ID,COUNT(CHECKI) ORDERS,CHECKI FROM T1
GROUP BY DRIVER_ID,CHECKI
ORDER BY DRIVER_ID)
,T3 AS(SELECT *,SUM(ORDERS) OVER(PARTITION BY DRIVER_ID ORDER BY DRIVER_ID) KGF FROM T2)
SELECT *,ROUND(ORDERS/KGF*100,2) SUCCES,100-ROUND(ORDERS/KGF*100,2) NODELIVERY FROM T3 
WHERE CHECKI='PASS';














 
 