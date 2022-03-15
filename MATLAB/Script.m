%% -------------- Set Up --------------
    clear; clc; close all;
    sampleTime = 1e-6;
    
%% -------------- Parameter Assignment --------------
% Note: SI Units are Used. (V, A, Ohm, H, rad/s, kgm^2 and Nm)
    RPMtoRad = @(rpm) 2*pi*rpm/60;
    [Nominal_V, NoLoadSpeed, NoLoadCurrent] = deal(24, RPMtoRad(8270), 164e-3);
    [Km,Jm, Jg] = deal(27.3e-3,72.8e-7, 1e-9);  %0.7e-7
    [Rw, Lw] = deal(0.331,0.103e-3);
    [GearBoxRatio,eff] = deal(1/83,1);  
% Dynamic Damping Factor Estimation
    NoLoadTorque  =  Km * NoLoadCurrent;
    Bm = NoLoadTorque/NoLoadSpeed; 
    
%% -------------- SimuLink Model ---------------------   
 KLoad = 0.95; MinLoadTorque = 5*NoLoadTorque;
 ExpectedSpeed = RPMtoRad(8000/83);% Specify it in RPM
 [Kp, Ki, Kd] = deal(1e-3,15,1e-11);
 SimulationTime = 1e-1;
 CF= 1000;
 ControllerPID;
 sim('ControllerPID',SimulationTime);
 
 %% ------------- Figures ---------------------------------
omegaM =ans.AngularVelocityM.Data;
torque = ans.torque.Data;
current = ans.current.Data;
voltage = ans.voltage.Data;

t = ans.AngularVelocityM.Time;
t2 = ans.torque.Time;
t3 = ans.current.Time;
t4=ans.voltage.Time;
subplot(2,2,1);
RadtoRPM= @(rad) rad*60/(2*pi);
plot (t*1e3, RadtoRPM(omegaM),'color', 'blue','LineWidth',2.25,'LineStyle','-','DisplayName','Actual Motor Speed \omega_M');
hold on; grid on; legend();
plot (t*1e3, RadtoRPM(ExpectedSpeed)*heaviside(t),'color', 'green','LineWidth',2.5,'LineStyle','--','DisplayName','Desired Motor Speed \omega_D');
ylabel("Speed(RPM)");xlabel("Time(msec)");
title("Simulation Result - Speed");xlim([0 SimulationTime*1e3])
subplot(2,2,2);
plot (t2*1e3,torque,'color', 'blue','LineWidth',2.25,'LineStyle','-','DisplayName','Torque \tau_M');
ylabel("Torque(Nm)");xlabel("Time(msec)");hold on; grid on; legend();

title("Simulation Result - Torque");xlim([0 SimulationTime*1e3])
subplot(2,2,3);
plot (t3*1e3,current,'color', 'blue','LineWidth',2.25,'LineStyle','-','DisplayName','Current i_M');
ylabel("Current(A)");xlabel("Time(msec)");hold on; grid on; legend();
title("Simulation Result - Current");xlim([0 SimulationTime*1e3])
subplot(2,2,4);
plot (t4*1e3,voltage,'color', 'blue','LineWidth',2.25,'LineStyle','-','DisplayName','Voltage V_{Appplied}');
ylabel("Voltage(V)");xlabel("Time(msec)");hold on; grid on; legend();
title("Simulation Result - Voltage");xlim([0 SimulationTime*1e3])