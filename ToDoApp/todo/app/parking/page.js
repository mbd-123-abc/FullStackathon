/*Mahika Bagri*/
/*February 26 2026*/

"use client";

import React, { useState, useEffect } from "react";
import { FaRegSquare, FaRegSquareCheck } from "react-icons/fa6";
import Link from "next/link";

const ToDo = (props) => {
    const [isComplete, setIsComplete] = useState(false);
    const API_URL = process.env.NEXT_PUBLIC_API_URL;

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
            <div style={{ cursor: "pointer" }} onClick={() => setIsComplete(!isComplete)}>
                {isComplete ? <FaRegSquareCheck size={40} /> : <FaRegSquare size={40} />}
            </div>
            <h2 style={{ marginLeft: 10 }}>{props.text}</h2>
        </div>
    );
}

export default function Page() {
  const [todos, setTodos] = useState([]);
  const [input, setInput] = useState("");
  const [error, setError] = useState("");

  const getTodos = async () => {
    const res = await fetch(`${API_URL}/todo/parking`,{
      headers: {
        Authorization: `Bearer ${localStorage.getItem("token")}`,
      },

  });
    const data = await res.json();
    setTodos(data);
  };

  useEffect(() => {
    getTodos();
  }, []);

  const updateInput = (e) => {
    setInput(e.target.value);
  };

  const addTodo = async (e) => {
    e.preventDefault()
    /* need to show/throw error*/
    if (input !== "") {
      try{
        const res = await fetch(`${API_URL}/todo`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${localStorage.getItem("token")}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          name: input
        }),
      });
            
      const data = await res.json();

      if (!res.ok) {
        setError("⚠️ " + data.detail||"Something went wrong");
        return;
      }
      getTodos();
      setInput("");
      setError("");
    } catch (errors) {
      setError("Servers Unreachable. Try again later.")
    }
    }
  };

  const clearTodo = async () => {
    const res = await fetch(`${API_URL}/todo/parking`, {
      method: "DELETE",
      headers: {
        Authorization: `Bearer ${localStorage.getItem("token")}`,
      },
    });

    await getTodos(); 
  };

  return (
    <main
      style={{
        backgroundImage: "url('/pageBack.png')",
        backgroundSize: "fill",
      }}
    >
      <Link href="/arenas">
        <img className="homeButton"
          src="/HomeButton.png"
        />
      </Link>
      <div className="App">
        <input 
        className = "input"
          type="text"
          placeholder="Todo Item"
          id="newTodo"
          value={input}
          onChange={updateInput}
        />
        <div className="button-row">
          <button onClick={addTodo} className = "button">
            <div className="Tagline">
              Enter
            </div>
          </button>
          <button onClick={clearTodo} className = "button">
            <div className="Tagline">
              Clear
            </div>
          </button>
        </div>
              {error && (
                        <div className="errorMessage">
                            {error}
                        </div>
                )}
        <ul>
          {todos.map((todo) => (
            <ToDo key={todo.id} text={todo.name} />
          ))}
        </ul>
      </div>
    </main>
  );
}