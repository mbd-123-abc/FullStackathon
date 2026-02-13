/*Mahika Bagri*/
/*February 12 2026*/

"use client";

import { useState, useEffect } from "react";
import { useSearchParams } from "next/navigation";
import Link from "next/link";

export default function Page() {
  const [error, setError] = useState("");
  const params = useSearchParams();
  const thisArenaId = parseInt(params.get("arenaId"), 10);
  const [arena, setArena] = useState(null);
  const [todos, setTodos] = useState([]);

  useEffect(() => {
    const fetchArena = async () => {
      try {
        const res = await fetch(`http://localhost:8000/arena/${thisArenaId}`, {
          headers: {
            Authorization: `Bearer ${localStorage.getItem("token")}`,
          },
        });
        const data = await res.json();

        if (!res.ok) {
          setError(data.detail);
          return;
        }

        setArena(data);
      } catch (err) {
        setError("Server unreachable");
      }
    };

    fetchArena();
  }, [thisArenaId]);

  useEffect(() => {
    const getTodos = async () => {
        const res = await fetch(`http://localhost:8000/todo/arena/${thisArenaId}`, {
          headers: {
            Authorization: `Bearer ${localStorage.getItem("token")}`,
          },
        });
        const data = await res.json();
        setTodos(data);
    };
    getTodos();
  }, [thisArenaId]);

  const backImages = {
      FORREST: "/ForrestBackground.png",
      DAYDREAM: "/DaydreamBackground.png",
      STARRYNIGHT: "/NightBackground.png",
      SAKURA: "/SakuraBackground.png",
  };

  return (
    <main
      style={{
        backgroundImage: arena
          ? `url(${backImages[arena.theme_key]})`
          : "none",
        backgroundPosition: "top center",
        backgroundSize: "100% auto", 
        backgroundAttachment: "scroll",
        minHeight: "250vh",
        backgroundRepeat: "repeat-y" 
      }}
    >
  {todos.map((todo, i) => {
    const y = 900 + (i * 250);
    const x = 710;
    const dotColor = todo.completion_status
      ? "#d28336" 
      : "white"; 
    const dotGlow = todo.completion_status
      ? "0 0 6px #fedd85)"
      : "0 0 6px white";

    const flagImage = (
      <div className = "flag"
        style={{
          position: "absolute",
          top: y,
          left: x,
          transform: "translateX(-48%)",
          zIndex: 10 + i,
          width: "fit-content",
          height: "fit-content",
        }} 
      >
          <img
            src="/PeachTodoFlag.png"
            style={{
              filter: todo.completion_status  
                ? "none": 
                "drop-shadow(0 0 12px rgba(255, 200, 120, 0.9))",
              opacity: todo.completion_status ? .5 : 1,
            }}
          />
        </div>
    )

    return(
      <div key={todo.id}>
        {[1, 2, 3].map((_, j) => (
          <div
            key={j}
            style={{
              position: "absolute",
              top: y + 62 - (j + 1) * 50,
              left: x,
              width: 8,
              height: 8,
              borderRadius: "90%",
              background: dotColor,
              boxShadow: dotGlow,
              zIndex: 20 + i
            }}
          />
        ))}
        {todo.completion_status? flagImage:
          <Link href={`/taskPage?todoId=${todo.id}&arenaId=${thisArenaId}`}>
            {flagImage}
          </Link>
        }
        </div>
        );
      })}
      <Link href="/arenas">
        <img className="homeButton"
          src="/HomeButton.png"
        />
      </Link>
      {arena && (
        <Link key={arena.id}
        href={`/todoForm?arenaId=${arena.id}`}>
          <img className="questsButton"
            src="/QuestButton.png"
          />
        </Link>
      )}

      <div className="goalContainer">
        <img src="/GoalButton.png"
          className="goalButton"
        />
        {arena && (
          <div className="goal">
            {arena.goal}
          </div>
        )}
      </div>
    </main>
  );
}
