parent(i::Int) = i ÷ 2
left(i::Int) = 2i
right(i::Int) = 2i + 1
parent(L::AbstractVector, i::Int) = L[parent(i)]
left(L::AbstractVector, i::Int) = L[left(i)]
right(L::AbstractVector, i::Int) = L[right(i)]

function exchange!(L::AbstractVector, i::Int, j::Int)
    #     println((i,j),": ", (L[i],L[j]))
    temp = L[i]
    L[i] = L[j]
    L[j] = temp
end
    
function minheapify!(L::AbstractVector, i::Int)
    min_ = i
    if left(i) <= length(L) && left(L, i) |> first < L[min_] |> first
        min_ = left(i)
    end
    if right(i) <= length(L) && right(L, i) |> first < L[min_] |> first
        min_ = right(i)
    end
    if min_ != i
        exchange!(L, i, min_)
        minheapify!(L, min_)
    end
end
        
function buildminheap!(L::AbstractVector)
    len = length(L)
    for i in len ÷ 2:-1:1
        minheapify!(L, i)
    end
end
    
heapmin(L::AbstractVector) = L[1]
    
function heapextractmin!(L::AbstractVector)
    head = L[1]
    tail = pop!(L)
    if length(L) > 0
        L[1] = tail
        minheapify!(L, 1)
    end
    return head
end
    
function heapdecreasekey!(L::AbstractVector, i::Int)
    while i > 1 && first(parent(L, i)) > first(L[i]) 
        exchange!(L, i, parent(i))
        i = parent(i)
    end               
end
    
function minheapinsert!(L::AbstractVector, v::T) where T
    push!(L, v)
    heapdecreasekey!(L, length(L))
end
    
function heapchangekey!(L::AbstractVector{T}, i::Int, v::T, oldkey) where T
    #     @assert i<=length(L)
    if first(v) == oldkey
        nothing
    elseif first(v) < oldkey
        L[i] = v
        heapdecreasekey!(L, i)
    else
        L[i] = v
        minheapify!(L, i)
    end
end
            
heapchangekey!(L::AbstractVector{T}, i::Int, v::T) where T = heapchangekey!(L, i, v, first(L[i]))
            
function buildminheap2!(L::AbstractVector)
    len = length(L)
    for i in 1:len
        heapdecreasekey!(L, i)
    end
end

# 可回滚heap
HistoryType = Vector{Tuple{Int64,Int64}}
abstract type AbstractRecHeap{T} <: AbstractVector{T} end
mutable struct RecHeap{T} <: AbstractRecHeap{T}
    vector::Vector{T}
    history::HistoryType
    unused::Int
end

RecHeap() = RecHeap(Vector(), HistoryType(), 0)
RecHeap(v::AbstractVector) = RecHeap(v, HistoryType(), 0)
Base.getindex(L::RecHeap, i) =  getindex(L.vector, i)
Base.setindex!(L::RecHeap, v, i) = setindex!(L.vector, v, i)
Base.length(L::RecHeap) = length(L.vector) - L.unused
Base.size(L::RecHeap) = (length(L),)

function exchange!(L::AbstractRecHeap, i::Int, j::Int) end
function heapextractmin!(L::AbstractRecHeap) end
function undo!(L::AbstractRecHeap, nsteps::Int) end
function historylen(L::AbstractRecHeap) end
"仅恢复堆的结构，节点的内容不恢复，即无法撤销heapchangekey!带来的节点key或者value的变化"
undo!(L::AbstractRecHeap; tostep::Int) = undo!(L, historylen(L) - tostep)

function minheapinsert!(L::AbstractRecHeap, v::T, his::HistoryType) where T
    error("RecHeap doesn't allow insert nodes.")
end

function exchange!(L::RecHeap, i::Int, j::Int)
    push!(L.history, (i, j))
    temp = L[i]
    L[i] = L[j]
    L[j] = temp
end

function heapextractmin!(L::RecHeap)
    head = L[1]
    exchange!(L, 1, length(L))
    L.unused += 1
    push!(L.history, (-1, -1))
    if length(L) > 0
        minheapify!(L, 1)
    end
    return head
end

historylen(L::RecHeap) = length(L.history)
function undo!(L::RecHeap, nsteps::Int)
    for i in 1:nsteps
        e = pop!(L.history)
        if e == (-1, -1)
            L.unused -= 1
        else
            exchange!(L.vector, e...)
        end
    end
end  
# 带位置追踪的heap
mutable struct tracHeap{T} <: AbstractRecHeap{T}
    heap::RecHeap{T}
    locL::AbstractVector
end

tracHeap() = tracHeap(RecHeap(), Vector())
tracHeap(v::AbstractVector) = tracHeap(RecHeap(v), [1:length(v)...])
tracHeap(v::AbstractVector, lv::AbstractVector) = tracHeap(RecHeap(v), lv)
Base.getindex(L::tracHeap, i) =  getindex(L.heap, i)
Base.setindex!(L::tracHeap, v, i) = setindex!(L.heap, v, i)
Base.length(L::tracHeap) = length(L.heap)
Base.size(L::tracHeap) = (length(L),)

function exchange!(L::tracHeap, i::Int, j::Int)
#     @assert i!=j
    exchange!(L.locL, last(L.heap[i]), last(L.heap[j]))
    exchange!(L.heap, i, j)
end

function heapextractmin!(L::tracHeap)
    head = L[1]
    exchange!(L, 1, length(L))
    L.heap.unused += 1
    push!(L.heap.history, (-1, -1))
    if length(L) > 0
        minheapify!(L, 1)
    end
    return head
end

historylen(L::tracHeap) = length(L.heap.history)

"仅恢复堆的结构，节点的内容不恢复，即无法撤销heapchangekey!带来的节点key或者value的变化"
function undo!(L::tracHeap, nsteps::Int)
    for i in 1:nsteps
        e = pop!(L.heap.history)
        if e == (-1, -1)
            L.heap.unused -= 1
        else
            exchange!(L.locL, last(L.heap[e[1]]), last(L.heap[e[2]]))
            exchange!(L.heap.vector, e...)
        end
    end
end
