#!/usr/bin/env julia-0.5

include("db.jl")

#
# File discovery
#

# Recursively scan a directory for matching files
function scan(dir, extensions)
    sources = Vector{String}()
    for entry in readdir(dir)
        path = joinpath(dir, entry)
        if isdir(path)
            append!(sources, scan(path, extensions))
        elseif isfile(path) && any(ex->endswith(path, ex), extensions)
            push!(sources, path)
        end
    end
    return sources
end


#
# Tree construction
#

using ProgressMeter

function create_functions!(parent::Node{FileNode}, repo::String)
    path = parent[:path]
    lines = parent[:lines]

    # parse functions and start line (end line = start next function)
    cmd = pipeline(`ctags -x $path`, `sort -k3 -n`)
    functions = Dict{String, Tuple{Int, Int}}()
    previous = nothing
    for line in readlines(cmd)
        ctags_re = r"^(\w+)\s+(\w+)\s+(\d+) [^ ]+ (.+)$"
        m = match(ctags_re, line)
        if m != nothing
            fn, ftype, line, sig = m.captures
            linenr = parse(Int, line)

            # fix end linenumber of previous def
            if previous != nothing
                functions[previous] = tuple(functions[previous][1], linenr-1)
            end

            if ftype == "function"
                functions[fn] = tuple(linenr, 0)
                previous = fn
            end
        end
    end

    # create function nodes and save range info
    nodes = Dict{String, Node}()
    for (fn,range) in functions
        nodes[fn] = Node{FunctionNode}()
        nodes[fn][:range] = range
    end

    # extract code snippets (extremely inefficient, I know)
    snippets = Dict{String,String}()
    for (id, f) in nodes
        code = open(readlines, path)
        range = f[:range]

        if range[2] == 0
            # ctags didn't manage to find the end, so do a quick scan for '}'
            endline = lines # worst case

            snippet = code[range[1]:end]
            for i in 1:length(snippet)
                if rstrip(snippet[i]) == "}"
                    snippet = snippet[1:i]
                    endline = range[1]+i
                    break
                end
            end

            range = tuple(range[1], min(lines, endline))
        end

        f[:range] = range
        f[:code] = join(code[range[1]:range[2]])
    end

    # gather last changed info
    times = Vector{Int}()
    for line in readlines(`git -C $repo blame $path --line-porcelain`)
        time_rt = r"^committer-time (\d+)$"
        m = match(time_rt, line)
        if m != nothing
            push!(times, parse(Int, m.captures[1]))
        end
    end
    @assert lines == length(times)
    for (id, f) in nodes
        range = f[:range]
        f[:mtime] = maximum(times[range[1]:range[2]])
    end

    for (id, f) in nodes
        parent.nodes[id] = f
    end
    return nodes
end

function create_file!(parent::Node{DirectoryNode}, path::String)
    # make sure all branches towards the file exist
    dirpath, filename = splitdir(path)
    dirs = split(dirpath, '/')
    direct_parent = parent
    for dir in dirs
        direct_parent = get!(direct_parent.nodes, dir, Node{DirectoryNode}())
    end

    # gather some properties
    size = stat(path).size
    lines = length(open(readlines, path))

    node = Node{FileNode}()
    node[:path] = path
    node[:size] = size
    node[:lines] = lines

    direct_parent.nodes[filename] = node
    return node
end

function propagate_info!(node::Node{DirectoryNode})
    node[:lines] = 0
    node[:size] = 0

    # process all director nodes
    dirs = filter((k,v) -> isa(v, Node{DirectoryNode}), node.nodes)
    for (id, dir) in dirs
        propagate_info!(dir)

        node[:lines] += dir[:lines]
        node[:size] += dir[:size]
    end

    # process all file nodes
    files = filter((k,v) -> isa(v, Node{FileNode}), node.nodes)
    if length(files) > 0
        node[:lines] += sum(pair->pair[2][:lines], files)
        node[:size] += sum(pair->pair[2][:size], files)
    end
end

function Tree(repo, sources)
    dir = Node{DirectoryNode}()

    # add leaves to the tree
    p = Progress(length(sources), 1)
    for path in sources
        rel = relpath(path, repo)
        file = create_file!(dir, rel)
        file.nodes = create_functions!(file, repo)
        next!(p)
    end

    # propagate information upwards in a DFS
    propagate_info!(dir)

    return dir
end


#
# Main
#

import Base: filter!

using JSON

const EXTENSIONS = [".c", ".cxx", ".cpp"]

# Recursively strip a node of certain properties
function filter!(cb, node::Node)
    filter!(cb, node.props)
    for (id,node) in node.nodes
        filter!(cb, node)
    end
end

function main(args)
    if length(args) != 1
        error("Usage: parse.jl SOURCEDIR")
    end
    repo = args[1]
    isdir(repo) || error("$sourcedir isn't a directory")
    sources = scan(repo, EXTENSIONS)

    tree = cd(repo) do
        Tree(repo, sources)
    end

    # write to disk, only the info necessary to visualize the tree
    structure = deepcopy(tree)
    filter!((k,v) -> k!=:code, structure)
    open("sample_structure.json", "w") do io
        JSON.print(io, structure)
    end

    # write to disk, only the code
    code = deepcopy(tree)
    filter!((k,v) -> k==:code, code)
    open("sample_code.json", "w") do io
        JSON.print(io, code)
    end
end
main(ARGS)
