#pragma once

#include "DDI.hpp"

#include <graaflib/algorithm/shortest_path/bfs_shortest_path.h>
#include <graaflib/algorithm/shortest_path/dijkstra_shortest_path.h>
#include <graaflib/algorithm/strongly_connected_components/tarjan.h>
#include <graaflib/graph.h>
#include <graaflib/io/dot.h>
#include <graaflib/types.h>

#include <algorithm>
#include <cstddef>
#include <cstdio>
#include <filesystem>
#include <list>
#include <ranges>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

namespace mgt
{
    /**
     * Module node. Keeps track of which compile unit/source requires/provides which module. This is required since the
     * module graph does not track dependencies between physical files, but between the modules' logical names.
     */
    struct ModuleInfo
    {
        //! The logical name of the module
        std::string name;

        //! A list of source files that provide this module. This should only be one. If you have some setup that
        //! re-combines stuff in different libs, it might happen that different sources provide the same module.
        std::vector< std::string > providedBy;

        //! A list of compilation units that require this module.
        std::vector< std::string > requiredBy;

        /**
         * Merges information from one node into this one. The names must match.
         *
         * @throw std::runtime_error If the names do not match.
         *
         * @param rhs The node to merge in
         * @return This node
         */
        ModuleInfo& operator+=(const ModuleInfo& rhs)
        {
            if (name != rhs.name)
            {
                throw std::runtime_error("Cannot merge nodes with different names.");
            }

            providedBy.insert(providedBy.end(), rhs.providedBy.begin(), rhs.providedBy.end());
            requiredBy.insert(requiredBy.end(), rhs.requiredBy.begin(), rhs.requiredBy.end());

            return *this;
        }
    };

    //! The edge between module nodes
    struct Edge
    {
    };

    //! Metrics that can be derived for each node (each @ref ModuleInfo)
    struct ModuleMetrics
    {
        //! Number of incoming edges - aka the number of nodes that require this node.
        std::size_t numIn = 0;
        //! Number of outgoing edges - aka the number of nodes this node requires.
        std::size_t numOut = 0;

        //! Is true if the module is not provided by any source file
        bool isMissing = false;
        //! Is true, if the node is not required by any other module
        bool isSource = false;
        //! Is true, if the node is not consumed by any other module
        bool isSink = false;
        //! If the node has no requirements and is not required by any other module.
        bool isDisconnected = false;

        /**
         * If the node is part of a strongly connected component group. Note: 2 SCCs are pair-wise disjoint -> no
         * overlap possible.
         */
        bool isSCC = false;
        //! True for a node that is in the shortest cycle of its SCC.
        bool isInShortestCycle = false;
    };

    //! Represents the loaded module requirements graph and provides some tools to work with it.
    class ModuleGraph
    {
    public:
        /**
         * Load all DDI files from a given path and build a module graph out of them,
         *
         * @param root The directory where to load the DDI
         *
         * @return The graph
         */
        [[nodiscard]] static ModuleGraph make(const std::filesystem::path& root)
        {
            // Creates a node or merges it with an existing one.
            auto getOrCreateNode = [](auto& graph, ModuleInfo info)
            {
                for (const auto& [id, moduleInfo] : graph.get_vertices())
                {
                    if (moduleInfo.name != info.name)
                    {
                        continue;
                    }

                    graph.get_vertex(id) += info;
                    return id;
                }

                return graph.add_vertex(info);
            };

            ModuleGraph result(root);

            // Transform the DDI info to a graph. This allows for easy application of graph algorithms to find issues
            // hidden within.
            auto& graph = result.m_graph;
            // Yeewww a deeply nested set of for-loops. My nerdy-senses tell me to replace this with a long sequence of
            // std::range transforms, joins and zips. However, my inner pragmatic programmer tells me that the mental
            // load required to read nested loops is way way lower than the ranges version. So, nested loops it is.
            for (const auto& ddi : mgt::ddi::load(root))
            {
                for (const auto& rule : ddi.rules)
                {
                    for (const auto& provide : rule.provides)
                    {
                        auto pid = getOrCreateNode(
                            graph, {.name = provide.logicalName, .providedBy = {provide.sourcePath}, .requiredBy = {}});

                        std::ranges::for_each(rule.requires_,
                                              [&](const mgt::ddi::DDI::Require& req)
                                              {
                                                  auto rid =
                                                      getOrCreateNode(graph, {.name = req.logicalName,
                                                                              .providedBy = {},
                                                                              .requiredBy = {rule.primaryOutput}});

                                                  // As this is a requirement-graph, the arrows point towards the
                                                  // required component.
                                                  graph.add_edge(pid, rid, Edge{});
                                              });
                    }
                }
            }

            // The strongest connected components indicate cycles in the requirement-graph.
            result.m_sccs = graaf::algorithm::tarjans_strongly_connected_components(graph) |
                            std::views::filter([](const auto& scc) -> bool { return scc.size() > 1; }) |
                            std::ranges::to< std::vector >();

            // Using the SCC, calculate the shortest cycle in each SCC
            for (const auto& scc : result.m_sccs)
            {
                NodeList shortest{};
                for (const auto& id : scc)
                {
                    for (const auto& neighbourId :
                         // For each neighbour,
                         graph.get_neighbors(id) |
                             // That is in this SCC
                             std::views::filter([&](const auto& neighbourId)
                                                { return std::ranges::contains(scc, neighbourId); }))
                    {
                        auto shortestPath =
                            graaf::algorithm::bfs_shortest_path(result.m_graph, neighbourId, id).value().vertices;
                        shortestPath.push_back(neighbourId); // closes the loop

                        if (shortest.empty() || (shortest.size() > shortestPath.size()))
                        {
                            shortest = shortestPath;
                        }
                    }
                }
                result.m_cycles.emplace_back(std::move(shortest));
            }

            // For each node, calculate some metrics per node. They only make sense in relation to the graph the node is
            // in.
            for (const auto& [vertexId, moduleInfo] : graph.get_vertices())
            {
                // const auto& moduleInfo = graph.get_vertex(vertexId);
                auto numIn = moduleInfo.requiredBy.size();
                auto numOut = graph.get_neighbors(vertexId).size();

                result.m_metrics.insert(
                    {vertexId,
                     {
                         .numIn = numIn,
                         .numOut = numOut,
                         .isMissing = moduleInfo.providedBy.size() == 0,
                         .isSource = (numIn == 0) && (numOut != 0),
                         .isSink = (numIn != 0) && (numOut == 0),
                         .isDisconnected = (numIn + numOut) == 0, // = isSource && isSink
                         .isSCC = std::ranges::any_of(result.m_sccs | std::views::join,
                                                      [&](const auto& id) { return id == vertexId; }),
                         .isInShortestCycle = std::ranges::any_of(result.m_cycles | std::views::join,
                                                                  [&](const auto& id) { return id == vertexId; }),
                     }});
            }

            return result;
        }

        /**
         * Prints a report about this module graph. Outputs warnings, SCCs and cycles.
         */
        void printReport()
        {
            std::cout << std::format("Report for {}\n\n", m_path.string());

            auto numWarnings = 0;
            auto numErrors = 0;

            // Multiple sources for a module?
            for (const auto& [_, moduleInfo] :
                 m_graph.get_vertices() |
                     std::views::filter([](const auto& v) { return v.second.providedBy.size() > 1; }))
            {
                // C++23: std::print and formatting ranges not yet working everywhere.
                std::cout << std::format("W: multiple source for module \"{}\":\n   -> {}\n", moduleInfo.name,
                                         moduleInfo.providedBy | std::views::join_with(std::string(", ")) |
                                             std::ranges::to< std::string >());
                numWarnings++;
            }
            std::cout << (numWarnings > 0
                              ? ("HINT: This is likely to be caused by multiple targets sharing the same set of module "
                                 "code. To fix these, pass one of the target specific sub-dirs of CMakeFiles.\n")
                              : "");

            // Missing source for a referenced module?
            for (const auto& [_, moduleInfo] :
                 m_graph.get_vertices() |
                     std::views::filter([](const auto& v) { return v.second.providedBy.size() == 0; }))
            {
                std::cout << std::format("E: No source provides the module: {}\n", moduleInfo.name);
                numErrors++;
            }

            // Report SCCs
            for (const auto& [i, scc] : m_sccs | std::views::enumerate)
            {
                std::cout << std::format(
                    "E: Circular dependency:\n   -> Strongly connected components: {}\n   -> Shortest cycle: {}\n",
                    scc | std::views::transform([&](const auto& id) { return m_graph.get_vertex(id).name; }) |
                        std::views::join_with(std::string(", ")) | std::ranges::to< std::string >(),
                    m_cycles.at(static_cast< std::size_t >(i)) |
                        std::views::transform([&](const auto& id) { return m_graph.get_vertex(id).name; }) |
                        std::views::join_with(std::string(" -> ")) | std::ranges::to< std::string >());

                numErrors++;
            }

            std::cout << std::format("{}Warnings: {}, Errors: {}\n", (numWarnings + numErrors > 0) ? "\n" : "",
                                     numWarnings, numErrors);
        }

        /**
         * Export the graph as DOT file.
         *
         * @param file The file to write to
         */
        void exportDOT(const std::filesystem::path& file)
        {
            graaf::io::to_dot(
                m_graph, file,
                // Node writer
                [&]([[maybe_unused]] graaf::vertex_id_t vertexId, const ModuleInfo& moduleInfo)
                {
                    const auto& metrics = m_metrics.at(vertexId);

                    constexpr auto flagFormat = "<b>&lt;{}&gt;</b>";
                    auto flag = metrics.isMissing ? std::format(flagFormat, "missing source") : "";

                    const auto* color = metrics.isMissing        ? "orange"
                                        : metrics.isDisconnected ? "tomato"
                                        : metrics.isSink         ? "mediumspringgreen"
                                        : metrics.isSource       ? "lightskyblue"
                                                                 : "lightgrey";

                    return std::format(
                        "label=<{}<br/>{}>, fontname=Monospace, shape=box, style=\"rounded,filled\", fillcolor={}",
                        moduleInfo.name, flag, color);
                },
                // Edge writer
                [&]([[maybe_unused]] const graaf::edge_id_t& edgeId, [[maybe_unused]] const Edge& edge) -> std::string
                {
                    auto [pid, rid] = edgeId;
                    const auto& metricsP = m_metrics.at(pid);
                    const auto& metricsR = m_metrics.at(rid);

                    // If both nodes are part of an SCC, the edge is part of that SCC
                    bool isSCC = metricsR.isSCC && metricsP.isSCC;
                    bool isCycle = metricsR.isInShortestCycle & metricsP.isInShortestCycle;

                    const auto* color = isSCC ? "crimson" : "gray";
                    const auto* style = isCycle ? "dashed" : "solid";
                    auto width = 1 + (isSCC ? 2 : 0) + (isCycle ? 2 : 0);

                    return std::format("style={}, penwidth={}, color={}, fontcolor=gray", style, width, color);
                });
        }

    private:
        //! The module graph is a simple di-graph that stores some extended info per module node.
        using ModuleGraphImplT = graaf::directed_graph< ModuleInfo, Edge >;

        //! The module requirements graph as constructed from DDI
        ModuleGraphImplT m_graph;

        //! The strongly connected components (excluding single nodes)
        graaf::algorithm::sccs_t m_sccs;

        //! List of node IDs
        using NodeList = std::list< graaf::vertex_id_t >;

        //! A list of cycles. Each cycle is a list of ids. Always (one of) the shortest cycle per SCC.
        std::vector< NodeList > m_cycles;

        //! A set of per-node metrics that have been derived from the graph.
        std::unordered_map< graaf::vertex_id_t, ModuleMetrics > m_metrics;

        //! The path from where the DDI files have been loaded.
        std::filesystem::path m_path;

        //! Not very useful constructor. Values are calculated and filled by @ref make
        explicit ModuleGraph(std::filesystem::path path) : m_path(std::move(path))
        {
        }
    };

} // namespace mgt
