#include <array>
#include <charconv>
#include <iostream>

// std::to_chars(char*, char*, double) is a floating-point overload that
// requires GLIBCXX_3.4.29, introduced in GCC 11.
int main() {
  std::array<char, 64> buf;
  auto result = std::to_chars(buf.data(), buf.data() + buf.size(), 3.14);
  std::cout.write(buf.data(), result.ptr - buf.data()) << '\n';
  return 0;
}
