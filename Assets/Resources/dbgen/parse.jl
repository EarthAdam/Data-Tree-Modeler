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
    mtime::Int
    code::String
end


abstract BranchNode <: Node

immutable FileNode <: BranchNode
    path::String
    size::Int
    lines::Int
    functions::Dict{String,FunctionNode}
end

type DirectoryNode <: BranchNode
    files::Dict{String,FileNode}
    directories::Dict{String,DirectoryNode}
    size::Int
    lines::Int

    DirectoryNode() = new(Dict{String,FileNode}(), Dict{String,DirectoryNode}())
end

function add_file!(repo::String, parent::DirectoryNode, path::String)
    # make sure all branches towards the file exist
    dirpath, filename = splitdir(path)
    dirs = split(dirpath, '/')
    dirnode = parent
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

    # gather cheap info
    size = stat(path).size
    lines = length(open(readlines, path))

    # extract code snippets (extremely inefficient, I know)
    snippets = Dict{String,String}()
    for (fn,range) in functions
        code = open(readlines, path)

        # ctags didn't manage to find the end, so do a quick scan for '}'
        if range[2] == 0
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

        functions[fn] = range
        snippets[fn] = join(code[range[1]:range[2]])
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

    # create function nodes
    functionnodes = Dict{String, FunctionNode}()
    for (fn,range) in functions
        functionnodes[fn] = FunctionNode(range, maximum(times[range[1]:range[2]]), snippets[fn])
    end

    filenode = FileNode(path, size, lines, functionnodes)
    dirnode.files[filename] = filenode

    return
end

function propagate_info!(node::DirectoryNode)
    node.lines = 0
    node.size = 0

    # process all branches
    for (id, dir) in node.directories
        propagate_info!(dir)

        node.lines += dir.lines
        node.size += dir.size
    end

    # process all leaves
    if length(node.files) > 0
        node.lines += sum(pair->pair[2].lines, node.files)
        node.size += sum(pair->pair[2].size, node.files)
    end
end

function Tree(repo, sources)
    node = DirectoryNode()

    # add leaves to the tree
    p = Progress(length(sources), 1)
    for path in sources
        rel = relpath(path, repo)
        add_file!(repo, node, rel)
        next!(p)
    end

    # propagate information upwards in a DFS
    propagate_info!(node)

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
    repo = args[1]
    isdir(repo) || error("$sourcedir isn't a directory")
    sources = scan(repo, EXTENSIONS)

    tree = cd(repo) do
        Tree(repo, sources)
    end

    open("sample.json", "w") do io
        JSON.print(io, tree)
    end
end
main(ARGS)
