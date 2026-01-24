/*Mahika Bagri*/
/*January 23 2026*/

"use client";

import { useState, useEffect } from "react";
import { useSearchParams } from "next/navigation";

export default function Page() {
  const [error, setError] = useState("");
  const params = useSearchParams();
  const thisArenaId = parseInt(params.get("arenaId"), 10);
  const [arena, setArena] = useState(null);

  useEffect(() => {
    const fetchArenas = async () => {
      try {
        const res = await fetch(`http://localhost:8000/arena/${thisArenaId}`);
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

    fetchArenas();
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
        backgroundSize: "cover", 
        backgroundAttachment: "scroll",
        minHeight: "250vh"
      }}
    >
    </main>
  );
}
