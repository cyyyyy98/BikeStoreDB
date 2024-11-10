library(DBI)
library(RMySQL)
library(dplyr)

BikeStore <- dbConnect(RMySQL::MySQL(),
                     dbname = "BikeStore",
                     host = "127.0.0.1",
                     port = 3306,
                     user = "root",
                     password = "xxxxxxx")

dbListTables(BikeStore)

Inventory <- dbReadTable(BikeStore, "v_inventory")
str(Inventory)
sum(is.na(Inventory))
Inventory$inventory_status <- as.factor(Inventory$inventory_status)

### INVENTORY AT STORES
inventory_sufficiency <- Inventory %>%
  group_by(store_name) %>%
  summarise(stock = sum(stock_quantity),
            order = sum(order_quantity)) %>%
  mutate(sufficiency = (stock / order))
# All stores have sufficient stock.

# Inventory Summary for Each Store
store_1_stock <- Inventory %>%
  filter(store_id == 1) %>%
  select(store_name, product_name, brand_name, stock_quantity, order_quantity, inventory_status) %>%
  mutate(sufficiency = (stock_quantity / order_quantity))

store_2_stock <- Inventory %>%
  filter(store_id == 2) %>%
  select(store_name, product_name, brand_name, stock_quantity, order_quantity, inventory_status) %>%
  mutate(sufficiency = (stock_quantity / order_quantity))

store_3_stock <- Inventory %>%
  filter(store_id == 3) %>%
  select(store_name, product_name, brand_name, stock_quantity, order_quantity, inventory_status) %>%
  mutate(sufficiency = (stock_quantity / order_quantity))

# Insufficient Stock of Products
insufficient_stock <- function (store_id) {
  Inventory %>%
    filter(store_id == store_id) %>%
    select(store_name, product_name, stock_quantity, order_quantity, inventory_status) %>%
    mutate(sufficiency = (stock_quantity / order_quantity)) %>%
    filter(sufficiency < 1)
}
store_1_insufficient <- insufficient_stock(1)
store_2_insufficient <- insufficient_stock(2)
store_3_insufficient <- insufficient_stock(3)

# When the function not working, run following:
stock_insufficient <- Inventory %>%
  select(store_id, store_name, product_name, stock_quantity, order_quantity, inventory_status) %>%
  mutate(sufficiency = (stock_quantity / order_quantity)) %>%
  filter(sufficiency < 1)

store_1_insufficient <- stock_insufficient %>%
  filter(store_id == 1)
store_2_insufficient <- stock_insufficient %>%
  filter(store_id == 2)
store_3_insufficient <- stock_insufficient %>%
  filter(store_id == 3)

### INVENTORY BY BRANDS
Orders <- dbReadTable(BikeStore, "orders")
Order_items <- dbReadTable(BikeStore, "order_items")
str(Orders)
str(Order_items)

# suppose days of stock = stock_quantity / daily orders
Collect_daily_orders <- left_join(Orders, Order_items, by = "order_id")
Daily_orders <- Collect_daily_orders %>%
  mutate(order_date = as.Date(order_date)) %>%
  group_by(order_date) %>%
  summarise(
    total_quantity = sum(quantity, na.rm = TRUE),
    total_orders = n_distinct(order_id)
  )
days_of_stock <- Daily_orders %>%
  filter(format(order_date, "%Y") == "2018") %>%
  group_by(order_date) %>%
  summarise(daily_total = sum(total_quantity, na.rm = TRUE)) %>%
  summarise(avg_daily_orders = mean(daily_total)) 
# 2016 avg_daily_order: 9
# 2017 avg_daily_order: 10
# 2018 avg_daily_order: 11
# 9.76 orders between 2016 and 2018 >>> So, assume that days of stock are 10

# Result: the over-stocked is defined when the sufficiency is GREATER (>) than 10
store_1_overstocked <- store_1_stock %>%
  filter(sufficiency > 10)
store_2_overstocked <- store_2_stock %>%
  filter(sufficiency > 10)
store_3_overstocked <- store_3_stock %>%
  filter(sufficiency > 10)

### SHIPPING: ON-TIME/LATE
Shipping <- dbReadTable(BikeStore, "v_shipping")
str(Shipping)
Shipping$shipping_status <- as.factor(Shipping$shipping_status)

library(ggplot2)
shipping_summary <- Shipping %>%
  group_by(shipping_status) %>%
  summarise(total_quantity = sum(quantity)) %>%
  mutate(percent_of_status = total_quantity/sum(total_quantity))

ggplot(Shipping, aes(x="", y=quantity, fill=shipping_status)) +
                          geom_bar(stat = "identity", width = 1) +
                          coord_polar(theta = "y") +
                          labs(title = "Shipping Overview") +
                          theme_void() +
                          theme(legend.title = element_blank())
# 68% on time, 32% late

### SALES by STORES
Sales_by_stores <- dbReadTable(BikeStore, "v_store_sales")
str(Sales_by_stores)

library(ggplot2)
sales_summary <- Sales_by_stores %>%
  group_by(store_name) %>%
  summarise(total_sales = sum(sales))

ggplot(sales_summary, aes(x=reorder(store_name, -total_sales), y=total_sales)) +
  geom_bar(stat = "identity", width = 0.5) +
  labs(title = "Totals Sales by Store") +
  theme(axis.title.x = element_blank(),
        axis.title.y = element_blank())
# Baldwin Bikes has the highest sales @1,674,256,160
# Rowlett Bikes @278,481,060

### CATEGORY REVENUES SUMMARY
Category <- dbReadTable(BikeStore, "v_category_overview")
str(Category)

category_summary <- Category %>%
  group_by(category_name) %>%
  summarise(total_sales = sum(sales))

ggplot(category_summary, aes(x=reorder(category_name, -total_sales), y=total_sales)) +
  geom_bar(stat = "identity", width = 0.5) +
  labs(title = "Total Sales by Category") +
  theme(axis.title.x = element_blank(),
        axis.title.y = element_blank())
# Top 1: Mountain Bikes @2,715,079.5
# Rank 2: Road Bikes @1,665,098.5
# Rank 3: Cruisers Bikes @995,032.6