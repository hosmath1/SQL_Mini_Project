-- Active: 1745835281349@@192.168.15.71@9033@music_system
USE `music_system`;

-- Top Selling Track with Most Revenue

WITH
    TrackSales AS (
        SELECT t.track_id, t.name AS track_name, SUM(il.unit_price * il.quantity) AS total_sales
        FROM track t
            JOIN invoice_line il ON t.track_id = il.track_id
        GROUP BY
            t.track_id,
            t.name
    )
SELECT
    track_id,
    track_name,
    total_sales,
    DENSE_RANK() OVER (
        ORDER BY total_sales DESC
    ) AS sales_rank
FROM TrackSales
ORDER BY sales_rank;

-- Tracks with Most Invoices Sold

WITH
    TrackInvoiceSales AS (
        SELECT
            i.invoice_date,
            t.track_id,
            t.name AS track_name,
            il.unit_price * il.quantity AS sales_amount
        FROM
            invoice i
            JOIN invoice_line il ON i.invoice_id = il.invoice_id
            JOIN track t ON il.track_id = t.track_id
    )
SELECT
    track_id,
    track_name,
    COUNT(DISTINCT i.invoice_id) AS num_invoices_sold
FROM
    TrackInvoiceSales t
    JOIN invoice i ON t.track_id = t.track_id
GROUP BY
    t.track_id,
    t.track_name
ORDER BY num_invoices_sold DESC;

-- Tracks with Sales Trend (Monthly)

WITH
    MonthlyTrackSales AS (
        SELECT
            DATE_FORMAT(i.invoice_date, '%Y-%m') AS sale_month,
            t.track_id,
            t.name AS track_name,
            SUM(il.unit_price * il.quantity) AS monthly_sales
        FROM
            invoice i
            JOIN invoice_line il ON i.invoice_id = il.invoice_id
            JOIN track t ON il.track_id = t.track_id
        GROUP BY
            t.track_id,
            t.name
    )
SELECT
    sale_month,
    track_id,
    track_name,
    monthly_sales
FROM MonthlyTrackSales
ORDER BY sale_month, monthly_sales DESC;

-- This query focuses on identifying top-performing tracks and albums, along with a rolling 3-month sales trend.

WITH
    MonthlySales AS (
        SELECT
            EXTRACT(
                MONTH
                FROM i.invoice_date
            ) AS sales_month,
            tl.track_id,
            SUM(tl.quantity * t.unit_price) AS monthly_revenue
        FROM
            invoice i
            JOIN invoice_line tl ON i.invoice_id = tl.invoice_id
            JOIN track t ON tl.track_id = t.track_id
        GROUP BY
            EXTRACT(
                MONTH
                FROM i.invoice_date
            ),
            tl.track_id
    )
SELECT
    ms.sales_month,
    ms.track_id,
    ms.monthly_revenue,
    RANK() OVER (
        ORDER BY ms.monthly_revenue DESC
    ) AS track_rank,
    AVG(ms.monthly_revenue) OVER (
        PARTITION BY
            EXTRACT(
                MONTH
                FROM ms.sales_month
            )
        ORDER BY EXTRACT(
                MONTH
                FROM ms.sales_month
            ) ROWS BETWEEN 1 PRECEDING
            AND 1 FOLLOWING
    ) AS rolling_3_month_avg
FROM MonthlySales ms;

-- This query calculates a 3-month moving average of sales for each track, grouped by month

WITH
    MonthlySales AS (
        SELECT
            DATE_FORMAT(i.invoice_date, '%Y-%m') AS sales_month,
            t.track_id,
            t.name,
            SUM(il.unit_price * il.quantity) AS monthly_sales
        FROM
            invoice i
            JOIN invoice_line il ON i.invoice_id = il.invoice_id
            JOIN track t ON il.track_id = t.track_id
        GROUP BY
            DATE_FORMAT(i.invoice_date, '%Y-%m'),
            t.track_id
        ORDER BY DATE_FORMAT(i.invoice_date, '%Y-%m')
    )
SELECT
    sales_month,
    track_id,
    name,
    AVG(monthly_sales) OVER (
        PARTITION BY
            track_id
        ORDER BY
            sales_month ROWS BETWEEN 2 PRECEDING
            AND CURRENT ROW
    ) AS moving_average_sales
FROM (
        SELECT
            sales_month, track_id, name, monthly_sales
        FROM MonthlySales
    ) AS MonthlySales
ORDER BY sales_month;

-- This query ranks tracks based on their total sales, handling ties gracefully using DENSE_RANK(). It also includes the total sales for each track.

WITH
    TrackSales AS (
        SELECT t.track_id, t.name AS track_name, SUM(il.unit_price * il.quantity) AS total_sales
        FROM track t
            JOIN invoice_line il ON t.track_id = il.track_id
        GROUP BY
            t.track_id,
            t.name
    )
SELECT
    track_id,
    track_name,
    total_sales,
    DENSE_RANK() OVER (
        ORDER BY total_sales DESC
    ) AS sales_rank
FROM TrackSales;

-- This query calculates the moving average of sales for each track over a 3-month window using an OVER clause with PARTITION BY and ORDER BY.
-- It also ranks the tracks within each month using DENSE_RANK() within a window function to get the top 3 tracks based on sales for each month.

WITH
    MonthlyTrackSales AS (
        SELECT
            DATE_FORMAT(i.invoice_date, '%Y-%m') AS sale_month, -- Extract year and month
            t.track_id,
            t.name AS track_name,
            SUM(il.unit_price * il.quantity) AS monthly_sales
        FROM
            invoice i
            JOIN invoice_line il ON i.invoice_id = il.invoice_id
            JOIN track t ON il.track_id = t.track_id
        GROUP BY
            t.track_id,
            t.name
    )
SELECT
    track_id,
    track_name,
    monthly_sales,
    DENSE_RANK() OVER (
        PARTITION BY
            sale_month
        ORDER BY monthly_sales DESC
    ) AS month_rank
FROM MonthlyTrackSales
ORDER BY sale_month, month_rank;
