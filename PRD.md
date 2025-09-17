

```markdown
# Product Requirements Document (PRD)

## Furniture Shop Management App

---

### 1. Product Overview
**Product Name**: FurniShop Manager  
**Version**: 1.1  
**Platform**: Flutter Mobile Application  
**Backend**: Supabase (PostgreSQL, Authentication, Real-time DB Subscriptions)  
**Push Notifications**: OneSignal  
**Courier Integration**: Steadfast API  
**Target Users**: Shop Owners, Managers, Employees, Production Staff  
**Design Theme**: Modern UI, Blue primary color + white accents  

---

### 2. Product Vision & Objectives
A comprehensive furniture shop management system integrating sales, production, HR, and inventory in a user-friendly mobile app.

**Objectives:**
- Simplify inventory & order management
- Enhance production efficiency
- Improve attendance tracking
- Actionable business insights through advanced reports
- Support online & offline sales with courier integration

---

### 3. Technical Architecture
- **Frontend:** Flutter (cross-platform mobile)
- **Backend:** Supabase (PostgreSQL, Authentication, Real-time DB Subscriptions)
- **Push Notifications:** OneSignal
- **Courier Integration:** Steadfast API
- **Design:** Modern UI, blue + white color scheme

---

### 4. User Roles & Permissions
- **Owner:** Super-admin, full control including financials, settings, all reports
- **Admin:** Full access to all modules, financials, settings, warehouse management
- **Manager:** All Employee permissions + stock/sales approvals, can monitor staff and reports (except profit margin)
- **Employee:** Sales, stock updates, product management, limited sales history (name, qty only)
- **Production Employee:** Access to production features, assigned jobs, production history, material requests

---

### 5. Core Features

#### 5.1 Order Management
- Orders start as **pending**; after confirmation, details entered in courier panel (Steadfast API) and Parcel ID returned/stored
- Statuses: pending, confirmed, shipped, delivered, cancelled, returned (configurable)
- Backorders allowed if insufficient stock; auto-deduct from warehouse after confirmation
- Offline sales: cash/due payments, invoice/receipt PDF
- Online orders: delivery type, customer details, shipment tracking
- Notifications for new/cancelled/returned orders **with product photo**

#### 5.2 Stock Management
- Multi-warehouse: each with name/address, default per product
- Add, transfer, deduct stock; real-time tracking
- Production integration: items move from Warehouse A → Warehouse B
- Low stock daily alerts (push notification)
- Backorders accepted if stock insufficient

#### 5.3 Employee Management
- Roles: Manager, Employee, Production Employee
- Attendance: mobile GPS check-in/out (within 0.5km)
- Logs in/out times, monthly attendance report (PDF)
- Admin/Owner can export attendance reports

#### 5.4 Production Material Management
- Production orders (date, products to produce)
- Assigned employee feature **removed**
- **All roles** can request production materials; managers/admin approve/deny
- Show purchased material history
- Real-time tracking: raw materials, consumables, packaging
- Reports: usage efficiency, wastage, demand forecasting, purchase history

#### 5.5 Due Book
- Tracks money owed/owing (customers, suppliers, staff)
- Visual indicator: green (receivable), red (payable)
- Full transaction history, notes per entry
- Linked to Sales & Purchase Book
- Automatic payment reminders

#### 5.6 Expense Book
- Default categories: salary, purchase, bills, rent, wages, raw material
- Custom categories possible
- Monthly breakdown/report (PDF export)

#### 5.7 Purchase Book
- Purchase tracking from suppliers (linked to Due Book)
- Inventory auto-updated after purchase
- Supplier details maintained
- Purchase history/PDF export

#### 5.8 Sales Book
- Online: customer info, courier API integration, Parcel ID stored, status/tracking
- Offline: sales (cash/due), due syncs with Due Book, auto-stock deduction, PDF invoice/receipt
- **Visibility:**
  - Employees: name + quantity only
  - Manager: name + quantity + **price**
  - Admin/Owner: full sales history + profit margin

#### 5.9 Product Management
- Add/Edit/Delete products
- Fields: name, description, buying/selling price, stock, **product photos** (multiple images)
- Bulk update
- Duplicate products
- Product categories
- Real-time stock/price

#### 5.10 Stock Book
- Stock counts by product/warehouse
- Show selling price/total value
- Stock movement history
- Generate **Stock Report by Warehouse** (PDF)

#### 5.11 Business Reports
- Standard: daily sales, monthly profit, inventory turnover, stock valuation by warehouse, attendance, pending orders (PDF export)
- **Advanced:**
  - Cash flow
  - Customer analysis (top customers, frequency, order patterns)
  - Employee performance (sales, productivity beyond attendance)
  - Supplier analysis
  - Product performance (top/worst sellers, profit margins)

---

### 6. Notifications via OneSignal
- Product-related: order placed/cancelled/returned, new product added, stock movement, production stock added (**all with product photo**)
- System: low stock alert, due payment reminders, material shortage/delays, attendance
- **Admin control:** role-based notification ON/OFF (granular, allows disabling by type/role)
- Users can mute non-critical notifications

---

### 7. Non-Functional Requirements
- App load time < 3 sec
- Offline support (sales, stock history)
- Secure role-based authentication
- PDF export for invoices/reports
- Scalable (multi-warehouse, 50+ concurrent users)

---

### 8. Data Models

#### Warehouses
- id, name, address, default_flag

#### Products
- id, name, description, buying_price, selling_price, category, default_warehouse_id, **product_images[]**

#### Orders
- id, customer_info, type (online/offline), delivery_type, parcel_id, payment_status, order_status

#### Employees
- id, role, profile, attendance_logs

#### Attendance
- employee_id, check_in, check_out, gps_location

#### Materials
- id, category, stock, min/max_threshold

#### Expenses
- category_id, amount, date, notes

#### Transactions (Due Book)
- entity_id, given/received, amount, notes, date

#### Notification Settings
- id, role_id, notification_type, enabled, created_by_admin_id, updated_at

#### Reports Cache
- id, report_type, generated_date, file_path, parameters, generated_by_user_id

---

### 9. Success Metrics
- 60% reduction in manual order processing
- 80% fewer stock-out incidents
- 100% automated courier integration after order confirmation
- Timely auto-generation of monthly PDF reports
- 95%+ accurate employee attendance (GPS-based)
- Advanced business reports available (cash flow, customer analysis, performance)
- 100% product-related push notifications with photos
- Improved sales tracked via detailed analytics

---
```

