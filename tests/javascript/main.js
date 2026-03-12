/** @typedef {{ name: string, score: number }} Player */

class Greeter {
  constructor(prefix) {
    this.prefix = prefix;
  }

  message(name) {
    return `${this.prefix}, ${name}!`;
  }
}

/** @returns {Promise<string[]>} */
async function buildMessages() {
  /** @type {Player[]} */
  const players = [
    { name: "Ada", score: 95 },
    { name: "Grace", score: 91 },
    { name: "Linus", score: 89 },
  ];

  const greeter = new Greeter("Hello from JavaScript");
  const selected = players.filter((p) => p.score >= 90).map((p) => greeter.message(p.name));
  return Promise.resolve(selected);
}

buildMessages().then((lines) => lines.forEach((line) => console.log(line)));

// Uncomment for diagnostics test:
// console.log(notDefinedAtAll);
