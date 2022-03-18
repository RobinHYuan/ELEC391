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
// Speed Variable
int LastStateA  = digitalRead(phaseA);
int LastStateB  = digitalRead(phaseB);
double speed = 0;
double counter  = 0;
// PID Variable 
double integral = 0;
double oldError = 0;
double desiredSpeed = 0;


void setup() {
  pinMode (phaseA, INPUT);
  pinMode (phaseB, INPUT);
  pinMode (Direction, OUTPUT);

  Serial.begin (115200);

  cli();//stop interrupts


  // Timer 4 is used for Speed Calculation
  TCCR4A = 0;// set entire TCCR1A register to 0
  TCCR4B = 0;// same for TCCR1B
  TCNT4  = 0;//initialize counter value to 0
  OCR4A = 15624;// = (16*10^6) / (1*1024) - 1 (must be <65536)
  TCCR4B |= (1 << WGM12);
  TCCR4B |= (1 << CS12) | (1 << CS10);  
  TIMSK4 |= (1 << OCIE4A);

  //Timer 2 is used for PID output
  TCCR2A = 0;// set entire TCCR1A register to 0
  TCCR2B = 0;// same for TCCR1B
  TCNT2  = 0;//initialize counter value to 0
  OCR2A = 31249;// = 16*10^6/(0.5*1024) -1
  TCCR2B |= (1 << WGM12);
  TCCR2B |= (1 << CS12) | (1 << CS10);  
  TIMSK2 |= (1 << OCIE2A);



  sei();// start interrupts
  
}

ISR(TIMER4_COMPA_vect)
{
  speed = (counter/40.0)/1;
  counter = 0;
  Serial.print ("Speed: ");
  Serial.print (speed);
  Serial.print ("\n");
}

ISR(TIMER2_COMPA_vect)
{
  PID(desiredSpeed,speed);
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
  double Error = desiredSpeed - currentSpeed;
  double integral =+ (Error + oldError) * deltaT/2.0;
  double edot =(Error - oldError)/deltaT;
  double x = Kp*Error + Ki*integral + Kd*edot;
  double dutyCycle = ((x/maxSpeed)*255>255) ? 255 :(x/maxSpeed)*255;
  double direction = desiredSpeed>currentSpeed ? 1 : 0;
  digitalWrite(Direction, direction);
  analogWrite(PWM, dutyCycle);  

}
