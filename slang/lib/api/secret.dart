// This file contains methods to calculate the secret.

int $calc0(int a, int b, int c) {
  return (a + b * 2) ^ c;
}

int $calc1(int a, int b, int c) {
  return (a * a - b) ^ c;
}
