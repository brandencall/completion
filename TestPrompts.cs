
public static class TestPrompts
{
    public static int SumUpTo(int n)
    {
        int sum = 0;
        int i = 1;
        while (i <= n)
        {
        }
    }

    public static bool ContainsZero(IList<int> values)
    {
        for (int i = 0; i < values.Count; i++)
        {
            if (values[i] != 0)
            {
            }
        }
    }


    public static List<int> FilterPositive(IList<int> values)
    {
        var result = new List<int>();

        for (int i = 0; i < values.Count; i++)
        {
            if (values[i] > 0)
            {
            }
        }
    }

    public static double? SafeDiv(double a, double b)
    {
        if (b == 0)
        {
        }
    }


    public static int FindFirstNull(IList<object?> values)
    {
        int i = 0;

        while (i < values.Count)
        {
            if (values[i] == null)
            {
            }
        }
    }
}

