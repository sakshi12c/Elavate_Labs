# Task 1: Database Setup and Schema Design - Complete Solution

## Objective
Learn to create databases, tables, and define relationships.

## Tools Used
- MySQL Workbench / pgAdmin / SQLiteStudio

## Domain Selected
**E-Commerce Management System**

---

## 1. ENTITIES AND RELATIONSHIPS IDENTIFIED

### Entities:
- **Users** - Store customer information
- **Categories** - Product categories
- **Products** - Product inventory
- **Orders** - Customer orders
- **Order_Items** - Line items in orders
- **Reviews** - Product reviews by users
- **Payments** - Payment details
- **Addresses** - User addresses

### Relationships:
- User (1) → Orders (Many) - One user places many orders
- Order (1) → Order_Items (Many) - One order contains many items
- Product (1) → Order_Items (Many) - One product can be in many orders
- Category (1) → Products (Many) - One category has many products
- User (1) → Reviews (Many) - One user writes many reviews
- Product (1) → Reviews (Many) - One product has many reviews
- Order (1) → Payments (Many) - One order can have multiple payments
- User (1) → Addresses (Many) - One user has multiple addresses

---

## 2. SQL SCRIPT - CREATE TABLE STATEMENTS

### Database Creation
```sql
CREATE DATABASE IF NOT EXISTS ecommerce_db;
USE ecommerce_db;
```

### Table Definitions with Primary and Foreign Keys

#### USERS Table
```sql
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    phone VARCHAR(15),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

#### CATEGORIES Table
```sql
CREATE TABLE categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### PRODUCTS Table
```sql
CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    category_id INT NOT NULL,
    product_name VARCHAR(150) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    stock_quantity INT NOT NULL DEFAULT 0,
    sku VARCHAR(50) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE CASCADE
);
```

#### ORDERS Table
```sql
CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(12, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'Pending',
    shipping_address TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);
```

#### ORDER_ITEMS Table (Junction/Bridge Table)
```sql
CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    subtotal DECIMAL(12, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT
);
```

#### REVIEWS Table
```sql
CREATE TABLE reviews (
    review_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL,
    user_id INT NOT NULL,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE KEY unique_review (product_id, user_id)
);
```

#### PAYMENTS Table
```sql
CREATE TABLE payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    payment_status VARCHAR(20) DEFAULT 'Pending',
    amount DECIMAL(12, 2) NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
);
```

#### ADDRESSES Table
```sql
CREATE TABLE addresses (
    address_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    address_type VARCHAR(20),
    street_address VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state_province VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50) NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);
```

### Performance Indexes
```sql
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_reviews_product_id ON reviews(product_id);
CREATE INDEX idx_reviews_user_id ON reviews(user_id);
CREATE INDEX idx_payments_order_id ON payments(order_id);
CREATE INDEX idx_addresses_user_id ON addresses(user_id);
```

---

## 3. ER DIAGRAM

```
┌─────────────────────────────────────────────────────────────┐
│                       DATABASE SCHEMA                       │
└─────────────────────────────────────────────────────────────┘

                          CATEGORIES
                          ───────────
                          PK: category_id
                          category_name
                          description
                               ▲
                               │ 1:M
                               │
                          PRODUCTS
                          ────────
                          PK: product_id
                          FK: category_id
                          product_name
                          price
                          stock_quantity
                    ┌─────────────┬──────────────┐
                    │             │              │
                    │ 1:M         │ 1:M          │
                    │             │              │
              ORDER_ITEMS     REVIEWS       (other relations)
              ──────────      ───────
              PK: order_item_id  PK: review_id
              FK: order_id       FK: product_id
              FK: product_id     FK: user_id
                    │             │
                    │ M:1         │ M:1
                    │             │
                 ORDERS          USERS
                 ──────          ─────
                 PK: order_id    PK: user_id
                 FK: user_id     username
                 total_amount    email
                 status          phone
                 │               │
                 │ 1:M           │ 1:M
                 │               │
            PAYMENTS          ADDRESSES
            ────────          ─────────
            PK: payment_id    PK: address_id
            FK: order_id      FK: user_id
            payment_method    street_address
            amount            city
```

---

## 4. KEY DESIGN DECISIONS

### Primary Keys
- All tables use `INT PRIMARY KEY AUTO_INCREMENT` for unique identification
- Auto-increment ensures unique values automatically

### Foreign Keys
- **ON DELETE CASCADE**: Used for dependent data (e.g., deleting user deletes their orders)
- **ON DELETE RESTRICT**: Used to prevent deletion of referenced data (e.g., products in order items)

### Constraints
- **UNIQUE**: username, email, SKU, and product-user review combination
- **NOT NULL**: Critical fields like names, prices, quantities
- **CHECK**: Rating must be between 1-5
- **DEFAULT**: Status, timestamps, stock quantity

### Data Types
- `INT` - IDs, quantities, ratings
- `VARCHAR` - Names, emails, addresses
- `DECIMAL` - Prices and amounts (not FLOAT for accuracy)
- `TEXT` - Descriptions and long content
- `TIMESTAMP` - Automatic audit trails
- `BOOLEAN` - True/False values

### Relationships
- **One-to-Many (1:M)**: Categories to Products, Users to Orders
- **Many-to-Many (M:M)**: Orders to Products (via Order_Items junction table)

---

## 5. OUTCOME

 **Well-Structured Schema Achieved**

The E-Commerce database schema includes:
- ✓ 8 normalized tables
- ✓ Proper primary and foreign keys
- ✓ Referential integrity constraints
- ✓ Performance indexes
- ✓ Audit trail timestamps
- ✓ Complete entity relationships
- ✓ Data validation rules
- ✓ Business logic constraints

**Ready for:** Data insertion, queries, application integration, and scaling.