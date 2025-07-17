/*
 * Copyright (c) 2023 Hartmut Kaiser
 * Copyright (c) 2023 Christopher Taylor
 *
 * SPDX-License-Identifier: BSL-1.0
 * Distributed under the Boost Software License, Version 1.0. *(See accompanying
 * file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
 */

#pragma once

#include <cxxabi.h>
#include <filesystem>
#include <string>
#include <typeinfo>
#include <variant>
#include <vector>

namespace chplx::util {

    namespace detail {
        template <typename T>
        std::string demangle()
        {
            const char* name = typeid(T).name();
            int status = 0;
            std::unique_ptr<char, decltype(&std::free)> demangled{
                abi::__cxa_demangle(name, nullptr, nullptr, &status),
                &std::free};
            return (status == 0 ? demangled.get() : name);
        }
        template <typename... Ts>
        std::string variant_active_type(const std::variant<Ts...>& v)
        {
            return std::visit(
                [](auto&& x) {
                    // decay_t to strip references/const-qualifiers
                    using U = std::decay_t<decltype(x)>;
                    return demangle<U>();
                },
                v);
        }
    }    // namespace detail

// global options
extern bool suppressLineDirectives;
extern bool fullFilePath;
extern bool compilerDebug;
extern std::filesystem::path output_path;

extern std::vector<std::filesystem::path> incdirs;
extern std::vector<std::filesystem::path> libdirs;
extern std::vector<std::string> libs; 
extern std::vector<std::string> flagscxx;
extern std::vector<std::string> packages_cmake;
extern std::vector<std::string> packages_pkgconfig;

// emit line directive
std::string emitLineDirective(char const* name, int line);
} // namespace chplx::util
