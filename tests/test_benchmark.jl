# tests/test_benchmark.jl
include("../src/algorithm/structures.jl")
include("../src/algorithm/utils.jl")
include("../src/algorithm/algorithm.jl")

function run_benchmark()
    # Mở file CSV để ghi kết quả
    csv_file = open("data/benchmark/benchmark_results.csv", "w")
    println(csv_file, "Dataset,Minsup,Time_Seconds,Memory_MB,Itemsets_Count")

    # === NHÓM 1: THỰC NGHIỆM THỜI GIAN THEO MINSUP ===
    # Định nghĩa các mốc test (Tên file, mảng các minsup cần test)
    # Cố định file, thay đổi minSup
    regular_test_cases = [
        ("chess.txt", [0.9, 0.85, 0.8, 0.75, 0.7]),
        ("mushroom.txt", [0.6, 0.55, 0.5, 0.45, 0.4]),
        ("T10I4D100K.txt", [0.05, 0.04, 0.03, 0.02, 0.01])
    ]

    # === NHÓM 2: THỰC NGHIỆM SCALABILITY ===
    # Cố định minsup, thay đổi kích thước file (Retail)
    retail_fixed_minsup = 0.05 # Chạy mốc 5% cho tất cả các phần retail
    scalability_test_cases = [
        ("retail_10.txt", [retail_fixed_minsup]),
        ("retail_25.txt", [retail_fixed_minsup]),
        ("retail_50.txt", [retail_fixed_minsup]),
        ("retail_75.txt", [retail_fixed_minsup]),
        ("retail.txt", [retail_fixed_minsup]) # File gốc (100%)
    ]

    # Gộp 2 nhóm lại để chạy 1 lần
    all_test_cases = vcat(regular_test_cases, scalability_test_cases)

    println("=== WARM UP (KHỞI ĐỘNG JULIA JIT) ===")
    a_close_main("./data/toy/toy_1_paper.txt", 0.4, true)
    
    println("\n=== BẮT ĐẦU BENCHMARK ===")
    for (filename, minsups) in all_test_cases
        filepath = "./data/benchmark/$filename"
        println(">> Đang xử lý: $filename")
        
        for minsup in minsups
            print("   - Minsup $minsup... ")
            
            # Buộc garbage collector dọn rác trước khi đo RAM
            GC.gc() 
            
            # Đo RAM (bytes) và Thời gian (giây)
            mem_bytes = @allocated begin
                time_sec = @elapsed begin
                    results = a_close_main(filepath, minsup, true) 
                end
            end
            
            # Xử lý số liệu
            mem_mb = round(mem_bytes / (1024 * 1024), digits=2)
            time_round = round(time_sec, digits=4)
            num_itemsets = length(results)
            
            println("Xong! Thời gian: $(time_round)s | RAM: $(mem_mb)MB | Itemsets: $num_itemsets")
            
            # Ghi vào file CSV
            println(csv_file, "$filename,$minsup,$time_round,$mem_mb,$num_itemsets")
        end
    end
    
    close(csv_file)
    println("\n=== HOÀN THÀNH! Số liệu đã được lưu tại benchmark_results.csv ===")
end

run_benchmark()