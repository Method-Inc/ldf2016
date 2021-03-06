import processing.net.*;

/**
https://processing.org/tutorials/network/
https://processing.org/reference/libraries/net/Server.html
https://processing.org/reference/libraries/net/Client.html
**/
class LocalService{
  
  public static final int ACTION_UPDATE_IMAGE = 10;
  
  public final String MSG_DELIMITER = ":";
  public final String MSG_IMAGEID = "MID";
  public final String MSG_ANIMATION_STATE = "AST";
  public final String MSG_ACTION = "A";

  private int port = 8888;
  
  private ConfigManager config; 
  
  private float lastInitTimestamp = 0.0f; 
  
  private Server server; 
  private Client client; 
  
  private int retryCounter = 0; 
  
  private StringDict cachedMessages = new StringDict();

  LocalService(ConfigManager config){
    println("setting up local connection"); 
    this.config = config; 
    
    this.port = config.p2pPort; 
    
    init(); 
  }
  
  private void init(){
    // throttle how frequently this is called 
    if(millis() - lastInitTimestamp < 500){
      return;   
    }
    
    if(getPIIndex() == 0){
      initServer();         
    } else{
      initClient();   
    }
    
    lastInitTimestamp = millis(); 
  }
  
  private void initServer(){
    retryCounter -= 1; 
    
    if(retryCounter > 0){
      return;   
    }
    
    retryCounter = 0; 
    
    if(server != null){
      if(server.active()){
        server.stop();         
      }
      server = null; 
    }
    
    println("initServer: " + config.hostAddress);    
    try{
      server = new Server(MainPApplet(), port, config.hostAddress);  // Start a simple server on a port=
      introduceSelf(); 
    } catch(Exception e){
      retryCounter = 10;
    }
  }
  
  private void initClient(){
    retryCounter -= 1; 
    
    if(retryCounter > 0){
      return;   
    }
    
    retryCounter = 0; 
    
    if(client != null){
      if(client.active()){
        client.stop();         
      }
      client = null; 
    }
    
    if(config.getMaster() == null){
      //println("config.getMaster() == null"); 
      return; 
    }
    
    println("initClient: " + config.getMaster().hostAddress);
    try{
      client = new Client(MainPApplet(), config.getMaster().hostAddress, port);
      introduceSelf(); 
    } catch(Exception e){
      client = null; 
      retryCounter = 500;   
    }
  }
  
  public boolean introduceSelf(){
    if(server != null && isConnected()){
      println("SERVER: HI: writing " + config.piIndex + "\n");
      try{
        server.write(config.piIndex + ":HI:" + config.piIndex + "\n");
      } catch(Exception e){ server = null; } 
    } else if(client != null && isConnected()){
      println("CLIENT: HI: writing " + config.piIndex + "\n");
      try{
        client.write(config.piIndex + ":HI:" + config.piIndex + "\n");        
      } catch(Exception e){ client = null; } 
    }        
    
    return true; 
  }   
  
  public boolean updatePairsOfNewImageId(String imageId, int imageNumber){
    if(imageId == null) return false;
    
    String msg = config.piIndex + MSG_DELIMITER + MSG_IMAGEID + MSG_DELIMITER + imageId + "\n";
    
    if(server != null && isConnected()){
      
      // flag waiting for update from all images 
      for(int i=0; i<config.pairs.size(); i++){
          Pair clientPair = (Pair)config.pairs.get(i);                    
          clientPair.setWaitingForImage(true); 
      }
            
      println("SERVER: NEW IMAGE ID: writing " + msg);      
      server.write(msg);  
    } else if(client != null && isConnected()){      
      println("CLIENT: NEW IMAGE ID: writing " + msg);      
      client.write(msg);
    }        
    
    return true; 
  }
  
  public boolean updatePairsOfNewAnimationState(int state){
    final String msg = config.piIndex + MSG_DELIMITER + MSG_ANIMATION_STATE + MSG_DELIMITER + state + "\n";
    
    if(server != null && isConnected()){      
      println("SERVER: ANIM STATE: writing " + msg);
      try{
        server.write(msg);
      } catch(Exception e){ server = null; } 
    } else if(client != null && isConnected()){
      println("CLIENT: ANIM STATE: writing " + msg);
      try{
        client.write(msg);
      } catch(Exception e){ client = null; } 
    }        
    
    return true; 
  }
  
  public boolean updatePairsOfAction(int action){
    final String msg = config.piIndex + MSG_DELIMITER + MSG_ACTION + MSG_DELIMITER + action + "\n";
    
    if(server != null && isConnected()){      
      println("SERVER: ACTION: writing " + msg);
      try{
        server.write(msg);
      } catch(Exception e){ server = null; } 
    } else if(client != null && isConnected()){
      println("CLIENT: ACTION: writing " + msg);
      try{
        client.write(msg);
      } catch(Exception e){ client = null; } 
    }        
    
    return true; 
  }
  
  public void update(float et){
    try{
      _update(et);   
    } catch(Exception e){}
  }
  
  private void _update(float et){
    if(!isConnected()){
      init(); 
      return; 
    }
    
    // *** CLIENT *** 
    if(client != null){
      if (client.available() > 0) {    
        String input = client.readString();
        
        if(input == null || input.length() == 0){
          return;   
        }
        
        println("DATA RECEIVED FROM SERVER " + input);
        
        String pInput = "";
        
        if(cachedMessages.hasKey(config.getMaster().hostAddress)){
          pInput = cachedMessages.get(config.getMaster().hostAddress);    
          cachedMessages.remove(config.getMaster().hostAddress);
        }
                
        // has terminator? 
        char lastCharacter = input.charAt(input.length()-1);        
        if(lastCharacter != '\n'){          
          cachedMessages.set(config.getMaster().hostAddress, pInput + input);          
        } else{
          // append any previously cached messages 
          input = pInput + input;
          
          String lines[] = input.split("\n");
          
          if(lines != null && lines.length > 0){
            for(int i=0; i<lines.length; i++){
              processPairMessage(client.ip(), lines[i]);                     
            }
          }  
        }                
      } 
    } 
    
    // *** SERVER *** 
    else if(server != null){
      Client pairClient = server.available();  
      while(pairClient != null){
        String input = pairClient.readString();
        if(input == null || input.length() == 0)
          continue; 
        
        String pInput = "";
        if(cachedMessages.hasKey(pairClient.ip())){
          pInput = cachedMessages.get(pairClient.ip());    
          cachedMessages.remove(pairClient.ip());
        }
                
        // has terminator? 
        char lastCharacter = input.charAt(input.length()-1);        
        if(lastCharacter != '\n'){          
          cachedMessages.set(pairClient.ip(), pInput + input);
          continue; 
        } 
        
        // append any previously cached messages 
        input = pInput + input; 
        
        println("DATA RECEIVED FROM CLIENT " + pairClient.ip() + " " + input);                       

        String lines[] = input.split("\n");
        if(lines != null && lines.length > 0){
          for(int i=0; i<lines.length; i++){
            processPairMessage(pairClient.ip(), lines[i]); 
          }
        }
                
        pairClient = server.available();
      }       
    }
  }  
  
  private void processPairMessage(String ipAddress, String line){
    if(line == null || line.length() == 0){
      return;   
    }
    
    String[] lineComponents = line.split(":"); 
    int clientIndex = int(lineComponents[0]);
    String command = lineComponents[1]; 
    String data = lineComponents[2];
    
    /*** IMAGEID **/ 
    if(command.equals(MSG_IMAGEID)){                  
      if(isClient()){
        setRequestedToFetchNextImage(true, data);     
      }
            
      Pair p = config.getPairWithIndex(clientIndex);
      p.hostAddress = ipAddress;
      
      println("Updating Pair " + p.index + " image id " + data);
      
      p.currentImageId = data;
      if(isServer()){
        p.setWaitingForImage(false);   
      } 
    }
    
    /*** ANIMSTATE **/ 
    else if(command.equals(MSG_ANIMATION_STATE)){            
      Pair p = config.getPairWithIndex(clientIndex);
      p.hostAddress = ipAddress;
        
      println("Updating Pair " + p.index + " animation state");
        
      p.currentAnimationState = int(data);                  
    }
    
    /*** ACTION **/ 
    else if(command.equals(MSG_ACTION)){      
      Pair p = config.getPairWithIndex(clientIndex);
      p.hostAddress = ipAddress;
        
      println("Updating Pair " + p.index + " animation state");
        
      p.currentAction = int(data);
      setRequestedToTransitionToNextImage(true);      
    }
    
    /*** HI **/ 
    else if(command.equals("HI")){
      Pair p = config.getPairWithIndex(clientIndex);
      p.hostAddress = ipAddress;      
    }
  }
  
  public int getPIIndex(){
    return config.piIndex;   
  }
  
  public boolean isClient(){
    return client != null;   
  }
  
  public boolean isServer(){
    return server != null;   
  }
  
  public boolean isConnected(){
    if(getPIIndex() == 0){
      return server != null && server.active();
    } else{
      return client != null && client.active();   
    }
  }
}