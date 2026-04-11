# tests/verify_benchmark.jl
include("../src/algorithm/structures.jl")
include("../src/algorithm/utils.jl")
include("../src/algorithm/algorithm.jl")

function read_spmf_output(filepath::String)
    spmf_results = Dict{Set{Int}, Int}()
    for line in eachline(filepath)
        if isempty(strip(line)) continue end
        parts = split(line, "#SUP:")
        items_str = strip(parts[1])
        support_str = strip(parts[2])
        items = isempty(items_str) ? Set{Int}() : Set(parse.(Int, split(items_str, " ")))
        support = parse(Int, support_str)
        spmf_results[items] = support
    end
    return spmf_results
end

function verify_single_case(data_file::String, spmf_file::String, minsup::Float64)
    # Lấy kết quả từ code Julia
    my_results = a_close_main(data_file, minsup, true)
    # Lấy kết quả từ SPMF
    spmf_results = read_spmf_output(spmf_file)
    
    total_spmf = length(spmf_results)
    total_mine = length(my_results)
    match_count = 0
    
    for (itemset, support) in my_results
        if haskey(spmf_results, itemset) && spmf_results[itemset] == support
            match_count += 1
        end
    end
    
    if total_spmf == total_mine && match_count == total_spmf
        return true, total_spmf
    else
        return false, total_spmf
    end
end

function run_all_verifications()
    regular_test_cases = [
        ("chess.txt", [0.9, 0.85, 0.8, 0.75, 0.7]),
        ("mushroom.txt", [0.6, 0.55, 0.5, 0.45, 0.4]),
        ("T10I4D100K.txt", [0.05, 0.04, 0.03, 0.02, 0.01])
    ]

    retail_fixed_minsup = 0.05
    scalability_test_cases = [
        ("retail_10.txt", [retail_fixed_minsup]),
        ("retail_25.txt", [retail_fixed_minsup]),
        ("retail_50.txt", [retail_fixed_minsup]),
        ("retail_75.txt", [retail_fixed_minsup]),
        ("retail.txt", [retail_fixed_minsup])
    ]

    all_test_cases = vcat(regular_test_cases, scalability_test_cases)
    
    println("=== BẮT ĐẦU KIỂM TRA ĐỐI CHIẾU HÀNG LOẠT ===")
    
    passed_tests = 0
    total_tests_run = 0
    missing_files = 0

    for (filename, minsups) in all_test_cases
        base_name = replace(filename, ".txt" => "")
        
        for minsup in minsups
            # Quy đổi minsup ra phần trăm số nguyên để làm tên file (VD: 0.85 -> 85, 0.05 -> 5)
            minsup_pct = round(Int, minsup * 100)
            
            data_filepath = "./data/benchmark/$filename"
            spmf_filepath = "./data/benchmark/spmf_$(base_name)_$(minsup_pct).txt"
            
            print("Đang check $filename (Minsup: $minsup) ... ")
            
            if !isfile(spmf_filepath)
                println("⚠️ BỎ QUA - Không tìm thấy file SPMF: $spmf_filepath")
                missing_files += 1
                continue
            end
            
            total_tests_run += 1
            is_match, num_items = verify_single_case(data_filepath, spmf_filepath, minsup)
            
            if is_match
                println("✅ Khớp 100% ($num_items itemsets)")
                passed_tests += 1
            else
                println("❌ CÓ SAI LỆCH!")
            end
        end
    end
    
    println("\n=== TỔNG KẾT BÁO CÁO CORRECTNESS ===")
    println("Tổng số bài test đã chạy: $total_tests_run")
    println("Số bài test Khớp 100%:    $passed_tests")
    println("Số bài test thiếu file:   $missing_files (Chưa chạy bằng SPMF Java)")
    
    if total_tests_run > 0 && passed_tests == total_tests_run
        println("=> ĐÁNH GIÁ: HOÀN HẢO! Code chạy đúng trên mọi tập dữ liệu.")
    end
end

run_all_verifications()