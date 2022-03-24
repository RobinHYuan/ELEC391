clc; clear; close all;
fileID = fopen('motor_driver.scp','r');
A = textscan(fileID,'%f   %f   %f ','HeaderLines',20);
[time, Vout] = deal(A{1},A{2});
sz = size(time);
for index = 1:1:sz(1)-1
    if(time(index)>0.5)
        break;
    end
end
time = time(index:index+8e1,:);
Vout = Vout(index:index+8e1,:);
plot (time, Vout,'color', 'blue','LineWidth',2.25,'LineStyle','-','DisplayName','Actual Motor Speed \omega_M');
hold on; grid on; legend();
