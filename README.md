# SudokuSolver
[![CI](https://github.com/guo-yong-zhi/SudokuSolver.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/guo-yong-zhi/SudokuSolver.jl/actions/workflows/ci.yml) [![CI-nightly](https://github.com/guo-yong-zhi/SudokuSolver.jl/actions/workflows/ci-nightly.yml/badge.svg)](https://github.com/guo-yong-zhi/SudokuSolver.jl/actions/workflows/ci-nightly.yml) [![codecov](https://codecov.io/gh/guo-yong-zhi/SudokuSolver.jl/branch/main/graph/badge.svg?token=43TOrL25V7)](https://codecov.io/gh/guo-yong-zhi/SudokuSolver.jl)  
This is a simple and pure sudoku puzzle solver with no other dependencies except the julia standard libraries. The package exports only one function, `solvesudoku`.
## Usage
The `solvesudoku` function takes a 9×9 integer matrix or a string as input. In the integer matrix, blank is represented by the number `0`. In the string, blank is represented by the character '`0`', '`-`', '`.`' or '`_`'. And invisible characters in the string, such as '\n', are ignored. Some sample puzzles can be found in `SudokuSolver.PuzzleExamples`. The function return the solved Sudoku puzzle as a 9×9 integer matrix.
```julia
using SudokuSolver
```
```julia
print(SudokuSolver.PuzzleExamples[9])
solvesudoku(SudokuSolver.PuzzleExamples[9])

[6 0 8 0 5 0 0 0 1; 
5 0 4 9 3 0 0 0 6; 
0 0 0 0 0 6 9 7 5; 
7 4 9 8 2 0 0 0 3; 
3 8 2 0 0 0 0 0 9; 
0 0 5 0 9 0 0 0 0; 
0 5 0 0 6 8 0 0 4; 
8 3 0 0 0 0 0 5 7; 
0 0 0 0 0 0 6 0 0]

9×9 Matrix{Int64}:
 6  9  8  7  5  2  4  3  1
 5  7  4  9  3  1  8  2  6
 2  1  3  4  8  6  9  7  5
 7  4  9  8  2  5  1  6  3
 3  8  2  6  1  7  5  4  9
 1  6  5  3  9  4  7  8  2
 9  5  7  2  6  8  3  1  4
 8  3  6  1  4  9  2  5  7
 4  2  1  5  7  3  6  9  8
```
```julia
print(SudokuSolver.PuzzleExamples[3])
solvesudoku(SudokuSolver.PuzzleExamples[3])

--53-----
8------2-
-7--1-5--
4----53--
-1--7---6
--32---8-
-6-5----9
--4----3-
-----97--

9×9 Matrix{Int64}:
 1  4  5  3  2  7  6  9  8
 8  3  9  6  5  4  1  2  7
 6  7  2  9  1  8  5  4  3
 4  9  6  1  8  5  3  7  2
 2  1  8  4  7  3  9  5  6
 7  5  3  2  9  6  4  8  1
 3  6  7  5  4  2  8  1  9
 9  8  4  7  6  1  2  3  5
 5  2  1  8  3  9  7  6  4
```
```julia
print(SudokuSolver.PuzzleExamples[4])
solvesudoku(SudokuSolver.PuzzleExamples[4])

98.7..6..7......8...6.5....4....3..2..794..6.......4...1......3..95...7.....2.1..

9×9 Matrix{Int64}:
 9  8  5  7  3  2  6  4  1
 7  3  2  1  6  4  9  8  5
 1  4  6  8  5  9  2  3  7
 4  9  1  6  8  3  7  5  2
 2  5  7  9  4  1  3  6  8
 8  6  3  2  7  5  4  1  9
 6  1  8  4  9  7  5  2  3
 3  2  9  5  1  6  8  7  4
 5  7  4  3  2  8  1  9  6
```
## Benchmark
A mini benchmark compared with package [Sudoku.jl](https://github.com/scheinerman/Sudoku.jl).
```julia
using BenchmarkTools
using SudokuSolver
using Sudoku

# Sudoku.jl
@btime begin
    sudoku(Sudoku.puzz1)
    sudoku(Sudoku.puzz2)
    sudoku(Sudoku.puzz3)
end
38.838 ms (93863 allocations: 8.48 MiB)
# our SudokuSolver.jl
@btime begin
    solvesudoku(Sudoku.puzz1)
    solvesudoku(Sudoku.puzz2)
    solvesudoku(Sudoku.puzz3)
end
2.252 ms (3191 allocations: 241.77 KiB)

# Sudoku.jl
@btime for puzzle in SudokuSolver.PuzzleExamples
    p = SudokuSolver.loadpuzzle(puzzle)
    sudoku(p)
end
5.406 s (313552 allocations: 28.31 MiB)
# our SudokuSolver.jl
@btime for puzzle in SudokuSolver.PuzzleExamples
    p = SudokuSolver.loadpuzzle(puzzle)
    solvesudoku(p)
end
245.776 ms (10722 allocations: 769.72 KiB)
```