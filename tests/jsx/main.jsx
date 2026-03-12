import React from "react";

export function HelloList({ names = ["Ada", "Grace", "Linus"] }) {
  return (
    <section className="hello-card">
      <h1>Hello from JSX</h1>
      <ul>
        {names.map((name) => (
          <li key={name}>{name}</li>
        ))}
      </ul>
    </section>
  );
}

// Uncomment for diagnostics test:
// <HelloList names={42} />
