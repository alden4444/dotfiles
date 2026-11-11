---
subject: Physics
code: "9702"
level: AS
exam_board: CIE
papers:
  - "Paper 1 (Multiple Choice)"
  - "Paper 2 (AS Level Structured Questions)"
  - "Paper 3 (Advanced Practical Skills)"
target_completion: 2027-04-23
status: In Progress
current_module: 1
---
# CIE AS Physics (9702)

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

### Module 1: Physical Quantities, Units & Kinematics
- [ ] **1.1 Physical Quantities and Units** `Ref: 1` `Student Book 1 pp. 2–19` `Target: 2026-09-16`
- [ ] **1.2 Kinematics** `Ref: 2.1` `Student Book 1 pp. 20–39` `Target: 2026-09-21`
- [ ] **Assignment 1** `Ref: 1 / 2.1` `Target: 2026-09-24` — Score: 

---

### Module 2: Accelerated Motion, Dynamics & Momentum
- [ ] **2.1 Accelerated Motion** `Ref: 2.2` `Student Book 1 pp. 40–55` `Target: 2026-09-30`
- [ ] **2.2 Dynamics & Momentum** `Ref: 3.1–3.2` `Student Book 1 pp. 56–77` `Target: 2026-10-06`
- [ ] **Assignment 2** `Ref: 2.2 / 3.1–3.2` `Target: 2026-10-08` — Score: 

---

### Module 3: Forces, Density & Pressure
- [ ] **3.1 Forces: Vectors and Moments** `Ref: 4.1` `Student Book 1 pp. 78–99` `Target: 2026-10-15`
- [ ] **3.2 Density & Pressure** `Ref: 4.2` `Student Book 1 pp. 100–113` `Target: 2026-10-20`
- [ ] **Assignment 3** `Ref: 4.1–4.2` `Target: 2026-10-22` — Score: 

---

### Module 4: Work, Energy, Power & Deformation
- [ ] **4.1 Work, Energy and Power** `Ref: 5` `Student Book 1 pp. 114–135` `Target: 2026-10-29`
- [ ] **4.2 Deformation of Solids** `Ref: 6` `Student Book 1 pp. 136–155` `Target: 2026-11-05`
- [ ] **Assignment 4** `Ref: 5 / 6` `Target: 2026-11-11` — Score: 

---

### Module 5: Waves & Superposition
- [ ] **5.1 Progressive Waves** `Ref: 7` `Student Book 1 pp. 156–181` `Target: 2026-11-18`
- [ ] **5.2 Superposition and Stationary Waves** `Ref: 8` `Student Book 1 pp. 182–209` `Target: 2026-11-24`
- [ ] **Assignment 5** `Ref: 7 / 8` `Target: 2026-11-26` — Score: 

---

### Module 6: Electricity & DC Circuits
- [ ] **6.1 Electric Current & Potential Difference** `Ref: 9` `Student Book 1 pp. 210–229` `Target: 2026-12-03`
- [ ] **6.2 Resistance, Resistivity & DC Circuits** `Ref: 10` `Student Book 1 pp. 230–257` `Target: 2026-12-09`
- [ ] **Assignment 6** `Ref: 9 / 10` `Target: 2026-12-14` — Score: 

---

### Module 7: Particle & Nuclear Physics
- [ ] **7.1 Atoms, Nuclei & Radiation** `Ref: 11.1` `Student Book 1 pp. 258–273` `Target: 2027-01-07`
- [ ] **7.2 Fundamental Particles** `Ref: 11.2` `Student Book 1 pp. 274–287` `Target: 2027-01-13`
- [ ] **Assignment 7** `Ref: 11.1–11.2` `Target: 2027-01-19` — Score: 

---

### Module 8: Practical Skills (Paper 3 Prep)
- [ ] **8.1 Practical Skills & Experimental Techniques** `Ref: 12` `Lab Book pp. 1–35` `Target: 2027-01-26`
- [ ] **8.2 Errors, Uncertainties & Data Analysis** `Ref: 12` `Lab Book pp. 36–70` `Target: 2027-02-02`
- [ ] **Assignment 8** `Ref: 12` `Target: 2027-02-05` — Score: 

---

### Module 9: Revision & Past Papers
- [ ] **9.1 Paper 1 (Multiple Choice) Techniques** `Ref: All` `Target: 2027-02-19`
- [ ] **9.2 Paper 2 Structured Questions Revision** `Ref: All` `Target: 2027-03-05`
- [ ] **9.3 Paper 3 Practical Skills Consolidation** `Ref: 12` `Target: 2027-03-19`
- [ ] **9.4 Full Mock Exams & Past Papers** `Ref: All` `Target: 2027-04-23`