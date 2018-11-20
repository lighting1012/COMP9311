--Q1:
DROP FUNCTION f1(integer);
create or replace function F1(course_id integer)
returns table(t1 bigint) 
as $$
select count(distinct rooms.id)
from rooms 
where rooms.capacity >=
(select count(distinct course_enrolments.student)
from course_enrolments
where course_enrolments.course = $1);
$$ language sql;

DROP FUNCTION f2(integer);
create or replace function F2(course_id integer)
returns table(t1 bigint) 
as $$
select count(distinct rooms.id)
from rooms
where rooms.capacity >=
(select count(distinct course_enrolments.student)
from course_enrolments
where course_enrolments.course = $1) + 
(select count(distinct student)
from course_enrolment_waitlist
where course = $1);
$$ language sql;

drop type if exists RoomRecord cascade;
create type RoomRecord as (valid_room_number bigint, bigger_room_number bigint);

DROP FUNCTION Q1(integer);
create or replace function Q1(course_id integer)
    returns setof RoomRecord
as $$
begin
if $1 not in (select id from courses) then
raise exception 'INVALID COURSEID';
end if;
return query
select * from f1($1), f2($1);
end
--... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;

---------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------
--Q2:

drop type if exists TeachingRecord cascade;
create type TeachingRecord as (cid integer, term char(4), code char(8), name text, uoc integer, average_mark integer, highest_mark integer, median_mark integer, totalEnrols integer);
drop function Q2(integer);
create or replace function Q2(staff_id integer)
returns setof TeachingRecord
as $$
begin

if $1 not in (select id from staff) then
raise exception 'INVALID STAFFID';
end if;

return query

select t1.id cid, cast(t1.term as char(4)) term, t1.code, cast(t1.name as text), t1.uoc, 
cast(round(avg(mark)) as integer) average ,cast(max(mark) as integer),cast(t2.median as integer), cast(count(distinct student) as integer)
from (select courses.id, right(cast(semesters.year as char(4)),2)||lower(semesters.term) term, 
	subjects.code, subjects.name, subjects.uoc ,course_enrolments.student, course_enrolments.mark
from course_enrolments, course_staff, courses, semesters, subjects
where course_staff.staff = $1
and course_staff.course = course_enrolments.course
and course_enrolments.course = courses.id
and courses.semester = semesters.id
and courses.subject = subjects.id
and course_enrolments.mark is not null) t1,
(select x.course, round(AVG(mark)) median
from
(select t1.course, t1.mark,
ROW_NUMBER() OVER (PARTITION BY course order by t1.mark asc) AS RowAsc,
ROW_NUMBER() OVER (PARTITION BY course order by t1.mark desc) AS RowDesc
from (select course_enrolments.course ,course_enrolments.mark
from course_enrolments,course_staff
where course_staff.staff = $1
and course_staff.course = course_enrolments.course
and course_enrolments.mark is not null
order by course_enrolments.course, mark) t1) x
where RowAsc IN (RowDesc, RowDesc - 1, RowDesc + 1)
group by course) t2
where t1.id = t2.course
group by id, term, code, name, uoc, t2.median;

end
--... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;

---------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------

-- table 4 :(courseid, term, code, name, uoc, avg_mark, totalenrol)
select t1.id, t1.term, t1.code, t1.name, t1.uoc,round(avg(mark)) average ,max(mark), count(distinct student)
from (select courses.id, right(cast(semesters.year as char(4)),2)||lower(semesters.term) term, 
	subjects.code, subjects.name, subjects.uoc ,course_enrolments.student, course_enrolments.mark
from course_enrolments, course_staff, courses, semesters, subjects
where course_staff.staff = 50413833
and course_staff.course = course_enrolments.course
and course_enrolments.course = courses.id
and courses.semester = semesters.id
and courses.subject = subjects.id
and course_enrolments.mark is not null) t1
group by id, term, code, name, uoc




-- table 3 :find mediam grade(use table 2)
select x.course, round(AVG(mark)) median
from
(select t1.course, t1.mark,
ROW_NUMBER() OVER (PARTITION BY course order by t1.mark asc) AS RowAsc,
ROW_NUMBER() OVER (PARTITION BY course order by t1.mark desc) AS RowDesc
from (select course_enrolments.course ,course_enrolments.mark
from course_enrolments,course_staff
where course_staff.staff = 50413833
and course_staff.course = course_enrolments.course
and course_enrolments.mark is not null
order by course_enrolments.course, mark) t1) x
where RowAsc IN (RowDesc, RowDesc - 1, RowDesc + 1)
group by course

-- table 2 :(courseid, mark)
select course_enrolments.course ,course_enrolments.mark
from course_enrolments,course_staff
where course_staff.staff = 50413833
and course_staff.course = course_enrolments.course
and course_enrolments.mark is not null
order by course_enrolments.course, mark

-- table 1 :(courseid, term, code, name, uoc, studentid, grade)
select courses.id, right(cast(semesters.year as varchar),2)||lower(semesters.term) term, 
	subjects.code, subjects.name, subjects.uoc ,course_enrolments.student, course_enrolments.mark
from course_enrolments, course_staff, courses, semesters, subjects
where course_staff.staff = 50413833
and course_staff.course = course_enrolments.course
and course_enrolments.course = courses.id
and courses.semester = semesters.id
and courses.subject = subjects.id
and course_enrolments.mark is not null

---------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------

--Q3:
-- function: Q3_subschool(): find subschool recursively
drop function Q3_subschool(integer);
create function Q3_subschool(org_id integer)
returns table(member integer)
as $$
with recursive cat as
(select t1.member, t1.owner from orgunit_groups t1 where t1.member = $1
union all
select t2.member, t2.owner from orgunit_groups t2
inner join cat on cat.member = t2.owner) 
select member from cat;
$$ language sql;

-- main function
drop type if exists CourseRecord cascade;
create type CourseRecord as (unswid integer, student_name text, course_records text);

create or replace function Q3(org_id integer, num_courses integer, min_score integer)
  returns setof CourseRecord
as $$
begin
if $1 not in (select orgunits.id from orgunits) then
raise exception 'INVALID ORGID';
end if;

return query
select t1.unswid, cast(t1.name as text), cast(string_agg(t1.course_records, chr(10))||chr(10) as text)
from
(
select people.unswid, people.name, cast(concat(subjects.code,', ',subjects.name,', ',
semesters.name,', ',orgunits.name,', ',course_enrolments.mark) as text) course_records, coalesce(course_enrolments.mark, 0) mark,
	ROW_NUMBER() OVER (PARTITION BY people.unswid order by coalesce(course_enrolments.mark, 0) desc) as RowDesc
from courses, course_enrolments, people, semesters, subjects, orgunits, (select * from Q3_subschool($1))members
(select people.unswid, count(course_enrolments.course), max(course_enrolments.mark)
from course_enrolments, courses, subjects, orgunits, people,
(select * from Q3_subschool($1)) members
where course_enrolments.course = courses.id
and course_enrolments.student = people.id
and courses.subject = subjects.id
and subjects.offeredby = orgunits.id
and orgunits.id = members.member
group by people.unswid
having count(course_enrolments.course) > $2
and max(course_enrolments.mark) >= $3 ) table2
where course_enrolments.student = people.id
and people.unswid = table2.unswid
and course_enrolments.course = courses.id
and courses.semester = semesters.id
and courses.subject = subjects.id
and subjects.offeredby = orgunits.id
and orgunits.id = members.member
group by people.unswid, people.name, course_records, course_enrolments.mark
) t1
where t1.rowdesc <= 5
group by t1.unswid, t1.name;
end
--... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;


---------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------

-- table 1: (unswid, name, subjects.code, subjects.name, 
--	semesters.name, orgunits.name, course_enrolments.mark)
select cast(t1.unswid as integer), cast(t1.name as text), cast(string_agg(t1.course_records, chr(10))||chr(10) as text)
from
(
select people.unswid, people.name, cast(concat(subjects.code,', ',subjects.name,', ',
semesters.name,', ',orgunits.name,', ',course_enrolments.mark) as text) course_records, coalesce(course_enrolments.mark, 0) mark,
	ROW_NUMBER() OVER (PARTITION BY people.unswid order by coalesce(course_enrolments.mark, 0) desc) as RowDesc
from courses, course_enrolments, people, semesters, subjects, orgunits,(select * from Q3_subschool(52)) members,
(select people.unswid, count(course_enrolments.course), max(course_enrolments.mark)
from course_enrolments, courses, subjects, orgunits, people,
(select * from Q3_subschool(52)) members
where course_enrolments.course = courses.id
and course_enrolments.student = people.id
and courses.subject = subjects.id
and subjects.offeredby = orgunits.id
and orgunits.id = members.member
group by people.unswid
having count(course_enrolments.course) > 35
and max(course_enrolments.mark) >= 100 ) table2
where course_enrolments.student = people.id
and people.unswid = table2.unswid
and course_enrolments.course = courses.id
and courses.semester = semesters.id
and courses.subject = subjects.id
and subjects.offeredby = orgunits.id
and orgunits.id = members.member
group by people.unswid, people.name, course_records, course_enrolments.mark
) t1
where t1.rowdesc <= 5
group by t1.unswid, t1.name;



-- table 2: (select student who meet requirement 1 and requirement 2)
select people.unswid, count(course_enrolments.course), max(course_enrolments.mark)
from course_enrolments, courses, subjects, orgunits, people,
(select * from Q3_subschool(52)) members
where course_enrolments.course = courses.id
and course_enrolments.student = people.id
and courses.subject = subjects.id
and subjects.offeredby = orgunits.id
and orgunits.id = members.member
group by people.unswid
having count(course_enrolments.course) > 35
and max(course_enrolments.mark) >= 100 





