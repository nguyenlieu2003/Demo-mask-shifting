%% Hàm tạo ma trận đo ngẫu nhiên với giá trị 0 và 1
function A = get_A_random(n, m)
    A = randi([0, 1], m, n); % Ma trận đo ngẫu nhiên với giá trị 0 và 1
end