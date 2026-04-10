using Test

# Import các file từ thư mục src
include("../src/algorithm/structures.jl")
include("../src/algorithm/utils.jl")
include("../src/algorithm/algorithm.jl")

# Hàm phụ trợ: Đọc file output của SPMF thành Dictionary để dễ so sánh
function read_spmf_output(filepath::String)
    spmf_results = Dict{Set{Int}, Int}()
    for line in eachline(filepath)
        if isempty(strip(line)) continue end
        
        # Format chuẩn SPMF: "1 2 3 #SUP: 4"
        parts = split(line, "#SUP:")
        items_str = strip(parts[1])
        support_str = strip(parts[2])
        
        # Chuyển chuỗi item thành Set (xử lý cả trường hợp tập rỗng nếu có)
        items = isempty(items_str) ? Set{Int}() : Set(parse.(Int, split(items_str, " ")))
        support = parse(Int, support_str)
        
        spmf_results[items] = support
    end
    return spmf_results
end

function run_all_tests()
    println("=== BẮT ĐẦU CHẠY UNIT TESTS (LEVEL 2) ===")
    
    # Danh sách các bài test: (Đường_dẫn_input, Đường_dẫn_spmf, Ngưỡng_minsup_ratio)
    test_cases = [
        ("../data/toy/toy_1_paper.txt",       "../data/toy/spmf_toy_1.txt", 0.4),
        ("../data/toy/toy_2_single_path.txt", "../data/toy/spmf_toy_2.txt", 0.5),
        ("../data/toy/toy_3_disjoint.txt",    "../data/toy/spmf_toy_3.txt", 0.5),
        ("../data/toy/toy_4_sparse.txt",      "../data/toy/spmf_toy_4.txt", 0.25),
        ("../data/toy/toy_5_mixed.txt",       "../data/toy/spmf_toy_5.txt", 0.4)
    ]
    
    # Sử dụng @testset của Julia để gom nhóm các bài test
    @testset "So sánh kết quả A-Close với SPMF trên 5 Toy Datasets" begin
        for (i, case) in enumerate(test_cases)
            input_file, spmf_file, minsup = case
            
            # Ghi chú cho từng bài test
            @testset "Test $i: $(basename(input_file)) (Minsup=$minsup)" begin
                # 1. Lấy kết quả từ code của bạn
                my_results = a_close_main(input_file, minsup)
                
                # 2. Lấy kết quả gốc từ SPMF
                spmf_results = read_spmf_output(spmf_file)
                
                # 3. So sánh: Số lượng tập đóng có bằng nhau không?
                @test length(my_results) == length(spmf_results)
                
                # 4. So sánh: Từng tập đóng và support có khớp chính xác 100% không?
                # Toán tử == của Dict trong Julia tự động kiểm tra key-value hoàn hảo
                @test my_results == spmf_results 
            end
        end
    end
end

# Khởi chạy test
run_all_tests()