#include <iostream>
#include "calculator.h"

int main() {
    std::cout << "Calculator Demo (Multi-file project)" << std::endl;
    std::cout << "5 + 3 = " << add(5, 3) << std::endl;
    std::cout << "5 - 3 = " << subtract(5, 3) << std::endl;
    return 0;
}
