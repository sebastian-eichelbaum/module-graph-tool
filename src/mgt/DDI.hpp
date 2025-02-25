#pragma once

#ifndef NDEBUG
    #define JSON_DIAGNOSTICS 1
#endif
#include <nlohmann/json.hpp>

#include <filesystem>
#include <format>
#include <fstream>
#include <iostream>
#include <ranges>
#include <stdexcept>

namespace mgt::ddi
{
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Data Structure
    //

    /**
     * The DDI structure. Represents a compilation unit's provides/requires rules of DDI version 1 - only modules
     * provide something.
     */
    struct DDI
    {
        //! A DDI provide-clause
        struct Provide
        {
            //! The logical name is the module name (also, full partition name)
            std::string logicalName;

            //! The source file where this is provided
            std::string sourcePath = "<undefined>";
        };

        //! A DDI require-clause
        struct Require
        {
            //! The logical name is the module name (also, full partition name)
            std::string logicalName;
        };

        //! A DDI rule
        struct Rule
        {
            //! The compilation output file.
            std::string primaryOutput;

            //! A list of provided modules/partitions
            std::vector< Provide > provides;
            //! The list of requirements to make primaryOutput compilable
            std::vector< Require > requires_;
        };

        //! DDI version. Currently, version 1 is supported.
        int version = 0;
        //! DDI revision. Currently, ignored.
        int revision = 0;

        //! A list of rules represented in a DDI file.
        std::vector< Rule > rules;

        //! The path of the file. Absolute.
        std::filesystem::path path;
        //! The root path where all DDI files have been loaded from.
        std::filesystem::path root;
    };

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // JSON Parsing Setup
    //
    // See https://json.nlohmann.me/features/arbitrary_types/

    //! @cond EXCLUDED

    inline void from_json(const nlohmann::json& j, DDI::Provide& p)
    {
        j.at("logical-name").get_to(p.logicalName);
        if (j.count("source-path") != 0)
        {
            j.at("source-path").get_to(p.sourcePath);
        }
    }

    inline void from_json(const nlohmann::json& j, DDI::Require& p)
    {
        j.at("logical-name").get_to(p.logicalName);
    }

    inline void from_json(const nlohmann::json& j, DDI::Rule& p)
    {
        if (j.count("provides") != 0)
        {
            j.at("provides").get_to(p.provides);
        }

        if (j.count("requires") != 0)
        {
            j.at("requires").get_to(p.requires_);
        }

        j.at("primary-output").get_to(p.primaryOutput);
    }

    inline void from_json(const nlohmann::json& j, DDI& p)
    {
        j.at("rules").get_to(p.rules);
        j.at("version").get_to(p.version);
        j.at("revision").get_to(p.revision);
    }

    //! @endcond

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // IO
    //

    /**
     * Find and load all DDI files in a given directory.
     *
     * @param root The root directory to search in.
     *
     * @return a range of @ref mgt::DDI instances
     */
    [[nodiscard]] inline decltype(auto) load(const std::filesystem::path& root)
    {
        return
            // 1: Find all ddi files
            std::filesystem::recursive_directory_iterator(root) |
            std::views::filter([](auto&& x) { return x.path().extension() == ".ddi"; }) |
            // 2: Load them into the mgt::DDI struct
            std::views::transform(
                [=](auto&& x) -> std::optional< DDI > // std::expected not yet available
                {
                    try
                    {
                        auto ddiJson = nlohmann::json::parse(std::ifstream(x.path()));
                        if (ddiJson["version"].get< int >() > 1)
                        {
                            throw std::runtime_error(
                                std::format("Expected DDI version 0 or 1. Got: {}", ddiJson["version"].get< int >()));
                        }

                        auto ddi = ddiJson.get< DDI >();
                        ddi.path = x.path();
                        ddi.root = root;

                        // Remove all rules that have no "provides"? If we keep those, we would include sinks that
                        // consume modules. That's not (yet) supported.
                        ddi.rules = ddi.rules | std::views::filter([](auto&& rule) { return !rule.provides.empty(); }) |
                                    std::ranges::to< std::vector >();

                        return ddi;
                    }
                    catch (std::exception& e)
                    {
                        auto relativePath = std::filesystem::relative(x, root);
                        std::cerr << std::format("ERR: Failed to load DDI file ({}). Error: {}",
                                                 std::string(relativePath), e.what())
                                  << "\n";
                    }

                    return std::nullopt;
                }) |
            // 3: "cache" the results in a vector. Refer to the C++ ranges transform+filter issue. Transform would be
            // called twice.
            std::ranges::to< std::vector >() |
            // 4: Remove trash (no module exports)
            std::views::filter([](auto&& x) { return x.has_value() && !x.value().rules.empty(); }) |
            std::views::transform([](auto&& x) { return x.value(); });
    }
} // namespace mgt::ddi
