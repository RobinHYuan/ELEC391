// PIN Assignments
#define phaseA 22
#define phaseB 24
#define PWM    12
#define Direction 23
// PID Parameters
#define Kp     1E-3
#define Ki     15
#define Kd     1E-9
#define deltaT 0.5
#define maxSpeed 1
#define HalfDutyCycle 127
#define FullDutyCycle 255
// Speed Variable
int LastStateA  = digitalRead(phaseA);
int LastStateB  = digitalRead(phaseB);
double speed = 0;
double counter  = 0;
// PID Variable 
double integral = 0;
double oldError = 0;
double desiredSpeed = 0;
double speedRecord[3] = {0,0,0};
double PIDLoopCounter =0;
int flag =0;
int ISRcounter =0;

void setup() {
  pinMode (phaseA, INPUT);
  pinMode (phaseB, INPUT);
  pinMode (Direction, OUTPUT);

  Serial.begin (115200);

  cli();//stopinterrupts 

  // Timer 4 is used for Speed Calculation
  TCCR4A = 0;// set entire TCCR1A register to 0
  TCCR4B = 0;// same for TCCR1B
  TCNT4  = 0;//initialize counter value to 0
  OCR4A = 15624;// = (16*10^6) / (1*1024) - 1 (must be <65536)
  TCCR4B |= (1 << WGM12);
  TCCR4B |= (1 << CS12) | (1 << CS10);  
  TIMSK4 |= (1 << OCIE4A);

  sei();// start interrupts
  
}



ISR(TIMER4_COMPA_vect)
{
  ISRcounter++;
  Serial.print(PIDLoopCounter);
  Serial.print("   ");
  Serial.print(ISRcounter);
  Serial.print("\n");
}


void loop() 
{

  double test1 =random(0,50);
  double test2 =random(0,50);
  PID(test1, test2);

}


void PID(double desiredSpeed, double currentSpeed)
{
  
  speedRecord[0] = currentSpeed;
  double SpeedWeighted = 0.7*speedRecord[0] + 0.2* speedRecord[1] + 0.1*speedRecord[2];
  double Error = desiredSpeed - SpeedWeighted;
  double integral =+ (Error + oldError) * deltaT/2.0;
  double edot =(Error - oldError)/deltaT;
  double speedOut = Kp*Error + Ki*integral + Kd*edot;
  double dutyPercent = ((0.5 + (speedOut/maxSpeed)/2) >= 1) ? 1: ((0.5 + (speedOut/maxSpeed)/2) <0) ? 0: 0.5 + (speedOut/maxSpeed)/2;
  double dutyCycle = (speedOut == 0) ? HalfDutyCycle: dutyPercent* FullDutyCycle;
  analogWrite(PWM, dutyCycle);  
  speedRecord[1] = speedRecord[0];
  speedRecord[2] = speedRecord[1];
  PIDLoopCounter++;
}


