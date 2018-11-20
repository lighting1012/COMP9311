-- COMP9311 18s1 Project 1
--
-- MyMyUNSW Solution Template


-- Q1: 
create or replace view Q1(unswid, name)
as
SELECT unswid, name
FROM People, Students, Course_enrolments
WHERE People.id = Students.id 
AND Students.stype = 'intl' 
AND course_enrolments.student = people.id 
AND course_enrolments.grade = 'HD'
GROUP BY unswid, name
HAVING count(course_enrolments.course) > 20;
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q2: 
create or replace view Q2(unswid, name)
as
SELECT rooms.unswid, rooms.longname
FROM rooms, buildings, room_types
WHERE rooms.building = buildings.id
AND rooms.rtype = room_types.id
AND buildings.name = 'Computer Science Building'
AND room_types.description = 'Meeting Room'
AND rooms.capacity >= 20;
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q3: 
create or replace view Q3(unswid, name)
as
SELECT people.unswid, people.name
FROM people
WHERE people.id in (SELECT course_staff.staff
					FROM course_staff, course_enrolments, people
					WHERE course_staff.course = course_enrolments.course 
					AND course_enrolments.student = people.id 
					AND people.name = 'Stefan Bilek'
					);
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q4:
create or replace view Q4(unswid, name)
as
(SELECT people.unswid, people.name
FROM people, course_enrolments, courses, subjects
WHERE people.id = course_enrolments.student 
AND course_enrolments.course = courses.id 
AND courses.subject = subjects.id 
AND subjects.code = 'COMP3331'
)
EXCEPT
(SELECT people.unswid, people.name
FROM people, course_enrolments, courses, subjects
WHERE people.id = course_enrolments.student 
AND course_enrolments.course = courses.id 
AND courses.subject = subjects.id 
AND subjects.code = 'COMP3231'
);
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q5: 
create or replace view Q5a(num)
as
SELECT count(distinct program_enrolments.student)
FROM program_enrolments, stream_enrolments, streams, semesters, students
WHERE program_enrolments.semester = semesters.id
AND semesters.name = 'Sem1 2011'
AND program_enrolments.id = stream_enrolments.partof
AND stream_enrolments.stream = streams.id
AND streams.name = 'Chemistry'
AND program_enrolments.student = students.id
AND students.stype = 'local';
--... SQL statements, possibly using other views/functions defined by you ...
;

-- Q5: 
create or replace view Q5b(num)
as
SELECT count(distinct students.id)
FROM students, program_enrolments, programs, orgunits, semesters
WHERE students.stype = 'intl'
AND students.id = program_enrolments.student
AND program_enrolments.program = programs.id
AND programs.offeredby = orgunits.id
AND orgunits.longname = 'School of Computer Science and Engineering'
AND program_enrolments.semester = semesters.id
AND semesters.name = 'Sem1 2011';
--... SQL statements, possibly using other views/functions defined by you ...
;


-- Q6:
create or replace function
	Q6(text) returns text
as
$$
SELECT subjects.code||' '||subjects.name||' '||subjects.uoc
FROM subjects
WHERE subjects.code = $1
--... SQL statements, possibly using other views/functions defined by you ...
$$ language sql;



-- Q7: 
create or replace view Q7(code, name)
as
SELECT programs.code, programs.name
FROM programs,
(SELECT programs.id as m1, count(program_enrolments.student) as n1
FROM students, program_enrolments, programs
WHERE students.stype = 'intl'
AND students.id = program_enrolments.student
AND program_enrolments.program = programs.id
GROUP BY m1
) t1,
(SELECT programs.id as m2, count(program_enrolments.student) as n2
FROM program_enrolments, programs
WHERE program_enrolments.program = programs.id
GROUP BY m2
) t2
WHERE programs.id = t1.m1
AND programs.id = t2.m2
AND t1.n1 * 1.0 / t2.n2 > 0.5;

--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q8:
create or replace view Q8(code, name, semester)
as
SELECT subjects.code, subjects.name, semesters.name
FROM course_enrolments, courses, subjects, semesters,
(SELECT course, avg
FROM (SELECT course_enrolments.course, 
	avg(course_enrolments.mark)
	FROM course_enrolments
	WHERE course_enrolments.mark is not null
	GROUP by course_enrolments.course
	HAVING count(course_enrolments.student) >= 15) as t1,

	(SELECT max(t1.avg) as mmm
	FROM (SELECT course_enrolments.course, 
	avg(course_enrolments.mark)
	FROM course_enrolments
	WHERE course_enrolments.mark is not null
	GROUP by course_enrolments.course
	HAVING count(course_enrolments.student) >= 15) as t1) as t2
WHERE t1.avg = t2.mmm) t1


WHERE subjects.id = courses.subject
AND courses.semester = semesters.id
AND courses.id = t1.course
GROUP BY subjects.code, subjects.name, semesters.name

--- (process)the course which have best average mark
SELECT course, avg
FROM (SELECT course_enrolments.course, 
	avg(course_enrolments.mark)
	FROM course_enrolments
	WHERE course_enrolments.mark is not null
	GROUP by course_enrolments.course
	HAVING count(course_enrolments.student) >= 15) as t1,

	(SELECT max(t1.avg) as mmm
	FROM (SELECT course_enrolments.course, 
	avg(course_enrolments.mark)
	FROM course_enrolments
	WHERE course_enrolments.mark is not null
	GROUP by course_enrolments.course
	HAVING count(course_enrolments.student) >= 15) as t1) as t2
WHERE t1.avg = t2.mmm


-- (process)the max average mark of all courses
SELECT max(t1.avg) as mmm
FROM (SELECT course_enrolments.course, 
	avg(course_enrolments.mark)
	FROM course_enrolments
	WHERE course_enrolments.mark is not null
	GROUP by course_enrolments.course
	HAVING count(course_enrolments.student) >= 15) as t1

--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q9:
create or replace view Q9(name, school, email, starting, num_subjects)
as


SELECT people.name, orgunits.longname as school, people.email, affiliations.starting, t2.num_subjects
FROM people, orgunits, orgunit_types, affiliations, staff_roles,

(SELECT staff, count(distinct t1.sss) num_subjects
FROM
(SELECT staff, subjects.code as sss
FROM course_staff, courses, subjects
WHERE course_staff.course = courses.id
AND courses.subject = subjects.id) t1
GROUP BY staff) t2

WHERE people.id = affiliations.staff
AND affiliations.ending is null
AND affiliations.isprimary = 't'
AND affiliations.role = staff_roles.id
AND staff_roles.name = 'Head of School'
AND affiliations.orgunit = orgunits.id
AND orgunits.utype = orgunit_types.id
AND orgunit_types.name = 'School'
AND affiliations.staff = t2.staff

--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q10:
create or replace view Q10(code, name, year, s1_HD_rate, s2_HD_rate)
as
SELECT t1.code, t1.name, right(cast(t1.year as varchar),2), t1.s1_hd_rate, t2.s2_hd_rate
FROM (SELECT subjects.code, subjects.name, semesters.year, semesters.term, t2.rate as s1_HD_rate, t2.course
FROM subjects, courses, semesters,
(SELECT code
FROM (SELECT subjects.code, semesters.year, semesters.term
FROM subjects, semesters, courses
WHERE subjects.id = courses.subject
AND courses.semester = semesters.id
GROUP BY subjects.code, semesters.year, semesters.term
HAVING semesters.year >= 2003
AND semesters.year <= 2012
AND subjects.code like 'COMP93%') t1
GROUP BY code
HAVING count(code) = 20) t1,
(SELECT course, coalesce(round(t1.count *1.0/t1.all, 2), 0.00) as rate
FROM (SELECT t1.course, t1.all, t2.count
FROM (SELECT course_enrolments.course, count(distinct course_enrolments.student) as all
FROM course_enrolments, courses, subjects,
(SELECT code
FROM (SELECT subjects.code, semesters.year, semesters.term
FROM subjects, semesters, courses
WHERE subjects.id = courses.subject
AND courses.semester = semesters.id
GROUP BY subjects.code, semesters.year, semesters.term
HAVING semesters.year >= 2003
AND semesters.year <= 2012
AND subjects.code like 'COMP93%') t1
GROUP BY code
HAVING count(code) = 20) t1
WHERE course_enrolments.mark >= 0
AND course_enrolments.course = courses.id
AND courses.subject = subjects.id
AND subjects.code = t1.code
GROUP BY course_enrolments.course) t1
LEFT JOIN
(SELECT course_enrolments.course, count(distinct course_enrolments.student)
FROM course_enrolments, courses, subjects,
(SELECT code
FROM (SELECT subjects.code, semesters.year, semesters.term
FROM subjects, semesters, courses
WHERE subjects.id = courses.subject
AND courses.semester = semesters.id
GROUP BY subjects.code, semesters.year, semesters.term
HAVING semesters.year >= 2003
AND semesters.year <= 2012
AND subjects.code like 'COMP93%') t1
GROUP BY code
HAVING count(code) = 20) t1
WHERE course_enrolments.mark >= 85
AND course_enrolments.course = courses.id
AND courses.subject = subjects.id
AND subjects.code = t1.code
GROUP BY course_enrolments.course) t2
ON t1.course = t2.course) t1) t2
WHERE subjects.code = t1.code
AND subjects.id = courses.subject
AND courses.id = t2.course
AND courses.semester = semesters.id
AND semesters.term = 'S1') t1,


(SELECT subjects.code, subjects.name, semesters.year, semesters.term, t2.rate as s2_HD_rate, t2.course
FROM subjects, courses, semesters,
(SELECT code
FROM (SELECT subjects.code, semesters.year, semesters.term
FROM subjects, semesters, courses
WHERE subjects.id = courses.subject
AND courses.semester = semesters.id
GROUP BY subjects.code, semesters.year, semesters.term
HAVING semesters.year >= 2003
AND semesters.year <= 2012
AND subjects.code like 'COMP93%') t1
GROUP BY code
HAVING count(code) = 20) t1,
(SELECT course, coalesce(round(t1.count *1.0/t1.all, 2), 0.00) as rate
FROM (SELECT t1.course, t1.all, t2.count
FROM (SELECT course_enrolments.course, count(distinct course_enrolments.student) as all
FROM course_enrolments, courses, subjects,
(SELECT code
FROM (SELECT subjects.code, semesters.year, semesters.term
FROM subjects, semesters, courses
WHERE subjects.id = courses.subject
AND courses.semester = semesters.id
GROUP BY subjects.code, semesters.year, semesters.term
HAVING semesters.year >= 2003
AND semesters.year <= 2012
AND subjects.code like 'COMP93%') t1
GROUP BY code
HAVING count(code) = 20) t1
WHERE course_enrolments.mark >= 0
AND course_enrolments.course = courses.id
AND courses.subject = subjects.id
AND subjects.code = t1.code
GROUP BY course_enrolments.course) t1
LEFT JOIN
(SELECT course_enrolments.course, count(distinct course_enrolments.student)
FROM course_enrolments, courses, subjects,
(SELECT code
FROM (SELECT subjects.code, semesters.year, semesters.term
FROM subjects, semesters, courses
WHERE subjects.id = courses.subject
AND courses.semester = semesters.id
GROUP BY subjects.code, semesters.year, semesters.term
HAVING semesters.year >= 2003
AND semesters.year <= 2012
AND subjects.code like 'COMP93%') t1
GROUP BY code
HAVING count(code) = 20) t1
WHERE course_enrolments.mark >= 85
AND course_enrolments.course = courses.id
AND courses.subject = subjects.id
AND subjects.code = t1.code
GROUP BY course_enrolments.course) t2
ON t1.course = t2.course) t1) t2
WHERE subjects.code = t1.code
AND subjects.id = courses.subject
AND courses.id = t2.course
AND courses.semester = semesters.id
AND semesters.term = 'S2') t2

WHERE t1.code = t2.code
AND t1.year = t2.year




--... with s1 rate
SELECT subjects.code, subjects.name, semesters.year, semesters.term, t2.rate as s1_HD_rate, t2.course
FROM subjects, courses, semesters,

(SELECT code
FROM (SELECT subjects.code, semesters.year, semesters.term
FROM subjects, semesters, courses
WHERE subjects.id = courses.subject
AND courses.semester = semesters.id
GROUP BY subjects.code, semesters.year, semesters.term
HAVING semesters.year >= 2003
AND semesters.year <= 2012
AND subjects.code like 'COMP93%') t1
GROUP BY code
HAVING count(code) = 20) t1,

(SELECT course, coalesce(round(t1.count *1.0/t1.all, 2), 0.00) as rate
FROM (SELECT t1.course, t1.all, t2.count
FROM (SELECT course_enrolments.course, count(distinct course_enrolments.student) as all
FROM course_enrolments, courses, subjects,
(SELECT code
FROM (SELECT subjects.code, semesters.year, semesters.term
FROM subjects, semesters, courses
WHERE subjects.id = courses.subject
AND courses.semester = semesters.id
GROUP BY subjects.code, semesters.year, semesters.term
HAVING semesters.year >= 2003
AND semesters.year <= 2012
AND subjects.code like 'COMP93%') t1
GROUP BY code
HAVING count(code) = 20) t1
WHERE course_enrolments.mark >= 0
AND course_enrolments.course = courses.id
AND courses.subject = subjects.id
AND subjects.code = t1.code
GROUP BY course_enrolments.course) t1
LEFT JOIN
(SELECT course_enrolments.course, count(distinct course_enrolments.student)
FROM course_enrolments, courses, subjects,
(SELECT code
FROM (SELECT subjects.code, semesters.year, semesters.term
FROM subjects, semesters, courses
WHERE subjects.id = courses.subject
AND courses.semester = semesters.id
GROUP BY subjects.code, semesters.year, semesters.term
HAVING semesters.year >= 2003
AND semesters.year <= 2012
AND subjects.code like 'COMP93%') t1
GROUP BY code
HAVING count(code) = 20) t1
WHERE course_enrolments.mark >= 85
AND course_enrolments.course = courses.id
AND courses.subject = subjects.id
AND subjects.code = t1.code
GROUP BY course_enrolments.course) t2
ON t1.course = t2.course) t1) t2

WHERE subjects.code = t1.code
AND subjects.id = courses.subject
AND courses.id = t2.course
AND courses.semester = semesters.id
AND semesters.term = 'S1'


--...with s2 rate
SELECT subjects.code, subjects.name, semesters.year, semesters.term, t2.rate as s2_HD_rate, t2.course
FROM subjects, courses, semesters,

(SELECT code
FROM (SELECT subjects.code, semesters.year, semesters.term
FROM subjects, semesters, courses
WHERE subjects.id = courses.subject
AND courses.semester = semesters.id
GROUP BY subjects.code, semesters.year, semesters.term
HAVING semesters.year >= 2003
AND semesters.year <= 2012
AND subjects.code like 'COMP93%') t1
GROUP BY code
HAVING count(code) = 20) t1,

(SELECT course, coalesce(round(t1.count *1.0/t1.all, 2), 0.00) as rate
FROM (SELECT t1.course, t1.all, t2.count
FROM (SELECT course_enrolments.course, count(distinct course_enrolments.student) as all
FROM course_enrolments, courses, subjects,
(SELECT code
FROM (SELECT subjects.code, semesters.year, semesters.term
FROM subjects, semesters, courses
WHERE subjects.id = courses.subject
AND courses.semester = semesters.id
GROUP BY subjects.code, semesters.year, semesters.term
HAVING semesters.year >= 2003
AND semesters.year <= 2012
AND subjects.code like 'COMP93%') t1
GROUP BY code
HAVING count(code) = 20) t1
WHERE course_enrolments.mark >= 0
AND course_enrolments.course = courses.id
AND courses.subject = subjects.id
AND subjects.code = t1.code
GROUP BY course_enrolments.course) t1
LEFT JOIN
(SELECT course_enrolments.course, count(distinct course_enrolments.student)
FROM course_enrolments, courses, subjects,
(SELECT code
FROM (SELECT subjects.code, semesters.year, semesters.term
FROM subjects, semesters, courses
WHERE subjects.id = courses.subject
AND courses.semester = semesters.id
GROUP BY subjects.code, semesters.year, semesters.term
HAVING semesters.year >= 2003
AND semesters.year <= 2012
AND subjects.code like 'COMP93%') t1
GROUP BY code
HAVING count(code) = 20) t1
WHERE course_enrolments.mark >= 85
AND course_enrolments.course = courses.id
AND courses.subject = subjects.id
AND subjects.code = t1.code
GROUP BY course_enrolments.course) t2
ON t1.course = t2.course) t1) t2

WHERE subjects.code = t1.code
AND subjects.id = courses.subject
AND courses.id = t2.course
AND courses.semester = semesters.id
AND semesters.term = 'S2'


--...(course.id, rate)
SELECT course, coalesce(round(t1.count *1.0/t1.all, 2), 0.00) as rate
FROM (SELECT t1.course, t1.all, t2.count
FROM (SELECT course_enrolments.course, count(distinct course_enrolments.student) as all
FROM course_enrolments, courses, subjects,

(SELECT code
FROM (SELECT subjects.code, semesters.year, semesters.term
FROM subjects, semesters, courses
WHERE subjects.id = courses.subject
AND courses.semester = semesters.id
GROUP BY subjects.code, semesters.year, semesters.term
HAVING semesters.year >= 2003
AND semesters.year <= 2012
AND subjects.code like 'COMP93%') t1
GROUP BY code
HAVING count(code) = 20) t1

WHERE course_enrolments.mark >= 0
AND course_enrolments.course = courses.id
AND courses.subject = subjects.id
AND subjects.code = t1.code
GROUP BY course_enrolments.course) t1

LEFT JOIN

(SELECT course_enrolments.course, count(distinct course_enrolments.student)
FROM course_enrolments, courses, subjects,

(SELECT code
FROM (SELECT subjects.code, semesters.year, semesters.term
FROM subjects, semesters, courses
WHERE subjects.id = courses.subject
AND courses.semester = semesters.id
GROUP BY subjects.code, semesters.year, semesters.term
HAVING semesters.year >= 2003
AND semesters.year <= 2012
AND subjects.code like 'COMP93%') t1
GROUP BY code
HAVING count(code) = 20) t1

WHERE course_enrolments.mark >= 85
AND course_enrolments.course = courses.id
AND courses.subject = subjects.id
AND subjects.code = t1.code
GROUP BY course_enrolments.course) t2

ON t1.course = t2.course) t1



--...(course.id, count(HD), count(all))
SELECT t1.course, t1.all, t2.count
FROM (SELECT course_enrolments.course, count(distinct course_enrolments.student) as all
FROM course_enrolments, courses, subjects,

(SELECT code
FROM (SELECT subjects.code, semesters.year, semesters.term
FROM subjects, semesters, courses
WHERE subjects.id = courses.subject
AND courses.semester = semesters.id
GROUP BY subjects.code, semesters.year, semesters.term
HAVING semesters.year >= 2003
AND semesters.year <= 2012
AND subjects.code like 'COMP93%') t1
GROUP BY code
HAVING count(code) = 20) t1

WHERE course_enrolments.mark >= 0
AND course_enrolments.course = courses.id
AND courses.subject = subjects.id
AND subjects.code = t1.code
GROUP BY course_enrolments.course) t1

LEFT JOIN

(SELECT course_enrolments.course, count(distinct course_enrolments.student)
FROM course_enrolments, courses, subjects,

(SELECT code
FROM (SELECT subjects.code, semesters.year, semesters.term
FROM subjects, semesters, courses
WHERE subjects.id = courses.subject
AND courses.semester = semesters.id
GROUP BY subjects.code, semesters.year, semesters.term
HAVING semesters.year >= 2003
AND semesters.year <= 2012
AND subjects.code like 'COMP93%') t1
GROUP BY code
HAVING count(code) = 20) t1

WHERE course_enrolments.mark >= 85
AND course_enrolments.course = courses.id
AND courses.subject = subjects.id
AND subjects.code = t1.code
GROUP BY course_enrolments.course) t2

ON t1.course = t2.course



--...(course.id, count(all))
SELECT course_enrolments.course, count(distinct course_enrolments.student) as all
FROM course_enrolments, courses, subjects,

(SELECT code
FROM (SELECT subjects.code, semesters.year, semesters.term
FROM subjects, semesters, courses
WHERE subjects.id = courses.subject
AND courses.semester = semesters.id
GROUP BY subjects.code, semesters.year, semesters.term
HAVING semesters.year >= 2003
AND semesters.year <= 2012
AND subjects.code like 'COMP93%') t1
GROUP BY code
HAVING count(code) = 20) t1

WHERE course_enrolments.mark >= 0
AND course_enrolments.course = courses.id
AND courses.subject = subjects.id
AND subjects.code = t1.code
GROUP BY course_enrolments.course


--... (course.id, count(HD))
SELECT course_enrolments.course, count(distinct course_enrolments.student)
FROM course_enrolments, courses, subjects,

(SELECT code
FROM (SELECT subjects.code, semesters.year, semesters.term
FROM subjects, semesters, courses
WHERE subjects.id = courses.subject
AND courses.semester = semesters.id
GROUP BY subjects.code, semesters.year, semesters.term
HAVING semesters.year >= 2003
AND semesters.year <= 2012
AND subjects.code like 'COMP93%') t1
GROUP BY code
HAVING count(code) = 20) t1

WHERE course_enrolments.mark >= 85
AND course_enrolments.course = courses.id
AND courses.subject = subjects.id
AND subjects.code = t1.code
GROUP BY course_enrolments.course



--... select 9311, 9331
SELECT code
FROM (SELECT subjects.code, semesters.year, semesters.term
FROM subjects, semesters, courses
WHERE subjects.id = courses.subject
AND courses.semester = semesters.id
GROUP BY subjects.code, semesters.year, semesters.term
HAVING semesters.year >= 2003
AND semesters.year <= 2012
AND subjects.code like 'COMP93%') t1
GROUP BY code
HAVING count(code) = 20




--... (subject.code, semesters.year, semesters.term)
SELECT subjects.code, semesters.year, semesters.term
FROM subjects, semesters, courses
WHERE subjects.id = courses.subject
AND courses.semester = semesters.id
GROUP BY subjects.code, semesters.year, semesters.term
HAVING semesters.year >= 2003
AND semesters.year <= 2012
AND subjects.code like 'COMP93%'



--... SQL statements, possibly using other views/functions defined by you ...
;










