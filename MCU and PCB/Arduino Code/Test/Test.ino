#define phaseA 22
#define phaseB 24

int LastStateA  = digitalRead(phaseA);
int LastStateB  = digitalRead(phaseB);
double counter = 0;
int toggle1 = 0;

void setup() {
  pinMode (phaseA, INPUT);
  pinMode (phaseB, INPUT);
  Serial.begin (115200);

  cli();//stop interrupts

  TCCR1A = 0;// set entire TCCR1A register to 0
  TCCR1B = 0;// same for TCCR1B
  TCNT1  = 0;//initialize counter value to 0
  OCR1A = 15624;// = (16*10^6) / (1*1024) - 1 (must be <65536)
  TCCR1B |= (1 << WGM12);
  TCCR1B |= (1 << CS12) | (1 << CS10);  
  TIMSK1 |= (1 << OCIE1A);

  sei();// start interrupts
  
}

ISR(TIMER1_COMPA_vect)
{
  double speed = (counter/40.0)/1;
  counter = 0;
  Serial.print ("Speed: ");
  Serial.print (speed);
  Serial.print ("\n");
}

void loop() 
{
  int CurrentStateA  = digitalRead(phaseA);
  int CurrentStateB  = digitalRead(phaseB);
  if (LastStateA != CurrentStateA) 
    if (CurrentStateB == LastStateA) counter--;
      else counter++;
  LastStateA = CurrentStateA;
}
