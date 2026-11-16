-- ============================================================================
-- CAR RENTAL MANAGEMENT SYSTEM | DBMS CAPSTONE PROJECT
-- Database: MySQL 8.0+ | Storage Engine: InnoDB
-- Core tables: branches, customers, cars, rentals, maintenance
--
-- EXECUTION ORDER
-- 1. Schema creation
-- 2. Sample data
-- 3. CRUD operations
-- 4. Business queries
-- 5. Indexing and EXPLAIN
-- 6. Views and view updates
-- 7. Window functions
-- 8. Stored procedures and triggers
--
-- IMPORTANT SAFETY NOTICE
-- The schema section drops and recreates the five project tables. The seed-data
-- section truncates those tables before inserting its sample records. Running
-- this script against an existing database will permanently remove its current
-- contents. Back up important data first. Run this in a dedicated test schema.
--
-- This file combines the eight project SQL scripts in their documented order.
-- It has not been executed against your local MySQL server in this session.
-- ============================================================================



==============================================================================
-- START OF 01_schema.sql
==============================================================================

-- ============================================================================
-- Car Rental Management System (MySQL 8.0+)
-- B.Tech CSE Data Science - DBMS Capstone Project
-- File: 01_schema.sql
-- Description: DDL Schema definition with exactly 5 core normalized tables,
--              integrity constraints, foreign keys, and CHECK validations.
-- ============================================================================

-- Step 1: Create Database and Set Context
CREATE DATABASE IF NOT EXISTS car_rental_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE car_rental_db;

-- Step 2: Drop Tables in reverse dependency order (Foreign Key safety)
DROP TABLE IF EXISTS maintenance;
DROP TABLE IF EXISTS rentals;
DROP TABLE IF EXISTS cars;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS branches;

-- ============================================================================
-- TABLE 1: branches
-- Purpose: Manages physical rental stations, fleet locations, and contact info.
-- ============================================================================
CREATE TABLE branches (
    branch_id INT AUTO_INCREMENT PRIMARY KEY,
    branch_name VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    address VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_branches_phone UNIQUE (phone),
    CONSTRAINT chk_branches_name_not_empty CHECK (CHAR_LENGTH(TRIM(branch_name)) > 0),
    CONSTRAINT chk_branches_city_not_empty CHECK (CHAR_LENGTH(TRIM(city)) > 0)
) ENGINE=InnoDB;

-- ============================================================================
-- TABLE 2: customers
-- Purpose: Stores registered client profiles, unique driver license numbers,
--          and affiliations to preferred/home branches.
-- ============================================================================
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL,
    license_number VARCHAR(50) NOT NULL,
    home_branch_id INT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_customers_email UNIQUE (email),
    CONSTRAINT uq_customers_license UNIQUE (license_number),
    CONSTRAINT uq_customers_phone UNIQUE (phone),
    CONSTRAINT chk_customers_email_format CHECK (email LIKE '%_@__%.__%'),
    CONSTRAINT chk_customers_first_name CHECK (CHAR_LENGTH(TRIM(first_name)) > 0),
    CONSTRAINT chk_customers_last_name CHECK (CHAR_LENGTH(TRIM(last_name)) > 0),
    CONSTRAINT fk_customers_home_branch 
        FOREIGN KEY (home_branch_id) 
        REFERENCES branches(branch_id)
        ON UPDATE CASCADE 
        ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================================
-- TABLE 3: cars
-- Purpose: Fleet inventory holding vehicle details, current branch location,
--          vehicle category, daily pricing, odometer mileage, and operational status.
-- Note: As specified, category and daily_rate are stored directly in this table.
-- ============================================================================
CREATE TABLE cars (
    car_id INT AUTO_INCREMENT PRIMARY KEY,
    branch_id INT NOT NULL,
    registration_number VARCHAR(20) NOT NULL,
    make VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    category VARCHAR(30) NOT NULL,
    daily_rate DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE',
    year_of_manufacture INT NOT NULL,
    mileage INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_cars_registration UNIQUE (registration_number),
    CONSTRAINT chk_cars_daily_rate CHECK (daily_rate > 0.00),
    CONSTRAINT chk_cars_mileage CHECK (mileage >= 0),
    CONSTRAINT chk_cars_year CHECK (year_of_manufacture >= 2000 AND year_of_manufacture <= 2030),
    CONSTRAINT chk_cars_status CHECK (status IN ('AVAILABLE', 'RENTED', 'MAINTENANCE', 'DECOMMISSIONED')),
    CONSTRAINT chk_cars_category CHECK (category IN ('SEDAN', 'SUV', 'LUXURY', 'ELECTRIC', 'HATCHBACK', 'TRUCK')),
    CONSTRAINT fk_cars_branch 
        FOREIGN KEY (branch_id) 
        REFERENCES branches(branch_id)
        ON UPDATE CASCADE 
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================================
-- TABLE 4: rentals
-- Purpose: Records rental bookings, active trips, actual return dates, contractual
--          daily rates, late return penalties, and final aggregated charges.
-- ============================================================================
CREATE TABLE rentals (
    rental_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    car_id INT NOT NULL,
    pickup_date DATE NOT NULL,
    expected_return_date DATE NOT NULL,
    actual_return_date DATE NULL,
    daily_rate DECIMAL(10, 2) NOT NULL,
    late_fee_per_day DECIMAL(10, 2) NOT NULL DEFAULT 25.00,
    total_amount DECIMAL(10, 2) NULL,
    rental_status VARCHAR(20) NOT NULL DEFAULT 'BOOKED',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_rentals_dates CHECK (expected_return_date >= pickup_date),
    CONSTRAINT chk_rentals_actual_return CHECK (actual_return_date IS NULL OR actual_return_date >= pickup_date),
    CONSTRAINT chk_rentals_daily_rate CHECK (daily_rate > 0.00),
    CONSTRAINT chk_rentals_late_fee CHECK (late_fee_per_day >= 0.00),
    CONSTRAINT chk_rentals_total_amount CHECK (total_amount IS NULL OR total_amount >= 0.00),
    CONSTRAINT chk_rentals_status CHECK (rental_status IN ('BOOKED', 'ACTIVE', 'COMPLETED', 'CANCELLED')),
    CONSTRAINT fk_rentals_customer 
        FOREIGN KEY (customer_id) 
        REFERENCES customers(customer_id)
        ON UPDATE CASCADE 
        ON DELETE RESTRICT,
    CONSTRAINT fk_rentals_car 
        FOREIGN KEY (car_id) 
        REFERENCES cars(car_id)
        ON UPDATE CASCADE 
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================================
-- TABLE 5: maintenance
-- Purpose: Tracks vehicle servicing logs, preventive inspections, repair costs,
--          out-of-service periods, and garage workshop records.
-- ============================================================================
CREATE TABLE maintenance (
    maintenance_id INT AUTO_INCREMENT PRIMARY KEY,
    car_id INT NOT NULL,
    service_type VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    completion_date DATE NULL,
    cost DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    description TEXT,
    maintenance_status VARCHAR(20) NOT NULL DEFAULT 'SCHEDULED',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_maint_dates CHECK (completion_date IS NULL OR completion_date >= start_date),
    CONSTRAINT chk_maint_cost CHECK (cost >= 0.00),
    CONSTRAINT chk_maint_status CHECK (maintenance_status IN ('SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
    CONSTRAINT fk_maintenance_car 
        FOREIGN KEY (car_id) 
        REFERENCES cars(car_id)
        ON UPDATE CASCADE 
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Verify table creation
SHOW TABLES;

-- END OF 01_schema.sql


==============================================================================
-- START OF 02_seed_data.sql
==============================================================================

-- ============================================================================
-- Car Rental Management System (MySQL 8.0+)
-- B.Tech CSE Data Science - DBMS Capstone Project
-- File: 02_seed_data.sql
-- Description: Comprehensive, normalized, and realistic test dataset.
-- ============================================================================

USE car_rental_db;

-- Disable Foreign Key checks for clean insertion and resetting
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE maintenance;
TRUNCATE TABLE rentals;
TRUNCATE TABLE cars;
TRUNCATE TABLE customers;
TRUNCATE TABLE branches;
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
-- 1. SEED DATA: branches
-- ============================================================================
INSERT INTO branches (branch_id, branch_name, city, address, phone) VALUES
(1, 'Downtown Financial Center', 'New York', '120 Broadway, Suite 400', '212-555-0101'),
(2, 'JFK International Airport Hub', 'Queens', 'Terminal 4 Ground Transportation', '718-555-0144'),
(3, 'Brooklyn Bay Ridge Station', 'Brooklyn', '86th St & 4th Ave', '718-555-0199'),
(4, 'O-Hare Terminal 2 Express', 'Chicago', '10000 W O-Hare Ave', '312-555-0220'),
(5, 'Loop Commercial District', 'Chicago', '200 N Michigan Ave', '312-555-0255');

-- ============================================================================
-- 2. SEED DATA: customers
-- ============================================================================
INSERT INTO customers (customer_id, first_name, last_name, phone, email, license_number, home_branch_id, created_at) VALUES
(1,  'Alice',   'Morgan',    '212-555-1111', 'alice.morgan@example.com',    'DL-NY-849201', 1, '2024-01-10 09:30:00'),
(2,  'Bob',     'Smith',     '212-555-2222', 'bob.smith@example.com',       'DL-NY-918234', 1, '2024-01-15 11:00:00'),
(3,  'Charlie', 'Davis',     '718-555-3333', 'charlie.davis@example.com',   'DL-NY-384729', 2, '2024-02-01 10:15:00'),
(4,  'Diana',   'Prince',    '718-555-4444', 'diana.prince@example.com',    'DL-NY-492817', 2, '2024-02-12 14:20:00'),
(5,  'Evan',    'Wright',    '718-555-5555', 'evan.wright@example.com',     'DL-NY-671928', 3, '2024-03-05 16:45:00'),
(6,  'Fiona',   'Gallagher', '212-555-6666', 'fiona.g@example.com',        'DL-NY-192837', 1, '2024-03-10 12:00:00'),
(7,  'George',  'Miller',    '312-555-7777', 'george.m@example.com',        'DL-IL-582910', 4, '2024-03-18 08:30:00'),
(8,  'Hannah',  'Abbott',    '312-555-8888', 'hannah.a@example.com',        'DL-IL-729104', 5, '2024-03-25 13:40:00'),
(9,  'Ian',     'Malcolm',   '212-555-9999', 'ian.malcolm@example.com',     'DL-NY-839102', 1, '2024-04-02 15:10:00'),
(10, 'Julia',   'Roberts',   '718-555-1010', 'julia.r@example.com',         'DL-NY-472019', 2, '2024-04-10 17:00:00'),
(11, 'Kevin',   'Bacon',     '312-555-2020', 'kevin.bacon@example.com',     'DL-IL-938201', 4, '2024-04-15 11:25:00'),
(12, 'Laura',   'Croft',     '718-555-3030', 'laura.croft@example.com',     'DL-NY-661928', 3, '2024-05-01 09:00:00');

-- ============================================================================
-- 3. SEED DATA: cars
-- Note: Storing category and daily_rate directly in the cars table.
-- ============================================================================
INSERT INTO cars (car_id, branch_id, registration_number, make, model, category, daily_rate, status, year_of_manufacture, mileage) VALUES
-- Sedans
(1,  1, 'NY-SDN-101', 'Toyota',        'Camry',       'SEDAN',    55.00,  'AVAILABLE',      2023, 14200),
(2,  1, 'NY-SDN-102', 'Honda',         'Accord',      'SEDAN',    52.00,  'RENTED',         2022, 19800),
(3,  2, 'NY-SDN-103', 'Hyundai',       'Sonata',      'SEDAN',    48.00,  'AVAILABLE',      2023, 11400),
(4,  4, 'IL-SDN-104', 'Nissan',        'Altima',      'SEDAN',    49.00,  'AVAILABLE',      2022, 23500),

-- SUVs
(5,  1, 'NY-SUV-201', 'Ford',          'Explorer',    'SUV',      85.00,  'AVAILABLE',      2023, 16800),
(6,  2, 'NY-SUV-202', 'Jeep',          'Grand Cher.', 'SUV',      89.00,  'MAINTENANCE',    2022, 28500),
(7,  3, 'NY-SUV-203', 'Toyota',        'Highlander',  'SUV',      92.00,  'RENTED',         2023, 15300),
(8,  5, 'IL-SUV-204', 'Subaru',        'Outback',     'SUV',      78.00,  'AVAILABLE',      2021, 34200),

-- Luxury
(9,  1, 'NY-LUX-301', 'BMW',           '530i',        'LUXURY',   145.00, 'AVAILABLE',      2023, 8900),
(10, 2, 'NY-LUX-302', 'Mercedes-Benz', 'E350',        'LUXURY',   155.00, 'AVAILABLE',      2023, 9400),
(11, 3, 'NY-LUX-303', 'Audi',          'A6',          'LUXURY',   140.00, 'MAINTENANCE',    2022, 22100),
(12, 5, 'IL-LUX-304', 'Genesis',       'G80',         'LUXURY',   130.00, 'AVAILABLE',      2023, 11200),

-- Electric
(13, 1, 'NY-EV-401',  'Tesla',         'Model 3',     'ELECTRIC', 75.00,  'AVAILABLE',      2023, 10500),
(14, 2, 'NY-EV-402',  'Tesla',         'Model Y',     'ELECTRIC', 90.00,  'RENTED',         2023, 12600),
(15, 3, 'NY-EV-403',  'Hyundai',       'Ioniq 5',     'ELECTRIC', 72.00,  'AVAILABLE',      2023, 14900),

-- Decommissioned
(16, 4, 'IL-OLD-999', 'Chevrolet',     'Impala',      'SEDAN',    40.00,  'DECOMMISSIONED', 2012, 185400);

-- ============================================================================
-- 4. SEED DATA: rentals
-- Logic:
-- Total Amount for Completed Rentals = (Days * daily_rate) + (Late Days * late_fee_per_day)
-- ============================================================================
INSERT INTO rentals (rental_id, customer_id, car_id, pickup_date, expected_return_date, actual_return_date, daily_rate, late_fee_per_day, total_amount, rental_status) VALUES
-- 1. Alice Morgan: 3-day on-time rental (Toyota Camry: 3 * 55 = 165.00)
(1,  1, 1,  '2024-01-15', '2024-01-18', '2024-01-18', 55.00, 25.00, 165.00,  'COMPLETED'),

-- 2. Bob Smith: 3-day scheduled, returned 2 days late (BMW 530i: 3*145 + 2*50 late fee = 435 + 100 = 535.00)
(2,  2, 9,  '2024-01-20', '2024-01-23', '2024-01-25', 145.00, 50.00, 535.00, 'COMPLETED'),

-- 3. Alice Morgan: 4-day on-time rental (Ford Explorer: 4 * 85 = 340.00)
(3,  1, 5,  '2024-02-10', '2024-02-14', '2024-02-14', 85.00, 30.00, 340.00,  'COMPLETED'),

-- 4. Fiona Gallagher: 4-day scheduled, 1 day late (Tesla Model 3: 4*75 + 1*35 = 300 + 35 = 335.00)
(4,  6, 13, '2024-02-18', '2024-02-22', '2024-02-23', 75.00, 35.00, 335.00,  'COMPLETED'),

-- 5. Alice Morgan: 4-day on-time rental (Toyota Camry: 4 * 55 = 220.00)
(5,  1, 1,  '2024-03-01', '2024-03-05', '2024-03-05', 55.00, 25.00, 220.00,  'COMPLETED'),

-- 6. Charlie Davis: 3-day on-time rental (Hyundai Sonata: 3 * 48 = 144.00)
(6,  3, 3,  '2024-02-05', '2024-02-08', '2024-02-08', 48.00, 25.00, 144.00,  'COMPLETED'),

-- 7. Diana Prince: 5-day on-time rental (Mercedes E350: 5 * 155 = 775.00)
(7,  4, 10, '2024-02-15', '2024-02-20', '2024-02-20', 155.00, 60.00, 775.00, 'COMPLETED'),

-- 8. Charlie Davis: 2-day on-time rental (Tesla Model Y: 2 * 90 = 180.00)
(8,  3, 14, '2024-03-01', '2024-03-03', '2024-03-03', 90.00, 40.00, 180.00,  'COMPLETED'),

-- 9. Evan Wright: 6-day scheduled, 2 days late (Toyota Highlander: 6*92 + 2*40 = 552 + 80 = 632.00)
(9,  5, 7,  '2024-03-08', '2024-03-14', '2024-03-16', 92.00, 40.00, 632.00,  'COMPLETED'),

-- 10. George Miller: 3-day on-time rental (Nissan Altima: 3 * 49 = 147.00)
(10, 7, 4,  '2024-03-20', '2024-03-23', '2024-03-23', 49.00, 25.00, 147.00,  'COMPLETED'),

-- 11. Hannah Abbott: 4-day on-time rental (Subaru Outback: 4 * 78 = 312.00)
(11, 8, 8,  '2024-03-26', '2024-03-30', '2024-03-30', 78.00, 30.00, 312.00,  'COMPLETED'),

-- 12. Kevin Bacon: 5-day on-time rental (Genesis G80: 5 * 130 = 650.00)
(12, 11, 12, '2024-04-18', '2024-04-23', '2024-04-23', 130.00, 50.00, 650.00, 'COMPLETED'),

-- 13. Active Rental: Fiona Gallagher renting Honda Accord
(13, 6, 2,  '2024-05-10', '2024-05-15', NULL, 52.00, 25.00, NULL, 'ACTIVE'),

-- 14. Active Rental: Laura Croft renting Toyota Highlander
(14, 12, 7, '2024-05-12', '2024-05-17', NULL, 92.00, 40.00, NULL, 'ACTIVE'),

-- 15. Active Rental: Diana Prince renting Tesla Model Y
(15, 4, 14, '2024-05-11', '2024-05-16', NULL, 90.00, 40.00, NULL, 'ACTIVE'),

-- 16. Future Booked Rental: Alice Morgan booking Tesla Model 3
(16, 1, 13, '2024-06-01', '2024-06-05', NULL, 75.00, 35.00, NULL, 'BOOKED'),

-- 17. Future Booked Rental: Bob Smith booking BMW 530i
(17, 2, 9,  '2024-06-02', '2024-06-06', NULL, 145.00, 50.00, NULL, 'BOOKED'),

-- 18. Cancelled Rental: Ian Malcolm cancelled reservation
(18, 9, 5,  '2024-04-05', '2024-04-08', NULL, 85.00, 30.00, 0.00, 'CANCELLED');

-- ============================================================================
-- 5. SEED DATA: maintenance
-- ============================================================================
INSERT INTO maintenance (maintenance_id, car_id, service_type, start_date, completion_date, cost, description, maintenance_status) VALUES
(1,  1,  'Oil & Filter Replacement',  '2024-01-05', '2024-01-05', 85.00,   'Routine 10k mile synthetic oil and filter change', 'COMPLETED'),
(2,  5,  'Brake System Overhaul',     '2024-01-25', '2024-01-27', 380.00,  'Front & rear ceramic brake pads and rotor resurfacing', 'COMPLETED'),
(3,  6,  'Transmission Diagnostics',   '2024-05-08', NULL,         450.00,  'Transmission gear slippage under load check', 'IN_PROGRESS'),
(4,  9,  'Tire Rotation & Balance',   '2024-02-02', '2024-02-02', 120.00,  'Rotated Michelin high-performance run-flat tires', 'COMPLETED'),
(5,  11, 'Suspension Arm Repair',     '2024-05-06', NULL,         620.00,  'Left control arm bushing wear replacement', 'IN_PROGRESS'),
(6,  13, 'HV Battery Health Diagnostic','2024-01-12', '2024-01-12', 150.00, 'Full high-voltage pack health diagnostic (98.4% capacity)', 'COMPLETED'),
(7,  16, 'Safety Airbag Recall Servicing','2023-11-10', '2023-11-12', 0.00, 'Manufacturer recall inspection prior to decommission', 'COMPLETED'),
(8,  3,  'Annual State Inspection',   '2024-06-15', NULL,         75.00,   'Scheduled emissions and mechanical inspection', 'SCHEDULED'),
(9,  8,  'Wheel Alignment & Struts',  '2024-02-20', '2024-02-21', 210.00,  '4-wheel laser alignment and front strut inspection', 'COMPLETED'),
(10, 10, 'Cabin AC Sanitization',     '2024-03-01', '2024-03-01', 95.00,   'HVAC evaporator decontamination and cabin HEPA filter', 'COMPLETED');

-- Summary counts verification
SELECT 'branches' AS entity, COUNT(*) AS record_count FROM branches
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'cars', COUNT(*) FROM cars
UNION ALL
SELECT 'rentals', COUNT(*) FROM rentals
UNION ALL
SELECT 'maintenance', COUNT(*) FROM maintenance;

-- END OF 02_seed_data.sql


==============================================================================
-- START OF 03_crud_operations.sql
==============================================================================

-- ============================================================================
-- Car Rental Management System (MySQL 8.0+)
-- B.Tech CSE Data Science - DBMS Capstone Project
-- File: 03_crud_operations.sql
-- Description: Standard Data Manipulation Language (DML) CRUD scenarios
--              demonstrating ACID compliance, data integrity, and FK protections.
-- ============================================================================

USE car_rental_db;

-- ============================================================================
-- 1. CREATE OPERATIONS (INSERT)
-- ============================================================================

-- (A) Register a new customer
INSERT INTO customers (first_name, last_name, phone, email, license_number, home_branch_id)
VALUES ('Marcus', 'Aurelius', '312-555-4321', 'marcus.a@example.com', 'DL-IL-112233', 4);

-- (B) Add a new fleet vehicle (Category and rate stored directly in cars)
INSERT INTO cars (branch_id, registration_number, make, model, category, daily_rate, status, year_of_manufacture, mileage)
VALUES (1, 'NY-SDN-105', 'Toyota', 'Corolla', 'SEDAN', 45.00, 'AVAILABLE', 2023, 5200);

-- (C) Book a new rental agreement
INSERT INTO rentals (customer_id, car_id, pickup_date, expected_return_date, daily_rate, late_fee_per_day, rental_status)
VALUES (
    (SELECT customer_id FROM customers WHERE email = 'marcus.a@example.com'),
    (SELECT car_id FROM cars WHERE registration_number = 'NY-SDN-105'),
    '2024-07-01',
    '2024-07-05',
    45.00,
    25.00,
    'BOOKED'
);

-- (D) Schedule a new maintenance task
INSERT INTO maintenance (car_id, service_type, start_date, cost, description, maintenance_status)
VALUES (
    (SELECT car_id FROM cars WHERE registration_number = 'NY-SDN-105'),
    'Factory 5,000-Mile Checkup',
    '2024-06-25',
    60.00,
    'Initial break-in inspection and fluid level check',
    'SCHEDULED'
);

-- ============================================================================
-- 2. READ OPERATIONS (SELECT with Filters and Joins)
-- ============================================================================

-- (A) Search active rentals with full customer, vehicle, and branch information
SELECT 
    r.rental_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.phone AS customer_phone,
    v.registration_number,
    CONCAT(v.make, ' ', v.model) AS vehicle,
    v.category,
    b.branch_name AS pickup_branch,
    r.pickup_date,
    r.expected_return_date,
    r.rental_status
FROM rentals r
JOIN customers c ON r.customer_id = c.customer_id
JOIN cars v ON r.car_id = v.car_id
JOIN branches b ON v.branch_id = b.branch_id
WHERE r.rental_status = 'ACTIVE';

-- (B) Find available luxury or electric vehicles in New York branches
SELECT 
    v.car_id,
    v.registration_number,
    v.make,
    v.model,
    v.category,
    v.daily_rate,
    v.mileage,
    b.branch_name,
    b.city
FROM cars v
JOIN branches b ON v.branch_id = b.branch_id
WHERE v.status = 'AVAILABLE'
  AND v.category IN ('LUXURY', 'ELECTRIC')
  AND b.city = 'New York';

-- (C) Inspect ongoing or scheduled maintenance backlog
SELECT 
    m.maintenance_id,
    v.registration_number,
    CONCAT(v.make, ' ', v.model) AS vehicle,
    m.service_type,
    m.start_date,
    m.cost,
    m.maintenance_status
FROM maintenance m
JOIN cars v ON m.car_id = v.car_id
WHERE m.maintenance_status IN ('SCHEDULED', 'IN_PROGRESS')
ORDER BY m.start_date ASC;

-- ============================================================================
-- 3. UPDATE OPERATIONS (UPDATE with Business Logic)
-- ============================================================================

-- (A) Update customer contact information
UPDATE customers
SET phone = '312-555-9876',
    home_branch_id = 5
WHERE email = 'marcus.a@example.com';

-- (B) Complete a rental: Record actual return, calculate late fee and total amount, and update car status
START TRANSACTION;

-- Calculate and finalize rental #13 (Honda Accord returned 1 day overdue)
UPDATE rentals
SET actual_return_date = '2024-05-16',
    total_amount = (
        -- Base charge: 5 days * 52.00 = 260.00
        (DATEDIFF('2024-05-15', pickup_date) * daily_rate) +
        -- Overdue penalty: 1 day late * 25.00 = 25.00 -> Total: 285.00
        (GREATEST(0, DATEDIFF('2024-05-16', expected_return_date)) * late_fee_per_day)
    ),
    rental_status = 'COMPLETED'
WHERE rental_id = 13;

-- Return vehicle to AVAILABLE status and record additional mileage (+340 miles)
UPDATE cars
SET status = 'AVAILABLE',
    mileage = mileage + 340
WHERE car_id = 2;

COMMIT;

-- (C) Complete a maintenance task and return vehicle to service
START TRANSACTION;

UPDATE maintenance
SET completion_date = '2024-05-12',
    cost = 485.00,
    maintenance_status = 'COMPLETED',
    description = CONCAT(description, ' - Replaced valve body solenoid; test drive passed.')
WHERE maintenance_id = 3;

UPDATE cars
SET status = 'AVAILABLE'
WHERE car_id = 6;

COMMIT;

-- ============================================================================
-- 4. DELETE OPERATIONS & REFERENTIAL INTEGRITY PROOFS
-- ============================================================================

-- (A) Safe Deletion: Cancel an unfulfilled booking
DELETE FROM rentals 
WHERE rental_id = 18 AND rental_status = 'CANCELLED';

-- (B) FK Integrity Demonstration:
-- Attempting to delete a customer who has existing rental history.
-- Expected Result in MySQL 8.0:
-- ERROR 1451 (23000): Cannot delete or update a parent row: a foreign key constraint fails (`fk_rentals_customer`)
-- This proves the schema prevents accidental historical data loss!
-- Uncomment to test the constraint:
-- DELETE FROM customers WHERE customer_id = 1;

-- (C) Safe Decommissioning Pattern (Alternative to hard deletion):
UPDATE cars
SET status = 'DECOMMISSIONED'
WHERE car_id = 16;

-- END OF 03_crud_operations.sql


==============================================================================
-- START OF 04_business_queries.sql
==============================================================================

-- ============================================================================
-- Car Rental Management System (MySQL 8.0+)
-- B.Tech CSE Data Science - DBMS Capstone Project
-- File: 04_business_queries.sql
-- Description: Core business logic, pricing computations, overlap detection,
--              fleet ROI analysis, and branch revenue aggregation.
-- ============================================================================

USE car_rental_db;

-- ============================================================================
-- 1. DYNAMIC RENTAL CHARGE AND LATE FEE COMPUTATION
-- ============================================================================
-- Formula:
-- Scheduled Duration = DATEDIFF(expected_return_date, pickup_date)
-- Days Late = GREATEST(0, DATEDIFF(COALESCE(actual_return_date, CURRENT_DATE), expected_return_date))
-- Base Charge = Scheduled Duration * daily_rate
-- Late Penalty = Days Late * late_fee_per_day
-- Computed Total = Base Charge + Late Penalty
SELECT 
    r.rental_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    v.registration_number,
    CONCAT(v.make, ' ', v.model) AS vehicle_name,
    v.category,
    r.pickup_date,
    r.expected_return_date,
    COALESCE(r.actual_return_date, CURRENT_DATE) AS effective_return_date,
    
    -- Duration metrics
    GREATEST(1, DATEDIFF(r.expected_return_date, r.pickup_date)) AS scheduled_days,
    GREATEST(0, DATEDIFF(COALESCE(r.actual_return_date, CURRENT_DATE), r.expected_return_date)) AS days_overdue,
    
    r.daily_rate,
    r.late_fee_per_day,
    
    -- Cost breakdown
    ROUND(GREATEST(1, DATEDIFF(r.expected_return_date, r.pickup_date)) * r.daily_rate, 2) AS base_charge,
    ROUND(GREATEST(0, DATEDIFF(COALESCE(r.actual_return_date, CURRENT_DATE), r.expected_return_date)) * r.late_fee_per_day, 2) AS late_fee_penalty,
    
    -- Calculated total charge vs stored total amount
    ROUND(
        (GREATEST(1, DATEDIFF(r.expected_return_date, r.pickup_date)) * r.daily_rate) +
        (GREATEST(0, DATEDIFF(COALESCE(r.actual_return_date, CURRENT_DATE), r.expected_return_date)) * r.late_fee_per_day),
        2
    ) AS calculated_total_charge,
    r.total_amount AS recorded_total_amount,
    r.rental_status
FROM rentals r
JOIN customers c ON r.customer_id = c.customer_id
JOIN cars v ON r.car_id = v.car_id
ORDER BY r.rental_id ASC;

-- ============================================================================
-- 2. VEHICLE AVAILABILITY CHECK WITH CALENDAR OVERLAP PREVENTION
-- ============================================================================
-- Checks which cars at a given branch (e.g., branch_id = 1) are available for a
-- prospective rental window ('2024-05-18' to '2024-05-22').
-- A vehicle is NOT available if:
--   1. Its current status is MAINTENANCE or DECOMMISSIONED.
--   2. There exists an active or booked rental that overlaps:
--      (pickup_date <= requested_end AND expected_return_date >= requested_start)
--   3. There exists an ongoing maintenance task during that period.
SET @req_pickup = '2024-05-18';
SET @req_return = '2024-05-22';
SET @req_branch = 1;

SELECT 
    v.car_id,
    v.registration_number,
    v.make,
    v.model,
    v.category,
    v.daily_rate,
    v.mileage,
    v.status AS current_operational_status,
    b.branch_name,
    b.city
FROM cars v
JOIN branches b ON v.branch_id = b.branch_id
WHERE v.branch_id = @req_branch
  AND v.status NOT IN ('MAINTENANCE', 'DECOMMISSIONED')
  AND NOT EXISTS (
      -- Check overlapping rentals
      SELECT 1 
      FROM rentals r
      WHERE r.car_id = v.car_id
        AND r.rental_status IN ('BOOKED', 'ACTIVE')
        AND r.pickup_date <= @req_return
        AND r.expected_return_date >= @req_pickup
  )
  AND NOT EXISTS (
      -- Check overlapping maintenance schedules
      SELECT 1 
      FROM maintenance m
      WHERE m.car_id = v.car_id
        AND m.maintenance_status IN ('SCHEDULED', 'IN_PROGRESS')
        AND m.start_date <= @req_return
        AND (m.completion_date IS NULL OR m.completion_date >= @req_pickup)
  );

-- ============================================================================
-- 3. CUSTOMER LIFETIME VALUE (CLV) & ACTIVITY PROFILE
-- ============================================================================
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    b.branch_name AS home_branch,
    COUNT(r.rental_id) AS total_rentals_count,
    SUM(CASE WHEN r.rental_status = 'COMPLETED' THEN 1 ELSE 0 END) AS completed_trips,
    COALESCE(SUM(r.total_amount), 0.00) AS lifetime_expenditure,
    COALESCE(ROUND(AVG(r.total_amount), 2), 0.00) AS average_spend_per_trip,
    MAX(r.pickup_date) AS most_recent_rental_date
FROM customers c
LEFT JOIN branches b ON c.home_branch_id = b.branch_id
LEFT JOIN rentals r ON c.customer_id = r.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.email, b.branch_name
ORDER BY lifetime_expenditure DESC;

-- ============================================================================
-- 4. FLEET FINANCIAL RETURN ON INVESTMENT (REVENUE VS MAINTENANCE COST)
-- ============================================================================
SELECT 
    v.car_id,
    v.registration_number,
    CONCAT(v.make, ' ', v.model) AS vehicle_model,
    v.category,
    v.daily_rate,
    v.status,
    COALESCE(rent_agg.total_revenue, 0.00) AS total_rental_revenue,
    COALESCE(rent_agg.rental_count, 0) AS times_rented,
    COALESCE(maint_agg.total_maintenance_cost, 0.00) AS cumulative_maintenance_cost,
    COALESCE(maint_agg.service_count, 0) AS total_services_count,
    (COALESCE(rent_agg.total_revenue, 0.00) - COALESCE(maint_agg.total_maintenance_cost, 0.00)) AS net_operating_profit
FROM cars v
LEFT JOIN (
    SELECT 
        car_id, 
        SUM(total_amount) AS total_revenue,
        COUNT(rental_id) AS rental_count
    FROM rentals
    WHERE rental_status = 'COMPLETED'
    GROUP BY car_id
) rent_agg ON v.car_id = rent_agg.car_id
LEFT JOIN (
    SELECT 
        car_id, 
        SUM(cost) AS total_maintenance_cost,
        COUNT(maintenance_id) AS service_count
    FROM maintenance
    WHERE maintenance_status = 'COMPLETED'
    GROUP BY car_id
) maint_agg ON v.car_id = maint_agg.car_id
ORDER BY net_operating_profit DESC;

-- ============================================================================
-- 5. BRANCH PERFORMANCE AND FLEET METRICS
-- ============================================================================
SELECT 
    b.branch_id,
    b.branch_name,
    b.city,
    COUNT(DISTINCT v.car_id) AS total_assigned_fleet,
    SUM(CASE WHEN v.status = 'AVAILABLE' THEN 1 ELSE 0 END) AS available_cars,
    SUM(CASE WHEN v.status = 'RENTED' THEN 1 ELSE 0 END) AS actively_rented_cars,
    SUM(CASE WHEN v.status = 'MAINTENANCE' THEN 1 ELSE 0 END) AS cars_in_maintenance,
    COALESCE(SUM(r.total_amount), 0.00) AS total_branch_revenue
FROM branches b
LEFT JOIN cars v ON b.branch_id = v.branch_id
LEFT JOIN rentals r ON v.car_id = r.car_id AND r.rental_status = 'COMPLETED'
GROUP BY b.branch_id, b.branch_name, b.city
ORDER BY total_branch_revenue DESC;

-- END OF 04_business_queries.sql


==============================================================================
-- START OF 05_indexing_and_explain.sql
==============================================================================

-- ============================================================================
-- Car Rental Management System (MySQL 8.0+)
-- B.Tech CSE Data Science - DBMS Capstone Project
-- File: 05_indexing_and_explain.sql
-- Description: B-Tree secondary indexes, composite indexes, EXPLAIN / EXPLAIN ANALYZE,
--              demonstration of index suppression (functions on columns),
--              and MySQL 8.0+ Functional Key Parts (Functional Indexes).
-- ============================================================================

USE car_rental_db;

-- ============================================================================
-- 1. CREATING STRATEGIC SECONDARY & COMPOSITE INDEXES
-- ============================================================================

-- (A) Composite Index for Availability & Booking Overlap Check
-- Speeds up queries filtering by car_id and date boundaries.
CREATE INDEX idx_rentals_car_dates 
ON rentals (car_id, pickup_date, expected_return_date);

-- (B) Composite Index for Fleet Inventory Status Lookups by Branch
-- Supports queries like "find available cars at branch X"
CREATE INDEX idx_cars_branch_status 
ON cars (branch_id, status, category);

-- (C) Lookup index for Customer Phone
CREATE INDEX idx_customers_phone 
ON customers (phone);

-- (D) Maintenance query acceleration
CREATE INDEX idx_maintenance_car_status 
ON maintenance (car_id, maintenance_status);

-- Inspect created indexes on rentals and cars
SHOW INDEX FROM rentals;
SHOW INDEX FROM cars;

-- ============================================================================
-- 2. QUERY PLAN ANALYSIS USING EXPLAIN & EXPLAIN ANALYZE
-- ============================================================================

-- Query 1: Fleet availability lookup using Composite Index (idx_cars_branch_status)
EXPLAIN 
SELECT car_id, registration_number, make, model, daily_rate
FROM cars
WHERE branch_id = 1 AND status = 'AVAILABLE';

-- MySQL 8.0+ Tree execution plan showing cost, rows, and index usage
EXPLAIN FORMAT=TREE
SELECT car_id, registration_number, make, model, daily_rate
FROM cars
WHERE branch_id = 1 AND status = 'AVAILABLE';

-- Query 2: Range check on rentals with EXPLAIN ANALYZE (Actual execution time and rows)
EXPLAIN ANALYZE
SELECT rental_id, customer_id, daily_rate, total_amount
FROM rentals
WHERE car_id = 1 
  AND pickup_date >= '2024-01-01' 
  AND expected_return_date <= '2024-06-30';

-- ============================================================================
-- 3. DEMONSTRATING WHEN AN INDEX IS NOT USED (SARGABILITY DEFECT)
-- ============================================================================

-- Case A: Normal Equality Search on Indexed Column (email is UNIQUE)
-- Expected: Type = const / eq_ref (Super fast single row lookup via B-Tree)
EXPLAIN
SELECT customer_id, first_name, last_name, email
FROM customers
WHERE email = 'alice.morgan@example.com';

-- Case B: Function applied directly to indexed column: LOWER(email)
-- Expected: Type = ALL (Full Table Scan!)
-- Explanation: The B-Tree contains raw email strings ('alice.morgan@example.com').
-- Wrapping the column in LOWER(email) prevents the database engine from traversing
-- the B-Tree index. MySQL must evaluate the function for every row in the table.
EXPLAIN
SELECT customer_id, first_name, last_name, email
FROM customers
WHERE LOWER(email) = 'alice.morgan@example.com';

-- Case C: Function on date column: YEAR(pickup_date)
-- Expected: Type = ALL (Index on pickup_date is bypassed)
EXPLAIN
SELECT rental_id, customer_id, pickup_date, total_amount
FROM rentals
WHERE YEAR(pickup_date) = 2024;

-- Optimized SARGable (Search Argument Able) alternative using explicit date bounds:
-- Expected: Type = range (Traverses idx_rentals_car_dates efficiently)
EXPLAIN
SELECT rental_id, customer_id, pickup_date, total_amount
FROM rentals
WHERE pickup_date >= '2024-01-01' AND pickup_date < '2025-01-01';

-- ============================================================================
-- 4. ADVANCED MYSQL 8.0+ FIX: FUNCTIONAL KEY PARTS (FUNCTIONAL INDEXES)
-- ============================================================================
-- In MySQL 8.0.13+, we can index expressions directly!

-- Create functional index on LOWER(email)
CREATE INDEX idx_customers_lower_email 
ON customers ((LOWER(email)));

-- Re-run the query that previously performed a full table scan:
-- Expected: Type = ref (Now uses idx_customers_lower_email instead of scanning ALL rows!)
EXPLAIN
SELECT customer_id, first_name, last_name, email
FROM customers
WHERE LOWER(email) = 'alice.morgan@example.com';

-- END OF 05_indexing_and_explain.sql


==============================================================================
-- START OF 06_views_and_updates.sql
==============================================================================

-- ============================================================================
-- Car Rental Management System (MySQL 8.0+)
-- B.Tech CSE Data Science - DBMS Capstone Project
-- File: 06_views_and_updates.sql
-- Description: Demonstrates Updatable vs Non-Updatable Views, WITH CHECK OPTION,
--              and MySQL Error 1471 mechanics for academic evaluation.
-- ============================================================================

USE car_rental_db;

-- Drop old views if existing
DROP VIEW IF EXISTS vw_available_cars;
DROP VIEW IF EXISTS vw_customer_rental_summary;
DROP VIEW IF EXISTS vw_active_rentals_detail;

-- ============================================================================
-- 1. SIMPLE UPDATABLE VIEW (1-TO-1 ROW MAPPING)
-- ============================================================================
-- A view is updatable in MySQL if:
--   - It selects directly from a single base table.
--   - It contains no aggregates (SUM, AVG, MIN, MAX, COUNT).
--   - It contains no DISTINCT, GROUP BY, HAVING, UNION, or subqueries in SELECT.
CREATE VIEW vw_available_cars AS
SELECT 
    car_id,
    registration_number,
    make,
    model,
    category,
    daily_rate,
    mileage,
    status
FROM cars
WHERE status = 'AVAILABLE'
WITH CHECK OPTION;

-- Query the view
SELECT * FROM vw_available_cars;

-- Test: Update through the view (THIS SUCCEEDS)
-- Updating the mileage of car_id = 1 through the view:
UPDATE vw_available_cars
SET mileage = mileage + 250
WHERE car_id = 1;

-- Verify the base table was updated:
SELECT car_id, registration_number, mileage, status 
FROM cars 
WHERE car_id = 1;

-- Test WITH CHECK OPTION enforcement:
-- Attempting to change status to 'RENTED' through vw_available_cars will FAIL
-- because WITH CHECK OPTION prevents updates that make the row disappear from the view!
-- Expected Result:
-- ERROR 1369 (HY000): CHECK OPTION failed 'car_rental_db.vw_available_cars'
-- (Uncomment to demonstrate during practical evaluation):
-- UPDATE vw_available_cars SET status = 'RENTED' WHERE car_id = 1;

-- ============================================================================
-- 2. COMPLEX NON-UPDATABLE AGGREGATED VIEW
-- ============================================================================
-- This view aggregates customer expenditure and booking counts using GROUP BY.
CREATE VIEW vw_customer_rental_summary AS
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    COUNT(r.rental_id) AS total_rentals_booked,
    SUM(CASE WHEN r.rental_status = 'COMPLETED' THEN 1 ELSE 0 END) AS completed_rentals,
    COALESCE(SUM(r.total_amount), 0.00) AS total_spending
FROM customers c
LEFT JOIN rentals r ON c.customer_id = r.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.email;

-- Query the aggregated summary view
SELECT * FROM vw_customer_rental_summary;

-- ============================================================================
-- 3. DEMONSTRATION: WHY UPDATING AN AGGREGATED VIEW FAILS
-- ============================================================================
-- Test: Attempting to update `total_spending` directly via the view.
--
-- Running the following statement in MySQL 8.0:
-- UPDATE vw_customer_rental_summary
-- SET total_spending = 500.00
-- WHERE customer_id = 1;
--
-- Fails with:
-- ERROR 1471 (HY000): The target table vw_customer_rental_summary of the UPDATE is not updatable
--
-- ACADEMIC & ARCHITECTURAL REASON FOR VIVA:
-- 1. Loss of 1-to-1 Bijection: Each row in `vw_customer_rental_summary` represents
--    a mathematical aggregation over multiple underlying physical rows in `rentals`.
-- 2. Ambiguity in Inverse Mapping: If `total_spending` changes from $725 to $500,
--    the database engine cannot mathematically deduce how that -$225 deduction
--    should be distributed across the individual rental records (Rental #1, #3, and #5).
-- 3. SQL Standard Compliance: Under ANSI/ISO SQL and MySQL architecture, any view
--    containing GROUP BY, aggregate functions, DISTINCT, or UNION is strictly non-updatable.

-- ============================================================================
-- 4. MULTI-TABLE JOIN VIEW (READ-ONLY REPORTING VIEW)
-- ============================================================================
CREATE VIEW vw_active_rentals_detail AS
SELECT 
    r.rental_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.phone AS customer_phone,
    c.license_number,
    v.registration_number,
    CONCAT(v.make, ' ', v.model) AS vehicle_model,
    v.category,
    b.branch_name AS station_location,
    r.pickup_date,
    r.expected_return_date,
    r.daily_rate,
    r.rental_status
FROM rentals r
JOIN customers c ON r.customer_id = c.customer_id
JOIN cars v ON r.car_id = v.car_id
JOIN branches b ON v.branch_id = b.branch_id
WHERE r.rental_status = 'ACTIVE';

SELECT * FROM vw_active_rentals_detail;

-- END OF 06_views_and_updates.sql


==============================================================================
-- START OF 07_window_functions.sql
==============================================================================

-- ============================================================================
-- Car Rental Management System (MySQL 8.0+)
-- B.Tech CSE Data Science - DBMS Capstone Project
-- File: 07_window_functions.sql
-- Description: Advanced analytical queries utilizing MySQL 8.0+ Window Functions:
--              RANK, DENSE_RANK, SUM OVER (Running Total), LAG, LEAD, and ROW_NUMBER.
-- ============================================================================

USE car_rental_db;

-- ============================================================================
-- 1. RANK() & DENSE_RANK(): CUSTOMER REVENUE RANKING WITHIN HOME BRANCHES
-- ============================================================================
-- Ranks customers by their total completed expenditure within each home branch.
-- Demonstrates the difference between RANK() (leaves gaps upon ties) and
-- DENSE_RANK() (no gaps in ranking sequence).
WITH CustomerBranchSpend AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        b.branch_name,
        COALESCE(SUM(r.total_amount), 0.00) AS total_spent
    FROM customers c
    JOIN branches b ON c.home_branch_id = b.branch_id
    LEFT JOIN rentals r ON c.customer_id = r.customer_id AND r.rental_status = 'COMPLETED'
    GROUP BY c.customer_id, c.first_name, c.last_name, b.branch_name
)
SELECT 
    branch_name,
    customer_name,
    total_spent,
    RANK() OVER (
        PARTITION BY branch_name 
        ORDER BY total_spent DESC
    ) AS spending_rank,
    DENSE_RANK() OVER (
        PARTITION BY branch_name 
        ORDER BY total_spent DESC
    ) AS spending_dense_rank
FROM CustomerBranchSpend
ORDER BY branch_name, spending_rank;

-- ============================================================================
-- 2. SUM() OVER(): CUMULATIVE RUNNING REVENUE CHRONOLOGICALLY
-- ============================================================================
-- Calculates cumulative business revenue over time as each rental is completed.
SELECT 
    r.rental_id,
    r.actual_return_date,
    CONCAT(v.make, ' ', v.model) AS vehicle,
    v.category,
    r.total_amount AS rental_charge,
    SUM(r.total_amount) OVER (
        ORDER BY r.actual_return_date ASC, r.rental_id ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_company_revenue
FROM rentals r
JOIN cars v ON r.car_id = v.car_id
WHERE r.rental_status = 'COMPLETED'
ORDER BY r.actual_return_date ASC;

-- ============================================================================
-- 3. LAG(): REPEAT CUSTOMER INTERVAL (INTER-RENTAL TIME ANALYSIS)
-- ============================================================================
-- Analyzes customer retention by computing the number of days elapsed between
-- a customer's previous rental return date and their next rental pickup date.
WITH CustomerTrips AS (
    SELECT 
        r.rental_id,
        r.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        r.pickup_date,
        r.actual_return_date,
        LAG(r.actual_return_date, 1) OVER (
            PARTITION BY r.customer_id 
            ORDER BY r.pickup_date ASC
        ) AS previous_return_date
    FROM rentals r
    JOIN customers c ON r.customer_id = c.customer_id
    WHERE r.rental_status = 'COMPLETED'
)
SELECT 
    customer_id,
    customer_name,
    rental_id,
    previous_return_date,
    pickup_date AS current_pickup_date,
    actual_return_date AS current_return_date,
    DATEDIFF(pickup_date, previous_return_date) AS days_since_last_rental
FROM CustomerTrips
ORDER BY customer_id, pickup_date;

-- ============================================================================
-- 4. ROW_NUMBER(): TOP-1 HIGHEST REVENUE GENERATING CAR IN EACH CATEGORY
-- ============================================================================
-- Partition by vehicle category to identify the top performing vehicle in each fleet segment.
WITH CarRevenueStats AS (
    SELECT 
        v.category,
        v.car_id,
        v.registration_number,
        CONCAT(v.make, ' ', v.model) AS vehicle_name,
        COALESCE(SUM(r.total_amount), 0.00) AS total_revenue_generated,
        ROW_NUMBER() OVER (
            PARTITION BY v.category 
            ORDER BY COALESCE(SUM(r.total_amount), 0.00) DESC
        ) AS category_position
    FROM cars v
    LEFT JOIN rentals r ON v.car_id = r.car_id AND r.rental_status = 'COMPLETED'
    GROUP BY v.category, v.car_id, v.registration_number, v.make, v.model
)
SELECT 
    category,
    car_id,
    registration_number,
    vehicle_name,
    total_revenue_generated
FROM CarRevenueStats
WHERE category_position = 1
ORDER BY total_revenue_generated DESC;

-- ============================================================================
-- 5. MOVING AVERAGE: 3-RENTAL MOVING AVERAGE SPEND PER COMPLETED TRANSACTION
-- ============================================================================
SELECT 
    r.rental_id,
    r.actual_return_date,
    r.total_amount,
    ROUND(
        AVG(r.total_amount) OVER (
            ORDER BY r.actual_return_date ASC, r.rental_id ASC
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS three_trip_moving_average_spend
FROM rentals r
WHERE r.rental_status = 'COMPLETED'
ORDER BY r.actual_return_date ASC;

-- END OF 07_window_functions.sql


==============================================================================
-- START OF 08_triggers_and_procedures.sql
==============================================================================

-- ============================================================================
-- Car Rental Management System (MySQL 8.0+)
-- B.Tech CSE Data Science - DBMS Capstone Project
-- File: 08_triggers_and_procedures.sql
-- Description: Stored Procedures, Business Triggers, and ACID Transactions
--              for automated operations in MySQL Workbench.
-- ============================================================================

USE car_rental_db;

DELIMITER $$

-- ============================================================================
-- 1. STORED PROCEDURE: sp_book_rental
-- Automates rental agreement creation, verifies vehicle availability,
-- sets daily rate snapshot, and updates vehicle status to 'RENTED'.
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_book_rental$$

CREATE PROCEDURE sp_book_rental(
    IN p_customer_id INT,
    IN p_car_id INT,
    IN p_pickup_date DATE,
    IN p_expected_return_date DATE,
    IN p_late_fee DECIMAL(10,2),
    OUT p_rental_id INT,
    OUT p_status_message VARCHAR(255)
)
proc_label: BEGIN
    DECLARE v_car_status VARCHAR(20);
    DECLARE v_daily_rate DECIMAL(10,2);
    DECLARE v_conflict_count INT DEFAULT 0;

    -- Basic date validation
    IF p_expected_return_date < p_pickup_date THEN
        SET p_status_message = 'ERROR: Expected return date cannot be earlier than pickup date.';
        LEAVE proc_label;
    END IF;

    -- Fetch vehicle status and daily rate
    SELECT status, daily_rate 
    INTO v_car_status, v_daily_rate
    FROM cars
    WHERE car_id = p_car_id;

    IF v_car_status IS NULL THEN
        SET p_status_message = 'ERROR: Specified vehicle does not exist.';
        LEAVE proc_label;
    END IF;

    IF v_car_status IN ('MAINTENANCE', 'DECOMMISSIONED') THEN
        SET p_status_message = CONCAT('ERROR: Vehicle is currently unavailable (Status: ', v_car_status, ').');
        LEAVE proc_label;
    END IF;

    -- Check for overlapping reservations
    SELECT COUNT(*) INTO v_conflict_count
    FROM rentals
    WHERE car_id = p_car_id
      AND rental_status IN ('BOOKED', 'ACTIVE')
      AND pickup_date <= p_expected_return_date
      AND expected_return_date >= p_pickup_date;

    IF v_conflict_count > 0 THEN
        SET p_status_message = 'ERROR: Vehicle already has a booking during the selected dates.';
        LEAVE proc_label;
    END IF;

    -- Execute Booking Transaction
    START TRANSACTION;

    INSERT INTO rentals (
        customer_id, car_id, pickup_date, expected_return_date, 
        daily_rate, late_fee_per_day, rental_status
    ) VALUES (
        p_customer_id, p_car_id, p_pickup_date, p_expected_return_date,
        v_daily_rate, COALESCE(p_late_fee, 25.00), 'BOOKED'
    );

    SET p_rental_id = LAST_INSERT_ID();

    -- If booking starts today, transition vehicle to RENTED immediately
    IF p_pickup_date <= CURRENT_DATE THEN
        UPDATE cars SET status = 'RENTED' WHERE car_id = p_car_id;
        UPDATE rentals SET rental_status = 'ACTIVE' WHERE rental_id = p_rental_id;
    END IF;

    COMMIT;

    SET p_status_message = CONCAT('SUCCESS: Rental booked successfully with ID: ', p_rental_id);
END$$

-- ============================================================================
-- 2. STORED PROCEDURE: sp_process_car_return
-- Handles vehicle drop-off, calculates exact duration, applies late fees,
-- records mileage increment, and restores vehicle status to 'AVAILABLE'.
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_process_car_return$$

CREATE PROCEDURE sp_process_car_return(
    IN p_rental_id INT,
    IN p_actual_return_date DATE,
    IN p_additional_mileage INT,
    OUT p_total_amount_billed DECIMAL(10,2),
    OUT p_status_message VARCHAR(255)
)
proc_label: BEGIN
    DECLARE v_car_id INT;
    DECLARE v_pickup_date DATE;
    DECLARE v_expected_return_date DATE;
    DECLARE v_daily_rate DECIMAL(10,2);
    DECLARE v_late_fee_per_day DECIMAL(10,2);
    DECLARE v_rental_status VARCHAR(20);
    DECLARE v_scheduled_days INT;
    DECLARE v_days_late INT;
    DECLARE v_base_charge DECIMAL(10,2);
    DECLARE v_late_penalty DECIMAL(10,2);

    -- Fetch rental record
    SELECT car_id, pickup_date, expected_return_date, daily_rate, late_fee_per_day, rental_status
    INTO v_car_id, v_pickup_date, v_expected_return_date, v_daily_rate, v_late_fee_per_day, v_rental_status
    FROM rentals
    WHERE rental_id = p_rental_id;

    IF v_car_id IS NULL THEN
        SET p_status_message = 'ERROR: Rental agreement not found.';
        LEAVE proc_label;
    END IF;

    IF v_rental_status = 'COMPLETED' THEN
        SET p_status_message = 'ERROR: This rental agreement has already been completed and settled.';
        LEAVE proc_label;
    END IF;

    -- Calculate days and financial charges
    SET v_scheduled_days = GREATEST(1, DATEDIFF(v_expected_return_date, v_pickup_date));
    SET v_days_late = GREATEST(0, DATEDIFF(p_actual_return_date, v_expected_return_date));

    SET v_base_charge = v_scheduled_days * v_daily_rate;
    SET v_late_penalty = v_days_late * v_late_fee_per_day;
    SET p_total_amount_billed = v_base_charge + v_late_penalty;

    -- Complete settlement transaction
    START TRANSACTION;

    UPDATE rentals
    SET actual_return_date = p_actual_return_date,
        total_amount = p_total_amount_billed,
        rental_status = 'COMPLETED'
    WHERE rental_id = p_rental_id;

    UPDATE cars
    SET status = 'AVAILABLE',
        mileage = mileage + COALESCE(p_additional_mileage, 0)
    WHERE car_id = v_car_id;

    COMMIT;

    SET p_status_message = CONCAT('SUCCESS: Return processed. Total billed: $', p_total_amount_billed, 
                                  ' (Scheduled Days: ', v_scheduled_days, ', Days Overdue: ', v_days_late, ')');
END$$

-- ============================================================================
-- 3. TRIGGER: trg_maintenance_car_status
-- When a vehicle enters maintenance, automatically set its car status to 'MAINTENANCE'.
-- When completed, return to 'AVAILABLE'.
-- ============================================================================
DROP TRIGGER IF EXISTS trg_after_maintenance_insert$$

CREATE TRIGGER trg_after_maintenance_insert
AFTER INSERT ON maintenance
FOR EACH ROW
BEGIN
    IF NEW.maintenance_status IN ('SCHEDULED', 'IN_PROGRESS') THEN
        UPDATE cars SET status = 'MAINTENANCE' WHERE car_id = NEW.car_id;
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_after_maintenance_update$$

CREATE TRIGGER trg_after_maintenance_update
AFTER UPDATE ON maintenance
FOR EACH ROW
BEGIN
    IF NEW.maintenance_status = 'COMPLETED' AND OLD.maintenance_status != 'COMPLETED' THEN
        UPDATE cars SET status = 'AVAILABLE' WHERE car_id = NEW.car_id;
    ELSEIF NEW.maintenance_status = 'IN_PROGRESS' THEN
        UPDATE cars SET status = 'MAINTENANCE' WHERE car_id = NEW.car_id;
    END IF;
END$$

DELIMITER ;

-- END OF 08_triggers_and_procedures.sql
