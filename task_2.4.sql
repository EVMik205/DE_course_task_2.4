-- Выполните следующие запросы:

/*
  a. Попробуйте вывести не просто самую высокую зарплату во всей
  команде, а вывести именно фамилию сотрудника с самой высокой зарплатой.
*/
SELECT Name, Salary FROM Employees WHERE Salary = (SELECT MAX(Salary) FROM Employees);

/*
  b. Попробуйте вывести фамилии сотрудников в алфавитном порядке
*/
SELECT Name FROM Employees ORDER BY Name;

/*
  c. Рассчитайте средний стаж для каждого уровня сотрудников
*/
SELECT Grade, AVG(AGE(DATE(NOW()), StartDate)) AS Experience FROM Employees GROUP BY Grade ORDER BY Grade;

/*
  d. Выведите фамилию сотрудника и название отдела, в котором он работает
*/
SELECT e.Name, d.Name FROM Employees e
JOIN Departments d 
ON e.Departmentid = d.Id;

/*
  e. Выведите название отдела и фамилию сотрудника с самой высокой
  зарплатой в данном отделе и саму зарплату также.
*/
SELECT d.Name, e.Name, e.Salary FROM Employees e
JOIN Departments d 
ON e.DepartmentId = d.Id
WHERE Salary = (SELECT MAX(Salary) FROM Employees);

/*
  f.* Выведите название отдела, сотрудники которого получат наибольшую
  премию по итогам года. Как рассчитать премию можно узнать в последнем
  задании предыдущей домашней работы.
*/

WITH Bonus_Tmp AS (
SELECT *, Q1Bonus*Q2Bonus*Q3Bonus*Q4Bonus AS Bonus FROM
(SELECT *, 
	CASE
		WHEN Q1Mark = 'A' THEN 1.2
		WHEN Q1Mark = 'B' THEN 1.1
		WHEN Q1Mark = 'C' THEN 1
		WHEN Q1Mark = 'D' THEN 0.9
		WHEN Q1Mark = 'E' THEN 0.8
		ELSE 1 END AS Q1Bonus,
	CASE
		WHEN Q2Mark = 'A' THEN 1.2
		WHEN Q2Mark = 'B' THEN 1.1
		WHEN Q2Mark = 'C' THEN 1
		WHEN Q2Mark = 'D' THEN 0.9
		WHEN Q2Mark = 'E' THEN 0.8
		ELSE 1 END AS Q2Bonus,
	CASE
		WHEN Q3Mark = 'A' THEN 1.2
		WHEN Q3Mark = 'B' THEN 1.1
		WHEN Q3Mark = 'C' THEN 1
		WHEN Q3Mark = 'D' THEN 0.9
		WHEN Q3Mark = 'E' THEN 0.8
		ELSE 1 END AS Q3Bonus,
	CASE
		WHEN Q4Mark = 'A' THEN 1.2
		WHEN Q4Mark = 'B' THEN 1.1
		WHEN Q4Mark = 'C' THEN 1
		WHEN Q4Mark = 'D' THEN 0.9
		WHEN Q4Mark = 'E' THEN 0.8
		ELSE 1 END AS Q4Bonus
FROM Marks) AS BM
)
SELECT b.Bonus, e.Name, d.Name FROM Bonus_Tmp b
JOIN Employees e
ON b.employeeid = e.id
JOIN Departments d
ON e.DepartmentId = d.Id
WHERE b.Bonus = (SELECT MAX(b.Bonus) FROM Bonus_Tmp b);

/*
  g.* Проиндексируйте зарплаты сотрудников с учетом коэффициента премии.
  Для сотрудников с коэффициентом премии больше 1.2 – размер индексации
  составит 20%, для сотрудников с коэффициентом премии от 1 до 1.2
  размер индексации составит 10%. Для всех остальных сотрудников индексация
  не предусмотрена.
*/
SELECT *, IndexBonus*Salary AS NewSalary FROM
(SELECT *, 
	CASE
		WHEN Bonus > 1.2 THEN 1.2
		WHEN Bonus > 1 AND Bonus <= 1.2 THEN 1.1
		ELSE 1.0 END AS IndexBonus
FROM Employees) AS Emps;

/*
  h.*** По итогам индексации отдел финансов хочет получить следующий отчет:
  вам необходимо на уровень каждого отдела вывести следующую информацию:

  i. Название отдела
  ii. Фамилию руководителя
  iii. Количество сотрудников
  iv. Средний стаж
  v. Средний уровень зарплаты
  vi. Количество сотрудников уровня junior
  vii. Количество сотрудников уровня middle
  viii. Количество сотрудников уровня senior
  ix. Количество сотрудников уровня lead
  x. Общий размер оплаты труда всех сотрудников до индексации
  xi. Общий размер оплаты труда всех сотрудников после индексации
  xii. Общее количество оценок А
  xiii. Общее количество оценок B
  xiv. Общее количество оценок C
  xv. Общее количество оценок D
  xvi. Общее количество оценок Е
  xvii. Средний показатель коэффициента премии
  xviii. Общий размер премии.
  xix. Общую сумму зарплат(+ премии) до индексации
  xx. Общую сумму зарплат(+ премии) после индексации(премии не
  индексируются)
  xxi. Разницу в % между предыдущими двумя суммами(первая/вторая)
*/
WITH
-- производные зарплат для сотрудников
NewSalaryTable AS (
SELECT Id, DepartmentId, StartDate, Salary, Bonus,
-- зарплата после индексации
	IndexBonus*Salary AS NewSalary,
-- размер премии
	((Bonus-1)*Salary) AS BonusSize,
-- зарплата с премией
	(Salary+((Bonus-1)*Salary)) AS SalaryWithBonus,
-- зарплата после индексации с премией
	((IndexBonus*Salary)+((Bonus-1)*Salary)) AS NewSalaryWithBonus
FROM 
	(SELECT *, CASE
		WHEN Bonus > 1.2 THEN 1.2
		WHEN Bonus > 1 AND Bonus <= 1.2 THEN 1.1
		ELSE 1.0 END AS IndexBonus
	FROM Employees) AS Emp
),
-- агрегация зарплат и премий сотрудников по отделам
SalaryInfo AS (
SELECT DepartmentId, 
-- средний стаж
	AVG(AGE(DATE(NOW()), StartDate)) AS ExperienceAvg,
-- средняя и суммарная зарплаты
	AVG(Salary) AS SalaryAvg, SUM(Salary) AS SalarySum,
-- средняя зарплата после индексации
	SUM(NewSalary) AS NewSalarySum,
-- средний показатель коэффициента премии
	AVG(Bonus) AS BonusAvg,
-- общий размер премии
	SUM(BonusSize) AS BonusSum,
-- суммарные зарплаты с премией до и после индексации
	SUM(SalaryWithBonus) AS SalaryWithBonusSum, SUM(NewSalaryWithBonus) AS NewSalaryWithBonusSum
FROM NewSalaryTable GROUP BY Departmentid
),
-- подсчёт сотрудников по грейдам
GradesCount AS (
SELECT DepartmentId,
   COUNT(CASE WHEN Grade='junior' THEN 1 END) AS Juniors,
   COUNT(CASE WHEN Grade='middle' THEN 1 END) AS Middles,
   COUNT(CASE WHEN Grade='senior' THEN 1 END) AS Seniors,
   COUNT(CASE WHEN Grade='lead' THEN 1 END) AS Leads,
   COUNT(Id) AS Total
FROM Employees e GROUP BY DepartmentId ORDER BY DepartmentId 
),
-- соединяем оценки и сотрудников
MarksByDepartments AS (
SELECT e.DepartmentId, m.Q1Mark, m.Q2Mark, m.Q3Mark, m.Q4Mark FROM Marks m
JOIN Employees e 
ON m.EmployeeId = e.Id
),
-- считаем оценки по кварталам для каждого отдела
MarksCountTmp AS (
SELECT DepartmentId,
	COUNT(CASE WHEN Q1Mark='A' THEN 1 END) AS A1Marks,
	COUNT(CASE WHEN Q2Mark='A' THEN 1 END) AS A2Marks,
	COUNT(CASE WHEN Q3Mark='A' THEN 1 END) AS A3Marks,
	COUNT(CASE WHEN Q4Mark='A' THEN 1 END) AS A4Marks,
	COUNT(CASE WHEN Q1Mark='B' THEN 1 END) AS B1Marks,
	COUNT(CASE WHEN Q2Mark='B' THEN 1 END) AS B2Marks,
	COUNT(CASE WHEN Q3Mark='B' THEN 1 END) AS B3Marks,
	COUNT(CASE WHEN Q4Mark='B' THEN 1 END) AS B4Marks,
	COUNT(CASE WHEN Q1Mark='C' THEN 1 END) AS C1Marks,
	COUNT(CASE WHEN Q2Mark='C' THEN 1 END) AS C2Marks,
	COUNT(CASE WHEN Q3Mark='C' THEN 1 END) AS C3Marks,
	COUNT(CASE WHEN Q4Mark='C' THEN 1 END) AS C4Marks,
	COUNT(CASE WHEN Q1Mark='D' THEN 1 END) AS D1Marks,
	COUNT(CASE WHEN Q2Mark='D' THEN 1 END) AS D2Marks,
	COUNT(CASE WHEN Q3Mark='D' THEN 1 END) AS D3Marks,
	COUNT(CASE WHEN Q4Mark='D' THEN 1 END) AS D4Marks,
	COUNT(CASE WHEN Q1Mark='E' THEN 1 END) AS E1Marks,
	COUNT(CASE WHEN Q2Mark='E' THEN 1 END) AS E2Marks,
	COUNT(CASE WHEN Q3Mark='E' THEN 1 END) AS E3Marks,
	COUNT(CASE WHEN Q4Mark='E' THEN 1 END) AS E4Marks
FROM MarksByDepartments GROUP BY DepartmentId ORDER BY DepartmentId 
),
-- общая сумма каждой из оценок
MarksCount AS (
SELECT *,
	(A1Marks+A2Marks+A3Marks+A4Marks) AS AMarks,
	(B1Marks+B2Marks+B3Marks+B4Marks) AS BMarks,
	(C1Marks+C2Marks+C3Marks+C4Marks) AS CMarks,
	(D1Marks+D2Marks+D3Marks+D4Marks) AS DMarks,
	(E1Marks+E2Marks+E3Marks+E4Marks) AS EMarks
FROM MarksCountTmp ORDER BY DepartmentId
)
-- сводим витрину
SELECT
-- Название отдела
d.Name,
-- Фамилия руководителя
d.Headname,
-- Количество сотрудников
d.EmployeeCount,
-- Средний стаж
si.ExperienceAvg,
-- Средний уровень зарплаты
si.SalaryAvg,
-- Количество сотрудников уровня junior
gc.Juniors,
-- Количество сотрудников уровня middle
gc.Middles,
-- Количество сотрудников уровня senior
gc.Seniors,
-- Количество сотрудников уровня lead
gc.Leads,
-- Общий размер оплаты труда всех сотрудников до индексации
si.SalarySum,
-- Общий размер оплаты труда всех сотрудников после индексации
si.NewSalarySum,
-- Общее количество оценок А
AMarks,
-- Общее количество оценок B
BMarks,
-- Общее количество оценок C
CMarks,
-- Общее количество оценок D
DMarks,
-- Общее количество оценок Е
EMarks,
-- Средний показатель коэффициента премии
si.BonusAvg,
-- Общий размер премии
si.BonusSum,
-- Общая сумма зарплат(+ премии) до индексации
si.SalaryWithBonusSum,
-- Общая сумма зарплат(+ премии) после индексации (премии не индексируются)
si.NewSalaryWithBonusSum,
-- Разница в % между предыдущими двумя суммами (первая/вторая)
(((si.NewSalaryWithBonusSum - si.SalaryWithBonusSum) / si.NewSalaryWithBonusSum) * 100) AS SalarySumPercentDiff
FROM Departments d 
JOIN SalaryInfo si
ON d.Id = si.DepartmentId
JOIN GradesCount gc
ON d.Id = gc.DepartmentId
JOIN MarksCount mc
ON d.Id = mc.DepartmentId
ORDER by d.Id
