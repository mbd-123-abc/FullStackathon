/*Mahika Bagri*/
/*January 21 2026*/

import { Trade_Winds, Sansita_Swashed } from "next/font/google";
import "./globals.css";

const tradeWinds = Trade_Winds({
  weight: "400",
  subsets: ["latin"],
  variable: "--font-title",
});

const sansita = Sansita_Swashed({
  weight: ["400", "600"],
  subsets: ["latin"],
  variable: "--font-tagline",
});

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body className={[tradeWinds.variable, sansita.variable].join(" ")}>
        {children}
      </body>
    </html>
  );
}
