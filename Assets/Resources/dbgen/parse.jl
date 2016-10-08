#!/usr/bin/env julia-0.5

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

abstract Node

abstract LeafNode <: Node

immutable FunctionNode
    range::Tuple{Int,Int}
    code::String
end


abstract BranchNode <: Node

immutable FileNode <: BranchNode
    path::String
    size::Int
    lines::Int
    functions::Dict{String,FunctionNode}
end

immutable DirectoryNode <: BranchNode
    files::Dict{String,FileNode}
    directories::Dict{String,DirectoryNode}

    DirectoryNode() = new(Dict{String,FileNode}(), Dict{String,DirectoryNode}())
end

function add_file!(root::DirectoryNode, path::String)
    # make sure all branches towards the file exist
    dirpath, filename = splitdir(path)
    dirs = split(dirpath, '/')
    dirnode = root
    for dir in dirs
        dirnode = get!(dirnode.directories, dir, DirectoryNode())
    end

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

    # extract code (extremely inefficient, I know)
    functionnodes = Dict{String, FunctionNode}()
    for (fn,range) in functions
        code = open(readlines, path)
        if range[2] == 0
            # ctags didn't manage to find the end, so do a quick scan for '}'
            snippet = code[range[1]:end]
            for i in 1:length(snippet)
                if rstrip(snippet[i]) == "}"
                    snippet = snippet[1:i]
                    range = tuple(range[1], range[1]+i)
                    break
                end
            end
        else
            snippet = code[range[1]:range[2]]
        end
        functionnodes[fn] = FunctionNode(range, join(snippet))
    end

    # gather other info
    size = stat(path).size
    lines = length(open(readlines, path))

    filenode = FileNode(path, size, lines, functionnodes)
    dirnode.files[filename] = filenode

    return
end

function Tree(root, sources)
    node = DirectoryNode()

    p = Progress(length(sources), 1)
    for path in sources
        rel = relpath(path, root)
        add_file!(node, rel)
        next!(p)
    end

    return node
end


#
# Main
#

using JSON

const EXTENSIONS = [".c", ".cxx", ".cpp"]

function main(args)
    if length(args) != 1
        error("Usage: parse.jl SOURCEDIR")
    end
    sourcedir = args[1]
    isdir(sourcedir) || error("$sourcedir isn't a directory")
    sources = scan(sourcedir, EXTENSIONS)

    tree = cd(sourcedir) do
        Tree(sourcedir, sources)
    end

    open("sample.json", "w") do io
        JSON.print(io, tree)
    end
end
main(ARGS)
