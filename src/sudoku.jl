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

# 预排序
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
function presortedsolver!(grid, P::Matrix{UInt16}=zeros(UInt16, 3, 9), order=ORDER; check=true)
    possinit!(P, grid)
    valid = sudokudfs!(grid, P, order)
    return check ? (valid ? grid : nothing) : grid
end

# 优先深搜
mutable struct KVpair{KT,VT}
    key::KT
    value::VT
end
Base.first(p::KVpair) = p.key
Base.last(p::KVpair) = p.value

function countzero(mask)
    c = 0
    while mask < 1 << 9 - 1
        mask2 = mask | (mask+1)
        bm = mask2 - mask
        c += 1
        mask = mask2
    end
    c
end

function idcountzero(P, id)
    r = (id - 1) % 9 + 1
    c = (id - 1) ÷ 9 + 1 
    p = (r - 1) ÷ 3 * 3 + (c - 1) ÷ 3 + 1
    countzero(P[1, r] | P[2, c] | P[3, p])
end
function heapinit!(P)
    heap = tracHeap([KVpair(idcountzero(P, id), id) for id in 1:81])
    buildminheap!(heap)
    return heap
end
function increasehold(P, H::tracHeap, r, c) 
    id = (c - 1) * 9 + r
    p = (r - 1) ÷ 3 * 3 + (c - 1) ÷ 3 + 1
    lc = H.locL[id]
#         @assert last(H[lc])==id
    if lc <= length(H)
        oldK = first(H[lc])
        H[lc].key = countzero(P[1, r] | P[2, c] | P[3, p])
        heapchangekey!(H, lc, H[lc], oldK)
    end
end

function decreasehold(P, H::tracHeap, r, c) # for release!
    id = (c - 1) * 9 + r
    p = (r - 1) ÷ 3 * 3 + (c - 1) ÷ 3 + 1
    lc = H.locL[id]
#         @assert last(H[lc])==id
    if lc <= length(H)
#             oldK = first(H[lc])
        H[lc].key = countzero(P[1, r] | P[2, c] | P[3, p])
#             heapchangekey!(H, lc, H[lc]) #交给undo!去完成结构调整
    end
end

function hold!(P, r, c, H::tracHeap)
    for i in 1:c - 1
        increasehold(P, H, r, i)
    end
    for i in c + 1:9
        increasehold(P, H, r, i)
    end
    for i in 1:r - 1
        increasehold(P, H, i, c)
    end
    for i in r + 1:9
        increasehold(P, H, i, c)
    end
    rr = (r - 1) % 3 + 1
    rc = (c - 1) % 3 + 1
    s = ((1, 2), (-1, 1), (-2, -1))
    for i in s[rr]        
        for j in s[rc]
            increasehold(P, H, r + i, c + j)
        end
    end
end

function release!(P, r, c, H::tracHeap)
    for i in 1:c - 1
        decreasehold(P, H, r, i)
    end
    for i in c + 1:9
        decreasehold(P, H, r, i)
    end
    for i in 1:r - 1
        decreasehold(P, H, i, c)
    end
    for i in r + 1:9
        decreasehold(P, H, i, c)
    end
    rr = (r - 1) % 3 + 1
    rc = (c - 1) % 3 + 1
    s = ((1, 2), (-1, 1), (-2, -1))
    for i in s[rr]        
        for j in s[rc]
            decreasehold(P, H, r + i, c + j)
        end
    end
end
function sudokudfs!(grid::Matrix, P::Matrix{UInt16}, H::tracHeap, id=last(heapextractmin!(H)))
    r = (id - 1) % 9 + 1
    c = (id - 1) ÷ 9 + 1 
    p = (r - 1) ÷ 3 * 3 + (c - 1) ÷ 3 + 1
    if id == -1
        return true
    end
    if grid[r, c] == 0
        mask = P[1, r] | P[2, c] | P[3, p]
        while mask < 1 << 9 - 1
            mask2 = mask | (mask+1)
            bm = mask2 - mask
            P[1, r] |= bm
            P[2, c] |= bm
            P[3, p] |= bm
            snapshot1 = historylen(H)
            hold!(P, r, c, H)
            snapshot2 = historylen(H)
            id2 = length(H) > 0 ? last(heapextractmin!(H)) : -1
            if sudokudfs!(grid, P, H, id2)
                grid[r, c] = intlog2(bm) + 1
                return true
            end
            P[1, r] &= ~bm
            P[2, c] &= ~bm
            P[3, p] &= ~bm
            undo!(H, tostep=snapshot2)
            release!(P, r, c, H)
            undo!(H, tostep=snapshot1)
            mask = mask2
        end
        return false
    else
        id2 = length(H) > 0 ? last(heapextractmin!(H)) : -1
        return sudokudfs!(grid, P, H, id2)
    end
end
function prioritysolver!(grid, P::Matrix{UInt16}=zeros(UInt16, 3, 9); check=true)
    possinit!(P, grid)
    H = heapinit!(P)
    valid = sudokudfs!(grid, P, H)
    return check ? (valid ? grid : nothing) : grid
end
function solvesudoku(sudoku::Matrix{<:Integer}, args...; solver=prioritysolver!, kargs...)
    solver(sudoku, args...; kargs...)
end
solvesudoku(sudoku::AbstractString, args...; kargs...) = solvesudoku(loadpuzzle(sudoku), args...; kargs...)