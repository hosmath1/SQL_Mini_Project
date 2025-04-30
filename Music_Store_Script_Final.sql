
SET SQL_SAFE_UPDATES = 0; --  Disables "safe update mode" in MySQL Workbench. Prevents errors like Error 1175 when running UPDATE or DELETE without a key column in the WHERE clause.

-- Adds a foreign key to album, linking it to the artist table.Ensures every album.artist_id must exist in artist.artist_id.

ALTER TABLE album
ADD CONSTRAINT fk_album_artist
FOREIGN KEY (artist_id) REFERENCES artist(artist_id);

-- Track Table Foreign Keys. (track.album_id → album.album_id), (track.media_type_id → media_type.media_type_id), (track.genre_id → genre.genre_id)
-- Prevents inserting a track unless related data exists in these referenced tables
ALTER TABLE track
ADD CONSTRAINT fk_track_album
FOREIGN KEY (album_id) REFERENCES album(album_id),
ADD CONSTRAINT fk_track_media_type
FOREIGN KEY (media_type_id) REFERENCES media_type(media_type_id),
ADD CONSTRAINT fk_track_genre
FOREIGN KEY (genre_id) REFERENCES Genre(genre_id);

-- composite key for playlist_track
-- Defines a composite primary key for playlist_track, Ensures a track can only appear once per playlist (no duplicate pairs).
-- Required before adding foreign keys referencing both fields

ALTER TABLE playlist_track
add primary key (playlist_id,track_id);

-- Foreign Key: Playlist_Track → Playlist
-- Links playlist_track.playlist_id to playlist.playlist_id
-- Ensures each entry in playlist_track references a valid playlist

ALTER TABLE Playlist_Track
ADD CONSTRAINT fk_playlisttrack_playlist
FOREIGN KEY (Playlist_Id) REFERENCES Playlist(Playlist_Id);

-- Delete Orphaned Playlist_Track Entries, -- Deletes rows in playlist_track where track_id has no match in track
-- Prevents foreign key constraint violation when you later link track_id
-- Uses LEFT JOIN + WHERE IS NULL to identify orphans (missing references)

DELETE pt
FROM Playlist_Track pt
LEFT JOIN Track t ON pt.Track_Id = t.Track_Id
WHERE t.Track_Id IS NULL;

-- Add Foreign Key: Playlist_Track → Track
-- Now safe to add—data is clean
-- Ensures every track in a playlist actually exists in the track table

ALTER TABLE Playlist_Track
ADD CONSTRAINT fk_playlisttrack_track
FOREIGN KEY (Track_Id) REFERENCES Track(Track_Id);

-- Employee Self-Referencing (Manager)
-- Finds employees whose reports_to field references a non-existent employee
-- Prepares for cleaning before adding a foreign key (self-referencing FK)

SELECT e1.employee_id, e1.reports_to
FROM employee e1
LEFT JOIN employee e2 ON e1.reports_to = e2.employee_id
WHERE e1.reports_to IS NOT NULL AND e2.employee_id IS NULL;

--  Clean Invalid Manager References
-- Nullifies invalid reports_to values.
-- Uses a subquery to avoid MySQL's restriction on directly updating the same table being selected from.
-- Prepares data to safely enforce the foreign key

UPDATE employee
SET reports_to = NULL
WHERE reports_to NOT IN (
    SELECT employee_id FROM (
        SELECT employee_id FROM employee
    ) AS valid_ids
);

-- Add FK: Employee → Employee (Self-Reference)
-- Enforces hierarchical reporting structure
-- Ensures reports_to values reference valid employee IDs

ALTER TABLE employee
ADD CONSTRAINT fk_employee_reports_to
FOREIGN KEY (reports_to) REFERENCES employee(employee_id);

-- Customer → Support Rep (Employee)
-- links each customer to an employee (support rep)
-- Enforces valid references to existing employees

ALTER TABLE customer
ADD CONSTRAINT fk_customer_supportrep
FOREIGN KEY (support_rep_id) REFERENCES employee(employee_id);

-- invoice table foregin key
-- Invoice → Customer
-- Ensures every invoice is linked to an actual customer

ALTER TABLE invoice
ADD CONSTRAINT fk_invoice_customer
FOREIGN KEY (customer_id) REFERENCES Customer(customer_id);


-- invoice_line table foregin key
--  Check Orphaned Invoice_Line Entries
-- Identifies invalid invoice_id and track_id values in invoice_line
-- Pre-cleanup before enforcing foreign keys

SELECT invoice_id
FROM invoice_line
WHERE invoice_id NOT IN (SELECT invoice_id FROM invoice);

SELECT track_id
FROM invoice_line
WHERE track_id NOT IN (SELECT track_id FROM track);

SET SQL_SAFE_UPDATES = 0; -- Temporarily Disable Safe Update Mode

-- Clean Up Orphaned Track IDs in Invoice_Line
-- Sets invalid track_ids to NULL to avoid foreign key constraint violations
-- Uses a derived table (AS valid_ids) to safely work around MySQL's update restriction.

UPDATE invoice_line 
SET track_id = NULL
WHERE track_id NOT IN (
    SELECT track_id FROM (
        SELECT track_id FROM track
    ) AS valid_ids
);

-- Add Foreign Keys to Invoice_Line
-- Links each line item to: (An invoice, and A track (if applicable))
-- Final step: ensures full referential integrity for sales data

ALTER TABLE invoice_line 
ADD CONSTRAINT fk_invoiceline_invoice
FOREIGN KEY (invoice_id) REFERENCES invoice(invoice_id),
ADD CONSTRAINT fk_invoiceline_track
FOREIGN KEY (track_id) REFERENCES track(track_id);

-- Re-enable Safe Update Mode

SET SQL_SAFE_UPDATES = 0;

-- Clean orphaned or invalid data
-- Validate with SELECTs
-- Enforce constraints only after data is valid

-- Describe table and Show Columns

DESCRIBE album;

DESCRIBE artist;

DESCRIBE customer;

DESCRIBE employee;

DESCRIBE genre ;

DESCRIBE invoice ;

DESCRIBE invoice_line ;

DESCRIBE invoice_line ;

DESCRIBE media_type ;

DESCRIBE playlist ;

DESCRIBE playlist_track ;

DESCRIBE track ;

-- Finding NULL Values and filling N/A in mirrio column

-- Finding Null values in state 
SELECT *
FROM customer
WHERE state IS NULL OR state = '';

SELECT 
    state, 
    IFNULL(NULLIF(state, ''), 'N/A') AS state_name
FROM 
    customer;

-- Finding Null values in Company 
UPDATE customer SET company = 'JetBrains s.r.o.' WHERE  company = 'JetBrains s.r.o.';

SELECT *
FROM customer
WHERE company IS NOT NULL AND TRIM(company)= '';

SELECT 
    company, 
    IFNULL(NULLIF(company, ''), 'N/A') AS state_name
FROM 
    customer;

-- Finding Null values in postal_code 
SELECT *
FROM customer
WHERE fax IS NOT NULL AND TRIM(fax)= '';

SELECT 
    fax, 
    IFNULL(NULLIF(fax, ''), 'N/A') AS fax_number
FROM 
    customer;

-- Finding Null values in postal_code
SELECT *
FROM customer
WHERE postal_code IS NOT NULL AND TRIM(postal_code)= '';

SELECT 
    postal_code, 
    IFNULL(NULLIF(postal_code, ''), 'N/A') AS postalcode_number
FROM 
    customer;

-- GROUP BY & Basic Calculation of Invoice

SELECT 
    count(Invoice_Id) AS TotalTransactions,
    SUM(Total) AS TotalSales,
    AVG(Total) AS AverageOrderValue,
    MIN(Total) AS MinimumInvoice,
    max(Total) AS MaximumInvoice
FROM Invoice;

-- Below gives us the count of albums_title each artist done

SELECT artist_id, COUNT(*) AS album_count
FROM album
GROUP BY artist_id;

-- Below gives us the customer count from each countries
SELECT country, COUNT(*) AS country_count
FROM customer
GROUP BY country;

-- Below gives us the title count in company
SELECT title, COUNT(*) AS title_count
FROM employee
GROUP BY title;

-- Below gives us the city count of employees working
SELECT city, COUNT(*) AS city_count
FROM employee
GROUP BY city;

-- JOINS FUNCTIONS

-- Below gives us the highest amount from each customer using Group and Join
SELECT c.customer_id,CONCAT(c.first_name, ' ', c.last_name) AS customer_name, MAX(i.total) AS max_total
FROM 
    customer c
JOIN 
    invoice i ON c.customer_id = i.customer_id
GROUP BY 
    c.customer_id, c.first_name, c.last_name
ORDER BY 
    max_total DESC;
    

-- find top 10 customers by total purchase amount
select c.customer_id, c.first_name, c.last_name, sum(i.total) as totalspent
from customer c 
join invoice i on c.customer_id = i.customer_id
group by c.customer_id, c.first_name, c.last_name
order by totalspent desc limit 10;

-- Customers and Their Support Representatives details

SELECT CONCAT(c.first_name, ' ', c.last_name)AS Customer_Name,
       CONCAT(e.first_name, ' ', e.last_name) AS Support_Rep_Name
FROM customer c
JOIN employee e ON c.support_rep_id = e.employee_id;

-- Albums Without Customer Support (need to check this with Monisha)
-- Find albums by artists that have no customer support representative assigned. 
-- Return the album title and artist name 

SELECT DISTINCT al.title AS AlbumTitle, ar.name AS ArtistName
FROM album al
JOIN artist ar ON al.artist_id = ar.artist_id
WHERE NOT EXISTS (
    SELECT 1
    FROM customer c
    JOIN employee e ON c.support_rep_id = e.employee_id
    WHERE e.employee_id = ar.artist_id
);

-- Artists and Number of Albums 
-- write the query to retrieves each artist's name and the number of albums they have.

SELECT ar.name AS ArtistName, COUNT(a.album_id) AS NumberOfAlbums
FROM artist ar
LEFT JOIN album a ON ar.artist_id = a.artist_id
GROUP BY ar.name
ORDER BY NumberOfAlbums DESC;

-- Playlists and Tracks (nned to check with monisha)
-- write the query to retrieves the playlist name and the name of each track in that playlist.

SELECT p.name AS PlaylistName, t.name AS TrackName
FROM playlist p
JOIN playlist_track pt ON p.playlist_id = pt.playlist_id
JOIN track t ON pt.track_id = t.track_id
ORDER BY PlaylistName DESC;

-- Tracks, Albums, and Genres 
-- write the query to retrieves the track name, album title, and genre name for all tracks. 

SELECT t.name AS TrackName, a.title AS AlbumTitle, g.name AS GenreName
FROM track t
JOIN album a ON t.album_id = a.album_id
JOIN genre g ON t.genre_id = g.genre_id;

-- Top Selling Artists by Country

-- "For each country, find the top 3 artists with the most tracks sold. we need to simulate 'sales' by counting track appearances in invoices."
-- (artist, album, track, invoice_line, invoice, customer), aggregation, window functions 
-- (or subqueries for ranking), and grouping by country.

WITH ArtistSales AS (
    SELECT 
        ar.artist_id,
        ar.name AS ArtistName,
        c.country AS CustomerCountry,
        COUNT(il.track_id) AS TrackSales,
        ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY COUNT(il.track_id) DESC) as rn
    FROM artist ar
    JOIN album al ON ar.artist_id = al.artist_id
    JOIN track t ON al.album_id = t.album_id
    JOIN invoice_line il ON t.track_id = il.track_id
    JOIN invoice i ON il.invoice_id = i.invoice_id
    JOIN customer c ON i.customer_id = c.customer_id
    GROUP BY ar.artist_id, ar.name, c.country
)
SELECT ArtistName, CustomerCountry, TrackSales
FROM ArtistSales
WHERE rn <= 3
ORDER BY CustomerCountry, TrackSales DESC;

-- Who is the best customer?
-- The customer who has spent the most money will be declared the best customer. 
-- Write a query that returns the person who has spent the most money.

SELECT customer.customer_id, first_name, last_name, SUM(total) AS total_spending
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id
ORDER BY total_spending DESC
LIMIT 1;

-- Write query to return the email, first name, last name, & Genre of all Rock Music listeners with alphabetic order by 1st name. 

SELECT DISTINCT first_name, last_name, email
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN(
	SELECT track_id FROM track
	JOIN genre ON track.genre_id = genre.genre_id
	WHERE genre.name LIKE 'Rock'
)
ORDER BY first_name ASC;

-- Let's invite the artists who have written the most rock music in our dataset. 
-- Write a query that returns the Artist name and total track count of the rock bands.

SELECT artist.artist_id, artist.name,COUNT(artist.artist_id) AS number_of_songs
FROM track
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id
ORDER BY number_of_songs DESC;


-- ADVANCED FUNCTIONS

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

-- -- Tracks with Most Invoices Sold

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

WITH MonthlyTrackSales AS (
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
        sale_month, t.track_id, t.name  -- Include sale_month here
)
SELECT
    sale_month,
    track_id,
    track_name,
    monthly_sales
FROM MonthlyTrackSales
ORDER BY monthly_sales DESC;

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

WITH MonthlyTrackSales AS (
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
        t.name,
        DATE_FORMAT(i.invoice_date, '%Y-%m') -- Include sale_month in GROUP BY
)
SELECT
    sale_month,  -- Include sale_month in the final SELECT
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


 
