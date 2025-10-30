#include <iostream>
#include <thread>
#include <mutex>
#include <atomic>
#include <chrono>
#include <vector>
#include <functional>
#include <memory>

// Для демонстрации livelock
std::mutex m1, m2;

// Для демонстрации голодания
std::mutex resource_mutex;
std::atomic<bool> high_priority_running{true};

void high_priority_task(int id) {
    while (high_priority_running) {
        std::lock_guard<std::mutex> lock(resource_mutex);

        // Имитация работы с общим ресурсом
        std::cout << "High-priority thread " << id << " using resource.\n";
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
}

void low_priority_task() {
    // Этот поток может "голодать", если высокоприоритетные не дают ему шанса
    for (int i = 0; i < 5; ++i) {
        std::lock_guard<std::mutex> lock(resource_mutex);
        std::cout << "Low-priority thread got resource! (" << i << ")\n";
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }
}

// Livelock: два потока постоянно уступают друг другу
void livelock_thread1() {
    for (int i = 0; i < 10; ++i) {
        std::cout << "Thread 1 trying to lock m1...\n";
        if (m1.try_lock()) {
            std::cout << "Thread 1 locked m1, now trying m2...\n";
            if (m2.try_lock()) {
                std::cout << "Thread 1 got both locks! Doing work.\n";
                m2.unlock();
                m1.unlock();
                return;
            } else {
                std::cout << "Thread 1: m2 busy, releasing m1.\n";
                m1.unlock();
            }
        }
        std::this_thread::yield(); // Уступаем — типично для livelock
    }
    std::cout << "Thread 1 gave up.\n";
}

void livelock_thread2() {
    for (int i = 0; i < 10; ++i) {
        std::cout << "Thread 2 trying to lock m2...\n";
        if (m2.try_lock()) {
            std::cout << "Thread 2 locked m2, now trying m1...\n";
            if (m1.try_lock()) {
                std::cout << "Thread 2 got both locks! Doing work.\n";
                m1.unlock();
                m2.unlock();
                return;
            } else {
                std::cout << "Thread 2: m1 busy, releasing m2.\n";
                m2.unlock();
            }
        }
        std::this_thread::yield(); // Уступаем — типично для livelock
    }
    std::cout << "Thread 2 gave up.\n";
}

// Пример с передачей ссылки
void modify_data(int& value) {
    value *= 2;
}

// Пример с unique_ptr (перемещение)
void consume_unique_ptr(std::unique_ptr<int> p) {
    std::cout << "Consumed unique_ptr with value: " << *p << "\n";
}

// Пример jthread с остановкой
#ifdef __cpp_lib_jthread
void cancellable_worker(std::stop_token stoken) {
    int count = 0;
    while (!stoken.stop_requested()) {
        std::cout << "Working... (" << ++count << ")\n";
        std::this_thread::sleep_for(std::chrono::milliseconds(300));
    }
    std::cout << "Worker stopped gracefully.\n";
}
#endif

int main() {
    std::cout << "=== Демонстрация проблем многопоточности ===\n\n";

    // 1. Голодание потоков
    std::cout << "1. ГОЛОДАНИЕ ПОТОКОВ:\n";
    std::vector<std::thread> high_prio_threads;
    for (int i = 0; i < 3; ++i) {
        high_prio_threads.emplace_back(high_priority_task, i);
    }

    std::thread low_prio(low_priority_task);

    // Даём высокоприоритетным потокам поработать 2 секунды
    std::this_thread::sleep_for(std::chrono::seconds(2));
    high_priority_running = false;

    for (auto& t : high_prio_threads)
        t.join();
    low_prio.join();
    std::cout << "\n";

    // 2. Livelock
    std::cout << "2. LIVELOCK:\n";
    std::thread t1(livelock_thread1);
    std::thread t2(livelock_thread2);
    t1.join();
    t2.join();
    std::cout << "\n";

    // 3. Передача аргументов: ссылка
    std::cout << "3. ПЕРЕДАЧА ССЫЛКИ:\n";
    int data = 10;
    std::thread t_ref(modify_data, std::ref(data));
    t_ref.join();
    std::cout << "Modified data via ref: " << data << "\n\n";

    // 4. Перемещение unique_ptr
    std::cout << "4. ПЕРЕМЕЩЕНИЕ УНИКАЛЬНОГО УКАЗАТЕЛЯ:\n";
    auto ptr = std::make_unique<int>(42);
    std::thread t_move(consume_unique_ptr, std::move(ptr));
    t_move.join(); // ptr теперь nullptr
    std::cout << "\n";

    // 5. jthread
#ifdef __cpp_lib_jthread
    std::cout << "5. JTHREAD С ОСТАНОВКОЙ (C++20):\n";
    std::jthread worker(cancellable_worker);
    std::this_thread::sleep_for(std::chrono::seconds(1));
    // worker автоматически запросит остановку при выходе из области видимости
    std::cout << "Main requesting stop...\n";
#endif

    std::cout << "=== Завершение ===\n";
    return 0;
}
