using SudokuSolver
using Test

@testset "SudokuSolver.jl" begin
    s6ans = [3 7 9 8 1 6 2 5 4; 8 6 4 2 7 5 1 9 3; 5 2 1 9 4 3 6 8 7; 6 5 7 4 3 1 9 2 8; 
    4 9 8 5 6 2 7 3 1; 1 3 2 7 8 9 5 4 6; 2 1 3 6 9 4 8 7 5; 7 4 5 1 2 8 3 6 9; 9 8 6 3 5 7 4 1 2]
    @test solvesudoku(SudokuSolver.PuzzleExamples[6]) == s6ans
    @test solvesudoku(SudokuSolver.PuzzleExamples[6], solver=SudokuSolver.presortsolver) == s6ans
    @test solvesudoku(SudokuSolver.PuzzleExamples[6], solver=SudokuSolver.naivesolver) == s6ans
end
