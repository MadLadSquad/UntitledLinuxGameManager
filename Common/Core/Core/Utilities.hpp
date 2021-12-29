#pragma once
#include <vector>
#include <string>
#include <thread>
#include <unistd.h>

namespace UGM::Core::Utilities
{
    template<typename T>
    struct Vector2
    {
        Vector2() = default;
        explicit Vector2(const T& mult)
        {
            x = mult;
            y = mult;
        }
        Vector2(const T& xx, const T& yy)
        {
            x = xx;
            y = yy;
        }
        T x{};
        T y{};
    };

    template<typename T>
    struct Vector3
    {
        Vector3() = default;
        explicit Vector3(const T& mult)
        {
            x = mult;
            y = mult;
            z = mult;
        }
        Vector3(const T& xx, const T& yy, const T& zz)
        {
            x = xx;
            y = yy;
            z = zz;
        }
        T x{};
        T y{};
        T z{};
    };

    template<typename T>
    struct Vector4
    {
        Vector4() = default;
        explicit Vector4(const T& mult)
        {
            x = mult;
            y = mult;
            z = mult;
            w = mult;
        }
        Vector4(const T& xx, const T& yy, const T& zz, const T& ww)
        {
            x = xx;
            y = yy;
            z = zz;
            w = ww;
        }
        T x{};
        T y{};
        T z{};
        T w{};
    };

    template<typename T>
    using Vector = Vector3<T>;

    /**
     * @brief Given a reference to a vector of strings, an array of c string containing a nullptr terminated shell command
     * and a hint of weather to use threads this function will fork the current process, execute a command and load its
     * stdin and stderr output buffers(which can be offloaded to a thread) into a the vector for standard strings and
     * return a pid_t pointing to the child process
     * @param lineBuffer An array to hold every line of text
     * @param command A command that needs to be run on the child process via exec
     * @param bUsingThreads If bUsing threads is set to true then the loading of the string buffer will be offloaded to a separate thread
     * @param thread A pointer to a std::thread
     * @return The process ID of the child process, needed so that when used with multithreading users can kill the process after they join the thread!
     */
    pid_t loadLineByLineFromPID(std::vector<std::string>& lineBuffer, char* const* command, bool bUsingThreads = false, std::thread* thread = nullptr);
}