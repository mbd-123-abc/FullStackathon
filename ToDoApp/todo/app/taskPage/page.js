/*Mahika Bagri*/
/*March 5 2026*/

import { Suspense } from "react";
import TaskPage from "./TaskPage"

export default function Page() {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <TaskPage />
    </Suspense>
  );
}
