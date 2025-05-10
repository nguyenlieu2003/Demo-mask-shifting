clc;
clear all; 
close all;

% Kích thước hình ảnh
image_size = 32;
n = image_size * image_size;

% Tạo hình ảnh xám
image = zeros(image_size, image_size);

% Kích thước hình vuông
square_size = 30;

% Vị trí ngẫu nhiên cho hình vuông
x_start = randi([1, image_size - square_size]);
y_start = randi([1, image_size - square_size]);

% Vẽ hình vuông vào hình ảnh
image(y_start:y_start + square_size - 1, x_start:x_start + square_size - 1) = 1;

image = double(image); 
m = 1000;
A = get_A_random(n, m);

[row, col] = find(image > 0);
positions = [row, col]; % Vị trí của các số khác 0

% Tạo ma trận ngẫu nhiên có kích thước n x n
random_matrix = zeros(image_size); % Khởi tạo ma trận ngẫu nhiên với giá trị 0

% Gán giá trị ngẫu nhiên cho các vị trí khác 0
for i = 1:size(positions, 1)
    random_matrix(positions(i, 1), positions(i, 2)) = rand(); % Gán giá trị ngẫu nhiên từ 0 đến 1
end


noise_level = [0.1, 0.01]; % Độ lớn của nhiễu
% Chia ma trận ngẫu nhiên cho 5, 10, 20, 30,...
divisors = [6, 8, 10]; % Các giá trị chia
N_matrices = cell(length(divisors), 1); % Khởi tạo cell array để lưu các ma trận N
snr_values = zeros(length(divisors)*length(noise_level), 1); % Khởi tạo mảng để lưu giá trị SNR
X_matrices = cell(length(divisors), 1); % Khởi tạo cell array để lưu các ma trận X
m_values = 100:100:1000; % Dải giá trị m
SNR_dB_values = zeros(length(divisors)*length(noise_level), 1);


% Khởi tạo biến lưu kết quả
rmse_matrix = zeros(length(m_values), length(noise_level)*length(divisors));
recovered_imgs = cell(1, length(m_values)); % Sửa lại để phù hợp với số lượng m_values

%% Vòng lặp chính
for idx_div = 1:length(divisors)
    N_matrices{idx_div} = random_matrix / divisors(idx_div); % Chia ma trận ngẫu nhiên cho các giá trị
    % Cộng ma trận N với ma trận ban đầu để thu được ma trận X
    X_matrices{idx_div} = image + N_matrices{idx_div}; % Cộng ma trận N với ma trận ban đầu
     
    f = X_matrices{idx_div}(:); % Chuyển ma trận X về dạng cột

    for n_idx = 1:length(noise_level)
        noise = noise_level(n_idx);
        total_snr = 0; % Khởi tạo biến tổng SNR cho từng mức độ nhiễu
        for m_idx = 1:length(m_values)
            mp = m_values(m_idx);
        
            % Tạo ma trận đo
            AP = A(1:mp, :);
            AS = circshift(AP, [0, 1]); % Dịch AP sang phải 1 đơn vị
            AS(:, 1) = 0; % Đặt cột đầu tiên của AS thành 0
            
            % Mô phỏng phép đo
            y = AP * f;
            y1 = AS * f;
            
            % Thêm nhiễu vào y và y1
            noise_y = noise * rand(size(y));  % Nhiễu cho y
            noise_y1 = noise * rand(size(y1)); % Nhiễu cho y1
            
            y_noisy = y + noise_y;  % y có nhiễu
            y1_noisy = y1 + noise_y1; % y1 có nhiễu
            
            Yout = y_noisy - y1_noisy; % Sử dụng y_noisy và y1_noise
            
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

           % Tính ma trận K
            K = y_noisy - y; % Tính ma trận K
            
            % Tính SNR cho từng vòng lặp m
            snr_value = (y.^2) ./ (K.^2); % Tính SNR cho từng giá trị
            snr_value(isnan(snr_value)) = 0; % Đặt giá trị NaN thành 0 (nếu có)
            snr_value(isinf(snr_value)) = 0; % Đặt giá trị vô cực thành 0 (nếu có)

            % Tính SNR trung bình cho từng phép đo
            snr_mean = mean(snr_value); % Tính SNR trung bình cho từng phép đo
            total_snr = total_snr + snr_mean; % Cộng dồn SNR trung bình
            
            recovered_img = reshape(xo, image_size, image_size);
              
            % Lưu ảnh cho m cuối cùng
            if m_idx == length(m_values)
               % Kích thước hình ảnh
               recovered_imgs{(idx_div - 1) * length(noise_level) + n_idx} = recovered_img;
            end
            
            % Tính RMSE
            rmse_value = sqrt(mean((f - xo).^2));
            
            % Lưu giá trị RMSE vào ma trận
            rmse_matrix(m_idx, (idx_div - 1) * length(noise_level) + n_idx) = rmse_value;  
        end
        
        % Tính SNR trung bình cho từng mức độ nhiễu
        snr_tb = total_snr / length(m_values); % Tính SNR trung bình
        SNR_dB_values((idx_div - 1) * length(noise_level) + n_idx) = 10 * log10(snr_tb); % Chuyển SNR trung bình sang dB
    end
end

% %% Vẽ đồ thị
% figure;
% hold on;
% colors = ['r', 'g', 'b', 'm', 'c', 'y', 'k', 'r', 'g', 'b', 'm', 'c', 'y', 'k', 'r'];
% for snr_idx = 1:length(SNR_dB_values)
%     plot(m_values, rmse_matrix(:,snr_idx), 'LineWidth', 2,'DisplayName', ['SNR = ', num2str(SNR_dB_values(snr_idx)), ' dB'], 'Color', colors(snr_idx));
% end
% xlabel('Số phép đo');
% ylabel('RMSE');
% title('Hiệu suất khôi phục theo SNR và số phép đo');
% legend show;
% grid on;
% hold off;
% 
% %% Hiển thị ảnh khôi phục
% figure;
% subplot(4,4,1);
% imshow(image, []);
% title('Ảnh gốc');
% 
% for snr_idx = 1:length(SNR_dB_values)
%     subplot(4,4,snr_idx+1);
%     imshow(recovered_imgs{snr_idx}, []);
%     title(['SNR = ', num2str(SNR_dB_values(snr_idx)), ' dB']);
% end

% Sắp xếp SNR_dB_values và rmse_matrix
[SNR_dB_values_sorted, sort_idx] = sort(SNR_dB_values); % Sắp xếp SNR_dB_values
rmse_matrix_sorted = rmse_matrix(:, sort_idx); % Sắp xếp rmse_matrix theo thứ tự của SNR_dB_values

% Vẽ đồ thị với SNR đã sắp xếp
figure('Color', [1 1 1]);
hold on;
colors = ['r', 'g', 'b', 'm', 'c', 'y', 'k', 'r', 'g', 'b', 'm', 'c', 'y', 'k', 'r'];
for snr_idx = 1:length(SNR_dB_values_sorted)
    plot(m_values, rmse_matrix_sorted(:, snr_idx), 'LineWidth', 2, 'DisplayName', ['SNR = ', num2str(SNR_dB_values_sorted(snr_idx)), ' dB'], 'Color', colors(snr_idx));
end
xlabel('Số phép đo');
ylabel('RMSE');
title('Hiệu suất khôi phục theo SNR và số phép đo (đã sắp xếp)');
legend show;
grid on;
hold off;

% Hiển thị ảnh khôi phục
figure('Color', [1 1 1]);
subplot(3, 3, 1);
imshow(image, []);
title('Ảnh gốc');

for snr_idx = 1:length(SNR_dB_values_sorted)
    subplot(3, 3, snr_idx + 1);
    imshow(recovered_imgs{sort_idx(snr_idx)}, []); % Sử dụng chỉ số đã sắp xếp để hiển thị ảnh khôi phục
    title(['SNR = ', num2str(SNR_dB_values_sorted(snr_idx)), ' dB']);
end