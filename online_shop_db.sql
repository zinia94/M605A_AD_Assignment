-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Jul 01, 2024 at 11:27 PM
-- Server version: 10.4.28-MariaDB
-- PHP Version: 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `online_shop_db`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `retrieve_best_selling_product` ()   BEGIN
	-- 10 best-selling products with the total amount and their supplier.

WITH product_sales AS (
    SELECT
        os.product_id,
        SUM(os.quantity) AS total_quantity
    FROM
        order_segments os
    JOIN orders o ON os.order_id = o.id
    GROUP BY os.product_id
)
SELECT
    p.name AS product_name,
    s.company_name as supplier_company,
    ps.total_quantity AS total_number_of_sell,
    COALESCE(s.website, 'No Website') AS suppliers_website
FROM
    product_sales ps
JOIN product_suppliers psup ON ps.product_id = psup.product_id
JOIN products p ON p.id = ps.product_id
JOIN suppliers s ON s.id = psup.supplier_id
ORDER BY
    ps.total_quantity DESC
LIMIT 10;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `retrieve_customers_with_their_purchases` ()   BEGIN
	-- List of customers and their total purchases.
SELECT
    CONCAT(c.first_name, ' ', c.last_name) AS customers_name,
    CONCAT(
        c.address,
        ', ',
        c.state,
        ' - ',
        c.post_code,
        ' ',
        c.country
    ) AS address,
    p.number_of_orders AS total_purchases
FROM
    customers c
JOIN(
    SELECT
        o.customer_id,
        COUNT(id) AS number_of_orders
    FROM
        orders o
    GROUP BY
        o.customer_id
) p
ON
    c.id = p.customer_id;
   
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `retrieve_returned_items` ()   BEGIN
	-- List of returned items.
SELECT
    p.name AS product_name,
    cro.number_of_item_returned,
    COALESCE(
        p.description,
        'No Description Available'
    ) AS description
FROM
    products p
JOIN(
    SELECT
        ro.product_id,
        SUM(ro.quantity) AS number_of_item_returned
    FROM
        returned_orders ro
    GROUP BY
        ro.product_id
) cro
ON
    p.id = cro.product_id;
   
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `retrieve_sold_fashion_product_last_month` ()   BEGIN
	-- List of products in the fashion category that were sold lastmonth.

WITH
    fashion_category AS(
    SELECT
        c.id AS fashion_category_id
    FROM
        categories c
    WHERE
        c.category_name = 'Fashion'
)
SELECT
    fashion_products.name AS product_name,
    lastmonthsale.created_at AS date_of_sale
FROM
    order_segments os
JOIN(
    SELECT
        o.id,
        o.created_at
    FROM
        orders o
    WHERE
        o.created_at >= CURRENT_DATE() - INTERVAL 1 MONTH) lastmonthsale
    ON
        os.order_id = lastmonthsale.id
    JOIN(
        SELECT
            *
        FROM
            products p
        JOIN fashion_category f ON
            p.category_id = f.fashion_category_id
    ) fashion_products
ON
    fashion_products.id = os.product_id;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `retrieve_supplier_info_with_products` ()   BEGIN
	-- Detail information about suppliers and the number of products that they provide.
SELECT
    s.company_name,
    a.total_products AS total_products_supplied,
    s.website,
    CONCAT(
        s.address,
        ', ',
        s.state,
        ' - ',
        s.post_code,
        ' ',
        s.country
    ) AS address,
    CONCAT(
        'Name: ',
        s.contact_name,
        ', Title: ',
        s.contact_title,
        ', Email: ',
        s.email,
        ', Phone No: ',
        s.phone_no
    ) AS contact_details,
    s.description,
    (
        CASE s.is_active WHEN 1 THEN 'TRUE' ELSE 'FALSE'
    END
) AS is_active
FROM
    suppliers s
INNER JOIN(
    SELECT
        ps.supplier_id,
        SUM(ps.quantity) AS total_products
    FROM
        product_suppliers ps
    GROUP BY
        ps.supplier_id
) a
ON
    s.id = a.supplier_id;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `id` bigint(20) NOT NULL,
  `category_name` varchar(50) NOT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `categories`
--

INSERT INTO `categories` (`id`, `category_name`, `description`) VALUES
(1, 'Electronics', 'Cutting-edge gadgets and devices for tech enthusiasts.'),
(2, 'Home and Kitchen', 'Essential appliances and stylish decor for your living spaces.'),
(3, 'Fashion', 'Trendy clothing and accessories for men, women, and kids.'),
(4, 'Beauty and Personal Care', 'Skincare, haircare, and beauty products for all your personal care needs.'),
(5, 'Health and Wellness', 'Products to support your physical and mental well-being.'),
(6, 'Toys and Games', 'Fun and educational toys and games for all ages.'),
(7, 'Books and Media', 'A diverse selection of books, music, and movies.'),
(8, 'Sports and Outdoors', 'Gear and apparel for outdoor adventures and sports activities.'),
(9, 'Office Supplies', 'Everything you need to stay organized and productive at work.'),
(10, 'Baby Products', 'Essentials and accessories for newborns and toddlers.');

-- --------------------------------------------------------

--
-- Table structure for table `comments`
--

CREATE TABLE `comments` (
  `comment_text` text NOT NULL,
  `customer_id` bigint(20) NOT NULL,
  `product_id` bigint(20) NOT NULL,
  `order_id` bigint(20) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `currencies`
--

CREATE TABLE `currencies` (
  `id` int(11) NOT NULL,
  `code` varchar(3) NOT NULL,
  `name` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `currencies`
--

INSERT INTO `currencies` (`id`, `code`, `name`) VALUES
(1, 'USD', 'United States Dollar'),
(2, 'EUR', 'Euro'),
(3, 'GBP', 'British Pound Sterling'),
(4, 'JPY', 'Japanese Yen'),
(5, 'AUD', 'Australian Dollar'),
(6, 'CAD', 'Canadian Dollar'),
(7, 'CHF', 'Swiss Franc'),
(8, 'CNY', 'Chinese Yuan'),
(9, 'SEK', 'Swedish Krona'),
(10, 'NZD', 'New Zealand Dollar'),
(11, 'MXN', 'Mexican Peso'),
(12, 'SGD', 'Singapore Dollar'),
(13, 'HKD', 'Hong Kong Dollar'),
(14, 'NOK', 'Norwegian Krone'),
(15, 'KRW', 'South Korean Won'),
(16, 'TRY', 'Turkish Lira'),
(17, 'INR', 'Indian Rupee'),
(18, 'RUB', 'Russian Ruble'),
(19, 'BRL', 'Brazilian Real'),
(20, 'ZAR', 'South African Rand');

-- --------------------------------------------------------

--
-- Table structure for table `customers`
--

CREATE TABLE `customers` (
  `id` bigint(20) NOT NULL,
  `first_name` varchar(50) NOT NULL,
  `last_name` varchar(50) NOT NULL,
  `email` varchar(50) NOT NULL,
  `date_of_birth` date NOT NULL,
  `gender` enum('MALE','FEMALE','OTHER') NOT NULL,
  `country` varchar(30) NOT NULL,
  `state` varchar(20) DEFAULT NULL,
  `post_code` char(20) DEFAULT NULL,
  `address` varchar(100) DEFAULT NULL,
  `phone_no` varchar(20) DEFAULT NULL,
  `password` varchar(20) NOT NULL,
  `last_login` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE current_timestamp(),
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `customers`
--

INSERT INTO `customers` (`id`, `first_name`, `last_name`, `email`, `date_of_birth`, `gender`, `country`, `state`, `post_code`, `address`, `phone_no`, `password`, `last_login`, `created_at`, `updated_at`, `is_active`) VALUES
(1, 'John', 'Doe', 'john.doe@abc.com', '1990-05-15', 'MALE', 'United States', 'California', '90001', '123 Main St', '+1 (123) 456-7890', 'password123', '2024-06-09 10:30:00', '2024-06-09 17:41:46', '0000-00-00 00:00:00', 1),
(2, 'Jane', 'Smith', 'jane.smith@abc.com', '1985-10-20', 'FEMALE', 'United States', 'New York', '10001', '456 Elm St', '+1 (234) 567-8901', 'pass123', '2024-06-08 07:45:00', '2024-06-09 17:41:46', '0000-00-00 00:00:00', 1),
(3, 'Michael', 'Johnson', 'michael.johnson@abc.com', '1978-03-08', 'MALE', 'United States', 'Texas', '75001', '789 Oak St', '+1 (345) 678-9012', 'securepass', '2024-06-07 13:20:00', '2024-06-09 17:41:46', '0000-00-00 00:00:00', 1),
(4, 'Emily', 'Brown', 'emily.brown@abc.com', '1995-12-25', 'FEMALE', 'United Kingdom', 'England', 'SW1A 1AA', '10 Downing St', '+44 20 1234 5678', 'p@ssw0rd', '2024-06-06 16:00:00', '2024-06-09 17:41:46', '0000-00-00 00:00:00', 1),
(5, 'David', 'Wilson', 'david.wilson@abc.com', '1982-08-12', 'MALE', 'Canada', 'Ontario', 'M5H 2N2', '123 Queen St W', '+1 (456) 789-0123', 'password321', '2024-06-05 08:10:00', '2024-06-09 17:41:46', '0000-00-00 00:00:00', 1),
(6, 'Sarah', 'Martinez', 'sarah.martinez@abc.com', '1993-04-30', 'FEMALE', 'Australia', 'New South Wales', '2000', '1 Macquarie St', '+61 2 9876 5432', 'mysecurepass', '2024-06-04 12:50:00', '2024-06-09 17:41:46', '0000-00-00 00:00:00', 1),
(7, 'James', 'Garcia', 'james.garcia@abc.com', '1989-07-18', 'MALE', 'Germany', 'Berlin', '10178', 'Alexanderplatz 7', '+49 30 12345678', 'pass123word', '2024-06-03 06:15:00', '2024-06-09 17:41:46', '0000-00-00 00:00:00', 1),
(8, 'Jennifer', 'Lopez', 'jennifer.lopez@abc.com', '1975-09-05', 'FEMALE', 'France', 'Île-de-France', '75001', 'Champs-Élysées', '+33 1 2345 6789', 'securepassword', '2024-06-02 15:30:00', '2024-06-09 17:41:46', '0000-00-00 00:00:00', 1),
(9, 'Christopher', 'Lee', 'christopher.lee@abc.com', '1980-11-23', 'MALE', 'Japan', 'Tokyo', '100-0005', '2 Chome-2-1 Nihonbashimuromachi', '+81 3-1234-5678', 'password123!', '2024-06-01 09:20:00', '2024-06-09 17:41:46', '0000-00-00 00:00:00', 1),
(10, 'Amanda', 'Taylor', 'amanda.taylor@abc.com', '1998-02-10', 'FEMALE', 'Spain', 'Madrid', '28001', 'Gran Vía', '+34 91 234 56 78', 'password456', '2024-05-31 07:40:00', '2024-06-09 17:41:46', '0000-00-00 00:00:00', 1);

-- --------------------------------------------------------

--
-- Table structure for table `images`
--

CREATE TABLE `images` (
  `id` bigint(20) NOT NULL,
  `title` varchar(100) DEFAULT NULL,
  `image_url` varchar(150) NOT NULL,
  `product_id` bigint(20) DEFAULT NULL,
  `uploaded_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `images`
--

INSERT INTO `images` (`id`, `title`, `image_url`, `product_id`, `uploaded_at`) VALUES
(1, 'Smartphone XYZ Image', 'https://xyzonlineshop.com/images/smartphone_xyz.jpg', 1, '2024-06-09 17:22:40'),
(2, 'Blender Pro 3000 Image', 'https://xyzonlineshop.com/images/blender_pro_3000.jpg', 2, '2024-06-09 17:22:40'),
(3, 'Men\'s Casual Shirt Image', 'https://xyzonlineshop.com/images/mens_casual_shirt.jpg', 3, '2024-06-09 17:22:40'),
(4, 'Luxury Facial Cream Image', 'https://xyzonlineshop.com/images/luxury_facial_cream.jpg', 4, '2024-06-09 17:22:40'),
(5, 'Organic Multivitamins Image', 'https://xyzonlineshop.com/images/organic_multivitamins.jpg', 5, '2024-06-09 17:22:40'),
(6, 'Educational Puzzle Set Image', 'https://xyzonlineshop.com/images/educational_puzzle_set.jpg', 6, '2024-06-09 17:22:40'),
(7, 'Mystery Novel Image', 'https://xyzonlineshop.com/images/mystery_novel.jpg', 7, '2024-06-09 17:22:40'),
(8, 'Yoga Mat Image', 'https://xyzonlineshop.com/images/yoga_mat.jpg', 8, '2024-06-09 17:22:40'),
(9, 'Ergonomic Office Chair Image', 'https://xyzonlineshop.com/images/ergonomic_office_chair.jpg', 9, '2024-06-09 17:22:40'),
(10, 'Baby Stroller Image', 'https://xyzonlineshop.com/images/baby_stroller.jpg', 10, '2024-06-09 17:22:40'),
(11, '4K LED TV Image', 'https://xyzonlineshop.com/images/4k_led_tv.jpg', 11, '2024-06-09 17:22:40'),
(12, 'Stainless Steel Cookware Set Image', 'https://xyzonlineshop.com/images/stainless_steel_cookware_set.jpg', 12, '2024-06-09 17:22:40'),
(13, 'Women\'s Handbag Image', 'https://xyzonlineshop.com/images/womens_handbag.jpg', 13, '2024-06-09 17:22:40'),
(14, 'Electric Toothbrush Image', 'https://xyzonlineshop.com/images/electric_toothbrush.jpg', 14, '2024-06-09 17:22:40'),
(15, 'Adjustable Dumbbells Image', 'https://xyzonlineshop.com/images/adjustable_dumbbells.jpg', 15, '2024-06-09 17:22:40'),
(16, 'Gaming Console Image', 'https://xyzonlineshop.com/images/gaming_console.jpg', 16, '2024-06-09 17:22:40'),
(17, 'Pressure Cooker Image', 'https://xyzonlineshop.com/images/pressure_cooker.jpg', 17, '2024-06-09 17:22:40'),
(18, 'Designer Jeans Image', 'https://xyzonlineshop.com/images/designer_jeans.jpg', 18, '2024-06-09 17:22:40'),
(19, 'Hair Dryer Image', 'https://xyzonlineshop.com/images/hair_dryer.jpg', 19, '2024-06-09 17:22:40'),
(20, 'Fitness Tracker Image', 'https://xyzonlineshop.com/images/fitness_tracker.jpg', 20, '2024-06-09 17:22:40'),
(21, 'Smartphone XYZ Image 2', 'https://xyzonlineshop.com/images/smartphone_xyz_2.jpg', 1, '2024-06-09 17:22:40');

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `id` bigint(20) NOT NULL,
  `total_amount` decimal(10,2) DEFAULT NULL,
  `order_status` enum('PENDING','CONFIRMED','PROCESSING','SHIPPED','DELIVERED','CANCELLED','RETURNED','REFUNDED','FAILED','ON_HOLD') NOT NULL,
  `comment` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE current_timestamp(),
  `customer_id` bigint(20) DEFAULT NULL,
  `currency_id` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`id`, `total_amount`, `order_status`, `comment`, `created_at`, `updated_at`, `customer_id`, `currency_id`) VALUES
(1, 479.97, 'PROCESSING', 'Please expedite delivery', '2022-03-18 15:55:51', '2024-06-12 23:37:27', 1, 1),
(2, 59.98, 'SHIPPED', 'Delivery completed successfully', '2023-07-01 22:56:01', '2024-06-12 23:37:27', 2, 1),
(3, 159.98, 'DELIVERED', 'Customer satisfied with product quality', '2023-09-03 22:15:03', '2024-06-12 23:37:27', 3, 1),
(4, 259.96, 'PROCESSING', 'Urgent delivery requested, awaiting confirmation', '2023-06-04 18:49:42', '2024-06-12 23:37:27', 2, 1),
(5, 749.98, 'SHIPPED', 'Order dispatched, tracking number: 987654321', '2024-05-22 03:45:50', '2024-06-12 23:37:27', 5, 1),
(6, 35.99, 'PENDING', 'Order processing initiated', '2021-09-30 10:42:36', '2024-06-12 23:37:27', 6, 1),
(7, 269.97, 'CANCELLED', 'Customer decided to cancel the order', '2022-01-27 19:38:00', '2024-06-12 23:37:27', 7, 1),
(8, 1149.97, 'PROCESSING', 'Preparing items for shipment', '2023-06-02 13:24:40', '2024-06-12 23:37:27', 7, 1),
(9, 764.96, 'SHIPPED', 'Order on the way to delivery address', '2023-09-06 11:31:48', '2024-06-12 23:37:27', 9, 1),
(10, 49.99, 'PROCESSING', 'Order being processed, estimated delivery date provided', '2023-09-13 17:47:34', '2024-06-12 23:37:27', 7, 1),
(11, 19.99, 'PROCESSING', 'Order received, processing started', '2023-01-05 07:44:52', '2024-06-12 23:37:27', 1, 1),
(12, 49.99, 'SHIPPED', 'Out for delivery, tracking number: 123456789', '2022-04-01 04:44:09', '2024-06-12 23:37:27', 2, 1),
(13, 819.97, 'DELIVERED', 'Product delivered, thank you for your purchase', '2023-03-26 03:48:41', '2024-06-12 23:37:27', 3, 1),
(14, 0.00, 'PROCESSING', 'Expedite this order, customer request', '2022-03-23 06:13:27', '2024-06-12 23:37:27', 4, 1),
(15, 399.99, 'PENDING', 'Awaiting payment confirmation', '2022-06-14 15:03:41', '2024-06-12 23:37:27', 5, 1),
(16, 0.00, 'PROCESSING', 'Items picked, packing in progress', '2023-11-17 13:00:36', '2024-06-12 23:37:27', 6, 1),
(17, 399.99, 'CANCELLED', 'Order cancelled by customer', '2022-02-09 16:14:24', '2024-06-12 23:37:27', 7, 1),
(18, 0.00, 'PROCESSING', 'Order confirmed, preparing for shipment', '2022-09-05 16:32:44', '2024-06-12 23:37:27', 8, 1),
(19, 184.98, 'SHIPPED', 'Dispatched, tracking number: 987654321', '2022-08-14 13:22:59', '2024-06-12 23:37:27', 9, 1),
(20, 0.00, 'DELIVERED', 'Delivered, customer satisfied', '2023-05-06 17:39:12', '2024-06-12 23:37:27', 10, 1),
(21, 1279.92, 'PROCESSING', 'Processing order, estimated delivery next week', '2024-06-02 00:29:31', '2024-06-12 23:37:27', 1, 1),
(22, 0.00, 'SHIPPED', 'Shipped, on the way', '2022-02-18 22:52:31', '2024-06-12 23:37:27', 2, 1),
(23, 179.98, 'PENDING', 'Payment pending, awaiting confirmation', '2023-12-03 13:16:32', '2024-06-12 23:37:27', 3, 1),
(24, 379.97, 'DELIVERED', 'Delivered, feedback received', '2023-04-12 20:07:35', '2024-06-12 23:37:27', 4, 1),
(25, 179.98, 'PROCESSING', 'Order processing, packaging in progress', '2022-12-02 17:10:48', '2024-06-12 23:37:27', 5, 1),
(26, 24.99, 'PROCESSING', 'Order received, in progress', '2023-01-19 21:53:47', '2024-06-12 23:37:27', 6, 1),
(27, 579.97, 'SHIPPED', 'Shipped, tracking number: 123789456', '2022-01-19 09:18:59', '2024-06-12 23:37:27', 7, 1),
(28, 599.96, 'CANCELLED', 'Cancelled by customer, refund initiated', '2022-02-16 04:16:03', '2024-06-12 23:37:27', 8, 1),
(29, 471.97, 'PROCESSING', 'Processing, expected to ship soon', '2022-10-09 15:45:50', '2024-06-12 23:37:27', 9, 1),
(30, 259.98, 'DELIVERED', 'Delivered, thank you for shopping', '2023-01-11 22:23:29', '2024-06-12 23:37:27', 10, 1);

-- --------------------------------------------------------

--
-- Table structure for table `order_segments`
--

CREATE TABLE `order_segments` (
  `product_id` bigint(20) NOT NULL,
  `order_id` bigint(20) NOT NULL,
  `quantity` int(11) NOT NULL,
  `total_price` decimal(10,2) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE current_timestamp(),
  `currency_id` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `order_segments`
--

INSERT INTO `order_segments` (`product_id`, `order_id`, `quantity`, `total_price`, `created_at`, `updated_at`, `currency_id`) VALUES
(1, 9, 1, 699.99, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(2, 25, 2, 179.98, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(3, 2, 2, 59.98, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(3, 4, 1, 29.99, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(3, 21, 2, 59.98, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(4, 10, 1, 49.99, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(4, 12, 1, 49.99, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(4, 28, 1, 49.99, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(5, 11, 1, 19.99, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(5, 13, 1, 19.99, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(5, 23, 1, 19.99, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(6, 9, 2, 49.98, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(6, 19, 1, 24.99, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(6, 21, 2, 49.98, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(6, 26, 1, 24.99, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(6, 28, 2, 49.98, '2024-06-10 22:06:50', '2024-06-10 22:11:21', 1),
(7, 9, 1, 14.99, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(8, 4, 2, 79.98, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(8, 21, 1, 39.99, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(9, 30, 2, 259.98, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(10, 5, 1, 249.99, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(11, 5, 1, 499.99, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(11, 8, 2, 999.98, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(11, 21, 2, 999.98, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(11, 28, 1, 499.99, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(12, 19, 1, 159.99, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(12, 23, 1, 159.99, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(13, 27, 2, 179.98, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(15, 4, 1, 149.99, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(15, 8, 1, 149.99, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(15, 24, 2, 299.98, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(16, 13, 2, 799.98, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(16, 15, 1, 399.99, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(16, 17, 1, 399.99, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(16, 27, 1, 399.99, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(16, 29, 1, 399.99, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(18, 3, 2, 159.98, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(18, 24, 1, 79.99, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(19, 29, 2, 71.98, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1),
(20, 21, 1, 129.99, '2024-06-10 22:08:27', '2024-06-10 22:11:21', 1);

-- --------------------------------------------------------

--
-- Table structure for table `products`
--

CREATE TABLE `products` (
  `id` bigint(20) NOT NULL,
  `name` varchar(50) NOT NULL,
  `description` text DEFAULT NULL,
  `price` decimal(10,2) NOT NULL,
  `stock_quantity` int(11) NOT NULL DEFAULT 0,
  `category_id` bigint(20) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE current_timestamp(),
  `currency_id` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `products`
--

INSERT INTO `products` (`id`, `name`, `description`, `price`, `stock_quantity`, `category_id`, `created_at`, `updated_at`, `currency_id`) VALUES
(1, 'Smartphone XYZ', 'Latest model with advanced features', 699.99, 99, 1, '2024-06-09 17:13:50', '2024-06-09 23:59:10', 1),
(2, 'Blender Pro 3000', 'High-speed blender for smoothies and more', 89.99, 128, 2, '2024-06-09 17:13:50', '2024-06-09 23:59:10', 1),
(3, 'Men\'s Casual Shirt', 'Comfortable and stylish casual shirt', 29.99, 158, 3, '2024-06-09 17:13:50', '2024-06-09 23:59:10', 1),
(4, 'Luxury Facial Cream', 'Anti-aging cream with natural ingredients', 49.99, 124, 4, '2024-06-09 17:13:50', '2024-06-09 23:59:10', 1),
(5, 'Organic Multivitamins', 'Daily vitamins for overall health', 19.99, 60, 5, '2024-06-09 17:13:50', '2024-06-09 23:59:10', 1),
(6, 'Educational Puzzle Set', 'Fun and educational puzzles for kids', 24.99, 55, 6, '2024-06-09 17:13:50', '2024-06-09 23:59:10', 1),
(7, 'Mystery Novel', 'Gripping mystery novel with unexpected twists', 14.99, 28, 7, '2024-06-09 17:13:50', '2024-06-09 23:59:10', 1),
(8, 'Yoga Mat', 'Non-slip yoga mat for all types of workouts', 39.99, 91, 8, '2024-06-09 17:13:50', '2024-06-09 23:59:10', 1),
(9, 'Ergonomic Office Chair', 'Comfortable office chair with lumbar support', 129.99, 55, 9, '2024-06-09 17:13:50', '2024-06-09 23:59:10', 1),
(10, 'Baby Stroller', 'Lightweight and durable baby stroller', 249.99, 69, 10, '2024-06-09 17:13:50', '2024-06-09 23:59:10', 1),
(11, '4K LED TV', 'Ultra HD 4K television with smart features', 499.99, 38, 1, '2024-06-09 17:13:50', '2024-06-09 23:59:10', 1),
(12, 'Stainless Steel Cookware Set', 'Premium cookware set with non-stick coating', 159.99, 21, 2, '2024-06-09 17:13:50', '2024-06-09 23:59:10', 1),
(13, 'Women\'s Handbag', 'Stylish handbag for all occasions', 89.99, 94, 3, '2024-06-09 17:13:50', '2024-06-09 23:59:10', 1),
(14, 'Electric Toothbrush', 'Rechargeable electric toothbrush with multiple modes', 59.99, 67, 4, '2024-06-09 17:13:50', '2024-06-09 23:59:10', 1),
(15, 'Adjustable Dumbbells', 'Set of adjustable dumbbells for home workouts', 149.99, 20, 8, '2024-06-09 17:13:50', '2024-06-09 23:59:10', 1),
(16, 'Gaming Console', 'Next-gen gaming console with 4K support', 399.99, 98, 1, '2024-06-09 17:13:50', '2024-06-09 23:59:10', 1),
(17, 'Pressure Cooker', 'Electric pressure cooker with multiple settings', 99.99, 93, 2, '2024-06-09 17:13:50', '2024-06-09 23:59:10', 1),
(18, 'Designer Jeans', 'High-quality designer jeans for everyday wear', 79.99, 81, 3, '2024-06-09 17:13:50', '2024-06-09 23:59:10', 1),
(19, 'Hair Dryer', 'Powerful hair dryer with ionic technology', 35.99, 92, 4, '2024-06-09 17:13:50', '2024-06-09 23:59:10', 1),
(20, 'Fitness Tracker', 'Advanced fitness tracker with heart rate monitor', 129.99, 27, 5, '2024-06-09 17:13:50', '2024-06-09 23:59:10', 1);

-- --------------------------------------------------------

--
-- Table structure for table `product_suppliers`
--

CREATE TABLE `product_suppliers` (
  `product_id` bigint(20) NOT NULL,
  `supplier_id` bigint(20) NOT NULL,
  `quantity` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `product_suppliers`
--

INSERT INTO `product_suppliers` (`product_id`, `supplier_id`, `quantity`) VALUES
(1, 2, 88),
(1, 4, 11),
(2, 2, 79),
(2, 3, 49),
(3, 2, 60),
(3, 6, 98),
(4, 5, 45),
(4, 8, 79),
(5, 1, 15),
(5, 7, 45),
(6, 7, 55),
(7, 5, 28),
(8, 11, 91),
(9, 4, 55),
(10, 8, 69),
(11, 4, 38),
(12, 8, 21),
(13, 9, 94),
(14, 7, 67),
(15, 7, 20),
(16, 6, 98),
(17, 9, 93),
(18, 6, 81),
(19, 8, 92),
(20, 7, 27);

-- --------------------------------------------------------

--
-- Table structure for table `product_tags`
--

CREATE TABLE `product_tags` (
  `product_id` bigint(20) NOT NULL,
  `tag_id` bigint(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `product_tags`
--

INSERT INTO `product_tags` (`product_id`, `tag_id`) VALUES
(1, 1),
(2, 2),
(3, 18),
(4, 7),
(5, 10),
(6, 11),
(7, 13),
(8, 17),
(9, 18),
(10, 21);

-- --------------------------------------------------------

--
-- Table structure for table `returned_orders`
--

CREATE TABLE `returned_orders` (
  `id` bigint(20) NOT NULL,
  `product_id` bigint(20) DEFAULT NULL,
  `order_id` bigint(20) DEFAULT NULL,
  `quantity` int(11) NOT NULL CHECK (`quantity` > 0),
  `returned_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `reason` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `returned_orders`
--

INSERT INTO `returned_orders` (`id`, `product_id`, `order_id`, `quantity`, `returned_date`, `reason`) VALUES
(1, 5, 13, 1, '2024-06-10 22:39:54', 'I\'m returning the Organic Multivitamin as it has expired.'),
(2, 15, 24, 2, '2024-06-10 22:39:54', 'Returning the Dumbbell as it is not functioning properly.');

-- --------------------------------------------------------

--
-- Table structure for table `suppliers`
--

CREATE TABLE `suppliers` (
  `id` bigint(20) NOT NULL,
  `company_name` varchar(50) NOT NULL,
  `contact_name` varchar(50) NOT NULL,
  `contact_title` varchar(50) DEFAULT NULL,
  `email` varchar(50) DEFAULT NULL,
  `website` varchar(100) DEFAULT NULL,
  `description` varchar(50) DEFAULT NULL,
  `country` varchar(30) NOT NULL,
  `state` varchar(20) DEFAULT NULL,
  `post_code` varchar(20) DEFAULT NULL,
  `address` varchar(100) DEFAULT NULL,
  `phone_no` varchar(20) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE current_timestamp(),
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `suppliers`
--

INSERT INTO `suppliers` (`id`, `company_name`, `contact_name`, `contact_title`, `email`, `website`, `description`, `country`, `state`, `post_code`, `address`, `phone_no`, `created_at`, `updated_at`, `is_active`) VALUES
(1, 'Tech Solutions Inc.', 'Alice Johnson', 'Sales Manager', 'alice.johnson@techsolutions.com', 'http://www.techsolutions.com', 'Leading provider of tech gadgets and solutions.', 'USA', 'California', '90001', '123 Tech Avenue, Los Angeles', '+1-310-555-1234', '2024-06-09 16:27:18', '0000-00-00 00:00:00', 1),
(2, 'Home Comforts Ltd.', 'Bob Smith', 'Purchasing Coordinator', 'bob.smith@homecomforts.com', 'http://www.homecomforts.com', 'Supplier of home and kitchen appliances.', 'USA', 'New York', '10001', '456 Home Street, New York', '+1-212-555-5678', '2024-06-09 16:27:18', '0000-00-00 00:00:00', 1),
(3, 'Fashion Forward', 'Catherine Lee', 'Fashion Director', 'catherine.lee@fashionforward.com', 'http://www.fashionforward.com', 'Trendy and sustainable fashion clothing.', 'USA', 'Texas', '73301', '789 Fashion Blvd, Austin', '+1-512-555-7890', '2024-06-09 16:27:18', '0000-00-00 00:00:00', 1),
(4, 'Beauty Bliss', 'David Kim', 'Marketing Manager', 'david.kim@beautybliss.com', 'http://www.beautybliss.com', 'Organic and natural beauty products.', 'Canada', 'Ontario', 'M4B 1B4', '101 Beauty Lane, Toronto', '+1-416-555-1010', '2024-06-09 16:27:18', '0000-00-00 00:00:00', 1),
(5, 'Wellness World', 'Eva Green', 'Product Specialist', 'eva.green@wellnessworld.com', 'http://www.wellnessworld.com', 'Health and wellness products for a balanced life.', 'Canada', 'British Columbia', 'V5K 0A1', '202 Wellness Road, Vancouver', '+1-604-555-2020', '2024-06-09 16:27:18', '0000-00-00 00:00:00', 1),
(6, 'Toy Universe', 'Frank Miller', 'Product Manager', 'frank.miller@toyuniverse.com', 'http://www.toyuniverse.com', 'Educational and fun toys for all ages.', 'UK', 'England', 'EC1A 1BB', '303 Toy Street, London', '+44-20-5555-3030', '2024-06-09 16:27:18', '0000-00-00 00:00:00', 1),
(7, 'Media Marvels', 'Grace White', 'Content Director', 'grace.white@mediamarvels.com', 'http://www.mediamarvels.com', 'Diverse selection of books, music, and movies.', 'UK', 'Scotland', 'EH1 1YS', '404 Media Road, Edinburgh', '+44-131-5555-4040', '2024-06-09 16:27:18', '0000-00-00 00:00:00', 1),
(8, 'Outdoor Adventures', 'Henry Black', 'Operations Manager', 'henry.black@outdooradventures.com', 'http://www.outdooradventures.com', 'Gear and apparel for outdoor sports.', 'Australia', 'New South Wales', '2000', '505 Adventure Lane, Sydney', '+61-2-5555-5050', '2024-06-09 16:27:18', '0000-00-00 00:00:00', 1),
(9, 'Office Essentials', 'Ivy Brown', 'Procurement Specialist', 'ivy.brown@officeessentials.com', 'http://www.officeessentials.com', 'Supplies for a productive office environment.', 'Australia', 'Victoria', '3000', '606 Office Park, Melbourne', '+61-3-5555-6060', '2024-06-09 16:27:18', '0000-00-00 00:00:00', 1),
(10, 'Pet Paradise', 'Jack Wilson', 'Pet Care Advisor', 'jack.wilson@petparadise.com', 'http://www.petparadise.com', 'Health and fun products for pets.', 'New Zealand', 'Auckland', '1010', '707 Pet Street, Auckland', '+64-9-5555-7070', '2024-06-09 16:27:18', '0000-00-00 00:00:00', 1),
(11, 'Tiny Tots Ltd.', 'Emma Wilson', 'Product Manager', 'emma.wilson@tinytots.com', 'http://www.tinytots.com', 'Supplier of baby products and accessories.', 'USA', 'California', '90001', '123 Baby Avenue, Los Angeles', '+1-310-555-1234', '2024-06-09 16:27:18', '0000-00-00 00:00:00', 1);

-- --------------------------------------------------------

--
-- Table structure for table `tags`
--

CREATE TABLE `tags` (
  `id` bigint(20) NOT NULL,
  `tag_name` varchar(50) NOT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tags`
--

INSERT INTO `tags` (`id`, `tag_name`, `description`) VALUES
(1, '#SmartDevices', 'Innovative and connected gadgets that enhance your lifestyle'),
(2, '#PortableTech', 'Compact and mobile electronics for on-the-go use'),
(3, '#SmartHome', 'Advanced appliances and devices to automate and enhance your home'),
(4, '#EcoFriendly', 'Environmentally conscious products for a sustainable home'),
(5, '#Streetwear', 'Trendy and casual urban fashion styles'),
(6, '#EcoFashion', 'Sustainable and eco-friendly clothing options'),
(7, '#OrganicBeauty', 'Natural and organic beauty products free from harmful chemicals'),
(8, '#AntiAging', 'Products designed to reduce signs of aging and promote youthful skin'),
(9, '#FitnessGear', 'Equipment and accessories to support your workout routines'),
(10, '#HolisticHealth', 'Products promoting overall wellness through natural methods'),
(11, '#STEMToys', 'Educational toys that focus on science, technology, engineering, and math'),
(12, '#OutdoorFun', 'Toys and games designed for outdoor play and activities'),
(13, '#Bestsellers', 'Popular and widely acclaimed books across various genres'),
(14, '#NewReleases', 'Recently published books and latest media arrivals'),
(15, '#CampingGear', 'Essential equipment and supplies for camping trips'),
(16, '#FitnessApparel', 'Clothing designed for comfort and performance during physical activities'),
(17, '#Ergonomic', 'Products designed to improve comfort and efficiency in the workplace'),
(18, '#Organization', 'Tools and supplies to keep your office neat and well-ordered'),
(19, '#PetHealth', 'Products that promote the health and well-being of your pets'),
(20, '#PetToys', 'Engaging and fun toys to keep your pets entertained'),
(21, '#OrganicBaby', 'Natural and safe products for babies, free from harmful chemicals'),
(22, '#BabyEssentials', 'Must-have items for newborns and toddlers, including clothing and accessories');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `comments`
--
ALTER TABLE `comments`
  ADD PRIMARY KEY (`customer_id`,`product_id`,`order_id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `order_id` (`order_id`);

--
-- Indexes for table `currencies`
--
ALTER TABLE `currencies`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `customers`
--
ALTER TABLE `customers`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `images`
--
ALTER TABLE `images`
  ADD PRIMARY KEY (`id`),
  ADD KEY `images_ibfk_1` (`product_id`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`),
  ADD KEY `customer_id` (`customer_id`),
  ADD KEY `currency_id` (`currency_id`);

--
-- Indexes for table `order_segments`
--
ALTER TABLE `order_segments`
  ADD PRIMARY KEY (`product_id`,`order_id`),
  ADD KEY `currency_id` (`currency_id`),
  ADD KEY `ordersegments_ibfk_2` (`order_id`);

--
-- Indexes for table `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`id`),
  ADD KEY `currency_id` (`currency_id`),
  ADD KEY `products_ibfk_1` (`category_id`);

--
-- Indexes for table `product_suppliers`
--
ALTER TABLE `product_suppliers`
  ADD PRIMARY KEY (`product_id`,`supplier_id`),
  ADD KEY `supplier_id` (`supplier_id`);

--
-- Indexes for table `product_tags`
--
ALTER TABLE `product_tags`
  ADD PRIMARY KEY (`product_id`,`tag_id`),
  ADD KEY `tag_id` (`tag_id`);

--
-- Indexes for table `returned_orders`
--
ALTER TABLE `returned_orders`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `order_id` (`order_id`);

--
-- Indexes for table `suppliers`
--
ALTER TABLE `suppliers`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tags`
--
ALTER TABLE `tags`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `categories`
--
ALTER TABLE `categories`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `currencies`
--
ALTER TABLE `currencies`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT for table `customers`
--
ALTER TABLE `customers`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `images`
--
ALTER TABLE `images`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- AUTO_INCREMENT for table `products`
--
ALTER TABLE `products`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT for table `returned_orders`
--
ALTER TABLE `returned_orders`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `suppliers`
--
ALTER TABLE `suppliers`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `tags`
--
ALTER TABLE `tags`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `comments`
--
ALTER TABLE `comments`
  ADD CONSTRAINT `comments_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `comments_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `comments_ibfk_3` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `images`
--
ALTER TABLE `images`
  ADD CONSTRAINT `images_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`currency_id`) REFERENCES `currencies` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `order_segments`
--
ALTER TABLE `order_segments`
  ADD CONSTRAINT `order_segments_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `order_segments_ibfk_2` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `order_segments_ibfk_3` FOREIGN KEY (`currency_id`) REFERENCES `currencies` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `products`
--
ALTER TABLE `products`
  ADD CONSTRAINT `products_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `products_ibfk_2` FOREIGN KEY (`currency_id`) REFERENCES `currencies` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `product_suppliers`
--
ALTER TABLE `product_suppliers`
  ADD CONSTRAINT `product_suppliers_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `product_suppliers_ibfk_2` FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `product_tags`
--
ALTER TABLE `product_tags`
  ADD CONSTRAINT `product_tags_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `product_tags_ibfk_2` FOREIGN KEY (`tag_id`) REFERENCES `tags` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `returned_orders`
--
ALTER TABLE `returned_orders`
  ADD CONSTRAINT `returned_orders_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `returned_orders_ibfk_3` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
