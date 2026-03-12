from dataclasses import dataclass


@dataclass(slots=True)
class Greeter:
    prefix: str

    def message(self, name: str) -> str:
        return f"{self.prefix}, {name}!"


def build_messages(names: list[str], greeter: Greeter) -> list[str]:
    return [greeter.message(name.strip()) for name in names if name.strip()]


def main() -> None:
    greeter = Greeter(prefix="Hello from Python")
    messages = build_messages(["Ada", "Grace", "Linus"], greeter)
    for line in messages:
        print(line)

    # Uncomment for diagnostics test:
    # reveal_type(messages)
    # print(undefined_name)


if __name__ == "__main__":
    main()
