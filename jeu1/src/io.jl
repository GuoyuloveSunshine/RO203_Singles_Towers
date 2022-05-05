# This file contains functions related to reading, writing and displaying a grid and experimental results

using JuMP
using Plots
import GR

"""
Read an instance from an input file

- Argument:
inputFile: path of the input file
"""
function readInputFile(inputFile::String)

    # Open the input file
    datafile = open(inputFile)

    data = readlines(datafile)
    close(datafile)
    n = size(data,1)
    output = Array{Int64}(undef, 0, n)
    row = Array{Int64}(undef, 0)
    # For each line of the input file
    i = Int64(1)
    for line in data
        
        ligne = split(line, ",")
        for n in ligne
            append!(row,parse(Int64,n))
        end
        output = vcat(output, row')
        row = Array{Int64}(undef, 0)
    end
    return n, output

end

"""
find the index of all same number in a line or a column
"""
function findSameNumber(lc::Vector{Int64}, n::Int64)
    index = Array{Int64}(undef, 0)
    for i in 1:size(lc,1)
        if lc[i] == n
            append!(index, i)
        end
    end
    if size(index,1) == 0
        append!(index,1)
    end
    return index
end

"""
verifier si le graphe (x) est connexe ou pas
"""
function isConnected(x_m, n::Int64)
    visited = CartesianIndex{2}[]
    visiting = CartesianIndex{2}[]
    pivot = findfirst(isequal(1), x_m)
    push!(visiting, pivot)
    while !isempty(visiting)
        pivot = pop!(visiting)
        if pivot[2]>=2
            if x_m[pivot[1], pivot[2]-1] == 1 && isempty(findall(isequal(CartesianIndex(pivot[1], pivot[2]-1)), visited)) && isempty(findall(isequal(CartesianIndex(pivot[1], pivot[2]-1)), visiting))
                push!(visiting, CartesianIndex(pivot[1], pivot[2]-1))
            end
        end
        if pivot[2]<=n-1
            if x_m[pivot[1], pivot[2]+1] == 1 && isempty(findall(isequal(CartesianIndex(pivot[1], pivot[2]+1)), visited)) && isempty(findall(isequal(CartesianIndex(pivot[1], pivot[2]+1)), visiting))
                push!(visiting, CartesianIndex(pivot[1], pivot[2]+1))
            end
        end
        if pivot[1]>=2
            if x_m[pivot[1]-1, pivot[2]] == 1 && isempty(findall(isequal(CartesianIndex(pivot[1]-1, pivot[2])), visited)) && isempty(findall(isequal(CartesianIndex(pivot[1]-1, pivot[2])), visiting))
                push!(visiting, CartesianIndex(pivot[1]-1, pivot[2]))
            end
        end
        if pivot[1]<=n-1
            if x_m[pivot[1]+1, pivot[2]] == 1 && isempty(findall(isequal(CartesianIndex(pivot[1]+1, pivot[2])), visited)) && isempty(findall(isequal(CartesianIndex(pivot[1]+1, pivot[2])), visiting))
                push!(visiting, CartesianIndex(pivot[1]+1, pivot[2]))
            end
        end
        push!(visited, pivot)
    end
    return count_white(x_m, n) == size(visited, 1)
end

"""
trouver des cases blanches
"""
function count_white(x_m, n::Int64)
    count = 0
    for i in 1:n
        for j in 1:n
            if x_m[i,j] == 1
                count = count + 1
            end
        end
    end
    return count
end

"""
transformer une matrice float en int
"""
function round_matrix(x::Matrix{Float64})
    x_n = Array{Int64,2}(undef, size(x,1), size(x,2))
    for i in 1:size(x,1)
        for j in 1:size(x,2)
            x_n[i,j] = round(x[i,j])
        end
    end
    return x_n
end

"""
verifier s'il y a deux cases voisines autour de la position (i,j)
"""
function isAjacent(x_m, i::Int64, j::Int64)
    n = size(x_m, 2)
    flag = 0
    if i>=2
        if x_m[i-1,j] == 0
            flag = 1
            return true
        end
    end
    if i<=n-1
        if x_m[i+1,j] == 0
            flag = 1
            return true
        end
    end
    if j>=2
        if x_m[i,j-1] == 0
            flag = 1
            return true
        end
    end
    if j<=n-1
        if x_m[i,j+1] == 0
            flag = 1
            return true
        end
    end
    if flag==0
        return false
    end
end

function isSame(p::Matrix{Int64}, i::Int64, j::Int64, number::Int64)
    n = size(p, 2)
    flag = 0
    for line in 1:n
        if p[line,j] == number && line != i
            flag = 1
            return true
        end
    end
    for col in 1:n
        if p[i,col] == number && col != j
            flag = 1
            return true
        end
    end
    if flag==0
        return false
    end
end

"""
remplacer la solution generee avec des chiffres
Argument:
- p : matrice du problem
- number : liste des chiffres
- (i, j) : postion
"""

function choose4one(p::Matrix{Int64}, numbers::Vector{Int64}, i::Int64, j::Int64)
    dup = copy(numbers)
    for line in 1:size(p, 1)
        filter!(!isequal(p[line, j]), dup)
    end
    for col in 1:size(p, 2)
        filter!(!isequal(p[i, col]), dup)
    end
    if (isempty(dup))
        return false
    else
        p[i, j] = rand(dup)
        return true
    end
    
end

function choose4zero(p::Matrix{Int64}, x::Matrix{Float64}, i::Int64, j::Int64)
    line_or_col = rand((1,2))
    if line_or_col == 1
        line = copy(p[i, findall(!isequal(0), x[i, :])])
        p[i, j] = rand(line)
    else
        col = copy(p[findall(!isequal(0), x[:, j]), j])
        p[i, j] = rand(col)
    end
end

"""
Argument
- puzzle : nom du fichier du problem ex. "input1.txt"
"""
function displayPuzzle(puzzle::String)
    _, p = readInputFile("../data/"*puzzle)
    for i in 1:size(p,1)
        for j in 1:size(p,2)-1
            print(p[i, j], " ")
        end
        println(p[i, size(p,2)])
    end
end

"""
Argument
- sol : nom du fichier de la solution ex. "cplex/input1.txt"
"""
function displaySolution(sol::String)
    resultFolder = "../res/"
    include(resultFolder*sol)
    if isOptimal
        for i in 1:size(solution,1)
            for j in 1:size(solution,2)-1
                if solution[i, j] == 0
                    print("- ")
                else
                    print(solution[i, j], " ")
                end
            end
            if solution[i, size(solution,2)] == 0
                println("- ")
            else
                println(solution[i, size(solution,2)])
            end
        end
    end
    
end



"""
Create a pdf file which contains a performance diagram associated to the results of the ../res folder
Display one curve for each subfolder of the ../res folder.

Arguments
- outputFile: path of the output file

Prerequisites:
- Each subfolder must contain text files
- Each text file correspond to the resolution of one instance
- Each text file contains a variable "solveTime" and a variable "isOptimal"
"""
function performanceDiagram(outputFile::String = "../res/jeu1.png")

    resultFolder = "../res/"
    
    # Maximal number of files in a subfolder
    maxSize = 0

    # Number of subfolders
    subfolderCount = 0

    folderName = Array{String, 1}()

    # For each file in the result folder
    for file in readdir(resultFolder)

        path = resultFolder * file
        
        # If it is a subfolder
        if isdir(path)
            
            folderName = vcat(folderName, file)
             
            subfolderCount += 1
            folderSize = size(readdir(path), 1)

            if maxSize < folderSize
                maxSize = folderSize
            end
        end
    end

    # Array that will contain the resolution times (one line for each subfolder)
    results = Array{Float64}(undef, subfolderCount, maxSize)

    for i in 1:subfolderCount
        for j in 1:maxSize
            results[i, j] = Inf
        end
    end

    folderCount = 0
    maxSolveTime = 0

    # For each subfolder
    for file in readdir(resultFolder)
            
        path = resultFolder * file
        
        if isdir(path)

            folderCount += 1
            fileCount = 0

            # For each text file in the subfolder
            for resultFile in filter(x->occursin(".txt", x), readdir(path))

                fileCount += 1
                include(path * "/" * resultFile)

                if isOptimal
                    results[folderCount, fileCount] = solveTime

                    if solveTime > maxSolveTime
                        maxSolveTime = solveTime
                    end 
                end 
            end 
        end
    end 

    # Sort each row increasingly
    results = sort(results, dims=2)

    println("Max solve time: ", maxSolveTime)

    # For each line to plot
    for dim in 1: size(results, 1)

        x = Array{Float64, 1}()
        y = Array{Float64, 1}()

        # x coordinate of the previous inflexion point
        previousX = 0
        previousY = 0

        append!(x, previousX)
        append!(y, previousY)
            
        # Current position in the line
        currentId = 1

        # While the end of the line is not reached 
        while currentId != size(results, 2) && results[dim, currentId] != Inf

            # Number of elements which have the value previousX
            identicalValues = 1

             # While the value is the same
            while results[dim, currentId] == previousX && currentId <= size(results, 2)
                currentId += 1
                identicalValues += 1
            end

            # Add the proper points
            append!(x, previousX)
            append!(y, currentId - 1)

            if results[dim, currentId] != Inf
                append!(x, results[dim, currentId])
                append!(y, currentId - 1)
            end
            
            previousX = results[dim, currentId]
            previousY = currentId - 1
            
        end

        append!(x, maxSolveTime)
        append!(y, currentId - 1)

        # If it is the first subfolder
        if dim == 1

            # Draw a new plot
            
            savefig(plot(x, y, label = folderName[dim], legend = :bottomright, xaxis = "Time (s)", yaxis = "Solved instances",linewidth=3), outputFile)

        # Otherwise 
        else
            # Add the new curve to the created plot
            savefig(plot!(x, y, label = folderName[dim], linewidth=3), outputFile)
        end 
    end
end 

"""
Create a latex file which contains an array with the results of the ../res folder.
Each subfolder of the ../res folder contains the results of a resolution method.

Arguments
- outputFile: path of the output file

Prerequisites:
- Each subfolder must contain text files
- Each text file correspond to the resolution of one instance
- Each text file contains a variable "solveTime" and a variable "isOptimal"
"""
function resultsArray(outputFile::String = "../res/array_jeu1.tex")
    
    resultFolder = "../res/"
    dataFolder = "../data/"
    
    # Maximal number of files in a subfolder
    maxSize = 0

    # Number of subfolders
    subfolderCount = 0

    # Open the latex output file
    fout = open(outputFile, "w")

    # Print the latex file output
    println(fout, raw"""\documentclass{article}

    \usepackage[french]{babel}
    \usepackage [utf8] {inputenc} % utf-8 / latin1 
    \usepackage{multicol}

    \setlength{\hoffset}{-18pt}
    \setlength{\oddsidemargin}{0pt} % Marge gauche sur pages impaires
    \setlength{\evensidemargin}{9pt} % Marge gauche sur pages paires
    \setlength{\marginparwidth}{54pt} % Largeur de note dans la marge
    \setlength{\textwidth}{481pt} % Largeur de la zone de texte (17cm)
    \setlength{\voffset}{-18pt} % Bon pour DOS
    \setlength{\marginparsep}{7pt} % Séparation de la marge
    \setlength{\topmargin}{0pt} % Pas de marge en haut
    \setlength{\headheight}{13pt} % Haut de page
    \setlength{\headsep}{10pt} % Entre le haut de page et le texte
    \setlength{\footskip}{27pt} % Bas de page + séparation
    \setlength{\textheight}{668pt} % Hauteur de la zone de texte (25cm)

    \begin{document}""")

    header = raw"""
    \begin{center}
    \renewcommand{\arraystretch}{1.4} 
    \begin{tabular}{l"""

    # Name of the subfolder of the result folder (i.e, the resolution methods used)
    folderName = Array{String, 1}()

    # List of all the instances solved by at least one resolution method
    solvedInstances = Array{String, 1}()

    # For each file in the result folder
    for file in readdir(resultFolder)

        path = resultFolder * file
        
        # If it is a subfolder
        if isdir(path)

            # Add its name to the folder list
            folderName = vcat(folderName, file)
             
            subfolderCount += 1
            folderSize = size(readdir(path), 1)

            # Add all its files in the solvedInstances array
            for file2 in filter(x->occursin(".txt", x), readdir(path))
                solvedInstances = vcat(solvedInstances, file2)
            end 

            if maxSize < folderSize
                maxSize = folderSize
            end
        end
    end

    # Only keep one string for each instance solved
    unique(solvedInstances)

    # For each resolution method, add two columns in the array
    for folder in folderName
        header *= "rr"
    end

    header *= "}\n\t\\hline\n"

    # Create the header line which contains the methods name
    for folder in folderName
        header *= " & \\multicolumn{2}{c}{\\textbf{" * folder * "}}"
    end

    header *= "\\\\\n\\textbf{Instance} "

    # Create the second header line with the content of the result columns
    for folder in folderName
        header *= " & \\textbf{Temps (s)} & \\textbf{Optimal ?} "
    end

    header *= "\\\\\\hline\n"

    footer = raw"""\hline\end{tabular}
    \end{center}

    """
    println(fout, header)

    # On each page an array will contain at most maxInstancePerPage lines with results
    maxInstancePerPage = 30
    id = 1

    # For each solved files
    for solvedInstance in solvedInstances

        # If we do not start a new array on a new page
        if rem(id, maxInstancePerPage) == 0
            println(fout, footer, "\\newpage")
            println(fout, header)
        end 

        # Replace the potential underscores '_' in file names
        print(fout, replace(solvedInstance, "_" => "\\_"))

        # For each resolution method
        for method in folderName

            path = resultFolder * method * "/" * solvedInstance

            # If the instance has been solved by this method
            if isfile(path)

                include(path)

                println(fout, " & ", round(solveTime, digits=2), " & ")

                if isOptimal
                    println(fout, "\$\\times\$")
                end 
                
            # If the instance has not been solved by this method
            else
                println(fout, " & - & - ")
            end
        end

        println(fout, "\\\\")

        id += 1
    end

    # Print the end of the latex file
    println(fout, footer)

    println(fout, "\\end{document}")

    close(fout)
    
end 
