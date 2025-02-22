SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM issued_status;
SELECT * FROM members;
SELECT * FROM return_status;

-- Project Tasks

-- Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')

-- Task 2: Update an Existing Member's Address

UPDATE members
SET member_address = '585 Oak St'
WHERE member_id = 'C109';

-- Task 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.

DELETE FROM issued_status
where issued_id = 'IS121';

-- Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.

SELECT issued_book_name
FROM issued_status
WHERE issued_emp_id = 'E101';

-- Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.

SELECT issued_member_id, COUNT (issued_member_id) AS no_of_books_issued
FROM issued_status
GROUP BY issued_member_id
HAVING COUNT(issued_member_id) > 1;

-- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**

CREATE TABLE book_issued_count AS
SELECT b.isbn, b.book_title, COUNT(ist.issued_id) AS issue_count
FROM issued_status ist
JOIN books b
ON ist.issued_book_isbn = b.isbn
GROUP BY b.isbn, b.book_title;

-- Task 7. Retrieve All Books in a Specific Category

SELECT *
FROM books
WHERE category = 'Dystopian';

-- Task 8: Find Total Rental Income by Category

SELECT b.category, SUM(b.rental_price),COUNT(*)
FROM books b
JOIN issued_status ist
ON ist.issued_book_isbn = b.isbn
GROUP BY b.category;

-- Task 9: List Members Who Registered in the Last 180 Days

SELECT *
FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '180 days';

-- Task 10: List Employees with Their Branch Manager's Name and their branch details

SELECT e1.*, b.manager_id, e2.emp_name AS manager
FROM employees e1
JOIN branch b
ON e1.branch_id = b.branch_id
JOIN employees e2
on b.manager_id = e2.emp_id;

-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold (7 USD)

CREATE TABLE books_price_greater_than_seven AS
SELECT * 
FROM books 
WHERE rental_price > 7;

-- Task 12: Retrieve the List of Books Not Yet Returned

SELECT * 
FROM issued_status iss
LEFT JOIN return_status rs 
ON iss.issued_id = rs.issued_id
WHERE rs.return_id IS NULL;

/* 
Task 13: Identify Members with Overdue Books
Write a query to identify members who have overdue books (assume a 30-day return period). 
Display the member's_id, member's name, book title, issue date, and days overdue.
*/

SELECT 
	m.member_id, 
	m.member_name, 
	ist.issued_book_name AS book_title, 
	ist.issued_date,
	CURRENT_DATE - ist.issued_date AS days_overdue
FROM members m 
JOIN issued_status ist
ON m.member_id = ist.issued_member_id
LEFT JOIN return_status rs
ON ist.issued_id = rs.issued_id
WHERE 
	rs.return_date IS NULL 
	AND 
	(CURRENT_DATE - ist.issued_date) > 30
ORDER BY m.member_id;

/* 
Task 14: Update Book Status on Return
Write a query to update the status of books in the books table to "Yes" when they are returned 
(based on entries in the return_status table).
*/

CREATE OR REPLACE PROCEDURE add_return_records(p_return_id VARCHAR(10), p_issued_id VARCHAR(10), p_book_quality VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
    v_isbn VARCHAR(50);
    v_book_name VARCHAR(80);
    
BEGIN

    INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
    VALUES
    (p_return_id, p_issued_id, CURRENT_DATE, p_book_quality);

    SELECT 
        issued_book_isbn,
        issued_book_name
        INTO
        v_isbn,
        v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;

    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;

    RAISE NOTICE 'Thank you for returning the book: %', v_book_name;
    
END;
$$

-- Calling Function
CALL add_return_records('RS138', 'IS135', 'Good');

CALL add_return_records('RS148', 'IS140', 'Good');

/*
Task 15: Branch Performance Report
Create a query that generates a performance report for each branch, showing the number of books issued,
the number of books returned, and the total revenue generated from book rentals.
*/

SELECT 
    b.branch_id,
    b.manager_id,
    COUNT(ist.issued_id) AS total_books_issued,
    COUNT(rs.return_id) AS total_books_returned,
    SUM(bk.rental_price) AS total_revenue
FROM branch  b
LEFT JOIN employees e 
ON e.branch_id = b.branch_id
LEFT JOIN issued_status ist 
ON e.emp_id = ist.issued_emp_id
LEFT JOIN return_status  rs
ON rs.issued_id = ist.issued_id
LEFT JOIN books  bk
ON ist.issued_book_isbn = bk.isbn
GROUP BY b.branch_id, b.manager_id;

/*
Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members 
containing members who have issued at least one book in the last 2 months.
*/

CREATE TABLE active_members 
AS 
SELECT *
FROM members 
WHERE member_id IN
	(
		SELECT DISTINCT issued_member_id
		FROM issued_status
		WHERE issued_date >= CURRENT_DATE - INTERVAL '2 month'
	);

/*
Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues.
Display the employee name, number of books processed, and their branch.
*/

SELECT e.emp_name, COUNT(ist.issued_emp_id) AS no_of_books_processed, e.branch_id
FROM employees e 
JOIN issued_status ist
ON e.emp_id = ist.issued_emp_id
GROUP BY e.emp_name, e.branch_id
ORDER BY no_of_books_processed DESC
LIMIT 3;

/*
Task 19: Stored Procedure Objective: Create a stored procedure to manage the status of books in a library system. 
Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 
The procedure should function as follows: The stored procedure should take the book_id as an input parameter. 
The procedure should first check if the book is available (status = 'yes'). 
If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 
If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.
*/

CREATE OR REPLACE PROCEDURE issue_book(p_issued_id VARCHAR(10), p_issued_member_id VARCHAR(30), p_issued_book_isbn VARCHAR(30), p_issued_emp_id VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
    v_status VARCHAR(10);

BEGIN

    SELECT 
        status 
        INTO
        v_status
    FROM books
    WHERE isbn = p_issued_book_isbn;

    IF v_status = 'yes' THEN

        INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
        VALUES
        (p_issued_id, p_issued_member_id, CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id);

        UPDATE books
            SET status = 'no'
        WHERE isbn = p_issued_book_isbn;

        RAISE NOTICE 'Book records added successfully for book isbn : %', p_issued_book_isbn;


    ELSE
        RAISE NOTICE 'Sorry to inform you the book you have requested is unavailable book_isbn: %', p_issued_book_isbn;
    END IF;
END;
$$


CALL issue_book('IS155', 'C108', '978-0-553-29698-2', 'E104');
CALL issue_book('IS156', 'C108', '978-0-375-41398-8', 'E104');


