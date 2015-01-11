class Cell {
  float x, y;
  float w, h;
  boolean active = false;
  int sampleIndex;
  int envelopeType;
  float volume;
  float attack;
  float decay;
  float sustain;
  float release;

  Cell(float tempX, float tempY, float tempW, float tempH) {
    x = tempX;
    y = tempY;
    w = tempW;
    h = tempH;
    sampleIndex = 0;
    envelopeType = 0;
    volume = 1;
    attack = 0.01;
    decay = 1;
    sustain = 1;
    release = 1;
  }

  void display( int step ) {
    stroke(0);

    if (active == true) {
      fill(255, 0, 0);
    } 
    else {
      fill(step);
    }

    rect(x, y, w, h);
    fill(255);
  }

  void pressed() {
    if (active == true) { 
      active = false;
    }
    else { 
      active = true;
    }
  }

  void trigger(int x, int y) {
    int y2;
    y2 = y+1;
    textSize(24);
    if (active == true) {
      text(x + "::" + y, 420, y2*CELL_DIVIDE);
    }
  }

  void sendMessage() {
    if (active==true) {
      // send OSC message!
      println("sample index val = " + sampleIndex);
      OscMessage myMessage = new OscMessage("/sequencer");
      myMessage.add("true");
      myMessage.add(sampleIndex);
      myMessage.add(envelopeType);
      myMessage.add(volume);
      myMessage.add(attack); // msg[5]
      myMessage.add(decay); // msg[6]
      myMessage.add(sustain); // msg[7]
      myMessage.add(release); //msg[8]

      /* send the message */
      oscP5.send(myMessage, myRemoteLocation);
    } 
    else {
      println("cell is not active");
    }
  }
  
  boolean getActive() {
    return active; 
  }
  
  void setActive(boolean val) {
    active = val; 
  }

  int getSampleIndex() {
    return sampleIndex;
  }

  void setSampleIndex(int val) {
    sampleIndex = val;
    println("sample index = " + sampleIndex);
  }

  int getEnvelopeType() {
    return envelopeType;
  }

  void setEnvelopeType(int val) {
    envelopeType = val;
    println("envelope type = " + envelopeType);
  }

  float getVolume() {
    return volume;
  }

  void setVolume(float val) {
    volume = val;
  }

  float getAttack() {
    return attack;
  }

  void setAttack(float val) {
    attack = val;
  }

  float getDecay() {
    return decay;
  }

  void setDecay(float val) {
    decay = val;
  }

  float getSustain() {
    return sustain;
  }

  void setSustain(float val) {
    sustain = val;
  }

  float getRelease() {
    return release;
  }

  void setRelease(float val) {
    release = val;
  }
}

