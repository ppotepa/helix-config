import React, { useMemo } from "react";

type HelloProps = {
  title: string;
  names: string[];
};

export function HelloPanel({ title, names }: HelloProps) {
  const sorted = useMemo(() => [...names].sort(), [names]);

  return (
    <article>
      <h2>{title}</h2>
      <p>Hello from TSX</p>
      <ol>
        {sorted.map((name) => (
          <li key={name}>{name}</li>
        ))}
      </ol>
    </article>
  );
}

// Uncomment for diagnostics test:
// <HelloPanel title="Test" names={[1, 2, 3]} />
