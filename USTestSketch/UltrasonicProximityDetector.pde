
import processing.io.*;

class UltrasonicProximityDetector{

  static final int GPIO_TRIGGER = 23; 
  static final int GPIO_ECHO = 24; 
  
  public float refreshFrequency = 0;
  
  private boolean updating = false;

  private float currentDistance = 0;    
  
  private float lastUpdated = 0; 

  /**
   *  References: 
   *  https://www.raspberrypi.org/blog/now-available-for-download-processing/
   *  https://github.com/processing/processing/wiki/Raspberry-Pi
   *  http://www.raspberrypi-spy.co.uk/2012/12/ultrasonic-distance-measurement-using-python-part-1/
   *  http://www.raspberrypi-spy.co.uk/2013/01/ultrasonic-distance-measurement-using-python-part-2/
   **/
  public UltrasonicProximityDetector() {
    super();   

    initSensor();  

    update();
  }

  private void initSensor() {
    GPIO.pinMode(GPIO_TRIGGER, GPIO.OUTPUT);
    GPIO.pinMode(GPIO_ECHO, GPIO.INPUT);

    GPIO.digitalWrite(GPIO_TRIGGER, GPIO.LOW);
  }

  void update() {
    if (!isReady()) {
      return;
    }        
    
    updating = true;

    lastUpdated = millis();     
    currentDistance = measureAverage();     
    
    updating = false;
  }

  int measureAverage() {
    int distance1 = measure();
    delay(100); 
    int distance2 = measure();
    delay(100);
    int distance3 = measure();

    return (distance1 + distance2 + distance3)/3;
  }

  int measure() {
    GPIO.digitalWrite(GPIO_TRIGGER, GPIO.HIGH);
    //delay(1);  
    GPIO.digitalWrite(GPIO_TRIGGER, GPIO.LOW);

    float startTime = millis(); 
    float stopTime = millis();

    while (GPIO.digitalRead(GPIO_ECHO) == GPIO.LOW) {
      startTime = millis();
    }

    while (GPIO.digitalRead(GPIO_ECHO) == GPIO.HIGH) {
      stopTime = millis();
    }

    float elapsedTime = stopTime - startTime; 
    return (int)(((elapsedTime/1000.0f) * 34300.0f) / 2.0f);
    //return (elapsedTime * 34300) / 2;
  }  

  public boolean isReady() {
    return !updating && (millis() - lastUpdated) >= refreshFrequency;
  }
}  