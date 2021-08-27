function loadpuzzle(s::String)
    s = replace(s, r"\s" => "")
    s = map(c -> c in "-._" ? 0 : parse(Int, c), s |> collect)
    reshape(s, 9, 9) |> permutedims
end
loadpuzzle(mat::Matrix{<:Integer}) = copy(mat)
function possinit!(P::Matrix{UInt16}, grid::Matrix)
    P .= 0
    for r in 1:9
        for c in 1:9
            p = (r - 1) ÷ 3 * 3 + (c - 1) ÷ 3 + 1
            v = grid[r, c]
            @assert 0 <= v <= 9
            if v > 0
                bm = 1 << (v-1)
                P[1, r] |= bm
                P[2, c] |= bm
                P[3, p] |= bm
            end
        end
    end
end
function intlog2(v)
    if v == 1 << 4
        return 4
    elseif v < 1 << 4
        if v == 1 << 2
            return 2
        elseif v > 1 << 2
            return 3
        else
            return v - 1
        end
    else
        if v == 1 << 7
            return 7
        elseif v > 1 << 7
            return 8
        elseif v < 1 << 6
            return 5
        else
            return 6            
        end
    end
end
# 朴素深搜（顺序搜索，逐列）
function sudokudfs!(grid::Matrix, P::Matrix{UInt16}=zeros(UInt16, 3, 9), id=1)
    if id == 82
        return true
    end
    r = (id - 1) % 9 + 1
    c = (id - 1) ÷ 9 + 1
    p = (r - 1) ÷ 3 * 3 + (c - 1) ÷ 3 + 1
    if grid[r, c] == 0
        mask = P[1, r] | P[2, c] | P[3, p]
        while mask < 1 << 9 - 1
            mask2 = mask | (mask+1)
            bm = mask2 - mask
            P[1, r] |= bm
            P[2, c] |= bm
            P[3, p] |= bm
            if sudokudfs!(grid, P, id + 1)
                grid[r, c] = intlog2(bm) + 1
                return true
            end
            P[1, r] &= ~bm
            P[2, c] &= ~bm
            P[3, p] &= ~bm
            mask = mask2
        end
        return false
    else
        return sudokudfs!(grid, P, id + 1)
    end
end
function naivesolver!(grid, P::Matrix{UInt16}=zeros(UInt16, 3, 9); check=true)
    possinit!(P, grid)
    valid = sudokudfs!(grid, P)
    return check ? (valid ? grid : nothing) : grid
end

# 重排搜索顺序
function sudokudfs!(grid::Matrix{<:Integer}, P::Matrix{UInt16}, order::Vector, id=1)
    if id == 82
        return true
    end
    id2 = order[id]
    r = (id2 - 1) % 9 + 1
    c = (id2 - 1) ÷ 9 + 1
    p = (r - 1) ÷ 3 * 3 + (c - 1) ÷ 3 + 1
    if grid[r, c] == 0
        mask = P[1, r] | P[2, c] | P[3, p]
        while mask < 1 << 9 - 1
            mask2 = mask | (mask+1)
            bm = mask2 - mask
            P[1, r] |= bm
            P[2, c] |= bm
            P[3, p] |= bm
            if sudokudfs!(grid, P, id + 1)
                grid[r, c] = intlog2(bm) + 1
                return true
            end
            P[1, r] &= ~bm
            P[2, c] &= ~bm
            P[3, p] &= ~bm
            mask = mask2
        end
        return false
    else
        return sudokudfs!(grid, P, id + 1)
    end
    
end
function presort()
    ids = [[1:9...], [9:-1:1...],[1:9...], [9:-1:1...],
    [1:9...], [9:-1:1...],[1:9...], [9:-1:1...],[1:9...]]# 一条龙序
    ids = vcat(broadcast((a, b) -> a .+ b, ids, 0:9:72)...)
end
const ORDER = presort()
function reordersolver!(grid, P::Matrix{UInt16}=zeros(UInt16, 3, 9), order=ORDER; check=true)
    possinit!(P, grid)
    valid = sudokudfs!(grid, P, order)
    return check ? (valid ? grid : nothing) : grid
end

# 优先深搜
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
function sudokudfs!(P::AbstractArray{T,3}, H::tracHeap, id=last(heapextractmin!(H))) where T
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
            if sudokudfs!(P, H, id)
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
function prioritysolver!(b, P::AbstractArray{T,3}=zeros(Int, 9, 9, 9); check=true) where T
    possinit!(P, b)
    H = heapinit!(P)
    valid = sudokudfs!(P, H)
    ans = reshape(mapslices(argmin, P, dims=3), 9, 9)
    return check ? (valid ? ans : nothing) : ans
end
function solvesudoku!(sudoku::Matrix{<:Integer}, args...; solver=naivesolver!, kargs...)
    solver(sudoku, args...; kargs...)
end
solvesudoku(sudoku, args...; kargs...) = solvesudoku!(loadpuzzle(sudoku), args...; kargs...)