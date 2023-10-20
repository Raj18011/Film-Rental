-- ---------------------------------------------------------------------------------------------------------------------
--                                               Film - Rental
-- ---------------------------------------------------------------------------------------------------------------------
-- Questions:
-- 1.	What is the total revenue generated from all rentals in the database? (2 Marks)
select sum(amount)
from payment;
-- ----------------------------------------------------------------------------------------
-- 2.	How many rentals were made in each month_name? (2 Marks)
select * from rental;
with cte1 as(select rental_date,monthname(rental_date) as month
from rental) select month,count(rental_date) from cte1 group by month;
-- ----------------------------------------------------------------------------------------
-- 3.	What is the rental rate of the film with the longest title in the database? (2 Marks)

with cte1 as (select title,char_length(title)as a, rental_rate from film)
select * from cte1 where a=(select max(char_length(title)) from film);
-- ----------------------------------------------------------------------------------------
-- 4.	What is the average rental rate for films that were taken from the last 
-- 30 days from the date("2005-05-05 22:04:30")? (2 Marks)
select avg(rental_rate) 
from rental join inventory using(inventory_id) join film using(film_id)
where rental_date in (
with cte2 as (
with cte1 as(
select distinct date(rental_date) as date_distinct
from rental where rental_date>'2005-05-05')
select *,row_number() over(order by date_distinct desc) as day_count from cte1)
select date_distinct from cte2 where day_count<=30);
-- ----------------------------------------------------------------------------------------
-- 5.What is the most popular category of films in terms of the number of rentals? (3 Marks)

with cte1 as (select  c.name,count(rental_date) as maxs   from rental  join inventory using(inventory_id) 
join film f using(film_id) join film_category fc on f.film_id=fc.film_id join category c using(category_id) 
group by c.name ) 
select * from cte1 where maxs= (select max(maxs) from cte1)  ;
-- ----------------------------------------------------------------------------------------
-- 6.	Find the longest movie duration from the list of films that have not been rented by any customer. (3 Marks)
select * from film;
select title,rental_duration,rental_date
from film f join inventory i using(film_id)
left join rental r using (inventory_id)
where rental_date is null;
-- ----------------------------------------------------------------------------------------
-- 7.	What is the average rental rate for films, broken down by category? (3 Marks)
select  c.name,avg(rental_rate)  
from rental  join inventory using(inventory_id) 
join film f using(film_id) join film_category fc on f.film_id=fc.film_id join category c using(category_id) 
group by c.name;
-- ----------------------------------------------------------------------------------------
-- 8.	What is the total revenue generated from rentals for each actor in the database? (3 Marks)
select  first_name,last_name,sum(amount) as revenue 
from payment join rental using(rental_id)  join inventory using(inventory_id) 
join film f using(film_id) join film_actor using(film_id) join actor using(actor_id) group by first_name,last_name;
-- ----------------------------------------------------------------------------------------
-- 9.	Show all the actresses who worked in a film having a "Wrestler" in the description. (3 Marks)
select * from actor;
select a.actor_id, concat(a.first_name, ' ', a.last_name) as actor_name
from actor a join film_actor fa using(actor_id)
join film using(film_id) 
where description like '%wrestler%' ;
-- ----------------------------------------------------------------------------------------
-- 10.	Which customers have rented the same film more than once? (3 Marks)

select c.customer_id,f.film_id,f.title,count(c.customer_id) as count_films
from customer c join rental r on c.customer_id=r.customer_id
join inventory i on r.inventory_id = i.inventory_id
join film f on i.film_id = f.film_id
group by c.customer_id,f.film_id
having count_films>1;
-- ----------------------------------------------------------------------------------------
-- 11.	How many films in the comedy category have a rental rate higher than the average rental rate? (3 Marks)
select title,rental_rate from film join film_category using(film_id) join category using(category_id)
 where name in('Comedy') and rental_rate > (select avg(rental_rate) from film);
 -- ----------------------------------------------------------------------------------------
-- 12.	Which films have been rented the most by customers living in each city? (3 Marks)

WITH RankRentals AS (SELECT c.city,f.title AS film_title,COUNT(*) AS rental_count,ROW_NUMBER() OVER (PARTITION BY c.city ORDER BY COUNT(*) DESC) AS ranking
  FROM rental r
    JOIN customer cu ON r.customer_id = cu.customer_id
    JOIN address a ON cu.address_id = a.address_id
    JOIN city c ON a.city_id = c.city_id
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
  GROUP BY
    c.city, f.title
)
SELECT city,film_title,rental_count FROM RankRentals WHERE ranking = 1;
 -- ----------------------------------------------------------------------------------------
-- 13.	What is the total amount spent by customers whose rental payments exceed $200? (3 Marks)
with cte1 as (select distinct c.customer_id,c.first_name,c.last_name,sum(amount) over(partition by customer_id) as rental_payment 
from payment p join customer c using(customer_id))
select customer_id,first_name,last_name, rental_payment from cte1 where rental_payment > 200;
-- ----------------------------------------------------------------------------------------
-- 14.	Display the fields which are having foreign key constraints related to the "rental" table. [Hint: using Information_schema] (2 Marks)
SELECT TABLE_NAME,COLUMN_NAME,CONSTRAINT_NAME,REFERENCED_TABLE_NAME,REFERENCED_COLUMN_NAME 
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE  
WHERE TABLE_NAME = 'rental' AND REFERENCED_TABLE_NAME IS NOT NULL;
-- ----------------------------------------------------------------------------------------
-- 15.	Create a View for the total revenue generated by each staff member, broken down by store city with the country name. (4 Marks)
select distinct staff_id,first_name,last_name,sum(amount)over(partition by staff_id),city,country 
from payment join staff using(staff_id) 
join  address using(address_id) 
join city using(city_id) 
join country using(country_id);
-- ----------------------------------------------------------------------------------------
select c.customer_id, rental_date, date_add(rental_date, interval 1 day) as diff_date, amount
from film join inventory using (film_id)
join rental using (inventory_id)
join payment using (rental_id)
join staff s on s.staff_id
join store st on st.store_id
join customer c on c.store_id;
-- ----------------------------------------------------------------------------------------
-- 16. Create a view based on rental information consisting of visiting_day, customer_name, the title of the film,
-- no_of_rental_days, the amount paid by the customer along with the percentage of customer spending.

create view rental_information as
select c.customer_id, rental_date, concat(c.first_name, ' ', c.last_name) as customer_name, title, rental_duration, amount as paid_amount,
((amount/ (select sum(amount) from payment)) *100) as pct
from rental join inventory using (inventory_id)
            join film using (film_id)
            join customer c using (customer_id)
            join payment using (rental_id)
group by c.customer_id, rental_date, title, rental_duration, paid_amount;

select * from rental_information;
-- ----------------------------------------------------------------------------------------
-- 17. Display the customers who paid 50% of their total rental costs within one day.

select c.customer_id,f.film_id, (f.rental_rate * f.rental_duration) as rental_cost , p.amount, (p.amount/(f.rental_rate * f.rental_duration))*100 as pct_paid
from film f join inventory i using (film_id)
			join rental r using (inventory_id)
            join customer c using (customer_id)
            join payment p using (rental_id)
where (p.amount/(f.rental_rate * f.rental_duration)) > 0.5 and payment_date < date_add(r.rental_date, interval 1 day);
-- ----------------------------------------------------------------------------------------
















