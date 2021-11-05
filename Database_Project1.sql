-----creating table project1_books----
drop table project1_books;
create table project1_books (
isbn varchar(26),
title varchar2(2256),
primary key(isbn)
);
----inserting values in project1_books
insert into project1_books select isbn10, title from project1_books_load;

------Creating project1_authors table--------
drop table project1_authors;
CREATE TABLE project1_authors
( AUTHOR_ID INT NOT NULL,
  NAME      VARCHAR2(250), 
  PRIMARY KEY(AUTHOR_ID)
);
desc project1_authors;
--------creating sequence to generate author_id--------
drop sequence author_id_seq;
CREATE SEQUENCE author_id_seq START WITH 1000 INCREMENT BY 1 NOCACHE NOCYCLE;

--------Retriving unique author names from the project1_books_load table---------
select count(1) from
(SELECT REGEXP_SUBSTR (authro, '[^,]+',1,1) as Name FROM project1_books_load
UNION
SELECT REGEXP_SUBSTR (authro, '[^,]+',1,2) as Name FROM project1_books_load
UNION
SELECT REGEXP_SUBSTR (authro, '[^,]+',1,3) as Name FROM project1_books_load
UNION
SELECT REGEXP_SUBSTR (authro, '[^,]+',1,4) as Name FROM project1_books_load
UNION
SELECT REGEXP_SUBSTR (authro, '[^,]+',1,5) as Name FROM project1_books_load
);15649

---------Inserting values in project1_authors table----------
insert into project1_authors select author_id_seq.nextval,a.name from (
SELECT REGEXP_SUBSTR (authro, '[^,]+',1,1) as Name FROM project1_books_load
UNION
SELECT REGEXP_SUBSTR (authro, '[^,]+',1,2) as Name FROM project1_books_load
UNION
SELECT REGEXP_SUBSTR (authro, '[^,]+',1,3) as Name FROM project1_books_load
UNION
SELECT REGEXP_SUBSTR (authro, '[^,]+',1,4) as Name FROM project1_books_load
UNION
SELECT REGEXP_SUBSTR (authro, '[^,]+',1,5) as Name FROM project1_books_load

) a ;
-------creating table project1_book_authors----------------
drop table project1_book_authors;
create table project1_book_authors
( AUTHOR_ID int NOT NULL,
  ISBN   varchar2(26)  NOT NULL,
  PRIMARY KEY(AUTHOR_ID, ISBN),
  FOREIGN KEY (AUTHOR_ID) REFERENCES project1_AUTHORS(AUTHOR_ID),
  FOREIGN KEY (ISBN) REFERENCES project1_BOOK(ISBN)
);
---- inserting data into project1_book_authors------
insert into project1_book_authors 
select A.author_id, B.isbn10 from project1_authors A,
(select name,isbn10 from(
SELECT REGEXP_SUBSTR (authro, '[^,]+',1,1) as Name,isbn10 FROM project1_books_load
UNION
SELECT REGEXP_SUBSTR (authro, '[^,]+',1,2) as Name,isbn10 FROM project1_books_load
UNION
SELECT REGEXP_SUBSTR (authro, '[^,]+',1,3) as Name,isbn10 FROM project1_books_load
UNION
SELECT REGEXP_SUBSTR (authro, '[^,]+',1,4) as Name,isbn10 FROM project1_books_load
UNION
SELECT REGEXP_SUBSTR (authro, '[^,]+',1,5) as Name,isbn10 FROM project1_books_load) where name is not null)B
where A.name=B.name;

---- creating table project1_library_branch-----------
drop project1_library_branch;
create table project1_library_branch(
branch_id number(38),
branch_name varchar2(26),
address varchar2(128),
primary key(branch_id)
);

-------inserting data in project1_library_branch------------

insert into project1_library_branch 
select * from project1_library_branch_load;

----- creating table project1_borrower------------------
drop table project1_borrower;
create table project1_borrower(
card_no varchar2(26),
ssn varchar2(26),
Fname varchar2(26),
Lname varchar2(26),
Address varchar2(50),
Phone varchar2(26),
primary key(card_no)
);

desc project1_borrower;
----Inserting data into project1_borrower-----

insert into project1_borrower
select id0000ID,ssn,first_name,last_name,address||','||city||','||state,phone
from project1_borrowers_load;

---Creating project1_book_copies_table------
drop table project1_book_copies;
create table project1_book_copies
(
book_id int not null,
isbn varchar2(26),
branch_id number(38),
primary key(book_id),
foreign key(isbn) references project1_book(isbn),
foreign key(branch_id) references project1_library_branch(branch_id)
);
--------Creating sequence to generate book_id in project1_book_copies table ----
drop sequence book_id_seq;
CREATE SEQUENCE book_id_seq START WITH 100 INCREMENT BY 1 NOCACHE NOCYCLE;

----PL/SQL program to insert records in project1_book_copies table------------
DECLARE
    rep_cnt NUMBER;
    CURSOR c_books
    IS
     SELECT BOOK_ID,BRANCH_ID,NO_OF_COPIES FROM PROJECT1_BOOK_COPIES_LOAD;
BEGIN
    FOR R_BOOK IN C_BOOKS
    LOOP
    rep_cnt := r_book.no_of_copies;
    
    LOOP
        IF REP_CNT <=0
        THEN
            EXIT;
        END IF;
        
        INSERT INTO project1_book_copies(Book_id,isbn,branch_id) 
        VALUES (book_id_seq.nextval,R_BOOK.BOOK_ID,R_book.BRANCH_ID);
        rep_cnt := rep_cnt-1;
    END LOOP;
 END LOOP;
END;

/

------creating table project1_book_loans------------
drop table project1_book_loans;
create table project1_book_loans(
loan_id int,
book_id number(38),
card_no varchar2(26),
date_out date,
due_date date,
date_in date,
primary key(loan_id),
foreign key(book_id) references project1_book_copies(book_id),
foreign key(card_no) references project1_borrower(card_no)
);

-------Creating sequence to generate loan_id----------

drop sequence loan_seq;
create sequence loan_seq START WITH 1000 INCREMENT BY 1 NOCACHE NOCYCLE;


------inserting data into project1_book_loans------

insert into project1_book_loans 
select loan_seq.nextval as loan_id,book_id,card_no,date_out,date_out+dbms_random.value(1,30)
as date_in,date_out+7 as due_date from(
select book_id,card_no,sysdate-dbms_random.value(1,30) as date_out from (
select Book.book_id,card.card_no from
(select book_id,book_rank from
(select book_id,isbn,rank() over(order by book_id) as book_rank from(
select book_id,isbn
from
(select * from (
select book_id,isbn, row_number()over(partition by isbn order by isbn) as book_rank
from (select book_id,isbn from project1_book_copies))
where book_rank in (1,2)
order by isbn) where rownum<=400))) Book,
(select card_no,card_rank from
(select card_no,rank()over(order by card_no) card_rank from project1_borrower where rownum<=200))
Card
where card.card_rank=book.book_rank
UNION ALL
select Book.book_id,card.card_no from
(select book_id,book_rank from
(select book_id,isbn,rank() over(order by book_id desc) as book_rank from(
select book_id,isbn
from
(select * from (
select book_id,isbn, row_number()over(partition by isbn order by isbn) as book_rank
from (select book_id,isbn from project1_book_copies))
where book_rank in (1,2)
order by isbn) where rownum<=400))) Book,
(select card_no,card_rank from
(select card_no,rank()over(order by card_no) card_rank from project1_borrower where rownum<=200))
Card
where card.card_rank=book.book_rank));

---creating table project1_fines------------
drop table project1_fines;
create table project1_fines(
loan_id int,
fine_amt varchar2(26),
paid varchar2(26),
foreign key (loan_id) references project1_book_loans(loan_id)
);

commit;

-----inserting data in project1_fines------------

insert into project1_fines
select loan_id,floor(trunc(date_in)-trunc(due_date))*10 as Fine_amt,round(dbms_random.value(0,1))
from project1_book_loans where trunc(date_in)>trunc(due_date);

commit;


------------Reports--------------------------
-------Top 5 borrower with highest fines due overall------------
select A.total_fine, B.card_no, B.fname,b.lname,B.phone from (select sum(fine_amt) as Total_fine,card_no
from(
select a.loan_id,a.fine_amt,b.card_no from project1_fines a,
project1_book_loans b
where a.loan_id=b.loan_id
and a.paid=0
and b.due_date<b.date_in)
group by card_no
order by total_fine desc) A,project1_borrower B
where A.card_no=B.card_no
and a.total_fine>50
order by total_fine desc;

----------- branches with total unpaid fines  ----------
select * from project1_fines where paid=0;
select A.branch_name,B.total_fine as total_due_amount
from project1_library_branch A,
(select branch_id,sum(fine_amt) as total_fine
from(
select c.branch_id,b.fine_amt from project1_fines B, project1_book_loans A, project1_book_copies C
where a.loan_id=b.loan_id
and a.book_id=c.book_id
and b.paid=0)
group by branch_id) B
where A.branch_id=B.branch_id
order by 2 desc;

---------
Select x.name, books_written from(
select a.name, count(*) as books_written
from project1_authors a
join project1_book_authors ba on a.author_id = ba.author_id
join project1_book b on ba.isbn = b.isbn
join project1_book_copies bc on b.isbn = bc.isbn
join project1_book_loans bl on bc.book_id = bl.book_id
group by a.name
order by books_written desc,a.name)x
where rownum <=10
order by books_written desc;







select a.name, count(*) as books_written
from project1_authors a, project1_book_authors ba, project1_book b,project1_book_copies bc,
project1_book_loans bl
where a.author_id = ba.author_id, ba.isbn = b.isbn,b.isbn = bc.isbn,bc.book_id = bl.book_id
group by a.name
order by books_written desc,a.name;
















