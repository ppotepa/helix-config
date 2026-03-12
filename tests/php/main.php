<?php

declare(strict_types=1);

final class Greeter
{
    public function __construct(private string $prefix) {}

    public function message(string $name): string
    {
        return sprintf('%s, %s!', $this->prefix, $name);
    }
}

$names = ['Ada', 'Grace', 'Linus'];
$greeter = new Greeter('Hello from PHP');

$messages = array_map(
    fn(string $name): string => $greeter->message($name),
    $names
);

foreach ($messages as $line) {
    echo $line . PHP_EOL;
}

// diagnostics test idea:
// echo $undefinedVar;
