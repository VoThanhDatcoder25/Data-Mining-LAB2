# tests/test_benchmark.jl
include("../src/algorithm/structures.jl")
include("../src/algorithm/utils.jl")
include("../src/algorithm/algorithm.jl")

function run_benchmark()
    # Mở file CSV để ghi kết quả
    csv_file = open("data/benchmark/benchmark_results.csv", "w")
    println(csv_file, "Dataset,Minsup,Time_Seconds,Memory_MB,Itemsets_Count")

    # Định nghĩa các mốc test (Tên file, mảng các minsup cần test)
    # Lưu ý: Chess rất đặc, minsup dưới 0.7 có thể bùng nổ RAM
    test_cases = [
        ("chess.txt", [0.9, 0.85, 0.8, 0.75, 0.7]),
        ("mushroom.txt", [0.4, 0.35, 0.3, 0.25, 0.2]),
        ("T10I4D100K.txt", [0.05, 0.04, 0.03, 0.02, 0.01])
    ]

    println("=== WARM UP (KHỞI ĐỘNG JULIA JIT) ===")
    a_close_main("../data/toy/toy_1_paper.txt", 0.4, use_optimization=true)
    
    println("\n=== BẮT ĐẦU BENCHMARK ===")
    for (filename, minsups) in test_cases
        filepath = "../data/benchmark/$filename"
        println(">> Đang xử lý: $filename")
        
        for minsup in minsups
            print("   - Minsup $minsup... ")
            
            # Buộc garbage collector dọn rác trước khi đo RAM
            GC.gc() 
            
            # Đo RAM (bytes) và Thời gian (giây)
            mem_bytes = @allocated begin
                time_sec = @elapsed begin
                    results = a_close_main(filepath, minsup, use_optimization=true)
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