type Role = "admin" | "user";

interface Person {
  id: number;
  name: string;
  role: Role;
}

function greet<T extends Pick<Person, "name">>(person: T, prefix = "Hello from TypeScript"): string {
  return `${prefix}, ${person.name}!`;
}

const people: Person[] = [
  { id: 1, name: "Ada", role: "admin" },
  { id: 2, name: "Grace", role: "user" },
  { id: 3, name: "Linus", role: "user" },
];

const messages = people.map((p) => greet(p));
messages.forEach((line) => console.log(line));

// Uncomment for diagnostics test:
// const brokenRole: Role = "owner";
