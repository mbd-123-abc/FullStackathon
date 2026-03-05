/*Mahika Bagri*/
/*March 5 2026*/

import { Suspense } from "react";
import TodoForm from "./TodoForm"

export default function Page() {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <TodoForm />
    </Suspense>
  );
}
