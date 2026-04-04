# Nạp các file vào môi trường
include("structures.jl")
include("utils.jl")
include("algorithm.jl")

function run_test()
    # Dùng @__DIR__ để ghim cứng đường dẫn tuyệt đối tới thư mục chứa main.jl
    filepath = joinpath(@__DIR__, "data.txt") 
    minsup_ratio = 0.4 
    
    println("Đang chạy A-Close trên file: $filepath \nvới minsup = $minsup_ratio")
    
    # Chạy hàm main
    results = a_close_main(filepath, minsup_ratio)
    
    # In kết quả
    println("\n=== KẾT QUẢ: CÁC TẬP ĐÓNG PHỔ BIẾN (FREQUENT CLOSED ITEMSETS) ===")
    for (closure, support) in results
        # Sắp xếp lại Set thành Mảng để in ra cho dễ nhìn
        sorted_closure = sort(collect(closure))
        println("Itemset: $sorted_closure \t Support: $support")
    end
end

# Chuẩn code Julia: Chỉ chạy run_test() khi file này được thực thi trực tiếp
# Giúp dứt điểm lỗi World Age trên Julia 1.12
if abspath(PROGRAM_FILE) == @__FILE__
    run_test()
end