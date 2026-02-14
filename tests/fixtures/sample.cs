// Sample.cs
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Demo
{
    public enum Status
    {
        Ok,
        Error,
        Unknown
    }

    public struct Point
    {
        public double X;
        public double Y;

        public double Distance() => Math.Sqrt(X * X + Y * Y);
    }

    public interface ICalculator
    {
        int Add(int a, int b);
    }

    public record Person(string Name, int Age);

    public class Calculator : ICalculator
    {
        private readonly int _base;

        public Calculator(int baseValue)
        {
            _base = baseValue;
        }

        public int Add(int a, int b)
        {
            return a + b + _base;
        }

        public T Multiply<T>(T a, T b) where T : struct
        {
            dynamic x = a;
            dynamic y = b;
            return (T)(x * y);
        }

        public async Task<int> ComputeAsync(IEnumerable<int> values)
        {
            await Task.Delay(10);

            int result = values
                .Where(v => v > 0)
                .Select(v => v * 2)
                .Sum();

            return result;
        }
    }

    public static class Program
    {
        public static async Task Main(string[] args)
        {
            var calc = new Calculator(10);

            List<int> numbers = new() { 1, 2, 3, 4 };

            int sum = await calc.ComputeAsync(numbers);

            int result = calc.Add(sum, 5);

            Point p = new() { X = 3.0, Y = 4.0 };

            string sizeCategory = result switch
            {
                > 20 => "Large",
                0 => "Zero",
                _ => "Small"
            };

            try
            {
                if (result > 10)
                {
                    Console.WriteLine("Result is greater than 10");
                }
                else
                {
                    Console.WriteLine("Result is 10 or less");
                }

                for (int i = 0; i < 3; i++)
                {
                    Console.WriteLine(i);
                }

                int counter = 0;
                while (counter < 2)
                {
                    Console.WriteLine(counter++);
                }

                object obj = p;

                if (obj is Point pt && pt.X > 0)
                {
                    Console.WriteLine($"Point X: {pt.X}");
                }

                void LocalFunction()
                {
                    Console.WriteLine("Inside local function");
                }

                LocalFunction();
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
            }
            finally
            {
                Console.WriteLine("Done.");
            }

            var person = new Person("Alice", 30);
            Console.WriteLine($"{person.Name} is {person.Age}");
        }
    }
}
