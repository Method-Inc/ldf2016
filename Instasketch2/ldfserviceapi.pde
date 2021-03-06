

boolean isFetchingImage(){
  return ldfService == null || ldfService.isFetchingImage(); 
}
 
void asyncFetchNextImage(){
  ldfService.fetchNextImage(); 
}

class LDFServiceAPI{
  
  public int imageCounter = 0; 
  
  boolean logging = true; 
   
  boolean fetchingImage = false; 
  float lastImageTimestamp = 0.0f;
  
  PImage colourisedImage;
  PImage fullColourImage;
  
  PImage sampleImage;
  
  ImageDetails imageDetails; 
  
  int cachedImageWidth; 
  int cachedImageHeight; 
  
  String getImageId = null; 
  
  LDFServiceAPI(int cachedImageWidth, int cachedImageHeight){
    this.cachedImageWidth = cachedImageWidth; 
    this.cachedImageHeight = cachedImageHeight;       
  }
  
  private void initCachedImages(int cachedImageWidth, int cachedImageHeight){
    colourisedImage = createImage((int)cachedImageWidth, (int)cachedImageHeight, RGB);  
    fullColourImage = createImage((int)cachedImageWidth, (int)cachedImageHeight, RGB);
  }
  
  float getTimeSinceLastImageUpdate(){
    return millis() - lastImageTimestamp;  
  }
  
  boolean isFetchingImage(){
    return fetchingImage;  
  }
  
  void setFetchingImage(boolean val){
    fetchingImage = val; 
  }
  
  boolean requestNextImage(){
    return requestNextImage(null); 
  }
  
  boolean requestNextImage(String imageId){
    if (isFetchingImage()) {
      return false;
    }  
    
    getImageId = imageId; 
  
    setFetchingImage(true);   
    thread("asyncFetchNextImage");
    
    return true; 
  }
  
  void fetchNextImage() {
    log("--- fetchNextImage ---");
    
    initCachedImages(cachedImageWidth, cachedImageHeight);
    
    String url = "";
    
    if(configManager.isMaster()){ // only the MASTER progresses through the queue, the others (SLAVES) just pull down the current image. 
      url = URL_POP + "?pi_index=" + configManager.piIndex;  
    } else{
      if(getImageId != null){
        url = URL_GET_IMAGE + "?pi_index=" + configManager.piIndex + "&image_id=" + getImageId;
      } else{
        url = URL_PEEK + "?pi_index=" + configManager.piIndex;  
      }      
    }
    log("POSTING: " + url);
    
    JSONObject responseJSON = null; 
    
    try{
      responseJSON = loadJSONObject(url);
    } catch(Exception e){
      println("Exception while trying to get image details " + e.getMessage()); 
    }
    
    if(responseJSON == null){
      setFetchingImage(false);
      onImageFetchFailed(this); 
      return; 
    }   
      
    imageDetails = new ImageDetails(responseJSON.getJSONObject("next_image"), configManager.piIndex);         
    
    boolean successfullyDownloadedImage = false; 
    
    try{
      successfullyDownloadedImage = fetchAndSetImage(imageDetails);  
    } catch(Exception e){
      println("Exception while calling fetchAndSetImage " + e.getMessage());
      successfullyDownloadedImage = false; 
    }
    
    if(!successfullyDownloadedImage){
      onImageFetchFailed(this);
      setFetchingImage(false);
      return;  
    }
    
    boolean successfullyDownloadedColourisedImage = false; 
    
    try{      
      successfullyDownloadedColourisedImage = fetchAndSetColoursiedImage(imageDetails);
    } catch(Exception e){
      println("Exception while calling fetchAndSetColoursiedImage " + e.getMessage());
      successfullyDownloadedColourisedImage = false;
    }
    
    if(!successfullyDownloadedColourisedImage){
      onImageFetchFailed(this);
      setFetchingImage(false);      
      return;
    }
    
    // now resize to be used as the source for the new pixels 
    sampleImage = colourisedImage.copy(); 
    sampleImage.resize(configManager.resolutionX, configManager.resolutionY);        
    
    lastImageTimestamp = millis();
    imageCounter += 1;
    
    onImageFetchComplete(this);
    
    getImageId = null; 
    
    setFetchingImage(false);        
  } 
  
  String getColourName(){
      if(imageDetails == null) return "";
      
      return imageDetails.myColourName;
  }
  
  color getColour(){
      if(imageDetails == null) return color(255, 255, 255); 
      
      return imageDetails.myColour;
  }  
  
  String getImageId(){
    if(imageDetails == null) return "";
    
    return imageDetails.getImageId(); 
  }
  
  private void log(String message){
    if(logging){
      println(message);   
    }
  }
  
  private boolean fetchAndSetImage(ImageDetails imageDetails){  
    // call the colourise service imageDetails){
    String imageUrl = imageDetails.getImageSrc();
    log("POSTING: " + imageUrl); 
    
    PImage image = loadImage(imageUrl, "jpg");
    
    if(image == null){
      return false;   
    }
    
    // resize image to fill fit the screen 
    float imageScale = 1.0f;   
    
    if(fullColourImage.width > fullColourImage.height){
      imageScale = (float)fullColourImage.width/(float)image.width;   
    } else{
      imageScale = (float)fullColourImage.height/(float)image.height;   
    }
    
    image.resize((int)(image.width * imageScale), (int)(image.height * imageScale));
    
    int ox = (int)(((float)fullColourImage.width - (float)image.width)*0.5f);
    int oy = (int)(((float)fullColourImage.height - (float)image.height)*0.5f);
    
    for(int y=0; y<fullColourImage.height; y++){
      for(int x=0; x<fullColourImage.width; x++){
        int sourceIndex = (y * fullColourImage.width) + x;
        int nextIndex = ((y - oy) * image.width) + (x + ox); 
        
        if(y < 0 || y >= fullColourImage.height || x < 0 || x >= fullColourImage.width){            
          continue; 
        }
        
        if((x + ox) < 0 || (x + ox) >= image.width || (y - oy) < 0 || (y - oy) >= image.height){
          fullColourImage.pixels[sourceIndex] = color(255, 255, 255);
          continue;   
        }            
        
        fullColourImage.pixels[sourceIndex] = image.pixels[nextIndex];             
      }
    }
    fullColourImage.updatePixels();  
    
    println("finished fetchAndSetImage"); 
    
    return true; 
  }
  
  private boolean fetchAndSetColoursiedImage(ImageDetails imageDetails){
    // call the colourise service 
    String colouriseUrl = URL_COLOURISED_IMAGE + "?image_url=" + imageDetails.getImageSrc() + "&colours=5" + "&swatch_index=" + configManager.piIndex + "&image_id=" + imageDetails.getImageId();
    log("POSTING: " + colouriseUrl); 
    
    PImage image = loadImage(colouriseUrl, "jpg");
    
    if(image == null){
      println("Error occured while trying to pull down latest image");
      return false;   
    }
    
    // resize image to fill fit the screen 
    float imageScale = 1.0f;   
    
    if(colourisedImage.width > colourisedImage.height){
      imageScale = (float)colourisedImage.width/(float)image.width;   
    } else{
      imageScale = (float)colourisedImage.height/(float)image.height;   
    }
    
    image.resize((int)(image.width * imageScale), (int)(image.height * imageScale));
    
    int ox = (int)(((float)colourisedImage.width - (float)image.width)*0.5f);
    int oy = (int)(((float)colourisedImage.height - (float)image.height)*0.5f);
    
    for(int y=0; y<colourisedImage.height; y++){
      for(int x=0; x<colourisedImage.width; x++){
        int sourceIndex = (y * colourisedImage.width) + x;
        int nextIndex = ((y - oy) * image.width) + (x + ox); 
        
        if(y < 0 || y >= colourisedImage.height || x < 0 || x >= colourisedImage.width){            
          continue; 
        }
        
        if((x + ox) < 0 || (x + ox) >= image.width || (y - oy) < 0 || (y - oy) >= image.height){
          colourisedImage.pixels[sourceIndex] = color(255, 255, 255);
          continue;   
        }            
        
        colourisedImage.pixels[sourceIndex] = image.pixels[nextIndex];             
      }
    }
    colourisedImage.updatePixels();  
    
    println("Finished fetchAndSetColoursiedImage"); 
    return true; 
  }
}