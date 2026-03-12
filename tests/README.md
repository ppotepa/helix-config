# Per-language smoke tests

Open each folder as a separate Helix workspace:

- `hx tests/rust`
- `hx tests/go`
- `hx tests/python`
- ...and so on for each language folder.

Why: this avoids mixed multi-language roots in one folder, which can break some LSP servers.

Each folder contains one advanced hello file and (when needed) minimal project files such as:
- `Cargo.toml`
- `go.mod`
- `package.json`
- `tsconfig.json`
- `pyproject.toml`
