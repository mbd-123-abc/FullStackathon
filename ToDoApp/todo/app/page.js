/*Mahika Bagri*/
/*January 21 2026*/

"use client";
import Link from "next/link";

function sparkle(e) {
  const s = document.createElement("div");
  s.className = "sparkle";
  s.style.left = e.clientX + "px";
  s.style.top = e.clientY + "px";

  document.body.appendChild(s);
}

export default function Page() {
  return (
    <main
      onMouseMove={sparkle}
      style={{
        backgroundImage: "url('/LandingPage.png')",
        backgroundSize: "fill",
        backgroundPosition: "center",
      }}
    >
      <header className="Name">
        Kriyarthika Arena
      </header>
      <Link href="/arenas" className="Tagline">
        Choose Your Own Progress
      </Link>
    </main>
  );
}
