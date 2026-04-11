

function get_support(itemset::Vector{Int}, transactions::Vector{Set{Int}})
    count = 0
    itemset_set = Set(itemset) # Chuyển itemset sang Set để kiểm tra nhanh hơn (issubset)
    for t in transactions
        if issubset(itemset_set, t)
            count += 1
        end
    end
    return count
end


function ac_generator(G_i::Vector{Generator}, minsup_count::Int, transactions::Vector{Set{Int}}, current_i::Int, level_ref::Ref{Int})
    G_next = Vector{Generator}()
    n = length(G_i)

    for j in 1:n
        for k in (j+1):n
            p = G_i[j].items
            q = G_i[k].items

            # Nối nếu i-1 phần tử đầu tiên giống nhau (chuẩn Apriori-gen)
            if p[1:end-1] == q[1:end-1]
                candidate_items = sort(unique(vcat(p, q))) # Nối và sắp xếp

                #Bước 2: Cắt tỉa 1 - mọi tập con kích thước i phải nằm trong G_i
                # (Lược bớt logic check tập con phức tạp ở Level 1 để chạy được trước)
                is_valid = true
                for drop_idx in 1:length(candidate_items)
                    subset = copy(candidate_items)
                    deleteat!(subset, drop_idx) # Tạo i-subset nhanh hơn list comprehension
                    
                    if !any(g -> g.items == subset, G_i)
                        is_valid = false
                        break
                    end
                end
                
                if !is_valid
                    continue 
                end

                #Bước 3: Tính support và Cắt tỉa 2 (Support < minsup_count)
                sup = get_support(candidate_items, transactions)
                if sup >= minsup_count

                    #Bước 4: Cắt tỉa 3 - Support của ứng viên == Support của tập con?
                    is_useless = false
                    for gen in G_i
                       # Chỉ cần kiểm tra gen có là tập con của candidate không
                        # (Vì gen nằm trong G_i nên chắc chắn nó là một i-subset)
                        if issubset(Set(gen.items), Set(candidate_items)) && gen.support == sup
                            is_useless = true
                            
                            # Cập nhật level nếu đây là lần cắt tỉa đầu tiên (Thuật toán 3, dòng 15-17)
                            if level_ref[] == 0
                                level_ref[] = current_i
                            end
                            break
                        end
                    end

                    # Chỉ thêm ứng viên vào G_next nếu không bị loại bỏ
                    if !is_useless
                        push!(G_next, Generator(candidate_items, sup, Set{Int}())) # Khởi tạo closure rỗng, sẽ được tính sau
                    end
                end
            end
        end
    end
    return G_next
end


function ac_closure!(generators::Vector{Generator}, transactions::Vector{Set{Int}})
    for p in generators
# Nếu đã có closure (được tính theo rule level), thì bỏ qua việc tính lại closure
        if p.closure !== nothing && !isempty(p.closure)
            continue 
        end

        p_set = Set(p.items)
        first_match = true

        for t in transactions
            if issubset(p_set, t)
                if first_match
                    p.closure = copy(t) # Khởi tạo closure với giao của p và t đầu tiên, gán bằng giao dịch đầu tiên chứa nó
                    first_match = false
                else
                    p.closure = intersect(p.closure, t) # Cập nhật closure bằng giao với t tiếp theo/các giao dịch tiếp theo
                end
            end
        end
    end
end


function a_close_main(filepath::String, minsup_ratio::Float64, use_optimization::Bool=true)
    transactions = read_spmf(filepath)
    num_transactions = length(transactions)
    minsup_count = ceil(Int, minsup_ratio * num_transactions)

    # Bước 1: Tạo G_1 (Các phần tử đơn lẻ)
    item_counts = Dict{Int, Int}()
    for t in transactions
        for item in t
            item_counts[item] = get(item_counts, item, 0) + 1
        end
    end

    G_1 = Vector{Generator}()
    for (item, count) in item_counts
        if count >= minsup_count
            push!(G_1, Generator([item], count, Set{Int}())) # Khởi tạo closure rỗng, sẽ được tính sau
        end
    end

    # Thêm dòng này ngay sau khi kết thúc vòng lặp tạo G_1 và trước bước 2
    sort!(G_1, by = x -> x.items[1]) # Sắp xếp G_1 theo item để đảm bảo thứ tự cố định khi sinh G_2

    # Fix Bug 3: Áp dụng cơ chế level để phân tách G và G' (Thuật toán 1)
    all_generators_by_size = Dict{Int, Vector{Generator}}()
    all_generators_by_size[1] = G_1

    level_ref = Ref(0) # Khởi tạo biến level dùng chung
    current_i = 1
    G_current = G_1

    while !isempty(G_current)
        # ac_closure!(G_current, transactions) # Tính closure cho các generator trong G_current
        G_next = ac_generator(G_current, minsup_count, transactions, current_i, level_ref)
        if !isempty(G_next)
            all_generators_by_size[current_i + 1] = G_next
        end
        G_current = G_next
        current_i += 1
        # append!(all_generators, G_next) # Thêm G_{i+1} vào tập hợp tất cả generator
        # G_current = G_next # Cập nhật G_current để tiếp tục vòng lặp
    end

    # Tách G và G' dựa trên biến level (Thuật toán 1, dòng 10-19)
    level = level_ref[]

    all_final_generators = Vector{Generator}()
    for (size_i, gens) in all_generators_by_size
        for p in gens
            # Áp dụng tối ưu khi flag use_optimization=true: Nếu đã vượt qua level, thì các generator còn lại tự là tập đóng của chính mình, không cần tính closure nữa
            if use_optimization && level > 2 && size_i < level - 1
                # Thuộc tập G: Chúng tự là tập đóng của chính mình, không cần duyệt data
                p.closure = Set(p.items)
            end
            push!(all_final_generators, p)
        end
    end

    # Bước 3: Tính Closure cho toàn bộ generator còn sống
    ac_closure!(all_final_generators, transactions) # Tính closure cho tất cả các generator đã tìm được

    # Bước 4: Lọc các bao đóng trùng lặp và trả về kết quả
    frequent_closed_itemsets = Dict{Set{Int}, Int}() # Sử dụng Dict để loại bỏ các bao đóng trùng lặp
    for gen in all_final_generators
        frequent_closed_itemsets[gen.closure] = gen.support # Lưu closure và support tương ứng
    end

    return frequent_closed_itemsets # Trả về Dict chứa các bao đóng phổ biến và support của chúng
end
