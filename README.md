# Module Graph Tool

A tool that helps analyzing the dependency structure of module-based C++ project that uses CMake+clang/gcc.

## About

With C++20, we got modules. Unfortunately, the C++ tooling and compiler support is still a bit lagging. In complex projekt with a lot of modules/partitions, it is very likely to create some **circular dependency**. CMake already informs us about it, but its output can be a bit overwhelming:

```
CMake Error: Circular dependency detected in the C++ module import graph. See modules named: "nx", "nx.assert", "nx.assert:Assert", "nx.assert:Assertions", "nx.fmt", "nx.fmt.formatter", "nx.fmt.formatter:Formatter", "nx.fmt.formatter:StdAdapter", "nx.fmt:Format", "nx.fmt:Print", "nx.fmt:formatters_StdSourceLocation", "nx.log", "nx.log:Adapter", "nx.log:Formatter", "nx.log:Logger", "nx.log:Message", "nx.log:Sink", "nx.log:Style", "nx.meta", "nx.meta:String", "nx.trait", "nx.trait:Iterable"
```

Instead of listing all the somehow related modules, it would be more useful to print the _strongly connected components_ in that dependency graph. This is where this tool comes in handy.

The module-graph-tool, 'mgt' for short, loads the compiler generated DDI files in your build directory, parses them and prints the strongly connected components (SCC) and the shortest circular dependency in that SCC group.

Additionally, it creates a DOT file of the dependency graph that can be used to analyce dependencies graphically.

## Requirements

(Testet with these versions, others might work too.)

-   Clang >= 18
-   GCC >= 14.2
-   Cmake >= 3.3

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

-   TODO

## FAQ

-   TODO
