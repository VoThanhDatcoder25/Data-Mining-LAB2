
mutable struct Generator
    items::Vector{Int} #giữ dạng vector (mảng đã sort) để dễ nối (join)
    support::Int  
    closure::Union{Set{Int}, Nothing} #Bao đóng, sẽ tính ở Phase 4
end