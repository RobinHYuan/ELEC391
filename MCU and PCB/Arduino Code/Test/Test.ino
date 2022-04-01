// PIN/PRORT Assignments
#define phaseA 22
#define phaseB 24
#define PWM    12
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
double speedRecord[3] = {0, 0, 0}; 

// Test Signal;
int toggle =0, toggle2 =0;
void setup() {
  pinMode (phaseA, INPUT);
  pinMode (phaseB, INPUT);
  pinMode  (49,OUTPUT);
  pinMode  (48,OUTPUT);
  Serial.begin (115200);

  cli();//stop interrupts


// Timer 4 is used for Speed Calculation fsample = 2000Hz

  TCCR4A = 0;// set entire TCCR4A register to 0
  TCCR4B = 0;// same for TCCR4B
  TCNT4  = 0;//initialize counter value to 0
  OCR4A = 49;// = (16*10^5) / (2000*1024) - 1 (must be <65536)
  TCCR4B |= (1 << WGM12);
  TCCR4B |= (1 << CS11)|(1 << CS10);  //64 pre-scale
  TIMSK4 |= (1 << OCIE4A);

//Timer 3 is used for PID output fcontrol  = 1300 Hz
  TCCR3A = 0;
  TCCR3B = 0;
  TCNT3  = 0;
  OCR3A = 95;// = 16*10^5/(1300*1024) -1
  TCCR3B |= (1 << WGM12);
  TCCR3B |= (1 << CS11)|(1 << CS10);   
  TIMSK3 |= (1 << OCIE3A);

int prescalerVal = 0x07; 
TCCR1B &= ~prescalerVal; //AND the value in TCCR0B with binary number "11111000"
//Now set the appropriate prescaler bits:
prescalerVal = 2; //set prescalerVal equal to binary number "00000001"
TCCR1B |= prescalerVal; //OR the value in TCCR0B with binary number "00000001"

sei();// start interrupts

}

ISR(TIMER4_COMPA_vect)
{
  speed = (counter)/(1/2000.0);
  counter = 0;
  Serial.print ("Speed: ");
  Serial.print (speed);
  Serial.print ("\n");

}

ISR(TIMER3_COMPA_vect)
{
  //PID(desiredSpeed,speed);
  digitalWrite(49,toggle);
  toggle =!toggle;
}


void loop() 
{

  int CurrentStateA  = digitalRead(phaseA);
  int CurrentStateB  = digitalRead(phaseB);
  if (LastStateA != CurrentStateA) 
    if   (CurrentStateB == LastStateA) counter--;
    else counter++;
   LastStateA = CurrentStateA;
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
}
