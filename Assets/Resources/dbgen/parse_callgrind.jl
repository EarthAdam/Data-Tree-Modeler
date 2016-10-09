#!/usr/bin/env julia-0.5

include("db.jl")


#
# Log parsing
#

function readlog(path, file_fns)
    files = Dict{Int,String}()
    functions = Dict{Int,String}()

    current_file = nothing
    coverage = Dict{Tuple{String,String}, Int}()

    fns = Set(Base.flatten(v for (k,v) in file_fns))

    # HACK
    function clean_fn(path, fn)
        _, file = splitdir(path)
        # BROKEN: too many headers, etc
        # if !haskey(file_fns, file)
        #     warn("unknown file $file")
        #     return fn
        # end

        # NOTE: we should probably save the full sig in parse_sources
        #       instead of cleaning it here
        matches = eachmatch(r"\b(\w+)\b", fn)
        for m in matches
            candidate = m.captures[1]
            if candidate in fns
                return candidate
            end
        end
        warn("couldn't match $fn")
        return nothing
    end

    for line in readlines(path)
        if (m = match(r"^c?f[il]=\((\d+)\) (.+)$", line)) != nothing
            id, file = m.captures
            files[parse(Int, id)] = file
            current_file = file
        elseif (m = match(r"^c?f[il]=\((\d+)\)$", line)) != nothing
            id = m.captures[1]
            current_file = files[parse(Int, id)]
        elseif (m = match(r"^c?fn=\((\d+)\) (.+)$", line)) != nothing
            id, func = m.captures
            func = clean_fn(current_file, func)
            if func != nothing
                functions[parse(Int, id)] = func
                key = tuple(current_file, func)
                visits = get(coverage, key, 0)
                coverage[key] = visits+1
            end
        elseif (m = match(r"^c?fn=\((\d+)\)$", line)) != nothing
            id = m.captures[1]
            if haskey(functions, parse(Int, id))    # HACK because conditionally add proper
                func = functions[parse(Int, id)]
                key = tuple(current_file, func)
                visits = get(coverage, key, 0)
                coverage[key] = visits+1
            end
        end
    end

    return coverage
end


#
# Tree construction
#

function create_file!(root::Node{DirectoryNode}, path::String)
    # make sure all branches towards the file exist
    parent, id = create_path!(root, path)

    node = Node{FileNode}()

    parent.nodes[id] = node
    return node
end

function create_functions!(parent::Node{FileNode}, functions::Dict{String,Int})
    # create function nodes and save range info
    nodes = Dict{String, Node}()
    for (fn,visits) in functions
        nodes[fn] = Node{FunctionNode}()
        nodes[fn][:visits] = visits
    end

    for (id, f) in nodes
        parent.nodes[id] = f
    end
    return nodes
end

function Tree(repo, coverage::Dict{Tuple{String,String}, Int})
    repo = realpath(repo)
    root = Node{DirectoryNode}()

    # filter and restructure the coverage map
    paths = Dict{String, Dict{String, Int}}()
    for (pair,visits) in coverage
        path, func = pair
        isfile(path) || continue
        path = realpath(path)
        if startswith(path, repo)
            funcs = get!(paths, path, Dict{String,Int}())
            funcs[func] = visits
        end
    end

    for (path, funcs) in paths
        rel = relpath(path, repo)
        file = create_file!(root, rel)
        create_functions!(file, funcs)
    end

    return root
end


#
# Main
#

function main(args)
    if length(args) != 2
        error("Usage: parse.jl SOURCEDIR LOGFILE")
    end
    repo = args[1]
    isdir(repo) || error("$repo isn't a directory")
    logfile = args[2]
    isfile(logfile) || error("$sourcedir isn't a log")

    # HACK
    file_fns = open("functions.dat", "r") do io
        deserialize(io)
    end
    
    coverage = readlog(logfile, file_fns)

    tree = Tree(repo, coverage)

    # write to disk
    open("sample_coverage.json", "w") do io
        JSON.print(io, tree)
    end
end
main(ARGS)
