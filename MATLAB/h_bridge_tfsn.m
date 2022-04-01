clc; close all; clear; 
rawTable = readtable('h_tfsn.xlsx','Sheet','Sheet1');
x = rawTable.X; %: get the excel column, Header1 (header name)
y = rawTable.Y; %: get the excel column, Header2 (header name)
figure;
x0 = x - x(1);
plot(x0*1e6,y,"LineWidth",2.25,"Color",'r','DisplayName', 'Motor Driver Step Response');
y_63_percent = 0.63*24;
%yline(y_63_percent, "Color", 'k', 'LineWidth', 1.5, 'LineStyle','--','DisplayName', 'y = 0.63*FV')

for i = 1 : 1 : 674
    if(y(i) < y_63_percent+0.1 && y(i) > y_63_percent-0.1)
        index = i;
        break;
    end
end

 tau = x0(index)

 s = tf('s');
 tsfn = 1/(0.65*tau*s + 1);
 tsfn = tsfn/dcgain(tsfn) * y(674)/5;
 hold on;
 dcgain(tsfn)
 opt = stepDataOptions('StepAmplitude',5);
 [h, t] = step(tsfn,opt);
 plot(t*1e6, h, "LineWidth",2,"Color",'b', 'DisplayName','First Order Appporximation');
 grid on; legend();
 ylabel("Amplitude(V)");
 xlabel("Time(\mu sec)")
 xlim([0 60])
 ylim([0 25])
 title ("Motor Driver - Step Response ")