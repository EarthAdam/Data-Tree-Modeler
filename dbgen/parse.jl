#!/usr/bin/env julia-0.5

using JSON

const DIR = "/opt/llvm/llvm-3.9.src/lib/Target/NVPTX"
const EXTENSIONS = [".c", ".cxx", ".cpp"]

function scan(parent)
    sources = Vector{String}()
    for child in readdir(parent)
        path = joinpath(parent, child)
        if isdir(path)
            append!(sources, scan(path))
        elseif isfile(path) && any(ex->endswith(path, ex), EXTENSIONS)
            push!(sources, path)
        end
    end
    return sources
end

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
    # TODO: includes?
    functions::Dict{String,FunctionNode}
end

leaves(node::FileNode) = node.functions
branches(node::FileNode) = Dict{String,BranchNode}()

immutable DirectoryNode <: BranchNode
    files::Dict{String,FileNode}
    directories::Dict{String,DirectoryNode}

    DirectoryNode() = new(Dict{String,FileNode}(), Dict{String,DirectoryNode}())
end

leaves(node::DirectoryNode) = LeafNode[]
branches(node::DirectoryNode) = merge(node.files, node.directories)

function add_file!(rootnode::BranchNode, path::String)
    dirpath, filename = splitdir(path)
    dirs = split(dirpath, '/')

    fullpath = joinpath(DIR, path)

    # parse functions and start line (end line = start next function)
    cmd = pipeline(`ctags -x $fullpath`, `sort -k3 -n`)
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
        code = open(readlines, fullpath)
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
    size = stat(fullpath).size
    lines = length(open(readlines, fullpath))

    filenode = FileNode(path, size, lines, functionnodes)

    dirnode = rootnode
    for dir in dirs
        dirnode = get!(dirnode.directories, dir, DirectoryNode())
    end
    dirnode.files[filename] = filenode
end

function build_tree(sources)
    root = DirectoryNode()

    for path in sources
        rel = relpath(path, DIR)
        add_file!(root, rel)
    end

    return root
end

function visualize{T<:BranchNode}(root::T, indent=0)
    println(" "^indent, "leaves: ")
    for (id,node) in leaves(root)
        println(" "^indent, "- $(typeof(node)): $id")
        visualize(node, indent+2)
    end

    println(" "^indent, "branches: ")
    for (id, node) in branches(root)
        println(" "^indent, "- $(typeof(node)): $id")
        visualize(node, indent+2)
    end
end

function visualize(root::FileNode, indent=0)
    println(" "^indent, "size: ", root.size)
    println(" "^indent, "lines: ", root.lines)

    println(" "^indent, "leaves: ")
    for (id,node) in leaves(root)
        println(" "^indent, "- $(typeof(node)): $id")
        visualize(node, indent+2)
    end

    println(" "^indent, "branches: ")
    for (id, node) in branches(root)
        println(" "^indent, "- $(typeof(node)): $id")
        visualize(node, indent+2)
    end
end

function visualize(node::FunctionNode, indent=0)
    println(" "^indent, "$(length(node.code)) lines of code")
end

function main(args)
    sources = scan(DIR)
    root = build_tree(sources)
    visualize(root)

    open("sample.json", "w") do io
        JSON.print(io, root)
    end
end
main(ARGS)