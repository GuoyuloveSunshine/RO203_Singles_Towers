include("resolution.jl")
include("io.jl")
# t,Vl,Vr,Vu,Vd = readInputFile("../data/instance_t5_normal_1.txt")
t,Vl,Vr,Vu,Vd = readInputFile("../data/instance_t5_hard_1.txt")
displayGrid(t,Vl,Vr,Vu,Vd)
resolutionTime = -1
isOptimal = false
x, isOptimal, resolutionTime = cplexSolve(t, Vl, Vr, Vu, Vd)
# println(x)
if isOptimal
    # x = Array{Int64}(x)
    # displayGrid(x,Vl,Vr,Vu,Vd)
    displaySolution(x,Vl,Vr,Vu,Vd)
    fout = open("222.txt","w")
    writeSolution(fout, x)
    close(fout)
end


