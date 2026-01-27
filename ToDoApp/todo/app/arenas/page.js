/*Mahika Bagri*/
/*January 24 2026*/

"use client";

import Link from "next/link";
import { useEffect, useState } from "react";

export default function Page() {
  const [arenas, all_arenas] = useState([]);
  const themeImages = {
    FORREST: "/ForrestCard.png",
    DAYDREAM: "/DaydreamCard.png",
    STARRYNIGHT: "/NightCard.png",
    SAKURA: "/SakuraCard.png",
  };


  useEffect(() => {
    fetch("http://localhost:8000/arena")
      .then(res => res.json())
      .then(data => all_arenas(data))
  }, []);

    const deleteArena = async (id) => {
    const res = await fetch(`http://localhost:8000/arena/${id}`, {
      method: "DELETE",
    });
    all_arenas((prev) => prev.filter((arena) => arena.id !== id));
  };

  return (
    <page
      style={{
        backgroundImage: "url('/pageBack.png')",
        backgroundSize: "fill",
        backgroundPosition: "center",
      }}
    >
      <header className="Title">
        Arenas
      </header> 
        <div className="arenas-grid">
          <Link href = "/arenaForm">

            <div className="arenas-card">
              <div className="card-header">
                <img
                  src="/AddCard.png"
                />
              </div>
              <div className="card-body">
                <h3>Create Arena</h3>
                <p>Create a new arena for your next big goal.</p>

                <div className="card-links">
                </div>
              </div>
            </div>
          </Link>

          <Link href = "/parking">
            <div className="arenas-card">
              <div className="card-header">
                <img
                  src="/ParkingCard.png"
                />
              </div>
              <div className="card-body">
                <h3>Parking Lot</h3>
                <p>For the tasks that matter, just not right now.</p>

                <div className="card-links">
                </div>
              </div>
            </div>
          </Link>
          
          {arenas.map((arena) => (
            <Link key={arena.id}
            href={`/arena?arenaId=${arena.id}`}>
              <div className="arenas-card">
                <div className="card-header">
                    <img
                      src={themeImages[arena.theme_key]}
                    />
                </div>

                <div className="card-body">
                  <h3>{arena.name}</h3>
                  <p>{arena.goal}</p>
                </div>
                <button className="cardButton"
                    onClick={(e) => {
                      e.preventDefault();   // stop navigation
                      e.stopPropagation(); // extra safety
                      deleteArena(arena.id);
                    }}
                >
                  Delete
                </button>
              </div>
            </Link>
          ))}
      </div>
    </page>
  );
}

