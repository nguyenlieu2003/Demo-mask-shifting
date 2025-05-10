clc;
clear all; 
close all;

% Đọc ảnh đầu vào
input_image = imread('anh.png'); % Thay đổi đường dẫn tới ảnh của bạn
image = rgb2gray(input_image); % Chuyển đổi ảnh sang ảnh xám nếu cần
image = im2double(image); % Chuyển đổi ảnh sang định dạng double

% Thay đổi kích thước ảnh về 32x32
image = imresize(image, [32, 32]);
% Kích thước hình ảnh
[image_row, image_col] = size(image);
n = image_row * image_col;

m = 1000;
A = get_A_random(n, m);

[row, col] = find(image > 0);
positions = [row, col]; % Vị trí của các số khác 0

% Tạo ma trận ngẫu nhiên có kích thước n x n
random_matrix = rand(image_row, image_col); % Khởi tạo ma trận ngẫu nhiên với giá trị từ 0 đến 1

% Gán giá trị ngẫu nhiên cho các vị trí khác 0
for i = 1:size(positions, 1)
    random_matrix(positions(i, 1), positions(i, 2)) = rand(); % Gán giá trị ngẫu nhiên từ 0 đến 1
end

% Chia ma trận ngẫu nhiên cho 5, 10, 20, 30,...
divisors = [2, 4, 6, 8]; % Các giá trị chia
N_matrices = cell(length(divisors), 1); % Khởi tạo cell array để lưu các ma trận N
snr_values = zeros(length(divisors), 1); % Khởi tạo mảng để lưu giá trị SNR
X_matrices = cell(length(divisors), 1); % Khởi tạo cell array để lưu các ma trận X
m_values = 100:100:1000; % Dải giá trị m
SNR_dB_values = zeros(length(divisors), 1);

% Khởi tạo biến lưu kết quả
rmse_matrix = zeros(length(m_values), length(divisors));
recovered_imgs = cell(1, length(divisors));

%% Vòng lặp chính
for idx_div = 1:length(divisors)
    N_matrices{idx_div} = random_matrix / divisors(idx_div); % Chia ma trận ngẫu nhiên cho các giá trị
    
    % Tính toán SNR cho mỗi trường hợp
    signal_power = sum(image(:).^2); % Tổng bình phương các giá trị của ma trận ban đầu
    noise_power = sum(N_matrices{idx_div}(:).^2); % Tổng bình phương các giá trị trong ma trận N
    snr_values(idx_div) = signal_power / noise_power; % Tính SNR
    
    % Chuyển SNR sang dB và lưu vào ma trận
    SNR_dB_values(idx_div) = 10 * log10(snr_values(idx_div)); 
    
    % Cộng ma trận N với ma trận ban đầu để thu được ma trận X
    X_matrices{idx_div} = image + N_matrices{idx_div}; % Cộng ma trận N với ma trận ban đầu
     
    f = X_matrices{idx_div}(:); % Chuyển ma trận X về dạng cột

    for m_idx = 1:length(m_values)
        mp = m_values(m_idx);
        
        % Tạo ma trận đo
        AP = A(1:mp, :);
        AS = circshift(AP, [0, 1]); % Dịch AP sang phải 1 đơn vị
        AS(:, 1) = 0; % Đặt cột đầu tiên của AS thành 0
        
        % Mô phỏng phép đo
        y = AP * f;
        y1 = AS * f;
        Yout = y - y1;
        
        % Giải bài toán tối ưu
        cvx_begin
            variable xp_flat(n)
            minimize(norm(xp_flat, 1))
            subject to
            AP * xp_flat == Yout
        cvx_end
        
        % Khôi phục ảnh
        xo = zeros(size(xp_flat));
        xo(end) = xp_flat(end);
        for i = 2:length(xp_flat) 
            j = length(xp_flat) - (i - 1); 
            xo(j) = xp_flat(j) + xo(j + 1); 
        end
        
        recovered_img = reshape(xo, image_row, image_col);
          
        % Lưu ảnh cho m cuối cùng
        if m_idx == length(m_values)
           % Kích thước hình ảnh
           recovered_imgs{idx_div} = recovered_img;
        end
        
        % Tính RMSE
        rmse_value = sqrt(mean((f - xo).^2));
        
        % Lưu giá trị RMSE vào ma trận
        rmse_matrix(m_idx, idx_div) = rmse_value;  
    end
end


%% Vẽ đồ thị
figure('Color', [1 1 1]);
hold on;
colors = ['r', 'g', 'b', 'm', 'c'];
for snr_idx = 1:length(SNR_dB_values)
    plot(m_values, rmse_matrix(:,snr_idx), 'LineWidth', 2,'DisplayName', ['SNR = ', num2str(SNR_dB_values(snr_idx)), ' dB'], 'Color', colors(snr_idx));
end
xlabel('Số phép đo');
ylabel('RMSE');
title('Hiệu suất khôi phục theo SNR và số phép đo');
legend show;
grid on;
hold off;

%% Hiển thị ảnh khôi phục
figure('Color', [1 1 1]);
subplot(2,3,1);
imshow(image, []);
title('Ảnh gốc');

for snr_idx = 1:length(SNR_dB_values)
    subplot(2,3,snr_idx+1);
    imshow(recovered_imgs{snr_idx}, []);
    title(['SNR = ', num2str(SNR_dB_values(snr_idx)), ' dB']);
end
% 
% figure('Color', [1 1 1]);
% hold on;
% colors = ['r', 'g', 'b', 'm', 'c'];
% for snr_idx = 1:length(SNR_dB_values)
%     plot(m_values, rmse_matrix(:,snr_idx), 'LineWidth', 2,'DisplayName', ['SNR = ', num2str(SNR_dB_values(snr_idx)), ' dB'], 'Color', colors(snr_idx));
% end
% xlabel('Số phép đo');
% ylabel('RMSE');
% title('Hiệu suất khôi phục theo SNR và số phép đo');
% legend show;
% grid on;
% 
% % % Thêm giới hạn trục để zoom
% % xlim([60 120]);
% % ylim([0 0.2]);
% 
% hold off;
