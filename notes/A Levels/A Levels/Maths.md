---
subject: Mathematics
code: "9709"
level: AS
exam_board: CIE
papers:
  - "Paper 1 (Pure 1)"
  - "Paper 4 (Mechanics)"
target_completion: 2027-01-22
status: In Progress
current_module: 1
---
# CIE AS Maths (9709)

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
### Module 1: Algebra & Quadratics
- [x] 1.1 Prior Knowledge Target: 2026-09-11
- [x] 1.2 Quadratics Ref: 1.1 Pages 1–32 Target: 2026-09-15
- [x] Assignment 1 Ref: 1.1 Target: 2026-09-22 — Score: 
---
### Module 2: Functions & Coordinate Geometry
- [ ] 2.1 Functions Ref: 1.2 Pages 33–69 Target: 2026-09-28
- [ ] 2.2 Coordinate Geometry Ref: 1.3 Pages 70–98 Target: 2026-10-01
- [ ] Assignment 2 Ref: 1.2–1.3 Target: 2026-10-05 — Score: 
---
### Module 3: Circular Measure & Trigonometry
- [ ] 3.1 Circular Measure Ref: 1.4 Pages 99–115 Target: 2026-10-09
- [ ] 3.2 Trigonometry Ref: 1.5 Pages 116–154 Target: 2026-10-13
- [ ] Assignment 3 Ref: 1.4–1.5 Target: 2026-10-16 — Score: 
---
### Module 4: Series & Differentiation
- [ ] 4.1 Series Ref: 1.6 Pages 155–189 Target: 2026-10-21
- [ ] 4.2 Differentiation Ref: 1.7 Pages 190–210 Target: 2026-10-26
- [ ] Assignment 4 Ref: 1.6–1.7 Target: 2026-10-28 — Score: 
---
### Module 5: Further Differentiation & Integration
- [ ] 5.1 Further Differentiation Ref: 1.8 Pages 211–234 Target: 2026-11-02
- [ ] 5.2 Integration Ref: 1.9 Pages 235–278 Target: 2026-11-06
- [ ] Assignment 5 Ref: 1.8–1.9 Target: 2026-11-10 — Score: 
---
### Module 6: Velocity, Acceleration & Constant Acceleration
- [ ] 6.1 Velocity & Acceleration Ref: 4.1 Pages 1–21 Target: 2026-11-13
- [ ] 6.2 Equations of Constant Acceleration Ref: 4.1 Pages 22–45 Target: 2026-11-17
- [ ] Assignment 6 Ref: 4.1 Target: 2026-11-20 — Score: 
---
### Module 7: Force and Motion in One & Two Dimensions
- [ ] 7.1 Newton's Laws & 1D Motion Ref: 4.2 Pages 46–68 Target: 2026-11-24
- [ ] 7.2 Resolving Forces & 2D Equilibrium Ref: 4.3 Pages 69–92 Target: 2026-11-27
- [ ] Assignment 7 Ref: 4.2–4.3 Target: 2026-12-02 — Score: 
---
### Module 8: Friction & Connected Particles
- [ ] 8.1 Friction Ref: 4.4 Pages 93–115 Target: 2026-12-04
- [ ] 8.2 Connected Particles Ref: 4.5 Pages 116–138 Target: 2026-12-08
- [ ] Assignment 8 Ref: 4.4–4.5 Target: 2026-12-11 — Score: 
---
### Module 9: General Motion in a Straight Line & Momentum
- [ ] 9.1 Variable Acceleration Calculus Ref: 4.6 Pages 139–162 Target: 2026-12-15
- [ ] 9.2 Momentum & Collisions Ref: 4.7 Pages 163–182 Target: 2026-12-18
- [ ] Assignment 9 Ref: 4.6–4.7 Target: 2026-12-23 — Score: 
---
### Module 10: Work, Energy & Power
- [ ] 10.1 Work & Kinetic Energy Ref: 4.8 Pages 183–204 Target: 2026-12-26
- [ ] 10.2 Work-Energy Principle & Power Ref: 4.9 Pages 205–228 Target: 2026-12-28
- [ ] Assignment 10 Ref: 4.8–4.9 Target: 2026-12-31 — Score: 
---
### Module 11: Revision & Past Papers
- [ ] 11.1 Pure Mathematics 1 Timed Mock Exam Target: 2027-01-15
- [ ] 11.2 Mechanics 1 Timed Mock Exam Target: 2027-01-22