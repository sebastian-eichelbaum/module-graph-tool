#include "mgt/ModuleGraph.hpp"

#include <filesystem>
#include <iostream>

int main([[maybe_unused]] int argc, [[maybe_unused]] const char** argv)
{
    std::cout << "Module Graph Tools\n";
    std::cout << "Sebastian Eichelbaum" << "\n";
    std::cout << "https://github.com/sebastian-eichelbaum/mgt" << "\n\n";

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
