// sample.c
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

typedef enum { STATUS_OK, STATUS_ERROR, STATUS_UNKNOWN } Status;

typedef struct {
  double x;
  double y;
} Point;

typedef struct {
  int base;
} Calculator;

/* "Constructor" */
void calculator_init(Calculator *calc, int base) { calc->base = base; }

/* Equivalent to add() method */
int calculator_add(const Calculator *calc, int a, int b) {
  return a + b + calc->base;
}

/* Since C has no templates, we implement int version */
int multiply_int(int a, int b) { return a * b; }

/* Process vector equivalent (int version only) */
int process_vector(const int *vec, size_t size) {
  int result = 0;

  for (size_t i = 0; i < size; ++i) {
    result += vec[i];
  }

  for (int i = 0; i < 10; ++i) {
    /* empty loop to mirror C++ example */
  }

  return result;
}

/* Equivalent of lambda distance function */
double distance(Point pt) { return sqrt(pt.x * pt.x + pt.y * pt.y); }

int main(void) {
  Calculator calc;
  calculator_init(&calc, 10);

  int numbers[] = {1, 2, 3, 4};
  size_t count = sizeof(numbers) / sizeof(numbers[0]);

  int sum = process_vector(numbers, count);
  int result = calculator_add(&calc, sum, 5);

  Point p = {3.0, 4.0};
  double dist = distance(p);

  (void)dist; /* suppress unused warning */

  /* No exceptions in C, so normal control flow */
  if (result > 20) {
    printf("Large result\n");
  } else {
    printf("Small result\n");
  }

  switch (result) {
  case 0:
    printf("Zero\n");
    break;
  default:
    printf("Non-zero\n");
    break;
  }

  int i = 0;
  while (i < 3) {
    printf("%d\n", i);
    ++i;
  }

  return 0;
}
