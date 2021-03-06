enum ProximityRange{
  Undefined(-1), 
  Close(0), 
  Medium(1), 
  Far(2); 
  
  private final int value;
  
  private ProximityRange(int value) {
    this.value = value;
  }

  public int getValue() {
    return value;
  }
}

class ProximityDetector implements Runnable{
  
  final long REFRESH_RATE = 200; 
  
  final int QUEUE_SIZE = 1;  
  
  int rangeChangeTicks = 0; 
  
  float rawDistance = 0.0f; 
  
  FloatList distanceQueue = new FloatList();  
  
  float rangeChangedTimestamp = 0.0f;
  
  int updatesPerSecond = 0; // counter of how many updates occur per second 
  float elapsedTimeSinceUpdate = 0; 
  float lastUpdateTimestamp = 0;
  int updatesPerSecondCounter = 0;
  
  ProximityRange previousRange = ProximityRange.Far; 
  ProximityRange currentRange = ProximityRange.Far;  
  
  boolean initilised = false; 
  boolean running = true; 
  
  ProximityDetector(){
    
  }
  
  void init(){
    initilised = true;     
  }
  
  void run(){
    init(); 
    
    while(running){
      long startFrameTime = System.currentTimeMillis();      
      
      update();       
      
      long et = System.currentTimeMillis() - startFrameTime;
      
      if(et < REFRESH_RATE){
        long diff = REFRESH_RATE - et;
        try{
          Thread.sleep(diff); 
        } catch(Exception e){}
      }                          
    }
  }
  
  public void update(){
    
    // ** update frequency, for debugging purposes - looking at how quickly the proximity is being refreshed. ** //  
    float et = millis() - lastUpdateTimestamp; 
    lastUpdateTimestamp = millis(); 
    
    elapsedTimeSinceUpdate += et;        
    
    if(elapsedTimeSinceUpdate >= 1000){
      updatesPerSecond = updatesPerSecondCounter; 
      updatesPerSecondCounter = 0; 
      elapsedTimeSinceUpdate -= 1000;
    }    
    
    updatesPerSecondCounter += 1;
  }    
  
  boolean onKeyDown(int keyCode){
    return false; 
  }
  
  ProximityRange distanceToProximityRange(float distance){
    return ProximityRange.Undefined;   
  }  
  
  public void setCurrentRange(ProximityRange range){
    if(range == currentRange){
      rangeChangeTicks = 0; 
      return; 
    }
    
    rangeChangeTicks++; 
    
    if(currentRange == ProximityRange.Undefined || (range.getValue() < currentRange.getValue() && rangeChangeTicks >= configManager.proximityRangeDownChangeThreshold) || 
        (range.getValue() > currentRange.getValue() && rangeChangeTicks >= configManager.proximityRangeUpChangeThreshold)){
      rangeChangeTicks = 0;
      rangeChangedTimestamp = millis(); 
      this.previousRange = this.currentRange; 
      this.currentRange = range;
    }        
    
    if(hasChanged()){
      onProximityChanged(this.currentRange);   
    }
  }
  
  public ProximityRange getCurrentRange(){
    return this.currentRange;  
  }
  
  public float getDistance(){
    if(distanceQueue.size() == 0){
      return 0.0f;   
    }
    
    float total = 0.0f; 
    for(int i=0; i<distanceQueue.size(); i++){
      total += distanceQueue.get(i);   
    }
    return total / (float)distanceQueue.size();  
  }
  
  public void updateDistance(float distance){
    distanceQueue.append(distance);
    
    while(distanceQueue.size() > QUEUE_SIZE){
      distanceQueue.remove(0); 
    }
    
    
    // update proximity range 
    ProximityRange newRange = distanceToProximityRange(this.getDistance()); 
    setCurrentRange(newRange); 
  }
  
  public boolean hasChanged(){
    return previousRange != currentRange;   
  }
}

class MockProximityDetector extends ProximityDetector{
  
  final int DISTANCE_INCREMENT = 50; 
  
  public MockProximityDetector(){
    super(); 
    updateDistance(300); 
  }
  
  void update(){
    super.update(); 
    
    updateDistance(getDistance());
  }
  
  boolean onKeyDown(int keyCode){    
    if(keyCode == UP){
      updateDistance(getDistance() + DISTANCE_INCREMENT); 
      return true; 
    } else if(keyCode == DOWN){
      updateDistance(getDistance() - DISTANCE_INCREMENT); 
      return true;
    }
    
    return false; 
  }
  
  ProximityRange distanceToProximityRange(float distance){
    ProximityRange range = ProximityRange.Undefined; 
    
    if(distance > configManager.distanceMedium){
      range = ProximityRange.Far;
    } else if(distance > configManager.distanceClose){
      range = ProximityRange.Medium;
    } else{
      range = ProximityRange.Close;
    }
    
    return range;    
  }
}