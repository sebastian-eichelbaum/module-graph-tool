# Module Graph Tool

A tool that helps analyzing the dependency structure of module-based C++ project that uses CMake+clang/gcc.

> [!IMPORTANT]
>
> -   This is basically a hack. It took me a few hours to put this together. It helped me to uncover some circular dependency issues in my code. It might help you too, but it will, most likely, not cover all the edge cases you might have.
> -   This is designed to be a temporary solution. As C++ tooling gets better and better every minute, it is just a matter of time until this tool is obsolete.

## About

#### The Problem

With C++20, we got modules. Unfortunately, the C++ tooling and compiler support is still a bit lagging. In a complex project with a lot of modules/partitions, it is very likely to create some **circular dependency**. CMake already informs us about it, but its output can be a bit overwhelming:

```
CMake Error: Circular dependency detected in the C++ module import graph. See modules named: "nx", "nx.assert", "nx.assert:Assert", "nx.assert:Assertions", "nx.fmt", "nx.fmt.formatter", "nx.fmt.formatter:Formatter", "nx.fmt.formatter:StdAdapter", "nx.fmt:Format", "nx.fmt:Print", "nx.fmt:formatters_StdSourceLocation", "nx.log", "nx.log:Adapter", "nx.log:Formatter", "nx.log:Logger", "nx.log:Message", "nx.log:Sink", "nx.log:Style", "nx.meta", "nx.meta:String", "nx.trait", "nx.trait:Iterable"
```

> [!NOTE]
> The Cmake devs have a ticket for that: https://gitlab.kitware.com/cmake/cmake/-/issues/26119

#### The 'Solution'

Instead of listing all the somehow related modules, it would be more useful to print the _strongly connected components_ in that dependency graph. This is where this tool comes in handy.

The module-graph-tool, 'mgt' for short, loads the compiler generated DDI files in your build directory, parses them and prints the strongly connected components (SCC) and the shortest circular dependency in that SCC group.

Additionally, it creates a DOT file of the dependency graph that can be used to analyze dependencies graphically.

##### SCC-what?

In graph-theory, stringly connected component (SCC) represents a subset of nodes in a graph, where each node is reach-able by each other node in that group. See [Wikipedia](https://en.wikipedia.org/wiki/Strongly_connected_component).

## Requirements

(Testet with these versions, others might work too.)

-   Clang >= 18
-   GCC >= 14.2
-   Cmake >= 3.3

**Tested on Linux** - but it will probably work on Mac and Windows too. Mac users have to pay 99€ in the app-store first, I guess 😉.

## Build

The dependencies are integrated as git submodules. When getting the code, make sure to get the submodules too:

```sh
git clone --recursive https://github.com/sebastian-eichelbaum/module-graph-tool.git
```

### Using clang/gcc directly:

As `mgt` is one CPP file, building it in a single call to the compiler is nearly trivial:

```sh
clang++ -O3 --std=c++23 src/main.cpp \
    -Iexternal/nlohmann_json/single_include \
    -Iexternal/graaf/include \
    -lstdc++
    -o mgt
```

### Using Cmake:

Use Cmake if you want to work with the code. It adds some common tooling, like clang-tidy or ccache if it is found.

```sh
cmake --preset x64-release-clang
cd build/x64-release-clang
ninja
```

## Usage

```sh
# Go to your build dir.
cd zen/build/x64-release-clang
# In there, you will have a directory called 'CMakeFiles'. Each sub-directory is a
# target of your project. It is recommended to use the tool per target, not per
# project as there might be a lot of overlap.
cd CMakeFiles/zen.dir
# Run mgt
mgt
# Alternatively, pass the directory to mgt:
mgt ~/Projects/zen/build/x64-release-clang/CmakeFiles/zen.dir
```

`mgt` will print a report. It will show you which modules a referenced but missing and where a circular dependency is:

```
Report for /home/seb/Projekte/zen/build/x64-release-clang/CMakeFiles/zen.dir

E: No source provides the module: test_missing:Some_Missing
E: Circular dependency:
   -> Strongly connected components: nx.fmt:Format, nx.fmt:Print, nx.fmt:formatters_StdSourceLocation, nx.fmt.formatter:Formatter, nx.fmt.formatter:StdAdapter, nx.fmt.formatter, nx.fmt
   -> Shortest cycle: nx.fmt -> nx.fmt.formatter -> nx.fmt.formatter:Formatter -> nx.fmt

Warnings: 0, Errors: 2
```

The shown shortest cycle is the path you should follow. In this case, the partition `nx.fmt.formatter:Formatter` imported `nx.fmt` again, by which it was imported, which imports the partition `nx.fmt.formatter:Formatter`, which imports `fmt.fmt`, which imports the partition `nx.fmt.formatter:Formatter`, which imports `nx.fmt` - Abort. Stack overflow 😬.

### Graph Visualization

Besides the textual report, `mgt` creates a file called `graph.dot`. This contains the whole dependency graph. It can be rendered either by going to [Graphviz Online](https://dreampuf.github.io/GraphvizOnline/?engine=dot), or by rendering it using `dot`.

```sh
# Convert to png using dot:
dot -Tpng graph.dot -o graph.png
```

It looks something like this:
![Rendered Graph](/doc/graph.webp?raw=true)

#### How to read:

-   Each Node is a module/module partition.
    -   Green-ish modules: These modules do not require anything, but are required by others.
    -   Blue-ish modules: These modules are not required by anything, but they require others.
    -   Orange modules: These modules where required, but their implementation could not be found.
    -   Red-ish: These modules are not required, nor do they require anything. They are completely disconnected.
    -   Grey: Modules that are required by others and require others.
-   Edges between nodes represent "requirement". `A->B` means "A requires B"
    -   Red: Modules connected by red edges represent strongly connected components (SCCs). There is a loop!
    -   Red+Dashed: This is the shortest circular dependency in that SCC

## TODO

-   [ ] Do not write the DOT file without asking
-   [ ] Allow customizing colors in the graph?
-   [ ] Fix all the issues and edge-cases people will come up with 🤯

## Thanks

❤️ [Graaf](https://github.com/bobluppes/graaf) - A lightweight graph library + some useful algorithms | ❤️ [nlohmann json](https://github.com/nlohmann/json) - JSON library

## Support

<a href="https://www.buymeacoffee.com/sebastian_eichelbaum" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41"></a>

<a href='https://ko-fi.com/sebastian_eichelbaum' target='_blank'><img src='https://storage.ko-fi.com/cdn/kofi1.png' alt='Buy Me a Coffee at ko-fi.com' height='41' /></a>
