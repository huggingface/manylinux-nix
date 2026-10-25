#include <algorithm>
#include <iostream>
#include <string>
#include <vector>

int main() {
  std::vector<std::string> words{"nonagon", "infinity", "opens", "the", "door"};
  std::sort(words.begin(), words.end());
  for (const auto &word : words) {
    std::cout << word << '\n';
  }
  return 0;
}
