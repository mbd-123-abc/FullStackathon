<!-- Mahika Bagri -->
<!-- March 2026 -->

# Kriyarthika Arena

**Version:** 1.0 (MVP)  
**Contributors:** Mahika Bagri

Born from research into female behavioral psychology and motivation, **Kriyarthika Arena** is a full-stack gamified productivity platform designed to help women achieve and sustain flow state. While countless productivity applications exist, relatively few explore how gamification can be tailored to the motivational patterns and preferences identified in research on women. Kriyarthika Arena was built to bridge that gap.

Kriyarthika Arena organizes goals into themed worlds called **Arenas**, giving each area of life its own intentional space rather than forcing every responsibility into a single to-do list. Inspired by research on female psychology and motivation, the platform was designed for women who balance multiple priorities and benefit from a visual, context-driven approach to organization. Through immersive environments and visual progression, productivity becomes less about completing isolated tasks and more about building meaningful momentum across every aspect of life.

Users can create personalized arenas, organize tasks, estimate time, track progress, and choose from calming themes such as Forest, Sakura, Daydream, and Starry Night to create a workspace that encourages focus and consistency.

Kriyarthika Arena was built around one central question:

> **What if productivity software was designed to help women enter flow state instead of simply helping them finish tasks?**

---

### Motivation

While researching female behavioral psychology, I became interested in how motivation differs across individuals and how many gamified productivity platforms are built around competition, leaderboards, streaks, and external rewards. Although these mechanics can be effective, they are often treated as a one-size-fits-all solution despite research suggesting that people can be motivated in different ways.

At the same time, I noticed there were very few productivity applications specifically exploring how gamification could be designed with women in mind. Rather than encouraging users through pressure or fear of losing progress, I wanted to explore an alternative approach centered on creativity, intrinsic motivation, visual environments, and sustainable habits.

Kriyarthika Arena is the result of that exploration. Users create themed arenas representing meaningful parts of their lives, transforming goals into immersive journeys instead of disconnected task lists. Beautiful environments, intentional organization, and visual progression work together to reduce friction and encourage deeper focus.

The project combines full-stack software engineering with behavioral psychology, user experience design, and human-centered technology. More than a to-do application, Kriyarthika Arena explores how research-driven design can make productivity feel engaging, enjoyable, and sustainable.

---

### Table of Contents

<details>
<summary>Expand</summary>
<ul>
  <li><a href="#kriyarthika-arena">Kriyarthika Arena</a>
    <ul>
      <li><a href="#motivation">Motivation</a></li>
      <li><a href="#roadmap">Roadmap</a></li>
    </ul>
  </li>
  <li><a href="#user-guide">User Guide</a>
    <ul>
      <li><a href="#why-use-kriyarthika-arena">Why Use Kriyarthika Arena?</a></li>
      <li><a href="#core-features-mvp">Core Features (MVP)</a></li>
      <li><a href="#demo">Demo</a></li>
      <li><a href="#feedback-form">Feedback Form</a></li>
    </ul>
  </li>
  <li><a href="#developer-guide">Developer Guide</a>
    <ul>
      <li><a href="#tech-stack">Tech Stack</a></li>
      <li><a href="#prerequisites">Prerequisites</a></li>
      <li><a href="#installation">Installation</a></li>
      <li><a href="#layout">Layout</a></li>
      <li><a href="#api-overview">API Overview</a></li>
      <li><a href="#contributing">Contributing</a></li>
      <li><a href="#bug-reports">Bug Reports</a></li>
    </ul>
  </li>
  <li><a href="#contact">Contact</a>
    <ul>
      <li><a href="#socials">Socials</a></li>
    </ul>
  </li>
</ul>
</details>

---

### Roadmap

- [x] JWT authentication
- [x] User accounts
- [x] Arena creation
- [x] Arena themes
- [x] Task management
- [x] Due dates and time estimation
- [x] Task completion tracking
- [x] Responsive Next.js interface
- [x] Parking lot for unassigned tasks
- [x] SQLAlchemy models and relationships
- [x] FastAPI backend
- [ ] Mobile application
- [ ] Productivity analytics
- [ ] Habit tracking
- [ ] Additional themes
- [ ] Social features
- [ ] Leaderboards
- [ ] Browser extension for quick task capture

---

## User Guide

### Why Use Kriyarthika Arena?

- **Research-driven gamification** — built using ideas from behavioral psychology rather than simply adding points and badges.
- **Organize life by purpose** — create separate arenas for academics, work, fitness, hobbies, or personal growth.
- **Visual motivation** — beautiful themes transform productivity into an environment users enjoy returning to.
- **Lower cognitive load** — divide large goals into smaller, manageable spaces.
- **Track progress naturally** — completion status and visual feedback make progress tangible.
- **Flexible organization** — store tasks in a parking lot before assigning them to specific arenas.

### Core Features (MVP)

- **Arena Creation** — create themed spaces with custom names, goals, and visual environments.
- **Task Management** — create, edit, delete, and organize tasks with due dates, tags, and time estimates.
- **Theme Selection** — choose from Forest, Sakura, Daydream, and Starry Night environments.
- **Task Parking Lot** — store unassigned tasks/non-urgent, un-important before moving them into arenas.
- **Secure Authentication** — JWT-based account system.
- **Responsive Design** — optimized for desktop and tablet experiences.

### Demo

* Live Demo: Coming Soon
* Video Walkthrough: Coming Soon

### Feedback Form

Feedback, feature requests, and suggestions are always welcome.

---

# Developer Guide

## Tech Stack

### Frontend

- **Next.js** — React framework utilizing the App Router architecture
- **React** — Component-based user interface development
- **TailwindCSS** — Utility-first styling framework for responsive design

### Backend

- **FastAPI** — High-performance Python web framework for RESTful APIs
- **SQLAlchemy** — ORM for database modeling and relationships
- **Pydantic** — Data validation and request serialization

### Database

- SQLite (development)

### Authentication

- JWT (JSON Web Tokens)
- Password hashing for secure user authentication

---

## Prerequisites

Before running Kriyarthika Arena, install:

- Python 3.10+
- Node.js 18+
- npm
- Git

---

## Installation

### Clone Repository

```bash
git clone https://github.com/mbd-123-abc/FullStackathon.git
cd FullStackathon/KriyarthikaArena
```

---

### Backend

```bash
cd backend

pip install -r requirements.txt

uvicorn main:app --reload
```

The FastAPI server will start on:

```
http://localhost:8000
```

Interactive API documentation:

```
http://localhost:8000/docs
```

---

### Frontend

```bash
cd frontend

npm install

npm run dev
```

The Next.js application will be available at:

```
http://localhost:3000
```

---

## Layout

```text
KriyarthikaArena/
├── backend/
│   ├── models/
│   │   ├── arena.py
│   │   ├── todo.py
│   │   ├── user.py
│   │   └── base.py
│   ├── routes/
│   │   ├── arena.py
│   │   ├── todo.py
│   │   └── user.py
│   ├── schemas/
│   │   ├── arena.py
│   │   ├── todo.py
│   │   └── user.py
│   ├── alembic/
│   ├── auth.py
│   ├── database.py
│   ├── main.py
│   └── requirements.txt
│
└── frontend/
    ├── app/
    │   ├── accountForm/
    │   ├── arena/
    │   ├── arenaForm/
    │   ├── arenas/
    │   ├── parking/
    │   ├── taskPage/
    │   ├── todoForm/
    │   ├── layout.js
    │   └── page.js
    ├── public/
    ├── package.json
    └── next.config.mjs
```

---

## API Overview

| Method | Endpoint | Description |
|---------|----------|-------------|
| POST | `/signup` | Register a new user |
| POST | `/login` | Authenticate a user and return a JWT |
| GET | `/users/me` | Retrieve the authenticated user |
| GET | `/arena` | Retrieve all arenas |
| POST | `/arena` | Create a new arena |
| GET | `/arena/{id}` | Retrieve a single arena |
| PUT | `/arena/{id}` | Update an arena |
| DELETE | `/arena/{id}` | Delete an arena |
| GET | `/todo` | Retrieve all tasks |
| POST | `/todo` | Create a task |
| GET | `/todo/{id}` | Retrieve a task |
| PUT | `/todo/{id}` | Update a task |
| DELETE | `/todo/{id}` | Delete a task |

Interactive API documentation is available at `/docs` while running locally.

---

## Contributing

Contributions are welcome.

1. Fork the repository.
2. Create a feature branch.

```bash
git checkout -b feature/your-feature
```

3. Make your changes.
4. Commit your work.

```bash
git commit -m "Add your feature"
```

5. Push your branch.

```bash
git push origin feature/your-feature
```

6. Open a Pull Request describing your changes.

---

## Bug Reports

Please open a GitHub Issue including:

- Steps to reproduce
- Expected behavior
- Actual behavior
- Screenshots (if applicable)
- Browser and operating system

---

# Contact

## Socials

- **GitHub:** https://github.com/mbd-123-abc
- **LinkedIn:** https://www.linkedin.com/in/mahika-bagri
- **Email:** mahika13.3@gmail.com
- **Discord:** https://discord.com/users/697914065418321961


