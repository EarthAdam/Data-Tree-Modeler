using JSON

abstract Node

function JSON.lower{T<:Node}(node::T)
    return Dict{Symbol, Any}(
        :type => typeof(node),
        :nodes => node.nodes,
        node.props...
    )
end

Base.getindex(node::Node, key::Symbol) = node.props[key]
Base.setindex!(node::Node, val, key::Symbol) = (node.props[key] = val)


abstract LeafNode <: Node

type FunctionNode <: LeafNode
    props::Dict{Symbol,Any}
    nodes::Dict{String,Node}

    FunctionNode() = new(Dict{Symbol,Any}(), Dict{String,Node}())
end


abstract BranchNode <: Node

type FileNode <: BranchNode
    props::Dict{Symbol,Any}
    nodes::Dict{String,FunctionNode}

    FileNode() = new(Dict{Symbol,Any}(), Dict{String,FunctionNode}())
end

type DirectoryNode <: BranchNode
    props::Dict{Symbol,Any}
    nodes::Dict{String,Node}

    DirectoryNode() = new(Dict{Symbol,Any}(), Dict{String,Node}())
end
