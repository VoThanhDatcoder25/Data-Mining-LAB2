# tests/split_data.jl
function split_dataset(filepath::String, out_prefix::String)
    println("Đang đọc file gốc: $filepath...")
    lines = readlines(filepath)
    total_lines = length(lines)
    
    percents = [0.10, 0.25, 0.50, 0.75, 1.0]
    
    for p in percents
        num_take = round(Int, total_lines * p)
        out_name = "$(out_prefix)_$(round(Int, p * 100)).txt"
        
        open(out_name, "w") do f
            for i in 1:num_take
                println(f, lines[i])
            end
        end
        println("Đã tạo $out_name với $num_take dòng.")
    end
end

# Thay đổi đường dẫn cho phù hợp nếu bạn chạy từ thư mục gốc
split_dataset("data/benchmark/retail.txt", "data/benchmark/retail")