/*Mahika Bagri*/
/*February 12 2026*/

"use client";

import React, { useState, useEffect } from "react";
import { useSearchParams } from "next/navigation";
import Link from "next/link";
import { useRouter } from "next/navigation";

export default function Page() {
    const params = useSearchParams();
    const thisTodoId = parseInt(params.get("todoId"), 10);
    const thisArenaId = parseInt(params.get("arenaId"), 10);
    const [error, setError] = useState("");
    const [todo, setTodo] = useState(null);
    const [reminders, setReminders] = useState([]);
    const [input, setInput] = useState("");
    const [pause, setPause] = useState(true)
    const [timeLeft, setTimeLeft] = useState(0);
    const [time, setTime] = useState(0);
    const [lotusBud, setLotusBud] = useState(0);
    const [menu, setMenu] = useState(false)
    const router = useRouter();
    const [length, Length] = useState(0);
  

    const change_complete = async (e) => {
        e.preventDefault()
        /* need to show/throw error*/
        try{
            const res = await fetch(`http://localhost:8000/todo/${thisTodoId}`, {
                method: "PATCH",
                headers: {
                  Authorization: `Bearer ${localStorage.getItem("token")}`,
                  "Content-Type": "application/json",
                },
            });
            
            const data = await res.json();

            if (!res.ok) {
                setError(data.detail);
            return;
            }
        } catch (errors) {
            setError("Servers Unreachable. Try again later.")
        }
      router.push(`/arena?arenaId=${thisArenaId}`);
    };

    const update_length = async (e) => {
        e.preventDefault()
        /* need to show/throw error*/
        const newLength =
          timeLeft > 0
            ? Math.floor(timeLeft / 60) + length
            : length;

        console.log("newLength:", newLength, typeof newLength);

        try{
            const res = await fetch(`http://localhost:8000/todo/${thisTodoId}/${newLength}`, {
                method: "PATCH",
                headers: {
                   Authorization: `Bearer ${localStorage.getItem("token")}`,
                  "Content-Type": "application/json",
                },
            });
            
            const data = await res.json();

            if (!res.ok) {
                setError(data.detail);
            return;
            }
        } catch (errors) {
            setError("Servers Unreachable. Try again later.")
        }
          setTimeLeft(newLength * 60);
          Length(0);

    };

  useEffect(() => {
    if (todo) {
      setTime(todo.length_minutes * 60);
      setTimeLeft(todo.length_minutes * 60);
    }
  }, [todo]);


  useEffect(() => {
    if(timeLeft === 0  && time > 0){
      setMenu(true);
    }
    if (pause||timeLeft === 0) {
      setPause(true);
      return; 
    }
    const interval = setInterval(() => {
      setTimeLeft(prev => {
        const next = prev - 1;
        setLotusBud((time-next)*(950/time));
        return next;
      });
    }, 1000);

    return () => clearInterval(interval);
    }, [pause, timeLeft]);

    useEffect(() => {
        const fetchTodo = async () => {
        try {
            const res = await fetch(`http://localhost:8000/todo/${thisTodoId}`, {
          headers: {
            Authorization: `Bearer ${localStorage.getItem("token")}`,
          },
        });
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
      { menu && (
        <>
        <img
            className = "menuBoard"
            src= "/menuBoard.png"
          />
        <Link href={`/arena?arenaId=${thisArenaId}`}>
          <img 
            className="homeMenuButton"
            src="/homeButton.png"
          />
        </Link>
        { todo && (
          <div 
          className = "menuTagline"
          style = {{
            position: "absolute",
            top: "180px",
            left: "370px",
          }}
          >
            Task Tag: {todo.tag}
          </div>
          )}
          <div 
            className = "menuTagline"
            style = {{
            position: "absolute",
            top: "250px",
            left: "370px",
          }}
          >
            Reminders: 
          </div>
            <ul className = "reminders">
              {reminders.map((reminder, index) => (
                <li 
                className = "reminder" 
                key={index}
                >
                  {reminder}
                </li>
              ))}
            </ul>
            <div 
            className = "menuTagline"
            style = {{
            position: "absolute",
            top: "430px",
            left: "370px",
          }}
          >
            Extend timer?
          </div>
          <input
          style = {{
            position: "absolute",
            top: "472px",
            left: "560px",
            width: "80px",
            height: "40px",
            zIndex: "4",
          }}
            type="number"
            placeholder="Task Length"
            value={length}
            onChange={(e) => Length(Number(e.target.value))}
            className="input"
          />
          <button 
          onClick={update_length}
           className = "button"
           style={{ 
              position: "absolute",
              width: "80px",
              height: "40px",
              top: "436px",
              left: "650px",
            }}
          >
            <div className="Tagline">
              Add
            </div>
          </button>
            <div 
            className = "menuTagline"
            style = {{
            position: "absolute",
            top: "500px",
            left: "370px",
          }}
          >
            Mark this task as complete?
          </div>
          <button 
          onClick={change_complete}
           className = "button"
           style={{ 
            position: "absolute",
              width: "80px",
              height: "40px",
              top: "505px",
              left: "730px",
            }}
          >
            <div className="Tagline">
              Yes
            </div>
          </button>
          <button 
           className = "button"
           style={{ 
              width: "80px",
              height: "40px",
              position: "absolute",
              top: "505px",
              left: "820px",

            }}
          >
            <div className="Tagline">
              No
            </div>
          </button>
        </>
      )}
        <img 
        onClick = {() => {
            setMenu(menu => !menu)
          }}
        className="menuButton"
        src="/menuButton.png"
        />
        <img 
          onClick = {() => {
            setPause(pause => !pause)
          }}
          className="timerButton"
          src= {pause ? "PlayButton.png" : "PauseButton.png"}
        />
        { !menu && (
          <>
          { todo && (
          <div className = "taskTitle">
            {todo.name}
          </div>
          )}
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
          onClick={setReminder}
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
          </div>
          </>
        )}
        <input 
            className = "input"
            type="text"
            placeholder="Workspace"
            style={{ 
              top: "-150px",
              width: "1000px",
              height: "400px",
              right: "0%",
              opacity: menu ? 0: 1,
            }}   
          />
          <img
            className = "lotusBud"
            src= "/lotusBud.png"
            style={{ 
              left: `${70 + lotusBud}px`,
            }} 
          />
          <img
            className = "timeBar"
            src= "/timeBar.png"
          />
    </main>
  );
}