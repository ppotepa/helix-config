let
  names = [ "Ada" "Grace" "Linus" ];
  greet = name: "Hello from Nix, ${name}!";
in {
  messages = builtins.map greet names;
  metadata = {
    language = "nix";
    smokeTest = true;
  };
}
