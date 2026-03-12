import java.util.List;

public class HelloJava {
    private static String greet(String name) {
        return "Hello from Java, " + name + "!";
    }

    public static void main(String[] args) {
        List<String> names = List.of("Ada", "Grace", "Linus");
        names.stream()
            .map(HelloJava::greet)
            .forEach(System.out::println);

        // Uncomment for diagnostics test:
        // System.out.println(unknownVariable);
    }
}
