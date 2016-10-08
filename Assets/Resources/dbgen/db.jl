using JSON

abstract NodeType
abstract DirectoryNode <: NodeType
abstract FileNode <: NodeType
abstract FunctionNode <: NodeType

const typenames = Dict{Type,Symbol}(
    DirectoryNode   => :directory,
    FileNode        => :file,
    FunctionNode    => :function
)

type Node{T<:NodeType}
    props::Dict{Symbol,Any}
    nodes::Dict{String,Node}

    Node() = new(Dict{Symbol,Any}(), Dict{String,Node}())
end

function JSON.lower{T<:NodeType}(node::Node{T})
    return Dict{Symbol, Any}(
        :type => typenames[T],
        :nodes => node.nodes,
        node.props...
    )
end

Base.getindex(node::Node, key::Symbol) = node.props[key]
Base.setindex!(node::Node, val, key::Symbol) = (node.props[key] = val)
