// sample.cpp
#include <cmath>
#include <iostream>
#include <vector>

namespace demo {

enum class Status { Ok, Error, Unknown };

struct Point {
  double x;
  double y;
};

class Calculator {
public:
  Calculator(int base) : base_(base) {}
  ~Calculator() {}

  int add(int a, int b) const { return a + b + base_; }

  template <typename T> T multiply(T a, T b) const { return a * b; }

private:
  int base_;
};

template <typename T> auto process_vector(const std::vector<T> &vec) -> T {
  T result{};
  for (const auto &item : vec) {
    result += item;
  }
  for (int i = 0; i < 10; ++i) {
  }
  return result;
}

} // namespace demo

int main() {
  using namespace demo;

  Calculator calc(10);

  std::vector<int> numbers = {1, 2, 3, 4};
  auto sum = process_vector(numbers);

  int result = calc.add(sum, 5);

  Point p{3.0, 4.0};

  auto distance = [](const Point &pt) {
    return std::sqrt(pt.x * pt.x + pt.y * pt.y);
  };

  try {
    if (result > 20) {
      std::cout << "Large result\n";
    } else {
      std::cout << "Small result\n";
    }

    switch (result) {
    case 0:
      std::cout << "Zero\n";
      break;
    default:
      std::cout << "Non-zero\n";
    }

    int i = 0;
    while (i < 3) {
      std::cout << i << "\n";
      ++i;
    }

  } catch (const std::exception &ex) {
    std::cerr << ex.what() << "\n";
  }

  return 0;
}
