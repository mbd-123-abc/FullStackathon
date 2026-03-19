/*Mahika Bagri*/
/*February 26 2026*/

"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";

export default function Page(){
    const router = useRouter();
    const API_URL = process.env.NEXT_PUBLIC_API_URL;

    const handleSubmit = async (e) => {
        e.preventDefault()
        /* need to show/throw error*/
        try{
            const res = await fetch(`${API_URL}/arena`, {
                method: "POST",
                headers: {
                    Authorization: `Bearer ${localStorage.getItem("token")}`,
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({
                    name: name,
                    goal: goal,
                    theme_key: theme
                }),
            });
            
            const data = await res.json();

            if (!res.ok) {
                setError("⚠️ " + data.detail||"Something went wrong");
            return;
            }
            setError("");
            Name("");
            Goal("");
            Theme("FORREST");

            router.push("/arenas");
        } catch (errors) {
            setError("Servers Unreachable. Try again later.")
        }
    };

    const [error, setError] = useState("");
    const [name, Name] = useState("");
    const [goal, Goal] = useState("");
    const [theme, Theme] = useState("FORREST");

    return(
        <main
        style={{
            backgroundImage: "url('/pageBack.png')",
            backgroundSize: "fill",
            backgroundPosition: "center",
        }}
        >
            <div style={{ padding: 20, maxWidth: "500px", margin: "0 auto" }}>
                <div className = "Title">
                    Mission
                </div>

                <form onSubmit={handleSubmit} style={{ display: "flex", flexDirection: "column", gap: "10px" }}>
                    <input
                    type="text"
                    placeholder="Arena Name"
                    value={name}
                    onChange={(e) => Name(e.target.value)}
                    className = "input"
                    required
                    />
                    <input
                    type="text"
                    placeholder="Arena Goal"
                    value={goal}
                    onChange={(e) => Goal(e.target.value)}
                    className = "input"
                    required
                    />
                    <select value={theme} 
                    onChange={(e) => Theme(e.target.value)}
                    className = "input">
                        <option value="FORREST">Forrest</option>
                        <option value="DAYDREAM">Daydream</option>
                        <option value="STARRYNIGHT">Starry Night</option>
                        <option value="SAKURA">Sakura</option>
                    </select>
                    <button type="submit"
                    className = "button">
                        <div className = "Tagline">
                            Begin
                        </div>
                    </button>
                </form>
                    {error && (
                        <div className="errorMessage">
                            {error}
                        </div>
                    )}
            </div>
        </main>
    );
}