/*Mahika Bagri*/
/*January 24 2026*/

"use client";

import React, { useState, useEffect } from "react";
import { useSearchParams } from "next/navigation";
import Link from "next/link";

const ToDo = (props) => {

    return (
        <div style={{
            border: "2px solid black",
            borderRadius: 15,
            width: "40vw",
            margin: "10px auto",
            padding: 10,
            display: "flex",
            flexDirection: "row",
            justifyContent: "flex-start",
            alignItems: "center",
            flexWrap: "wrap"
        }}>
            <h2 style={{ marginLeft: 10 }}>{props.text}</h2>
        </div>
    );
}

export default function Page() {
    const params = useSearchParams();
    const thisArenaId = parseInt(params.get("arenaId"), 10);
    const [todos, setTodos] = useState([]);
    const [error, setError] = useState("");
    const [name, Name] = useState("");
    const [length, Length] = useState(0);
    const [date, DueDate] = useState("");
    const [tag, Tag] = useState("");

const getTodos = async () => {
    const res = await fetch(`http://localhost:8000/todo/${thisArenaId}`);
    const data = await res.json();
    setTodos(data);
  };

  useEffect(() => {
    getTodos();
  }, []);

    const handleSubmit = async (e) => {
        e.preventDefault()
        /* need to show/throw error*/
        try{
            const res = await fetch("http://localhost:8000/todo", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({
                    name: name,
                    due_date: date,
                    length_minutes: length,
                    tag: tag,
                    arena_key: thisArenaId
                }),
            });
            
            const data = await res.json();

            if (!res.ok) {
                setError(data.detail);
            return;
            }
        } catch (errors) {
            setError("Servers Unreachable. Try again later.")
        }
    
    Name("");
    DueDate("");
    Length(0);
    Tag("");
    
    getTodos();
    };

  return (
    <main
      style={{
        backgroundImage: "url('/pageBack.png')",
        backgroundSize: "fill",
      }}
    >
        <Link
            href={`/arena?arenaId=${thisArenaId}`}
        >
        <img
            className="homeButton"
            src="/HomeButton.png"
        />
</Link>

      <div style={{ padding: 20, maxWidth: "500px", margin: "0 auto" }}>
                <div className = "Title">
                    Quests
                </div>

                <form onSubmit={handleSubmit} style={{ display: "flex", flexDirection: "column", gap: "10px" }}>
                    <input 
                    type="text"
                    placeholder="Task Name"
                    value={name}
                    onChange={(e) => Name(e.target.value)}
                    className = "input"
                    required
                    />
                    <input
                    type="date"
                    value={date}
                    placeholder="Task Due Date"
                    onChange={(e) => DueDate(e.target.value)}
                    className="input"
                    />
                    <input
                    type="number"
                    placeholder="Task Length"
                    value={length}
                    onChange={(e) => Length(Number(e.target.value))}
                    className="input"
                    />
                    <input
                    type="text"
                    placeholder="Task Tag"
                    value={tag}
                    onChange={(e) => Tag(e.target.value)}
                    className = "input"
                    />
                    <button type="submit"
                    className = "button">
                        <div className = "Tagline">
                            Add
                        </div>
                    </button>
                </form>
                <ul 
                    style={{ 
                        position: "relative",
                        right: "10%" 
                    }}>
                {todos !== undefined &&
                    todos.map((todo) => (
                        <ToDo key={todo.id} text={todo.name} />
                    ))}
                </ul>
            </div>
    </main>
  );
}