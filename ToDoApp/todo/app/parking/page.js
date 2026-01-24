/*Mahika Bagri*/
/*January 23 2026*/

"use client";

import React, { useState, useEffect } from "react";
import { FaRegSquare, FaRegSquareCheck } from "react-icons/fa6";

const ToDo = (props) => {
    const [isComplete, setIsComplete] = useState(false);

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
    const res = await fetch("http://localhost:8000/todo/parking");
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
        const res = await fetch("http://localhost:8000/todo", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          name: input
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
    }
    getTodos();
    setInput("");
  };

  const clearTodo = async () => {
    const res = await fetch("http://localhost:8000/todo/parking", {
      method: "DELETE",
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

          <button onClick={addTodo} className = "button">Enter</button>
          <button onClick={clearTodo} className = "button">Clear</button>
        
        </div>

        <ul>
          {todos.map((todo) => (
            <ToDo key={todo.id} text={todo.name} />
          ))}
        </ul>
      </div>
    </main>
  );
}