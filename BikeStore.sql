create schema if not exists BikeStore;
use BikeStore;

drop table if exists	brands, 
						categories, 
						customers, 
						order_items, 
						orders, 
						products, 
						staffs, 
						stocks, 
						stores;

create table brands (
	brand_id 	int 		not null,
    brand_name 	varchar(14) not null,
    primary key (brand_id),
    unique key (brand_name)
);

create table categories (
	category_id 		int 		not null,
    category_name 		varchar(20) not null,
    primary key (category_id),
    unique key (category_name)
);

create table customers (
	customer_id 	int 			not null,
    first_name 		varchar(30) 	not null,
    last_name 		varchar(30) 	not null,
    phone 			varchar(15),
    email 			varchar(90) 	not null,
    street 			varchar(30) 	not null,
    city 			varchar(25) 	not null,
    state 			varchar(2) 		not null,
    zip_code 		varchar(5) 		not null,
    primary key (customer_id),
    unique key (email)
);

create table order_items (
	order_id 	int 			not null,
    item_id 	int 			not null,
    product_id 	int 			not null,
    quantity 	int				not null,
    list_price 	decimal(10,2) 	not null,
    discount 	decimal(3,2) 	not null,
    primary key (order_id, item_id)
);

create table orders (
	order_id 		int 	not null,
    customer_id 	int 	not null,
    order_status 	int 	not null,
    order_date		date,
    required_date 	date,
    shipped_date 	date,
    store_id 		int 	not null,
    staff_id 		int 	not null,
	foreign key (customer_id) references customers (customer_id),
    primary key (order_id)
);

create table products (
	product_id 		int 			not null,
    product_name 	varchar(100) 	not null,
    brand_id 		int 			not null,
    category_id 	int 			not null,
    model_year 		int 			not null,
    list_price 		decimal(10,2)	not null,
    foreign key (brand_id) references brands (brand_id) on delete cascade,
    foreign key (category_id) references categories (category_id) on delete cascade,
    primary key (product_id, list_price)
);

create table staffs (
	staff_id 	int 		not null,
    first_name 	varchar(30) not null,
    last_name 	varchar(30) not null,
    email 		varchar(90) not null,
    phone 		varchar(50) not null,
    active 		int 		not null,
    store_id 	int 		not null,
    manager_id 	int,
    primary key (staff_id, store_id)
);

create table stocks (
	store_id 	int not null,
    product_id 	int not null,
    quantity 	int not null,
    primary key (store_id, product_id)
);

create table stores (
	store_id 	int 		not null,
    store_name 	varchar(20) not null,
    phone		varchar(15)	not null,
    email 		varchar(90) not null,
    street 		varchar(30) not null,
    city 		varchar(25) not null,
    state 		varchar(2) 	not null,
    zip_code 	varchar(5) 	not null,
    foreign key (store_id) references stocks (store_id) on delete cascade,
    primary key (store_id)
);

create or replace view v_store_sales as
select 	o.store_id,
		s.store_name,
        p.product_name,
        (oi.quantity),
		(oi.list_price * (1 - oi.discount)) as price,
        sum(oi.quantity * (oi.list_price * (1 - oi.discount))) as sales
from order_items oi
join orders o on oi.order_id = o.order_id
join stores s on o.store_id = s.store_id
join products p on oi.product_id = oi.product_id
group by s.store_name, o.store_id, oi.quantity, oi.list_price, oi.discount;

select * from v_store_sales order by sales desc;

create or replace view v_category_overview as
select 	c.category_name, 
		p.product_id, 
		p.product_name, 
		sum(oi.quantity) as good_sold,
        oi.list_price as price,
        oi.discount,
        sum(oi.quantity * (oi.list_price * (1 - oi.discount))) as sales
from products p
join categories c on p.category_id = c.category_id
join order_items oi on p.product_id = oi.product_id
group by c.category_name, p.product_id, p.product_name, oi.list_price, oi.discount;

select * 
from v_category_overview
order by sales desc;

create or replace view v_shipping as
select 	oi.product_id,
		p.product_name,
		o.customer_id,
		c.first_name,
        c.last_name,
        c.city,
        o.shipped_date,
        o.required_date,
case 
	when shipped_date > required_date 
    then 'Late'
    else 'On Time'
end as shipping_status
from orders o
join customers c on o.customer_id = c.customer_id
join order_items oi on o.order_id = oi. order_id
join products p on oi.product_id = p.product_id
where o.order_status = 4;

select * from v_shipping;

create or replace view v_inventory as
select		sk.store_id,
			sr.store_name,
            p.product_name,
            b.brand_name,
			sk.quantity as stock_quantity,
            oi.quantity as order_quantity,
case
	when sk.quantity > oi.quantity
    then 'Sufficient'
    else 'Insufficient'
end as inventory_status
from stocks sk
join stores sr on sk.store_id = sr.store_id
join products p on sk.product_id = p.product_id
join brands b on p.brand_id = b.brand_id
join order_items oi on sk.product_id = oi.product_id;

select * from v_inventory;