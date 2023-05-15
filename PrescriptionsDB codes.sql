create database PrescriptionsDB
use PrescriptionsDB
go    

----creating Medical_Practice Table
create table Medical_Practice(
PRACTICE_CODE nvarchar(100) not null primary key,
PRACTICE_NAME  nvarchar(100) not null,
ADDRESS_1  nvarchar(100) not null,
ADDRESS_2  nvarchar(100),
ADDRESS_3  nvarchar(100) ,
ADDRESS_4  nvarchar(100) ,
POSTCODE  nvarchar(100) not null 
)
create table Drugs(
BNF_CODE nvarchar(50) not null primary key,
CHEMICAL_SUBSTANCE_BNF_DESCR nvarchar(max) not null,
BNF_DESCRIPTION nvarchar(max) not null,
BNF_CHAPTER_PLUS_CODE nvarchar(max) not null
)

create table Prescriptions(
PRESCRIPTION_CODE int primary key,
PRACTICE_CODE nvarchar(100) not null
foreign key (PRACTICE_CODE) references Medical_Practice(PRACTICE_CODE),
BNF_CODE nvarchar(50) not null foreign key (BNF_CODE) references drugs(BNF_CODE),
QUANTITY float,
ITEMS float,
ACTUAL_COST money
)


------putting data into the Medical_Practice
insert into Medical_Practice(Practice_code, Practice_name,address_1,address_2,address_3,address_4,postcode)
select m.Practice_code, m.Practice_name,m.address_1,m.address_2, m.address_3, m.address_4, m.postcode
from Medical_Practice_data as m

------putting data into the Drugs
insert into drugs(bnf_code, chemical_substance_bnf_descr,bnf_description, bnf_chapter_plus_code)
select d.bnf_code, d.chemical_substance_bnf_descr,d.bnf_description,d.bnf_chapter_plus_code
from drugs_data as d

------putting data into Prescriptions
insert into Prescriptions(prescription_code, practice_code,bnf_code,quantity,items,actual_cost)
select p.prescription_code, p.practice_code,p.bnf_code, p.quantity,p.items,actual_cost
from prescriptions_data as p

----dropping the data tables
drop table prescriptions_data
drop table drugs_data
drop table Medical_practice_data

--Question2 | Querry that returns details of drugs in the form of tables or capsules
select * from drugs
where BNF_DESCRIPTION  like '%' + 'tablets' 
   or     BNF_DESCRIPTION  like '%' + 'capsules'

--Question3 | Querry that returns the total quantity of each prescription
select prescription_code, practice_code, bnf_code, floor(quantity*items) as TotalQuantity
from Prescriptions

--Question4. Query to return a list of distinct chemical substances which appears in the drug table. 
select distinct chemical_substance_bnf_descr as Chemical_Substances 
from drugs


--Question5. Query that returns the number of prescriptions for each BNF_CHAPTER_PLUS_CODE
select a. BNF_CHAPTER_PLUS_CODE, count(a.BNF_CHAPTER_PLUS_CODE) as 
No_of_Prescriptions, avg(b. actual_cost) as Average_Cost,
max(b.actual_cost) as Max_Cost, min(b.actual_cost) as Min_Cost
from drugs as a inner join Prescriptions as b on a. BNF_CODE = b. BNF_CODE
group by a. BNF_CHAPTER_PLUS_CODE
order by  a. BNF_CHAPTER_PLUS_CODE

--Question6. Query that returns the most expensive prescription by each practice for prescriptions that are more than £4000. 
select a.practice_name, max(b.actual_cost)as most_expensive_prescription
from Medical_Practice as a inner join prescriptions as b on a. practice_code = b.practice_code
where actual_cost >4000
group by a.practice_name
order by most_expensive_prescription desc

--drugs most prescribed
select a.bnf_description, sum(b.quantity) as Total_Quantity from 
drugs as a
inner join Prescriptions as b on a.BNF_CODE = b.BNF_CODE
group by a.bnf_description 
order by total_quantity desc

--top 5 most expensive drugs
select top 5 a.bnf_description, max(floor(b.actual_cost/(b.quantity*b.items))) as Cost_per_item from 
drugs as a
inner join Prescriptions as b on a.BNF_CODE = b.BNF_CODE
group by a.bnf_description, a.BNF_CODE
order by cost_per_item desc


-- count of  prescription, total quantity and total_cost  by each medical practice
select a.practice_code, a.practice_name, count(a.practice_code) as num_of_prescriptions, 
sum(b.quantity*b.items) as Total_Quantity, sum(b.actual_cost) as Total_Cost
from Medical_Practice a 
inner join prescriptions b on a.PRACTICE_CODE=b.PRACTICE_CODE
group by a.practice_code, a.practice_name
order by Total_Quantity desc

--number of medical practice in each postal district
SELECT  value as Postal_District, count(value) as No_of_Medical_Practice
FROM Medical_Practice
CROSS APPLY STRING_SPLIT(postcode, ' ')
WHERE value  LIKE '%BL%'
group by value

--medical practice and the drugs they prescribed most
with count_of_prescription  as (
  select p.practice_code, d.bnf_code, count(*) AS prescriptions 
  from Prescriptions p
  JOIN Drugs d on d.bnf_code = p.BNF_CODE
  group by p.practice_code, d.bnf_code),
max_count_of_prescription as (
  select practice_code, max(prescriptions) as max_prescriptions
  from count_of_prescription
  group by practice_code)
select a.practice_name as MedicalPractice, b.bnf_description as MostPrescribedDrug, 
j.prescriptions as CountOfMostPrescribedDrug
from Medical_Practice a
INNER JOIN Prescriptions c on a.practice_code = c.practice_code
INNER JOIN Drugs b on b.bnf_code = c.BNF_CODE
INNER JOIN count_of_prescription as j on j.practice_code = a.practice_code AND j.bnf_code = b.bnf_code
INNER JOIN max_count_of_prescription as k on k.practice_code = a.practice_code AND k.max_prescriptions = j.prescriptions
group by a.practice_name, b.bnf_description, j.prescriptions;


