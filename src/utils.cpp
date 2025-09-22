#include <iostream>
#include <thread>
#include <chrono>

#ifdef DEBUG_MODE
    #define DBG_PRINT(x) std::cout << "[DEBUG] " << x << std::endl;
#else
    #define DBG_PRINT(x)
#endif

void delay(int seconds) {
    DBG_PRINT("Starting delay for " << seconds << " seconds");
    std::this_thread::sleep_for(std::chrono::seconds(seconds));
    DBG_PRINT("Delay finished");
}

int main() {
    std::cout << "Utils Demo with threading" << std::endl;
    delay(2);
    std::cout << "Program finished" << std::endl;
    return 0;
}
