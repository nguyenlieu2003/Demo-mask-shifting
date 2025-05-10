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

noise_level = [0.01, 0.1, 1]; % Độ lớn của nhiễu
m_values = 100:100:1000; % Dải giá trị m

% Khởi tạo biến lưu kết quả
rmse_matrix = zeros(length(m_values), length(noise_level));
recovered_imgs = cell(1, length(noise_level));
snr_values = zeros(length(noise_level),1);

f = image(:); % Chuyển ma trận X về dạng cột

%% Vòng lặp chính
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
        
        Yout = y_noisy - y1_noisy; % Sử dụng y_noisy và y1_noisy

        % Tính SNR
        signal_power = sum(y_noisy.^2); % Tổng bình phương của y_noisy
        noise_power = sum(noise_y.^2); % Tổng bình phương của noise_y
        snr = signal_power / noise_power; % Tính SNR
     
        % Cộng dồn SNR
        total_snr = total_snr + snr; 
        
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
        
        recovered_img = reshape(xo, image_size, image_size);
          
         % Lưu ảnh cho m cuối cùng
        if m_idx == length(m_values)
           % Kích thước hình ảnh
           recovered_imgs{n_idx} = recovered_img;
        end
        
        % Tính RMSE
        rmse_value = sqrt(mean((f - xo).^2));
        
        % Lưu giá trị RMSE vào ma trận
                % Lưu giá trị RMSE vào ma trận
        rmse_matrix(m_idx, n_idx) = rmse_value;  
    end
    
    % Tính SNR trung bình cho từng mức độ nhiễu
    snr_tb = total_snr / length(m_values); % Tính SNR trung bình
    snr_values(n_idx) = 10 * log10(snr_tb); % Chuyển SNR trung bình sang dB
end

%% Vẽ đồ thị
figure('Color', [1 1 1]);
hold on;
colors = ['r', 'g', 'b', 'm', 'c'];
for snr_idx = 1:length(snr_values)
    plot(m_values, rmse_matrix(:,snr_idx), 'LineWidth', 2,'DisplayName', ['SNR = ', num2str(snr_values(snr_idx)), ' dB'], 'Color', colors(snr_idx));
end
xlabel('Số phép đo');
ylabel('RMSE');
title('Hiệu suất khôi phục theo SNR và số phép đo');
legend show;
grid on;
hold off;

%% Hiển thị ảnh khôi phục
figure('Color', [1 1 1]);
subplot(2,2,1);
imshow(image, []);
title('Ảnh gốc');

for snr_idx = 1:length(snr_values)
    subplot(2,2,snr_idx+1);
    imshow(recovered_imgs{snr_idx}, []);
    title(['SNR = ', num2str(snr_values(snr_idx)), ' dB']);
end