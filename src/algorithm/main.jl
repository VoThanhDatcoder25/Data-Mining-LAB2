include("structures.jl")
include("utils.jl")
include("algorithm.jl")

function write_spmf_output(results::Dict{Set{Int}, Int}, output_filepath::String)
    open(output_filepath, "w") do f
        for (closure, support) in results
            # Chuyển Set thành mảng, sắp xếp và ghép thành chuỗi phân cách bởi khoảng trắng
            items_str = join(sort(collect(closure)), " ")
            println(f, "$items_str #SUP: $support")
        end
    end
end

function run_cli()
    # Nhận tham số từ dòng lệnh (ARGS)
    if length(ARGS) < 3
        println("Cách sử dụng: julia main.jl <input_file> <output_file> <minsup_ratio>")
        println("Ví dụ: julia main.jl data.txt output.txt 0.4")
        return
    end

    input_filepath = ARGS[1]
    output_filepath = ARGS[2]
    minsup_ratio = parse(Float64, ARGS[3])

    println("Đang chạy A-Close...")
    println("- Input: $input_filepath")
    println("- Minsup: $minsup_ratio")
    
    # Đo thời gian chạy thực tế (rất hữu ích cho Chương 4)
    @time begin
        results = a_close_main(input_filepath, minsup_ratio, use_optimization=true) # Bật tối ưu hóa mặc định
    end
    
    write_spmf_output(results, output_filepath)
    println("Hoàn thành! Kết quả đã được lưu tại: $output_filepath")
end

if abspath(PROGRAM_FILE) == @__FILE__
    run_cli()
end