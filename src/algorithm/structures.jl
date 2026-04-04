
mutable struct Generator
    items::Vector{Int} #giữ dạng vector (mảng đã sort) để dễ nối (join)
    support::Int  
    closure::Set{Int} #Bao đóng, sẽ tính ở Phase 4
end