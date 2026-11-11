---
subject: Computer Science
code: "9618"
level: AS
exam_board: CIE
papers:
  - "Paper 1 (Theory Fundamentals)"
  - "Paper 2 (Fundamental Problem-Solving & Programming Skills)"
target_completion: 2027-04-23
status: In Progress
current_module: 1
---
# CIE AS Computer Science (9618)

> [!quote] Progress
> ```dataviewjs
> const file = dv.current();
> 
> // 1. Count main units only (ignoring sub-tasks)
> const allTasks = file.file.tasks;
> const parentTasks = allTasks.filter(t => !t.parent);
> const completed = parentTasks.filter(t => t.completed).length;
> const total = parentTasks.length;
> const percent = total > 0 ? Math.round((completed / total) * 100) : 0;
> 
> // 2. Extract plain scores like "Score: 85%" or "Score: 85"
> const scores = [];
> for (let t of allTasks) {
>   const match = t.text.match(/Score:\s*(\d+(?:\.\d+)?)/i);
>   if (match) {
>     scores.push(parseFloat(match[1]));
>   }
> }
> 
> const avg = scores.length > 0 
>   ? Math.round(scores.reduce((a, b) => a + b, 0) / scores.length) + "%" 
>   : "—";
> 
> dv.paragraph(`
> * **Progress:** **${percent}%** (${completed} / ${total} completed)
> * **Average Assignment Score:** **${avg}** (${scores.length} marked)
> `);
> ```

---
### Module 1: Information Representation
- [x] **1.1 Number Representation** `Ref: 1.1` `Pages 2–22` `Target: 2026-09-14`
- [x] **1.2 Images and Sound** `Ref: 1.2–1.3` `Pages 23–36` `Target: 2026-09-18`
- [x] **1.3 Compression and Text** `Ref: 1.4` `Pages 37–46` `Target: 2026-09-23`
- [x] **Assignment 1** `Ref: 1.1–1.4` `Target: 2026-09-25` — Score: 

---

### Module 2: Communication & Internet Technologies
- [ ] **2.1 Networks and Protocols** `Ref: 2.1` `Pages 47–71` `Target: 2026-10-02`
- [ ] **2.2 Internet and Cloud** `Ref: 2.2` `Pages 72–88` `Target: 2026-10-07`
- [ ] **Assignment 2** `Ref: 2.1–2.2` `Target: 2026-10-09` — Score: 

---

### Module 3: Hardware & Virtual Machines
- [ ] **3.1 Computers and Components** `Ref: 3.1` `Pages 89–108` `Target: 2026-10-14`
- [ ] **3.2 Logic Gates and Circuits** `Ref: 3.2` `Pages 109–128` `Target: 2026-10-19`
- [ ] **Assignment 3** `Ref: 3.1–3.2` `Target: 2026-10-23` — Score: 

---

### Module 4: System Software & Assembly
- [ ] **4.1 Operating Systems & Utilities** `Ref: 4.1` `Pages 129–147` `Target: 2026-10-30`
- [ ] **4.2 Language Translators** `Ref: 4.2` `Pages 148–158` `Target: 2026-11-04`
- [ ] **4.3 Assembly Language** `Ref: 4.3` `Pages 159–175` `Target: 2026-11-09`
- [ ] **Assignment 4** `Ref: 4.1–4.3` `Target: 2026-11-13` — Score: 

---

### Module 5: Security, Privacy & Ethics
- [ ] **5.1 Data Security & Privacy** `Ref: 5.1` `Pages 176–194` `Target: 2026-11-20`
- [ ] **5.2 Integrity & Ethics** `Ref: 5.2` `Pages 195–211` `Target: 2026-11-25`
- [ ] **Assignment 5** `Ref: 5.1–5.2` `Target: 2026-11-30` — Score: 

---

### Module 6: Databases & Relational Models
- [ ] **6.1 Database Concepts** `Ref: 6.1` `Pages 212–228` `Target: 2026-12-07`
- [ ] **6.2 Database Normalisation & DDL/DML** `Ref: 6.2` `Pages 229–254` `Target: 2026-12-11`
- [ ] **Assignment 6** `Ref: 6.1–6.2` `Target: 2026-12-16` — Score: 

---

### Module 7: Algorithm Design & Problem-Solving
- [ ] **7.1 Computational Thinking & Flowcharts** `Ref: 7.1` `Pages 255–278` `Target: 2027-01-08`
- [ ] **7.2 Algorithms: Search & Sort** `Ref: 7.2` `Pages 279–302` `Target: 2027-01-15`
- [ ] **Assignment 7** `Ref: 7.1–7.2` `Target: 2027-01-20` — Score: 

---

### Module 8: Data Representation & Structures in Python
- [ ] **8.1 Data Types & Structures** `Ref: 8.1` `Pages 303–326` `Target: 2027-01-27`
- [ ] **8.2 Arrays & File Handling** `Ref: 8.2` `Pages 327–348` `Target: 2027-02-03`
- [ ] **Assignment 8** `Ref: 8.1–8.2` `Target: 2027-02-08` — Score: 

---

### Module 9: Programming & Software Development
- [ ] **9.1 Subroutines & Parameter Passing** `Ref: 9.1` `Pages 349–374` `Target: 2027-02-15`
- [ ] **9.2 Software Development Lifecycle & Testing** `Ref: 9.2` `Pages 375–398` `Target: 2027-02-22`
- [ ] **Assignment 9** `Ref: 9.1–9.2` `Target: 2027-02-26` — Score: 

---

### Module 10: Revision & Past Papers
- [ ] **10.1 Paper 1 Fundamentals Revision** `Ref: 1–6` `Target: 2027-03-12`
- [ ] **10.2 Paper 2 Problem-Solving Revision** `Ref: 7–9` `Target: 2027-03-26`
- [ ] **10.3 Mock Exams & Past Papers** `Ref: All` `Target: 2027-04-23`