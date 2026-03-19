/*Mahika Bagri*/
/*March 5 2026*/

import { Suspense } from "react";
import Arena from "./Arena"

export default function Page() {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <Arena />
    </Suspense>
  );
}
