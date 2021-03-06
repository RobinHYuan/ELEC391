%% -------------- Set Up --------------
    clear; clc;close all;
    sampleTime = 1e-3;
    
%% -------------- Parameter Assignment --------------
% Note: SI Units are Used. (V, A, Ohm, H, rad/s, kgm^2 and Nm)
    RPMtoRad = @(rpm) 2*pi*rpm/60;
    [Nominal_V, NoLoadSpeed, NoLoadCurrent] = deal(24, RPMtoRad(8270), 164e-3);
    [NominalTorque, NominalSpeed] = deal(108e-3, RPMtoRad(7710));
    [Km,Jm, Jg] = deal(27.3e-3,72.8e-7, 10.82e-7);  %0.7e-7
    [Rw, Lw] = deal(0.331,150.103e-3);
    [GearBoxRatio, i, effMax] = deal(1/63,63, 0.9);
    NominalEff = 1 -2*(1-effMax);
% Dynamic Damping Factor Estimation
    NoLoadTorque  =  Km * NoLoadCurrent;
    Bm = NoLoadTorque/NoLoadSpeed; 
% Gear Box Parameter Estimation 
    syms Tout Bg OmegaG
    eq1 = NominalTorque - Bm * NominalSpeed + Bg *(OmegaG-NominalSpeed) == 0;
    eq2 = NominalEff * NominalSpeed *  Bg *-(OmegaG-NominalSpeed) == OmegaG*Tout;
    eq3 = OmegaG ==NominalSpeed*GearBoxRatio;
    sol = solve(eq1,eq2,eq3);
    Bg = double(sol.Bg);
    

%% -------------- SimuLink Model ---------------------   
    Jload = 0.01;  %Jg = 0;Jload = 0; Bg =0; i = 1;
    Jls = i^2* (Jm + 0.5*Jg) + 0.5* Jg + Jload ;
    Bls =i^(Bm+Bg); 

 
 %% -------------- Open-Loop Xfer Function --------------  
    CF = 1300;
    AmpMotor = tf([23.999996164545507],[4.296783667510467e-05, 5]);
    uControl = tf([2*CF],[1, 2*CF]);
    MotorE = tf([1],[Lw,Rw]);
    MechY  =tf([1],[Jls, Bls]);
    MotorFWD = MotorE * Km*i * MechY;
    MotorFBCK = Km*i;
    MotorXfer = MotorFWD/(1 + MotorFWD *MotorFBCK);
    
    s = tf('s');
    OLXfer = minreal(AmpMotor * uControl * MotorXfer * 1/s);
    
    % ------- Determine the controller Dynamics-------
        rla(OLXfer);
        figure;
        [XferD, Kp, Ki, Kd] = PIDZero(OLXfer, OLXfer, 1e-5, 0, CF)  
        
        
        OLXferD = XferD * OLXfer; % Unity Gain OPEN LOOP PID control + OLXfer
        
    % ------- Determine Master Gain ---------------       
     % K = RecursiveSearch(1e-4,1e-4, 10, margin(OLXferD)/2, OLXferD, 0, 1);
     
    time =  0: 1e-3: 2;
    Foward = XferD* AmpMotor  * MotorXfer * 1/s;
    FBCK = uControl;
    
    bestKp = RecursiveSearch(1e-5,1, 1, margin(OLXferD)/2, time, Foward,FBCK, 1,10, 60, 1)

     [Gm, PmBest, Wcg, Wcp] = margin(OLXferD*bestKp);
     [Gm, PmTest, Wcg, Wcp] = margin(OLXferD);
     K = bestKp;
     % ------- Nyquist Plot---------------  
        figure;
        nyqlog(OLXferD*bestKp);
        figure;
        nyqlog(OLXferD);
        
       % Huristic Tuning
       Ki = Ki/50;
       Kd = Kd*1/20;
       Kp = 1.25*Kp;
       XferD = Kp + Ki*1/s + Kd*(2*CF*s)/(s+2 * CF)
        
 %% -------------- Simulation --------------          
        SimulationTime = 3;
        ControllerPID;
        ExpectedPosition= pi/2;% Specify it in rad
        sim('ControllerPID',SimulationTime);
    


 %% ------------- Figures ---------------------------------
 figure;
omegaM =ans.AngularVelocityM.Data;
torque = ans.torque.Data;
current = ans.current.Data;
voltage = ans.voltage.Data;
position = ans.position.Data;
omegaM1 =ans.AngularVelocityM1.Data;

t = ans.AngularVelocityM.Time;
t2 = ans.torque.Time;
t3 = ans.current.Time;
t4= ans.voltage.Time;
t5= ans.position.Time;
t6 = ans.AngularVelocityM1.Time;
subplot(2,3,1);
RadtoRPM= @(rad) rad*60/(2*pi);
plot (t5*1e3, position,'color', 'blue','LineWidth',2.25,'LineStyle','-','DisplayName','Actual MotorpPosition \theta_M');
hold on; grid on; legend();
plot (t*1e3, ExpectedPosition*heaviside(t),'color', 'green','LineWidth',2.5,'LineStyle','--','DisplayName','Desired Motor Position \theta_D');
ylabel("Position(rad)");xlabel("Time(msec)");
title("Simulation Result - Position");xlim([0 SimulationTime*1e3])
subplot(2,3,2);
plot (t2*1e3,torque,'color', 'blue','LineWidth',2.25,'LineStyle','-','DisplayName','Torque \tau_M');
ylabel("Torque(Nm)");xlabel("Time(msec)");hold on; grid on; legend();

title("Simulation Result - Torque");xlim([0 SimulationTime*1e3])
subplot(2,3,3);
plot (t3*1e3,current,'color', 'blue','LineWidth',2.25,'LineStyle','-','DisplayName','Current i_M');
ylabel("Current(A)");xlabel("Time(msec)");hold on; grid on; legend();
title("Simulation Result - Current");xlim([0 SimulationTime*1e3])
subplot(2,3,4);
plot (t4*1e3,voltage,'color', 'blue','LineWidth',2.25,'LineStyle','-','DisplayName','Voltage V_{Appplied}');
ylabel("Voltage(V)");xlabel("Time(msec)");hold on; grid on; legend();
title("Simulation Result - Voltage");xlim([0 SimulationTime*1e3])

subplot(2,3,5);hold on;
plot (t*1e3, RadtoRPM(omegaM),'color', 'blue','LineWidth',2.25,'LineStyle','-','DisplayName','End Effector Speed \omega_r');
plot (t6*1e3, RadtoRPM(omegaM1),'color', 'red','LineWidth',2.25,'LineStyle','-','DisplayName','Motor Speed \omega_r');
hold on; grid on; legend();
ylabel("Speed(RPM)");xlabel("Time(msec)");
title("Simulation Result - Speed");xlim([0 SimulationTime*1e3])


%% ------------Function ------------
function [XferD, Kp, Ki, Kd] = PIDZero(orgSys, sys, precision, LastPXO, CF)
   [Gm, Pm, Wcg, Wcp] = margin(sys);
   figure(2);
   margin(sys)
   target = round(Wcg,abs(log10(precision)),"significant");
   LastPXO = round(LastPXO,abs(log10(precision)),"significant");
   s = tf('s');
   XferDPole  = [0, -2*CF];

   if( LastPXO <= target * (1+precision*10) &&LastPXO >= target * (1-precision*10) )     
        XferDzero = [-LastPXO/10, -LastPXO/10];
        Ki = 1;
        Kp = (2)/(LastPXO/10) - 1/(2*CF);
        Kd = 1/((LastPXO/10)^2) - Kp/(2*CF);
        XferD = Kp + Ki*1/s + Kd*(2*CF*s)/(s+2 * CF);
   else 
        if(LastPXO > target) 
            Zt = abs(LastPXO - (LastPXO-target)/2)/10 ;
            XferDzero = [-Zt, -Zt];
            XferD = zpk(XferDzero, XferDPole, 1);
            [XferD, Kp, Ki, Kd]   = PIDZero(orgSys, XferD*orgSys, precision, Zt*10, CF)      
        else if(LastPXO < target)
                Zt = abs(LastPXO +(target-LastPXO)/2)/10 ;
                XferDzero = [-Zt, -Zt];
                XferD = zpk( XferDzero, XferDPole, 1);
                [XferD, Kp, Ki, Kd]  = PIDZero(orgSys, XferD*orgSys, precision, Zt*10, CF) 
            end
        end      
   end
end 
function [PeakTime, RiseTime, SettleTime, OvershootPercentage] =  SecondOrderApproxCoeff(Xfer,time, figureHandle, enableFigure)


    [ydata, xdata ] = step(Xfer,time);
    % Remeber that the unit of x-axis is in msec
    sz = size(ydata); % Get size and assume xdata and ydata have the same size
    FinalValue = ydata(sz(1)); % Assume the last cell contains the final value
    RiseTimeFlag = 0; PeakTimeFlag = 0; SettleTimeFlag = 0; PeakTime = xdata(sz(1));
    [PeakTime, RiseTime, SettleTime]= deal(0,0,0);
for index = 1 : 1: sz(1) - 1
    
    if(ydata(index) <= FinalValue && ydata(index + 1) >= FinalValue && not(RiseTimeFlag)) 
         slope = (ydata(index + 1) - ydata(index))/(xdata(index + 1) - xdata(index));
         t = (FinalValue - ydata(index))/slope;
         RiseTime = xdata(index) + t
         %print = sprintf('y(index + 1)/FV == %f and y(index)/FV == %f',ydata (index + 1)/FinalValue,ydata (index)/FinalValue )
        RiseTimeFlag = 1;
    end
    
    if(ydata(index) >= ydata(index + 1) && ydata(index) >= ydata(index - 1) && not(PeakTimeFlag))
        PeakTime = xdata(index)
        PeakValue = ydata(index);
        PeakTimeFlag = 1;
    end
    
    if( abs(ydata(index)-FinalValue)/FinalValue >= 0.02 && abs(ydata(index + 1)-FinalValue)/FinalValue <= 0.02 && not(SettleTimeFlag) && xdata(index) > PeakTime  )
         SettlePointFlag = 1;
         for j = 1: 1:  sz(1) - 1 -index
             if (abs(ydata(index + j)-FinalValue)/FinalValue >= 0.02)
              SettlePointFlag = 0;
              break;
             end
         end
         if(   SettlePointFlag == 1)
         slope = (ydata(index + 1) - ydata(index))/(xdata(index + 1) - xdata(index));
         if( ydata(index)> FinalValue)
         t = (FinalValue * 1.02 - ydata(index))/slope; 
         else   t = (FinalValue * 0.98 - ydata(index))/slope;end
         SettleTime = xdata(index) + t
         SettleTimeFlag = 1;
         %print = sprintf('y(index + 1)/FV == %f and y(index)/FV == %f',ydata (index + 1)/FinalValue,ydata (index)/FinalValue )
         end
    end
         
end
figure(figureHandle);
clear j slope SettleTimeFlag t
OvershootPercentage = (PeakValue-FinalValue)/FinalValue*100
OvershootValue = (PeakValue-FinalValue)
clear RiseTimeFlag RiseTimeIndex index PeakTimeFlag SettleTimeFlag print
if(enableFigure)
hold on; legend ();
yline(FinalValue,'color','red','LineWidth',1.75, 'LineStyle','--','DisplayName','Final Value');
xline(RiseTime, 'color','green','LineWidth',1.75, 'LineStyle',':','DisplayName','Rise Time')
xline(PeakTime, 'color','black','LineWidth',1.75, 'LineStyle','-.','DisplayName','Peak Time')
yline(PeakValue, 'color','blue','LineWidth',1.75, 'LineStyle','--','DisplayName','Peak Value')
xline(SettleTime,'color','magenta','LineWidth',1.75, 'LineStyle',':','DisplayName','Settle Time')
yline(FinalValue*0.98,'color','#813C85','LineWidth',1.75, 'LineStyle',':','DisplayName','Settle Value')
yline(FinalValue*1.02,'color','#813C85','LineWidth',1.75, 'LineStyle',':','DisplayName','Settle Value')
hold off;
end

end
function bestKp = KpSearch(startingPoint, increment, endPoint, time, Foward,H_Xfer, figureHandle,overshootPercent, config)
   
 LowestTime = 1e9;  
 LowestError = 100;
 bestKp = startingPoint;
 for k= startingPoint : increment :endPoint;
    TF = minreal(k*Foward/(1+k*Foward*H_Xfer));   
    figure(figureHandle);
    [d, time] = step(TF,time);
    plot(time, d, 'green','LineWidth',2.5,'LineStyle','-','DisplayName','Position')
    
    sz=size(d);

    FirstOrderFlag = 1;
    for index = 1: 1:  (sz(1)-1)/2;
        if(d(sz(1))<d(index)) 
            FirstOrderFlag = 0;
            break;
        end
    end
if(config == 1)     
    if(FirstOrderFlag==0) 
        [PeakTime, RiseTime, SettleTime, Overshoot] =  SecondOrderApproxCoeff(TF, time, figureHandle, 0);
        if(LowestTime>=PeakTime + RiseTime + SettleTime && RiseTime > 0.15 && SettleTime < 1.5 &&  Overshoot < overshootPercent ) 
            figure(figureHandle); legend();
            [PeakTime, RiseTime, SettleTime, Overshoot] =  SecondOrderApproxCoeff(TF, time, figureHandle, 1);
            LowestTime = PeakTime + RiseTime + RiseTime;
            bestKp = k;
        end
    end

else    if(FirstOrderFlag==0) 
        [PeakTime, RiseTime, SettleTime, Overshoot] =  SecondOrderApproxCoeff(TF, time, figureHandle, 0);
        ssError = (1-dcgain(TF))*100
        if(LowestError > ssError && Overshoot <overshootPercent  ) 
            figure(figureHandle); legend();
            [PeakTime, RiseTime, SettleTime, Overshoot] =  SecondOrderApproxCoeff(TF, time, figureHandle, 1);
            LowestTime = ssError;
            bestKp = k;
        end
    end 
end
end


end
function bestKp = RecursiveSearch(Precision,startingPoint, increment, endPoint, time, G_Xfer,H_Xfer, bestKp,figureHandle, overshootPercent, config)
         if(increment<Precision) bestKp = bestKp;
         else 
              bestKp = KpSearch(startingPoint, increment, endPoint, time, G_Xfer,H_Xfer, figureHandle,overshootPercent, config);
              bestKp = RecursiveSearch(Precision,bestKp-increment, increment/10, bestKp+increment, time, G_Xfer,H_Xfer, bestKp,figureHandle,overshootPercent, config)
         end
         
end
