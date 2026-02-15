#include "mgt/ModuleGraph.hpp"

#include <filesystem>
#include <iostream>

int main([[maybe_unused]] int argc, [[maybe_unused]] const char** argv)
{
    std::cout << "Module Graph Tool\n";
    std::cout << "Sophia Eichelbaum" << "\n";
    std::cout << "https://github.com/seichelbaum/module-graph-tool" << "\n\n";

    auto location = std::filesystem::current_path();
    if (argc == 2)
    {
        location = std::filesystem::path(argv[1]); // NOLINT: pointer arithmetic is acceptable here.
    }

    auto moduleGraph = mgt::ModuleGraph::make(location);
    moduleGraph.exportDOT("graph.dot");
    moduleGraph.printReport();

    return 0;
}
