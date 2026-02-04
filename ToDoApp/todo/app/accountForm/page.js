/*Mahika Bagri*/
/*February 3 2026*/

"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";

export default function Page(){
    const router = useRouter();

    const handleCreate = async (e) => {
        e.preventDefault()
        /* need to show/throw error*/
        try{
            const res = await fetch("http://localhost:8000/user", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({
                    username: username,
                    password: password
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

    Username("");
    Password("");
    };

    const handleLogIn = async (e) => {
        e.preventDefault()
        /* need to show/throw error*/
        try{
            const res = await fetch("http://localhost:8000/user/login", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({
                    username: username,
                    password: password
                }),
            });
            
            const data = await res.json();
            localStorage.setItem("token", data.access_token);

            if (!res.ok) {
                setError(data.detail);
            return;
            }
        } catch (errors) {
            setError("Servers Unreachable. Try again later.")
        }

    Username("");
    Password("");

    router.push("/arenas");

    };

    const [username, Username] = useState("");
    const [password, Password] = useState("");
    const [error, setError] = useState("");

    return(
        <main
        style={{
            backgroundImage: "url('/pageBack.png')",
            backgroundSize: "fill",
            backgroundPosition: "center",
        }}
        >
            <div style={{ padding: 20, maxWidth: "500px", margin: "0 auto" }}>

                <input
                    type="text"
                    placeholder="Username"
                    value={username}
                    onChange={(e) => Username(e.target.value)}
                    className = "input"
                    required
                />
                <input
                style={{ 
                    marginTop: "15px",
                }}   
                    type="password"
                    placeholder="Password"
                    value={password}
                    onChange={(e) => Password(e.target.value)}
                    className = "input"
                    required
                />
                <div className = "button-row">
                    <button 
                    className = "button"
                    onClick={handleCreate}>
                        <div className = "Tagline">
                            Create
                        </div>
                    </button>
                    <button 
                    className = "button"
                    onClick={handleLogIn}>
                        <div className = "Tagline">
                            Log In
                        </div>
                    </button>
                </div>
            </div>
        </main>
    );
}

