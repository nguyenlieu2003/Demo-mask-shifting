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
m = 500;
A = get_A_random(n, m);

m_values = 50:50:350; % Dải giá trị m

% Khởi tạo biến lưu kết quả
rmse_matrix = zeros(length(m_values), 1); % Đảm bảo kích thước đúng

f = image(:); 

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
    
    recovered_img = reshape(xo, image_size, image_size);
      
    % Tính RMSE
    rmse_value = sqrt(mean((f - xo).^2));
    
    % Lưu giá trị RMSE vào ma trận
    rmse_matrix(m_idx) = rmse_value;    
end

%% Vẽ đồ thị
figure('Color', [1 1 1]);
hold on;
colors = ['r', 'g', 'b', 'm', 'c'];
plot(m_values, rmse_matrix,'LineWidth', 2, 'Color', colors(1));
xlabel('Số phép đo');
ylabel('RMSE');
title('Hiệu suất khôi phục theo số phép đo');
legend show;
grid on;
hold off;

% %% Vẽ đồ thị
% figure;
% hold on;
% plot(m_values, rmse_matrix, 'LineWidth', 2, 'Color', 'b');
% xlabel('Số phép đo (m)');
% ylabel('RMSE');
% title('Hiệu suất khôi phục theo số phép đo');
% grid on;
% hold off;


%% Hiển thị ảnh khôi phục
figure('Color', [1 1 1]);
subplot(2,1,1);
imshow(image, []);
title('Ảnh gốc');

subplot(2,1,2);
imshow(recovered_img, []);
title('Ảnh khôi phục');