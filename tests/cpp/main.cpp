#include <algorithm>
#include <iostream>
#include <string>
#include <vector>

class Greeter {
public:
    explicit Greeter(std::string prefix) : prefix_(std::move(prefix)) {}

    [[nodiscard]] std::string message(const std::string &name) const {
        return prefix_ + ", " + name + "!";
    }

private:
    std::string prefix_;
};

int main() {
    Greeter greeter{"Hello from C++"};
    std::vector<std::string> names{"Ada", "Grace", "Linus"};
    std::ranges::sort(names);

    for (const auto &name : names) {
        std::cout << greeter.message(name) << '\n';
    }

    // Uncomment for diagnostics test:
    // std::cout << missing_symbol << '\n';

    return 0;
}
