#define phaseA 22
#define phaseB 24

int LastStateA  = digitalRead(phaseA);
int LastStateB  = digitalRead(phaseB);
int counter = 0;

void setup() {
  pinMode (phaseA, INPUT);
  pinMode (phaseB, INPUT);
  Serial.begin (115200);
}

void loop() {
  
  int CurrentStateA  = digitalRead(phaseA);
  int CurrentStateB  = digitalRead(phaseB);

 if (LastStateA != CurrentStateA) 
    if (CurrentStateB == LastStateA) counter--;
      else counter++;
    
  Serial.print (counter);
  Serial.print ("\n");
  LastStateA = CurrentStateA;
}
