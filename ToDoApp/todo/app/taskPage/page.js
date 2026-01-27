/*Mahika Bagri*/
/*January 26 2026*/

"use client";

import React, { useState, useEffect } from "react";
import { useSearchParams } from "next/navigation";
import Link from "next/link";

export default function Page() {
    const params = useSearchParams();
    const thisTodoId = parseInt(params.get("todoId"), 10);
    const thisArenaId = parseInt(params.get("arenaId"), 10);
    const [error, setError] = useState("");
    const [todo, setTodo] = useState(null);
    const [reminders, setReminders] = useState([]);
    const [input, setInput] = useState("");

    useEffect(() => {
        const fetchTodo = async () => {
        try {
            const res = await fetch(`http://localhost:8000/todo/${thisTodoId}`);
            const data = await res.json();

            if (!res.ok) {
            setError(data.detail);
            return;
            }

            setTodo(data);
        } catch (err) {
            setError("Server unreachable");
        }
        };

        fetchTodo();
    }, [thisTodoId]);

  const updateInput = (e) => {
    setInput(e.target.value);
  };

    const setReminder = () => {
    if(input !== ""){
      const updatedTodo = [...reminders, input];
      setReminders(updatedTodo);
      setInput("");
    }
  }


  return (
    <main
      style={{
        backgroundImage: "url('/TaskPageBack.png')",
        backgroundSize: "cover",
      }}
    >
      { todo && (
        <div className = "taskTitle">
          {todo.name}
        </div>
      )}
      <Link href={`/arena?arenaId=${thisArenaId}`}>
        <img className="homeButton"
          src="/HomeButton.png"
        />
        <img className="timerButton"
          src="/playButton.png"
        />
      </Link>
      <div className="App">
        <div className="button-row">
        <input 
            className = "input"
            type="text"
            placeholder="For the distracting, yet important mental notes. They'll be waiting for when you're done."
            id="reminder"
            value={input}
            onChange={updateInput}
            style={{ 
              width: "850px",
              right: "0%",
            }}   
          />
          <button 
          onClick={setReminders}
           className = "button"
           style={{ 
              width: "150px",
              height: "50px",
              top: "-35px",
              left: "0%",
            }}
          >
            <div className="Tagline">
              Save
            </div>
          </button>
          </div>
          <input 
            className = "input"
            type="text"
            placeholder="Workspace"
            style={{ 
              top: "-150px",
              width: "1000px",
              height: "400px",
              right: "0%",
            }}   
          />
          <img
            className = "lotusBud"
            src= "/lotusBud.png"
          />
          <img
            className = "timeBar"
            src= "/timeBar.png"
          />
       </div>
    </main>
  );
}