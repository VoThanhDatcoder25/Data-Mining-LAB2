
# Meaning: Functions for reading transaction data and performing common operations needed in frequent itemset mining algorithms.
function read_spmf(filepath::String)
    transactions = Vector{Set{Int}}()
    for line in eachline(filepath)
        items = parse.(Int, filter(!isempty, split(line, " ")))
        push!(transactions, Set(items))
    end
    return transactions
end