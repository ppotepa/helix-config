using System;
using System.Collections.Generic;
using System.Linq;

namespace HelixSmoke.CSharp;

public record User(int Id, string Name, int Score);

public static class Program
{
    public static void Main()
    {
        var users = new List<User>
        {
            new(1, "Ada", 95),
            new(2, "Grace", 91),
            new(3, "Linus", 86),
        };

        var top = users
            .Where(u => u.Score >= 90)
            .OrderByDescending(u => u.Score)
            .Select(u => $"Hello from C#, {u.Name}! ({u.Score})");

        foreach (var line in top)
        {
            Console.WriteLine(line);
        }

        // diagnostics test idea:
        // Console.WriteLine(NotDefinedSymbol);
    }
}
