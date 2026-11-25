# คู่มืออธิบายโปรเจกต์ Employee Query Lab

เอกสารนี้สรุปภาพรวมระบบ สิ่งที่เพิ่มและแก้ไข หลักการของ SQL และตำแหน่งไฟล์ เพื่อใช้เตรียมอธิบายโปรเจกต์

## ภาพรวมระบบ

โปรเจกต์เป็นเว็บแอป Flask ที่อ่านข้อมูลพนักงานจาก PostgreSQL โดยใช้ Docker Compose สำหรับเปิดฐานข้อมูล, pgAdmin และเว็บแอป ตารางหลักชื่อ `employees` มีคอลัมน์ `id`, `first_name`, `last_name`, `department`, `salary` และ `hire_date`

หน้าเว็บเดิมค้นหารายชื่อพนักงานตามแผนกได้ งานที่เพิ่มคือ query วิเคราะห์ข้อมูล 2 แบบ พร้อมปุ่มและตารางผลลัพธ์

## ฟังก์ชันบนหน้าเว็บ

### 1. ค้นหาพนักงานตามแผนก (ฟังก์ชันเดิม)

ผู้ใช้ระบุชื่อแผนก ระบบใช้ `WHERE department ILIKE %s` เพื่อค้นหาโดยไม่แยกตัวพิมพ์เล็กและใหญ่ ถ้าไม่ระบุแผนกจะแสดงพนักงานทั้งหมด

### 2. สถิติเงินเดือนรายแผนก (query ที่เพิ่ม)

**ตอบคำถาม:** แต่ละแผนกมีพนักงานกี่คน เงินเดือนเฉลี่ยเท่าไร และเงินเดือนสูงสุด/ต่ำสุดเท่าไร

```sql
SELECT department, COUNT(*) AS employee_count,
       AVG(salary) AS average_salary,
       MAX(salary) AS highest_salary,
       MIN(salary) AS lowest_salary
FROM employees
GROUP BY department
ORDER BY department;
```

- `GROUP BY department` รวมแถวพนักงานที่อยู่แผนกเดียวกันเป็นกลุ่ม
- `COUNT(*)` นับจำนวนพนักงานในแต่ละกลุ่ม
- `AVG`, `MAX`, `MIN` คำนวณเงินเดือนเฉลี่ย สูงสุด และต่ำสุดภายในกลุ่มนั้น
- ผลลัพธ์จึงมีหนึ่งแถวต่อหนึ่งแผนก และเรียงตามชื่อแผนก

### 3. พนักงานที่เงินเดือนสูงกว่าค่าเฉลี่ยแผนกตัวเอง (query ที่เพิ่มและปรับล่าสุด)

**ตอบคำถาม:** พนักงานคนใดได้เงินเดือนมากกว่าค่าเฉลี่ยของพนักงานในแผนกเดียวกัน พร้อมแสดงค่าเฉลี่ยเพื่อใช้เปรียบเทียบ

```sql
SELECT first_name, last_name, department, salary, hire_date,
       (
           SELECT AVG(e2.salary)
           FROM employees e2
           WHERE e2.department = e.department
       ) AS department_average
FROM employees e
WHERE e.salary > (
    SELECT AVG(e2.salary)
    FROM employees e2
    WHERE e2.department = e.department
)
ORDER BY department, salary DESC, last_name, first_name;
```

- Query ด้านนอกตั้งชื่อแถวพนักงานปัจจุบันว่า `e`
- Subquery ด้านในอ่านตาราง `employees` อีกครั้งในชื่อ `e2` และ `WHERE e2.department = e.department` ทำให้คำนวณค่าเฉลี่ยเฉพาะแผนกของพนักงานแถวนั้น หลักการนี้เรียกว่า correlated subquery เพราะ subquery อ้างถึงค่าจาก query ชั้นนอก
- เงื่อนไข `e.salary > (subquery)` เลือกเฉพาะคนที่เงินเดือนสูงกว่าค่าเฉลี่ยแผนก
- Subquery ในส่วน `SELECT` คำนวณค่าเฉลี่ยเดียวกันเพื่อแสดงเป็นคอลัมน์ `department_average`
- `ORDER BY` เรียงแผนกก่อน ตามด้วยเงินเดือนจากมากไปน้อย และชื่อเพื่อให้ผลเรียงสม่ำเสมอ

Query นี้ใช้ correlated subquery เพื่อหาค่าเฉลี่ยของแผนกของพนักงานแต่ละคน แล้วเลือกและแสดงเฉพาะข้อมูลที่เกี่ยวข้อง

## การเพิ่มข้อมูลพนักงานตัวอย่าง

เพิ่มไฟล์ `init/zz_more_employees.sql` เพื่อเพิ่มข้อมูลตัวอย่างได้สูงสุด 230 คน จากข้อมูลตั้งต้น 70 คน รวมเป็น 300 คนเมื่อเริ่มจากฐานข้อมูลว่าง

- สร้างชุดชื่อและนามสกุลจาก `unnest(ARRAY[...])` สองชุด แล้วใช้ `CROSS JOIN` สร้างคู่ชื่อ
- `NOT EXISTS` ตรวจว่าคู่ชื่อและนามสกุลนั้นยังไม่มีใน `employees` ก่อนนำเข้า จึงหลีกเลี่ยงการเพิ่มชื่อเต็มคู่เดิมซ้ำ
- `ORDER BY random()` และ `LIMIT 230` สุ่มเลือกคู่ที่ยังไม่มีได้ไม่เกิน 230 คู่
- เลือกแผนกจากรายการด้วย `random()` และกำหนดเงินเดือนตั้งต้นต่างกันตามแผนก ก่อนสุ่มเพิ่ม พร้อมสุ่มวันเริ่มงาน
- `setseed(0.42)` กำหนด seed ของการสุ่ม เพื่อให้การสุ่มทำซ้ำได้ภายใต้ข้อมูลตั้งต้นและลำดับการประมวลผลเดียวกัน

การตรวจชื่อซ้ำใช้คู่ `first_name` และ `last_name` ไม่ได้บังคับให้ชื่อแต่ละส่วนไม่ซ้ำกันเดี่ยว ๆ และ SQL นี้ไม่ได้กำหนดจำนวนพนักงานสูงสุดรวมไว้ที่ 300 หากนำไปรันซ้ำจะเพิ่มคู่ชื่อที่ยังไม่มีได้อีก จึงควรรันครั้งเดียวเมื่อต้องการข้อมูลชุด 300 คน

## ไฟล์ที่เกี่ยวข้องและสิ่งที่ทำ

| ไฟล์ | หน้าที่/การเปลี่ยนแปลง |
|---|---|
| `web-app/app.py` | เชื่อมต่อ PostgreSQL และจัดการ action ของฟอร์ม เพิ่ม query สถิติรายแผนกและ query เงินเดือนสูงกว่าค่าเฉลี่ยแผนก รวมทั้งแก้ query หลังสุดให้ใช้ correlated subquery |
| `web-app/templates/index.html` | แสดงฟอร์มค้นหา ปุ่ม query ตารางสถิติ และตารางรายชื่อพนักงานพร้อมค่าเฉลี่ยแผนก |
| `init/init.sql` | สร้างตาราง `employees` และเพิ่มข้อมูลพนักงานตั้งต้น 70 คน |
| `init/zz_more_employees.sql` | เพิ่มข้อมูลพนักงานตัวอย่างได้สูงสุด 230 คนด้วยชุดชื่อ/นามสกุลและการสุ่ม |
| `docker-compose.yml` | กำหนดบริการ PostgreSQL, pgAdmin และเว็บแอป รวมถึง mount โฟลเดอร์ `init` ให้ PostgreSQL ประมวลผล SQL ตอนสร้าง data volume ใหม่ |
| `PROJECT_WORK_SUMMARY.md` | บันทึกสรุปงานและสถานะการตรวจสอบ |

ระหว่างแก้เว็บเคยพบการเรียก `fetchall()` ซ้ำ ทำให้การอ่านครั้งที่สองได้ผลลัพธ์ว่างและทับข้อมูลเดิม จึงลบการอ่านผลซ้ำออก

## เส้นทางการทำงานของ query ในเว็บ

ฟอร์มใน `index.html` ส่งค่า `action` แบบ POST มายัง route `/` ใน `app.py` จากนั้น Python ตรวจ action แล้วรัน SQL ที่ตรงกันด้วย `cur.execute()` อ่านผลด้วย `cur.fetchall()` และส่งข้อมูลไป render ใน template

- `department` ใช้ค้นหาตามแผนกหรือแสดงทั้งหมด
- `department_stats` ใช้ query สรุปสถิติและส่งผลไปแสดงในตารางสถิติ
- `above_department_average` ใช้ query correlated subquery แล้วส่งรายชื่อกับค่าเฉลี่ยไปแสดงในตารางพนักงาน

## การรันโปรเจกต์

เปิด PowerShell ที่โฟลเดอร์โปรเจกต์ แล้วสั่ง:

```powershell
docker compose up --build -d
docker compose ps
```

เว็บแอปเปิดที่ <http://localhost:5001> และ pgAdmin ที่ <http://localhost:5050> PostgreSQL map พอร์ต `5432` ไว้ที่เครื่อง

สคริปต์ใน `/docker-entrypoint-initdb.d` จะทำงานเมื่อ PostgreSQL สร้าง data volume ว่างครั้งแรกเท่านั้น หากมี volume เดิมอยู่แล้ว ไฟล์เพิ่มพนักงานจะไม่ทำงานอัตโนมัติ สามารถสั่งรันไฟล์ใน container ได้ครั้งเดียวด้วย:

```powershell
docker compose exec -T postgres psql -U postgres -d labdb -f /docker-entrypoint-initdb.d/zz_more_employees.sql
```

หลีกเลี่ยง `docker compose down -v` เว้นแต่ตั้งใจลบข้อมูลใน volume เพราะคำสั่งนี้ลบฐานข้อมูลที่เก็บไว้ด้วย

## สถานะการทดสอบ

ตรวจสอบโค้ดและ diff ของไฟล์แล้ว แต่ในรอบงานนี้ยังไม่ได้รันเว็บแอปหรือ query กับ PostgreSQL ดังนั้นยังไม่มีการยืนยันผลจากการทำงานจริงใน container
