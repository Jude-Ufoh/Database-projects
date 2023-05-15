Create database Central_Library
use Central_Library

--creating members table
create table members(
username nvarchar(10) not null primary key,
Pass_word BINARY(64) NOT NULL,
firstname nvarchar(50) not null,
lastname nvarchar(50) not null,
addresses nvarchar(100) not null,
DoB date not null,
email nvarchar(100) unique ,
telephone nvarchar(20),
joined_date date not null default getdate(),
left_date date,
member_status nvarchar(20) default 'Active',
constraint chk_members check (member_status ='Inactive' or member_status='Active' and email like '%_@_%._%' ))

---- creating authors table
create table authors(
authorID int identity(1,1) not null primary key,
author_name nvarchar (100) 
)

-- creating authors_items table
create table authors_items(
authorID int foreign key (authorID) references authors(authorID),
itemID int foreign key (itemID) references items(itemID)
)
-- creating items table
create table items (
  itemID int identity(1,1) not null primary key,
  title nvarchar(500) not null,
  category nvarchar(50) not null, 
  year_of_publication int not null,
  ISBN nvarchar (50),
  added_date date default getdate() not null,
  item_status nvarchar(50) default 'Available', 
  constraint chk_items check(
    (item_status='Available' or item_status='On Loan' or item_status='Removed' or item_status='overdue') 
    and 
    (category ='Book' or category ='Journal' or category ='DVD' or category ='Other Media')
  )
);
-- creating the loan table
create table loans(
loanID int identity (1,1) not null primary key,
username nvarchar(10) not null foreign key (username) references members(username),
itemID int not null foreign key (itemID) references items(itemID),
loaned_date date not null default getdate(),
due_date date not null,
returned_date date
)
---creating fines table
create table fines(
fineID int identity (1,1) not null primary key,
loanID int not null foreign key (loanID) references loans(loanID),
fined_date date not null,
total_fine money not null
)
-- creating fine repayment table
create table fineRepayment(
finerepaymentID int identity(1,1) not null primary key,
fineID int not null foreign key (fineID) references fines(fineID),
repayment_date datetime not null,
repaid_amount money not null,
repayment_method nvarchar(10) not null check (repayment_method='Cash' or repayment_method='Card')
)
---creating lost items table
create table lostRemovedItems(
lostremoveditemID int identity(1,1) not null primary key,
itemID int not null foreign key (itemID) references items(itemID),
lostRemoved_date date not null,
ISBN nvarchar(50)
)

---creating formerMembers
create table formerMembers(
oldmemberID int identity(1,1) not null primary key,
username nvarchar(10) not null foreign key (username) references members(username),
firstname nvarchar(50) not null,
lastname nvarchar(50) not null,
addresses nvarchar(100) not null,
DoB date not null,
email nvarchar(100) unique ,
telephone nvarchar(20),
left_date date default getdate(),
constraint chk_oldmembers check (email like '%_@_%._%' ))





-- stored procedure to add a member
create procedure insertaNewMember 
    (@username nvarchar(10), @password nvarchar(50),  @firstname nvarchar(50),
    @lastname nvarchar(50), @address nvarchar(500), @dob date, @email nvarchar(500), 
    @phoneNo nvarchar(50), @joindate date, @leftdate date = NULL, 
    @status nvarchar(10) )
as
begin
    begin try
        begin transaction

        insert into members 
        (Username, Pass_word, FirstName, LastName, Addresses, DoB,Email, Telephone, Joined_Date, 
          Left_Date, member_Status)
        values  (@username,  (convert(binary, '@password')), @firstname,  @lastname, @address, 
           @dob,  @email, @phoneNo, @joindate, @leftdate,  @status)      
            commit transaction
   end try
   begin catch
        rollback transaction
        throw
    end catch
end
--example
exec insertNewMember
@username ='ttc340',
@password='opkkg', 
@firstname = 'Cletus',
@lastname= 'Loggerman', 
@address = '34 Urmston Drive', 
@dob = '1996-12-07', 
@email = 'ght44@yahoo.com', @phoneNo ='0786956455', @joindate = '2023-04-15',
@leftdate = null, @status= 'Active'

-- stored procedure to add an item
alter procedure add_items
(@author1_name nvarchar(100), @author2_name nvarchar(100), @item_title nvarchar(500),
  @item_category nvarchar(50),@item_year_of_publication int, @item_ISBN nvarchar(50))
  as begin begin try
        begin transaction
		 declare @author1_id int declare @author2_id int  declare @item_id int
        -- Insert first author and retrieve the new ID
        insert into authors (author_name) values (@author1_name) set @author1_id =scope_identity()
		 -- Insert second author and retrieve the new ID
        insert into authors (author_name) values (@author2_name) set @author2_id = scope_identity()
		 -- Insert new item and retrieve the new ID
        insert into items (title, category, year_of_publication, ISBN)
        values (@item_title, @item_category, @item_year_of_publication, @item_ISBN) set @item_id = scope_identity()
		 -- Insert new records into authors_items table
        insert into authors_items (itemID, authorID) values (@item_id, @author1_id)
       insert into authors_items (itemID, authorID) values (@item_id, @author2_id)
	     commit transaction end try
    begin catch
        rollback transaction
        throw
    end catch
end

---inserting item with one author
exec add_items @author1_name = ' Tim Peter', @author2_name =null ,
    @item_title = 'Artificial Intelligence' , @item_category= 'Book' , @item_year_of_publication = 2005,
    @item_ISBN= '234-yut61-88'
---inserting item with more tha one author
exec add_items @author1_name = 'The Mirror', @author2_name =null,
    @item_title ='Modern day slavery' , @item_category="Journal" ,@item_year_of_publication = 2008,
    @item_ISBN=null

	--stored procedure to create a loan
	create PROCEDURE createLoan
    @username nvarchar(10), @itemID int, @loaned_date date
as
begin
    if exists (select * from members where username = @username and member_status = 'Active')
        and exists (select * from items where itemID = @itemID and item_status = 'Available')
    begin
        insert loans (username, itemID, loaned_date, due_date, returned_date)
        values (@username, @itemID, @loaned_date, dateadd(day,21,@loaned_date), NULL)
    end
    else
    begin
        raiserror('Check that username exist and item is availaible', 16, 1)
    end
end
select * from members
select * from items
EXEC createLoan @username = 'ecg340', @itemID = 1, @loaned_date ='2023-04-19'
EXEC createLoan @username = 'myh340', @itemID = 3, @loaned_date ='2023-02-21'
---stored procedure to update the loans table
create proc returnLoan
    @loanID int
as
begin
    update loans
    set returned_date = getdate()
    where loanID = @loanID
end
--TRIGGER TO INSERT INTO FINES
create trigger Insert_into_fines
on loans
after insert, update
as
begin
  -- Insert fines for new overdue loans
  insert into fines (loanID, fined_date, total_fine)
  select i.loanID, dateadd(day, 22, i.loaned_date), datediff(day, i.due_date, coalesce(i.returned_date, getdate())) * 10
  from inserted i
  left join fines f on i.loanID = f.loanID
  where (i.returned_date > i.due_date OR i.returned_date IS NULL) AND getdate() > i.due_date AND f.loanID IS NULL;
  
  -- Update fines for existing overdue loans
  update fines
  set total_fine = datediff(day, loans.due_date, coalesce(loans.returned_date, getdate())) * 10
 from fines
  inner join loans on fines.loanID = loans.loanID
  where loans.returned_date is null and getdate() > loans.due_date and fines.total_fine <> datediff(day, loans.due_date, 
   coalesce(loans.returned_date, getdate())) * 10 
   and not exists(select 1 from inserted i where i.loanID = loans.loanID and i.returned_date is not null );
END

-- STORE PROCEDURE TO INSERT INTO THE FINEREPAYMENT TABLE
create procedure InsertIntoFineRepayment
   @fineID int, @repaymentDate date, @repaidAmount money, @repaymentMethod varchar(50)
as
begin
  if EXISTS(select 1 from fines where fineID = @fineID)
   begin
     insert into fineRepayment(fineID, repayment_date, repaid_amount, repayment_method)
      values(@fineID, @repaymentDate, @repaidAmount, @repaymentMethod);
  end
else
   begin
      raiserror('FineID does not exist', 16, 1);
   end
end;
select * from fines
EXEC InsertIntoFineRepayment 2913439, '2023-04-20', 250, 'cash';
select * from fines
select * from fineRepayment

--INSERTING INTO THE LOSTREMOVEDITEMS TABLE
--procedure to update the items table
create procedure Update_Item_Status
    @itemID int,
    @newStatus nvarchar(10)
as
begin
    update items
    set item_status = @newStatus
    where itemID = @itemID
end
--trigger to insert into the lostRemovedItemstable
create trigger insertIntoLostRemovedItems
on items
after update
as
begin
    if update(item_status) --checks for items status update
    begin
        declare @itemID int
        select @itemID = inserted.itemID from inserted
        
        if (select item_status from inserted) = 'Removed'
        begin
            insert into lostRemovedItems (itemID, lostRemoved_date, ISBN)
            select itemID, getdate(), ISBN from inserted where itemID = @itemID
        end
    end
end
--trigger to delete from the lostRemovedItemstable
create trigger deleteFromLostRemovedItems
on items
after update
as
begin
    if update(item_status) -- Check if the item_status column was updated
    begin
        declare @itemID int
        select @itemID = inserted.itemID from inserted
        
        if (select item_status from inserted) = 'Available'
        begin
            delete from lostRemovedItems where itemID = @itemID
        end
    end
end

     select * from items
	 --TO TEST FOR LOSTREMOVEDITEMS TABLE
exec Update_Item_Status @itemID =1 , @newStatus = 'Removed'
select top 3 * from items 
select * from lostRemovedItems
delete lostRemovedItems

--Inserting into the formerMembers table
-- creating procedure for updating members status
create procedure Update_member_Status
    @username nvarchar(10),
    @newStatus nvarchar(10)
as
begin
    update members
    set member_status = @newStatus,
        left_date = case when @newStatus = 'Inactive' then getdate() else left_date end
    where username = @username
end

exec Update_member_Status @username =aug029, @newStatus = 'Active'
--creating a trigger to insert into oldMembers table
create trigger InsertIntoformermembers
on members
after update
as
begin
  if update(member_status) AND EXISTS (select * from inserted where member_status = 'Inactive')
  begin
    insert into formerMembers (username, firstname, lastname, addresses, DoB, email, telephone)
    select username, firstname, lastname, addresses, DoB, email, telephone
    from deleted;
  end;
end;
--trigger to delete from oldmembers
create trigger DeleteFromformerMembers
on members
after update
as
begin
    if update(member_status)
    begin
        delete from formerMembers
        where username IN (select username from deleted)
        and exists (select 1 from inserted where inserted.username = formerMembers.username
		                   and inserted.member_status = 'Active')
    end
end

--TO TEST FOR FORMERMEMBERS TABLE


alter procedure MemberLogin @username nvarchar(10), @password binary(64), @result nvarchar(50) output
as
begin
    set nocount on;
	    declare @db_password binary(64)
    declare @member_status nvarchar(20)
    select @db_password = Pass_word, @member_status = member_status
    from members
    where username = @username
	    if (@db_password IS NOT NULL)
    begin
        if (@db_password = @password)
        begin
            if (@member_status = 'Active')
            begin set @result = 'Welcome.'; end
        else begin set @result = 'Your account is inactive'; end  end
        else begin set @result = 'Invalid password.'; end end
        else begin set @result = 'Username does not exist.'; end
end

DECLARE @result nvarchar(50)
EXEC MemberLogin @username = 'mfm460', @password = 0x4070617373776F726400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000,@result = @result OUTPUT
SELECT @result


--INSERTING FLAT DATA TO BE USED FOR PRACTICE

------Inserting Data into the members table from members_data.csv
insert into members (username, pass_word, firstname,lastname, addresses, Dob, 
email, telephone, joined_date)
select a. username, (CONVERT(binary, a.password)), a.firstname, a.lastname, a.address, a.DoB,a.email,a.telephone, a.join_date
from members_data as a 
select * from members
insert into items(Title, Category, ISBN, added_date, year_of_publication)
select b.title, b.type, b.ISBN, b.doa,b.yofp 
from items_data as b

------Inserting Data into the items table from items_data.csv 
insert into items(Title, Category, ISBN, added_date, year_of_publication)
select b.title, b.type, b.ISBN, b.doa,b.yofp 
from items_data as b
----- inserting data into the author's table from items_data.csv
insert into authors (Author_name)
select distinct(First_author) from dbo.items_data 
union 
select distinct(other_authors) from dbo.items_data 
----inserting data into the authors_items table from items_data.csv
insert into authors_items (itemID, AuthorID)
select a.itemID, b.authorID
from items a
inner join dbo.items_data c on a.Title=c.Title
inner join authors b on (b.Author_name = c.First_Author or b.author_name =c.other_authors)

---- inserting data into the loans table from loans_data, 
insert into loans(username, itemID, loaned_date, due_date, returned_date)
select a.username, b.itemID, a.loandate, dateadd(day,21,a.loandate), a.returndate
from loans_data as a
inner join items as b on b.title=a.itemtitle

drop table members_data
drop table items_data
drop table loans_data

--ANSWERS TO QUESTION
--2a..Procedure to search the catalogue for matching strings
create procedure  search_item_by_title 
  @title nvarchar(500)
as
begin
  set nocount on;

  select items.*, 
    string_agg(authors.author_name, ', ') as authors
  from items
  JOIN authors_items on items.itemID = authors_items.itemID
  JOIN authors on authors_items.authorID = authors.authorID
  where items.title LIKE '%' + @title + '%'
  group by items.itemID, items.title, items.category, 
    items.year_of_publication, items.ISBN, items.added_date, items.item_status;
	end
	--example
	exec search_item_by_title @title = 'python';

	--2b items that are due in 5 days
create proc Timebeforeduedate @due_in int
as
begin
select a.Title, b.FirstName +'  '+b.LastName as borrower, c.due_date as duedate,
DATEDIFF(day, (cast (getdate() as date)), c.due_date) as remainingdays
from items a 
inner join loans c on a.itemID = c.itemID
inner join members b on c.username = b.username
where  DATEDIFF(day, (cast (getdate() as date)), c.due_date) < @due_in
and DATEDIFF(day, (cast (getdate() as date)), c.due_date) > 0 and c.returned_date is null
end
--example
exec Timebeforeduedate @due_in = 20


--2c stored procedure to insert a new member
--this has already beeen created above a

--2d-Stored procedure to update a member
create procedure updateMember (@username nvarchar(50), @password  nvarchar(50)=null, @firstname nvarchar(50)=null,
@lastname nvarchar(50)=null, @address nvarchar(500)=null, @dob date=null, @email nvarchar(500)=null, 
@phoneNo nvarchar(50)=null, @joindate date=null,
@leftdate date =null, @status nvarchar(10)=null)
as
begin
  update members set  Username=@username, 
  Pass_word=isnull((convert(binary, @password)), Pass_word ), 
  FirstName=isnull(@firstname, FirstName),
  LastName=isnull(@lastname,  LastName),
  Addresses =isNull(@address, Addresses), 
  DoB =isnull(@dob,DoB),
  Email=isnull(@email, Email),
  Telephone=isnull(@phoneNo,Telephone),
  Joined_Date=isnull(@joindate, Joined_Date),
  Left_Date=isnull(@leftdate, Left_Date), 
  member_Status=isnull(@status,member_Status)
  where Username=@username
end

updateMember @address = '7 Wiltshere road', @username='mfm460'
select * from members where username ='mfm460'

--Question3. View of loan history
create view loan_history as
select
  a.loanID,  b.firstname,  b.lastname, b.email, b.telephone,  c.title, c.category, a.loaned_date,  a.due_date,
  a.returned_date,  d.total_fine, coalesce(e.repaid_amount, 0) as total_payment, (d.total_fine-coalesce(e.repaid_amount, 0))
  as Balance
from
  loans as  a
  inner join members as b on a.username = b.username
  inner join items as c on a.itemID = c.itemID
  inner join fines as d on a.loanID=d.loanID
  left join fineRepayment as e on e.fineID= d.fineID
 
select * from loan_history

--Question4  Trigger to change the status of an item to available
alter trigger updateStatus
on loans
after update
as
begin
    declare @itemID int, @returned_date date
    select @itemID = inserted.itemID, @returned_date = inserted.returned_date
    from inserted
    if @returned_date IS NOT NULL
    begin
        -- Item has been returned
        update items
        set item_status = 'Available' where itemID = @itemID 
		end
end

--Question5: a function number of loans on each date
create function TotalLoansOn (@date as date)
returns int
as 
begin
    return (select count(*) as num_loans
	from loans
	where loaned_date = @date)
end;

SELECT dbo.TotalLoansOn('2023-02-08') as loan_count;

----FURTHER VIEWS
--view of all the items in the database
create view items_details as
select a.itemID, a.title, string_agg(b.author_name, ', ') as authors, a.category, 
 a.year_of_publication, a.ISBN, a.added_date, a.item_status
from items as a
join authors_items as c on a.itemID = c.itemID
join authors as b on c.authorID = b.authorID
group by a.itemID, a.title, a.category, 
  a.year_of_publication, a.ISBN, a.added_date, a.item_status;

  select * from items_details

  SELECT TABLE_NAME AS Name, 'Table' AS Type
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE='BASE TABLE' AND TABLE_CATALOG='central_library'
UNION
SELECT SPECIFIC_NAME AS Name, 'Stored Procedure' AS Type
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_TYPE='PROCEDURE' AND ROUTINE_CATALOG='central_library';


  --CREATION OF SCHEMAS
 create schema Main
 create schema Finance
 create schema General

  --transfering objects to Main schema
  ALTER SCHEMA Main TRANSFER dbo.add_items
  ALTER SCHEMA Main TRANSFER createLoan
  ALTER SCHEMA Main TRANSFER Update_Item_Status
  ALTER SCHEMA Main TRANSFER Update_member_Status
  ALTER SCHEMA Main TRANSFER Timebeforeduedate
  ALTER SCHEMA Main TRANSFER insertaNewMember
  ALTER SCHEMA Main TRANSFER updateMember
  ALTER SCHEMA Main TRANSFER items
  ALTER SCHEMA Main TRANSFER lostRemovedItems
  ALTER SCHEMA Main TRANSFER authors
 ALTER SCHEMA Main TRANSFER authors_items
 ALTER SCHEMA Main TRANSFER formerMembers
 ALTER SCHEMA Main TRANSFER members
 --transfering objects to General schema
 ALTER SCHEMA General TRANSFER items_details
 ALTER SCHEMA General TRANSFER MemberLogin
 ALTER SCHEMA General TRANSFER search_item_by_title
  --transfering objects to General schema
 ALTER SCHEMA Finance TRANSFER returnLoan
 ALTER SCHEMA Finance TRANSFER InsertIntoFineRepayment
 ALTER SCHEMA Finance TRANSFER TotalLoansOn
 ALTER SCHEMA Finance TRANSFER loans
 ALTER SCHEMA Finance TRANSFER Fines
 ALTER SCHEMA Finance TRANSFER fineRepayment
 ALTER SCHEMA Finance TRANSFER loan_history


CREATE LOGIN mfm460
WITH PASSWORD = 'okppg';

CREATE USER mfm460 FOR LOGIN mfm460;
GO
 
 GRANT SELECT ON SCHEMA :: General TO mfm460;



BACKUP DATABASE central_library
TO DISK = 'D:\backup\central_library.bak';

--restoring the database
RESTORE DATABASE central_library
FROM  DISK = 'D:\backup\central_library.bak'



