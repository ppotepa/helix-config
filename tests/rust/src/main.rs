use std::collections::HashMap;

#[derive(Debug, Clone)]
struct Greeter {
    prefix: String,
}

impl Greeter {
    fn greet(&self, name: &str) -> String {
        format!("{}, {name}!", self.prefix)
    }
}

fn language_usage() -> HashMap<&'static str, usize> {
    
    HashMap::from([
        ("rust", 4),
        ("go", 3),
        ("python", 5),
    ])
}

fn main() {
    let greeter = Greeter {
        prefix: "Hello from Rust".to_string(),
    };

    for name in ["Ada", "Grace", "Linus"] {
        println!("{}", greeter.greet(name));
    }

    let total: usize = language_usage().values().sum();
    println!("Total sample usage points: {total}");

    // Uncomment for diagnostics test:
    // let broken: i32 = "not a number";
}
