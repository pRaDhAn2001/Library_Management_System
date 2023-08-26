--Creating Table Books
CREATE TABLE Books (
    book_id INT PRIMARY KEY,
    book_name VARCHAR(100),
    author VARCHAR(100),
	genres VARCHAR(50),
	price DECIMAL(10),
    tot_copies INT
);

--Creating Table Members
CREATE TABLE Members (
    member_id INT PRIMARY KEY,
    member_name VARCHAR(100),
    join_date DATE,
	num_of_books INT,
	tot_fine DECIMAL(10,2) DEFAULT 0
);

--Creating Table Transactions
CREATE TABLE Transactions (
    transaction_id INT PRIMARY KEY,
    member_id INT,
    book_id INT,
    issue_date DATE,
    due_date DATE,
	return_date DATE,
	renewal_count INT,
    CONSTRAINT MNO_FKEY FOREIGN KEY (member_id) REFERENCES Members(member_id),
    CONSTRAINT BNO_FKEY FOREIGN KEY (book_id) REFERENCES Books(book_id)
);

--Creating Table Transactions_History
CREATE TABLE Transaction_History (
	book_id INT,
	member_id INT,
	issue_date DATE,
	due_date DATE,
	return_date DATE,
	fine DECIMAL(10,2),
    CONSTRAINT MNO_FKEY1 FOREIGN KEY (member_id) REFERENCES Members(member_id),
    CONSTRAINT BNO_FKEY1 FOREIGN KEY (book_id) REFERENCES Books(book_id)
);

--Inserting some values into Books Table
INSERT INTO Books (book_id, book_name, author, genres, price, tot_copies) VALUES
    (1, 'Book 1', 'ABC', 'Fiction', 500, 3),
    (2, 'Book 2', 'DEF', 'Economics', 740, 6),
	(3, 'Book 3', 'GHI', 'Travel', 300, 2),
    (4, 'Book 4', 'JKL', 'Horror', 470, 4),
	(5, 'Book 5', 'MNO', 'Thriller', 520, 8),
    (6, 'Book 6', 'PQR', 'Spiritual', 780, 1),
	(7, 'Book 7', 'STU', 'Romance', 590, 7),
    (8, 'Book 8', 'VWX', 'Poetry', 610, 6),
	(9, 'Book 9', 'YZA', 'Detective', 506, 3),
    (10, 'Book 10', 'DEF', 'Science', 260, 2),
	(11, 'Book 11', 'PSD', 'Adventure', 370, 1),
    (12, 'Book 12', 'MNO', 'Thriller', 754, 3),
	(13, 'Book 13', 'IND', 'History', 910, 8),
    (14, 'Book 14', 'TBH', 'Romance', 725, 5),
	(15, 'Book 15', 'FCB', 'Biography', 684, 4);


--Inserting some values into Members Table
INSERT INTO Members (member_id, member_name, join_date, num_of_books, tot_fine) VALUES
    (1, 'Member 1', '2023-01-01', 0, 0),
    (2, 'Member 2', '2023-02-15', 0, 0),
	(3, 'Member 3', '2023-02-21', 0, 0),
    (4, 'Member 4', '2023-03-05', 0, 0),
	(5, 'Member 5', '2023-04-11', 0, 0),
    (6, 'Member 6', '2023-04-17', 0, 0),
	(7, 'Member 7', '2023-04-29', 0, 0),
	(8, 'Member 8', '2023-05-08', 0, 0),
	(9, 'Member 9', '2023-05-14', 0, 0),
    (10, 'Member 10', '2023-06-10', 0, 0);


--Inserting some values into Transactions Table
INSERT INTO Transactions (transaction_id, member_id, book_id, issue_date, due_date, return_date, renewal_count) VALUES
    (1, 1, 8, '2023-05-01', '2023-05-15', '2023-05-13', 0),
    (2, 6, 7, '2023-05-10', '2023-05-24', '2023-05-28', 0),
	(1, 1, 8, '2023-06-03', '2023-06-17', '2023-06-11', 0),
    (2, 6, 7, '2023-06-14', '2023-06-28', '2023-06-29', 0),
	(1, 1, 8, '2023-06-21', '2023-07-05', '2023-07-16', 1),
    (2, 6, 7, '2023-07-12', '2023-07-26', '2023-05-26', 0);


--Creating Sequence 
CREATE SEQUENCE transaction_seq
    START WITH 1
    INCREMENT BY 1;

--Creating Procedure Renewbook for Renewal System of Books
CREATE OR REPLACE PROCEDURE RenewBook(
    p_transaction_id INT
) AS
    v_renewal_count INT;
BEGIN
    -- Check if the transaction exists
    SELECT renewal_count INTO v_renewal_count FROM Transactions WHERE transaction_id = p_transaction_id;

    -- Check if the renewal count is within the limit
    IF v_renewal_count >= 1 THEN
        RAISE_APPLICATION_ERROR(-20005, 'You have already reached the renewal limit.');
    END IF;

    -- Update renewal count and due date
    UPDATE Transactions SET due_date = due_date + 7, renewal_count = renewal_count + 1 WHERE transaction_id = p_transaction_id;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;


--Creating Procedure BorrowBook for Borrowing Books from Library by Members
CREATE OR REPLACE PROCEDURE BorrowBook(
    p_member_id INT,
    p_book_id INT,
    p_due_date DATE
) AS
    v_valid_member INT;
	v_available_copies INT;
    v_borrowed_books INT;
	v_pending_returns INT;
	v_renewal_limit INT;
BEGIN
    -- Check if the member is valid (exists in the Members table)
    SELECT COUNT(*) INTO v_valid_member
    FROM Members
    WHERE member_id = p_member_id;

    IF v_valid_member = 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Invalid member ID. Please provide a valid member ID.');
    END IF;
	
	-- Check if the book is available
    SELECT tot_copies - COUNT(*) INTO v_available_copies
    FROM Transactions
    WHERE book_id = p_book_id AND return_date IS NULL;

    IF v_available_copies <= 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Book is not available for borrowing.');
    END IF;

	-- Check how many books the member has already borrowed
    SELECT COUNT(*) INTO v_borrowed_books
    FROM Transactions
    WHERE member_id = p_member_id AND return_date IS NULL;

    IF v_borrowed_books >= 2 THEN
        RAISE_APPLICATION_ERROR(-20007, 'You have already borrowed the maximum number of books. Please return some books to borrow new ones.');
    END IF;
    
    -- Check if the member has pending book returns
    SELECT COUNT(*) INTO v_pending_returns
    FROM Transactions
    WHERE member_id = p_member_id AND return_date IS NULL;

    IF v_pending_returns > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'You have a pending book return. Please return the book before borrowing a new one.');
    END IF;

	-- Check if the member has reached the renewal limit
    SELECT tot_copies INTO v_renewal_limit
    FROM Members
    WHERE member_id = p_member_id;

    IF v_renewal_limit >= 1 THEN
        RAISE_APPLICATION_ERROR(-20004, 'You have already reached the renewal limit.');
    END IF;

    -- Calculate fine based on due date and current date (0 since it's borrowing)
    DECLARE
        v_fine DECIMAL(10, 2) := 0;
    BEGIN
        -- Insert a new transaction record using the sequence into Transactions table
        INSERT INTO Transactions (transaction_id, member_id, book_id, issue_date, due_date)
        VALUES (transaction_seq.NEXTVAL, p_member_id, p_book_id, SYSDATE, p_due_date);

        -- Insert a record into Transaction_History with fine set to 0
        INSERT INTO Transaction_History (book_id, member_id, issue_date, due_date, fine)
        VALUES (p_book_id, p_member_id, SYSDATE, p_due_date, v_fine);

    -- Update member's book count
    UPDATE Members SET num_of_books = num_of_books + 1 WHERE member_id = p_member_id;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;


--Creating Procedure ReturnBook for Returning Books back to Library by Members
CREATE OR REPLACE PROCEDURE ReturnBook(
    p_transaction_id INT
) AS
    v_fine DECIMAL(10, 2);
    v_due_date DATE;
BEGIN
    -- Check if the transaction exists
    SELECT due_date INTO v_due_date FROM Transactions WHERE transaction_id = p_transaction_id;

    IF v_due_date > SYSDATE THEN
        v_fine := 0;
    ELSE
        v_fine := (SYSDATE - v_due_date) * 2; -- Example fine calculation: INR 2 per day
    END IF;

    -- Update transaction record and member's book count
    UPDATE Transactions SET return_date = SYSDATE, fine = v_fine WHERE transaction_id = p_transaction_id;

   -- Update Transaction_History with fine
    UPDATE Transaction_History
    SET return_date = SYSDATE, fine = v_fine
    WHERE book_id = (SELECT book_id FROM Transactions WHERE transaction_id = p_transaction_id)
      AND member_id = (SELECT member_id FROM Transactions WHERE transaction_id = p_transaction_id);

	
	UPDATE Members
    SET num_of_books = num_of_books - 1,
        tot_fine = tot_fine + v_fine
    WHERE member_id = (SELECT member_id FROM Transactions WHERE transaction_id = p_transaction_id);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;


--Creating Trigger RestrictBookTransactions to Members incase of borrow or returning of Books
CREATE OR REPLACE TRIGGER RestrictBookTransactions
BEFORE INSERT OR UPDATE ON Transactions
FOR EACH ROW
DECLARE
    v_current_day VARCHAR(10);
    v_current_hour NUMBER;
BEGIN
    -- Get current day and hour
    SELECT TO_CHAR(SYSDATE, 'DY'), EXTRACT(HOUR FROM SYSDATE) INTO v_current_day, v_current_hour FROM dual;

    -- Check if the current day is between Monday and Friday
    IF v_current_day NOT IN ('MON', 'TUE', 'WED', 'THU', 'FRI') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Book transactions are only allowed from Monday to Friday.');
    END IF;

    -- Check if the current hour is between 10 AM and 4 PM
    IF v_current_hour < 10 OR v_current_hour >= 16 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Book transactions are only allowed between 10 AM and 4 PM.');
    END IF;
END;

--Creating Role Manager as library_manager
CREATE ROLE library_manager;

--Granting access of Insertion and Deletion Operations on Members to Manager
GRANT INSERT, DELETE ON Members TO library_manager;


--Creating Trigger RestrictManagerOperations on Manager incase of Insertion and Deletion Operations
CREATE OR REPLACE TRIGGER RestrictManagerOperations
BEFORE INSERT OR DELETE ON Members
FOR EACH ROW
DECLARE
    v_current_day VARCHAR(10);
    v_current_hour NUMBER;
BEGIN
    -- Get current day and hour
    SELECT TO_CHAR(SYSDATE, 'DY'), EXTRACT(HOUR FROM SYSDATE) INTO v_current_day, v_current_hour FROM dual;

    -- Check if the current day is between Monday and Friday
    IF v_current_day NOT IN ('MON', 'TUE', 'WED', 'THU', 'FRI') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Manager operations are only allowed from Monday to Friday.');
    END IF;

    -- Check if the current hour is between 10 AM and 4 PM
    IF v_current_hour < 10 OR v_current_hour >= 16 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Manager operations are only allowed between 10 AM and 4 PM.');
    END IF;
END;


--Granting access of Insertion Operations on Books to Manager
GRANT INSERT ON Books TO library_manager;

--Creating Procedure InsertNewBook to insert new book record to Books Table
CREATE OR REPLACE PROCEDURE InsertNewBook(
    p_book_id INT,
    p_book_name VARCHAR(100),
    p_author VARCHAR(100),
    p_genres VARCHAR(50),
    p_price DECIMAL(10),
    p_tot_copies INT
) AS
BEGIN
    -- Insert a new book record
    INSERT INTO Books (book_id, book_name, author, genres, price, tot_copies)
    VALUES (p_book_id, p_book_name, p_author, p_genres, p_price, p_tot_copies);
    
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;

--Creating Trigger RestrictManagerBookInsert on Manager incase of Insertion Operation on Books Table
CREATE OR REPLACE TRIGGER RestrictManagerBookInsert
BEFORE INSERT ON Books
FOR EACH ROW
DECLARE
    v_current_day VARCHAR(10);
    v_current_hour NUMBER;
BEGIN
    -- Get current day and hour
    SELECT TO_CHAR(SYSDATE, 'DY'), EXTRACT(HOUR FROM SYSDATE) INTO v_current_day, v_current_hour FROM dual;

    -- Check if the current day is between Monday and Friday
    IF v_current_day NOT IN ('MON', 'TUE', 'WED', 'THU', 'FRI') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Manager book insertion is only allowed from Monday to Friday.');
    END IF;

    -- Check if the current hour is between 10 AM and 4 PM
    IF v_current_hour < 10 OR v_current_hour >= 16 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Manager book insertion is only allowed between 10 AM and 4 PM.');
    END IF;
END;

