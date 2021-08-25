function loadpuzzle(s::String)
    s = replace(s, r"\s" => "")
    s = map(c -> c in "-._" ? 0 : parse(Int, c), s |> collect)
    reshape(s, 9, 9) |> permutedims
end
loadpuzzle(mat::Matrix{<:Integer}) = mat
# function traversalrela(f, r::Int, c::Int)
#     for i in 1:c-1
#         f(r, i)
#     end
#     for i in c+1:9
#         f(r, i)
#     end
#     for i in 1:r-1
#         f(i, c)
#     end
#     for i in r+1:9
#         f(i, c)
#     end
#     rr = (r-1) % 3 + 1
#     rc = (c-1) % 3 + 1
#     s = ((1, 2), (-1, 1), (-2, -1))
#     for i in s[rr]        
#         for j in s[rc]
#             f(r+i, c+j)
#         end
#     end
# end
# function hold!(P::AbstractArray{T, 3}, r, c, v) where T
#     traversalrela(r, c) do i, j
#         P[i, j, v] += 1
#     end
# end
# function release!(P::AbstractArray{T, 3}, r, c, v) where T
#     traversalrela(r, c) do i, j
#         P[i, j, v] -= 1
#     end
# end

function possinit!(P::AbstractArray{T,3}, b::AbstractArray{W,2}) where {T,W}
    P .= 0
    for r in 1:9
        for c in 1:9
            if b[r, c] > 0
                hold!(P, r, c, b[r, c])
                P[r, c, :] .+= 1
                P[r, c, b[r, c]] -= 1
            end
        end
    end
end
function hold!(P::AbstractArray{T,3}, r, c, v) where T
    for i in 1:c - 1
        P[r, i, v] += 1
    end
    for i in c + 1:9
        P[r, i, v] += 1
    end
    for i in 1:r - 1
        P[i, c, v] += 1
    end
    for i in r + 1:9
        P[i, c, v] += 1
    end
    rr = (r - 1) % 3 + 1
    rc = (c - 1) % 3 + 1
    s = ((1, 2), (-1, 1), (-2, -1))
    for i in s[rr]        
        for j in s[rc]
            P[r + i, c + j, v] += 1
        end
    end
end

function release!(P::AbstractArray{T,3}, r, c, v) where T
    for i in 1:c - 1
        P[r, i, v] -= 1
    end
    for i in c + 1:9
        P[r, i, v] -= 1
    end
    for i in 1:r - 1
        P[i, c, v] -= 1
    end
    for i in r + 1:9
        P[i, c, v] -= 1
    end
    rr = (r - 1) % 3 + 1
    rc = (c - 1) % 3 + 1
    s = ((1, 2), (-1, 1), (-2, -1))
    for i in s[rr]        
        for j in s[rc]
            P[r + i, c + j, v] -= 1
        end
    end
end

# 朴素深搜（顺序搜索，逐列）
function sudokudfs(P::AbstractArray{T,3}, id=1) where T
    r = (id - 1) % 9 + 1
    c = (id - 1) ÷ 9 + 1
    if id == 81
        for v in 1:9
            if P[r, c, v] == 0
                return true
            end
        end
        return false
    end
    
    for v in 1:9
        if P[r, c, v] == 0
#             @show v
            hold!(P, r, c, v)
            if sudokudfs(P, id + 1)
                return true
            end
            release!(P, r, c, v)
        end
    end
    return false
end
function naivesolver(b, P::AbstractArray{T,3}=zeros(Int, 9, 9, 9); check=true) where T
    possinit!(P, b)
    valid = sudokudfs(P)
    ans = reshape(mapslices(argmin, P, dims=3), 9, 9)
    return check ? (valid ? ans : nothing) : ans
end

# 预先排序（一条龙）
function presort(P) 
    ids = [[1:9...], [9:-1:1...],[1:9...], [9:-1:1...],
    [1:9...], [9:-1:1...],[1:9...], [9:-1:1...],[1:9...]]# 一条龙序
    ids = vcat(broadcast((a, b) -> a .+ b, ids, 0:9:72)...)
end

function sudokudfs(P::AbstractArray{T,3}, idmap::AbstractVector, id=1) where T
    r = (idmap[id] - 1) % 9 + 1
    c = (idmap[id] - 1) ÷ 9 + 1
    if id == 81
        for v in 1:9
            if P[r, c, v] == 0
                return true
            end
        end
        return false
    end
    
    for v in 1:9
        if P[r, c, v] == 0
            hold!(P, r, c, v)
            if sudokudfs(P, idmap, id + 1)
                return true
            end
            release!(P, r, c, v)
        end
    end
    return false
end
    
function presortsolver(b, P::AbstractArray{T,3}=zeros(Int, 9, 9, 9); check=true) where T
    possinit!(P, b)
    ids = presort(P)
    valid = sudokudfs(P, ids)
    ans = reshape(mapslices(argmin, P, dims=3), 9, 9)
    return check ? (valid ? ans : nothing) : ans
end

# 优先深搜
mutable struct KVpair{KT,VT}
    key::KT
    value::VT
end
Base.first(p::KVpair) = p.key
Base.last(p::KVpair) = p.value

function heapinit!(P::AbstractArray{T,3}) where T
    pocount = sum(P .== 0, dims=3)[:]
    heap = tracHeap([KVpair(v, id) for (id, v) in enumerate(pocount)])
    buildminheap!(heap)
    return heap
end
function increasehold(P::AbstractArray{T,3}, H::tracHeap, r, c, v) where T
    if P[r, c, v] == 0
        id = (c - 1) * 9 + r
        lc = H.locL[id]
#         @assert last(H[lc])==id
        if lc <= length(H)
            oldK = first(H[lc])
            H[lc].key -= 1 
            heapchangekey!(H, lc, H[lc], oldK)
        end
        
    end
P[r, c, v] += 1
end

function decreasehold(P::AbstractArray{T,3}, H::tracHeap, r, c, v) where T # for release!
    if P[r, c, v] == 1
        id = (c - 1) * 9 + r
        lc = H.locL[id]
#         @assert last(H[lc])==id
        if lc <= length(H)
#             oldK = first(H[lc])
            H[lc].key += 1 
#             heapchangekey!(H, lc, H[lc]) #交给undo!去完成结构调整
        end
    end
P[r, c, v] -= 1
end

function hold!(P::AbstractArray{T,3}, r, c, v, H::tracHeap) where T
    for i in 1:c - 1
        increasehold(P, H, r, i, v)
    end
    for i in c + 1:9
        increasehold(P, H, r, i, v)
    end
    for i in 1:r - 1
        increasehold(P, H, i, c, v)
    end
    for i in r + 1:9
        increasehold(P, H, i, c, v)
    end
    rr = (r - 1) % 3 + 1
    rc = (c - 1) % 3 + 1
    s = ((1, 2), (-1, 1), (-2, -1))
    for i in s[rr]        
        for j in s[rc]
            increasehold(P, H, r + i, c + j, v)
        end
    end
end

function release!(P::AbstractArray{T,3}, r, c, v, H::tracHeap) where T
    for i in 1:c - 1
        decreasehold(P, H, r, i, v)
    end
    for i in c + 1:9
        decreasehold(P, H, r, i, v)
    end
    for i in 1:r - 1
        decreasehold(P, H, i, c, v)
    end
    for i in r + 1:9
        decreasehold(P, H, i, c, v)
    end
    rr = (r - 1) % 3 + 1
    rc = (c - 1) % 3 + 1
    s = ((1, 2), (-1, 1), (-2, -1))
    for i in s[rr]        
        for j in s[rc]
            decreasehold(P, H, r + i, c + j, v)
        end
    end
end
function sudokudfs(P::AbstractArray{T,3}, H::tracHeap, id=last(heapextractmin!(H))) where T
    r = (id - 1) % 9 + 1
    c = (id - 1) ÷ 9 + 1 
    if length(H) == 0
        for v in 1:9
            if P[r, c, v] == 0
                return true
            end
        end
        return false
    end
    for v in 1:9
        if P[r, c, v] == 0
            snapshot1 = historylen(H)
            hold!(P, r, c, v, H)
            snapshot2 = historylen(H)
            id = last(heapextractmin!(H))
            if sudokudfs(P, H, id)
#                 @show id
                return true
            end
            undo!(H, tostep=snapshot2)
            release!(P, r, c, v, H)
            undo!(H, tostep=snapshot1)
        end
    end
    return false
end
function prioritysolver(b, P::AbstractArray{T,3}=zeros(Int, 9, 9, 9); check=true) where T
    possinit!(P, b)
    H = heapinit!(P)
    valid = sudokudfs(P, H)
    ans = reshape(mapslices(argmin, P, dims=3), 9, 9)
    return check ? (valid ? ans : nothing) : ans
end
function solvesudoku(sudoku::Matrix{<:Integer}, args...; solver=prioritysolver, kargs...)
    solver(sudoku, args...; kargs...)
end
solvesudoku(sudoku::AbstractString, args...; kargs...) = solvesudoku(loadpuzzle(sudoku), args...; kargs...)