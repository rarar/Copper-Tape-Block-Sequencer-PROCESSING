import processing.serial.*;
import controlP5.*;
import oscP5.*;
import netP5.*;
import java.util.*;

Cell[][] grid;
Cell selectorSlot;


int cols = 4;
int rows = 1;
int starttime;
int delaytime = 2000;
float volume = 1;
float attack = 0.01;
float decay, sustain, release = 1;
float steps = 4;
int curtime;  
float count_up;
float count_down;
int steptimer;
int oldsteptimer = 0;
boolean play = false;

int CELL_DIVIDE = 100;

OscP5 oscP5;
NetAddress myRemoteLocation;

ControlP5 cp5;
Knob delayTimeKnob;
Knob volumeKnob;
Knob attackKnob;
Knob releaseKnob;
Knob stepsKnob;

Button storeButton;
Button removeButton;

DropdownList samplesList;
DropdownList envelopeTypeList;
DropdownList sequenceList;
String[] sampleFileNames;
String[] envelopeTypes = {
  "perc", "sine", "triangle"
};

// let's store a referrence to the current sample index
int currentSampleIndex = 0;
int currentEnvelopeType = 0;

// sequence storage
int storedSequenceCount = 0;
int currentStoredSequence = 0;

// Arduino stuff
Serial arduinoPort;
int[] switchVals = {
  0, 0, 0, 0, 0
};

int[] oldSwitchVals = {
  0, 0, 0, 0, 0
};

int selectorVal, oldSelectorVal = 0;

boolean canUpdate = false;

void setup() {
  size(600, 400);
  grid = new Cell[cols][rows];
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      println("creating grid " + i + ", " + j);
      grid[i][j] = new Cell(i*CELL_DIVIDE + 50, j*CELL_DIVIDE + 20, CELL_DIVIDE, CELL_DIVIDE);
    }
  }

  selectorSlot = new Cell(350, 250, CELL_DIVIDE, CELL_DIVIDE);

  setUpOSC();
  setUpControl();
  setUpArduino();
}

void setUpArduino() {
  println(Serial.list());
  arduinoPort = new Serial(this, Serial.list()[1], 9600);
  arduinoPort.bufferUntil(10); // line feed ASCII
}



void serialEvent(Serial arduinoPort) {
  while (arduinoPort.available () > 0 ) {

    String inString = arduinoPort.readStringUntil(10);
    inString = trim(inString);
    String[] splitString = split(inString, ",");
    switch (inString.charAt(0)) {
    case 'S': // we've got new switch data
      println("we've got new switch stuff");
      if (splitString.length >= 6) {
        for (int i = 0; i < switchVals.length; i++) {
          switchVals[i] = Integer.parseInt(splitString[i+1]);
        }
        selectorVal = Integer.parseInt(splitString[5]);
        try {
          readSwitches();
        } 
        catch(Exception e) {
          println("we've got an error!");
        }
      }
      break;
    case 'R': // rotary encoder data here
      if (splitString.length >= 3 && canUpdate) {
        int rotaryVal = Integer.parseInt(splitString[2]);
        if (Integer.parseInt(splitString[1])==1) {
          println("current sample will be " + rotaryVal);
          samplesList.setIndex(rotaryVal);
          samplesList.setColorBackground(color(255, 0, 0));
          envelopeTypeList.setColorBackground(color(60));
          sequenceList.setColorBackground(color(60));
        } 
        else if (Integer.parseInt(splitString[1])==2) {
          println("current sequence will be " + rotaryVal);
          sequenceList.setIndex(rotaryVal % storedSequenceCount);
          sequenceList.setColorBackground(color(255, 0, 0));
          envelopeTypeList.setColorBackground(color(60));
          samplesList.setColorBackground(color(60));
        }
        else {
          println("button push = " + Integer.parseInt(splitString[1]));
          println("current envelope type index will be " + (rotaryVal % envelopeTypes.length));
          envelopeTypeList.setIndex(rotaryVal % envelopeTypes.length);
          envelopeTypeList.setColorBackground(color(255, 0, 0));
          samplesList.setColorBackground(color(60));
          sequenceList.setColorBackground(color(60));
        }
      }
      break;
    }
  }
}

void setUpControl() {
  cp5 = new ControlP5(this);

  delayTimeKnob = cp5.addKnob("delaytime")
    .setRange(50, 5000)
      .setValue(2000)
        .setPosition(50, 150)
          .setRadius(25)
            .setDragDirection(Knob.VERTICAL)
              ;
  volumeKnob = cp5.addKnob("volume")
    .setRange(0, 1)
      .setValue(1)
        .setPosition(150, 150)
          .setRadius(25)
            .setDragDirection(Knob.VERTICAL)
              ;

  attackKnob = cp5.addKnob("attack")
    .setRange(0, 1.5)
      .setValue(0.01)
        .setPosition(50, 250)
          .setRadius(25)
            .setDragDirection(Knob.VERTICAL)
              ;

  releaseKnob = cp5.addKnob("release")
    .setRange(0, 1.5)
      .setValue(1)
        .setPosition(150, 250)
          .setRadius(25)
            .setDragDirection(Knob.VERTICAL)
              ;
              
  stepsKnob = cp5.addKnob("steps")
    .setRange(1, 4)
      .setValue(4)
                     .setNumberOfTickMarks(3)
               .setTickMarkLength(4)
               .snapToTickMarks(true)
        .setPosition(100, 325)
          .setRadius(25)
            .setDragDirection(Knob.VERTICAL)
              ;


  sequenceList = cp5.addDropdownList("sequenceList")
    .setPosition(280, 232)
      .setSize(200, 200);

  customizeDDList(sequenceList, "sequences", 0);

  envelopeTypeList = cp5.addDropdownList("envelopeTypeList")
    .setPosition(280, 200)
      .setSize(200, 200);

  customizeDDList(envelopeTypeList, "envelope", 1);

  samplesList = cp5.addDropdownList("samplesList")
    .setPosition(280, 168)
      .setSize(200, 200);

  customizeDDList(samplesList, "samples", 2);

  // Store Button
  // create a new button with name 'buttonA'
  storeButton = cp5.addButton("store")
    .setValue(0)
      .setPosition(500, 20)
        .setSize(30, 30)
          ;
  storeButton.setColorBackground(color(60, 90, 255));

  // Store Button
  // create a new button with name 'buttonA'
  removeButton = cp5.addButton("remove")
    .setValue(0)
      .setPosition(500, 90)
        .setSize(40, 30)
          ;
  removeButton.setColorBackground(color(255, 90, 90));

  // here's where we load all the sample files into the dropdown
  loadSampleFiles();
  loadEnvelopeTypes();
  //loadSequences();
}

// function colorA will receive changes from 
// controller with name colorA
public void store(int theValue) {
  // ADD CURRENT SEQUENCE IN DROPDOWN LIST
  if (frameCount > 1) {
    sequenceList.addItem("Sequence " + storedSequenceCount, storedSequenceCount);
    storedSequenceCount++;
  }
}

public void remove(int theValue) {
  if (frameCount > 1) {
    sequenceList.removeItem("Sequence " + currentStoredSequence);
    sequenceList.setCaptionLabel("sequences"  );
    storedSequenceCount--;
    if (storedSequenceCount < 0 ) storedSequenceCount = 0;
    currentStoredSequence = int(sequenceList.getValue());
  }
}

void customizeDDList(DropdownList ddl, String title, int id) {
  ddl.setId(id);
  ddl.setBackgroundColor(color(190));
  ddl.setItemHeight(20);
  ddl.setBarHeight(15);
  ddl.captionLabel().set(title);
  ddl.captionLabel().style().marginTop = 3;
  ddl.captionLabel().style().marginLeft = 3;
  ddl.valueLabel().style().marginTop = 3;
  ddl.setColorBackground(color(60));
  ddl.setColorActive(color(255, 128));
}

// let's set a filter (which returns true if file's extension is .jpg)
java.io.FilenameFilter samplesFilter = new java.io.FilenameFilter() {
  boolean accept(File dir, String name) {
    return name.toLowerCase().endsWith(".wav");
  }
};

void loadSampleFiles() {
  java.io.File folder = new java.io.File(dataPath("/Users/rarar/samples"));
  sampleFileNames = folder.list(samplesFilter);
  println(sampleFileNames.length + " samples in the sample directory!");
  for (int i = 0; i < sampleFileNames.length; i++) {
    samplesList.addItem(sampleFileNames[i], i);
  }
}

void loadEnvelopeTypes() {
  for (int i = 0; i < envelopeTypes.length; i++) {
    envelopeTypeList.addItem(envelopeTypes[i], i);
  }
}

void controlEvent(ControlEvent theEvent) {
  // DropdownList is of type ControlGroup.
  // A controlEvent will be triggered from inside the ControlGroup class.
  // therefore you need to check the originator of the Event with
  // if (theEvent.isGroup())
  // to avoid an error message thrown by controlP5.
  println("control id = " + theEvent.getId());
  if (theEvent.isGroup()) {
    switch(theEvent.getId()) {
    case 0:
      currentStoredSequence = int(theEvent.getGroup().getValue());
      println("got from sequencelist!");
      break;
    case 1:
      currentEnvelopeType = int(theEvent.getGroup().getValue());
      //println("got from envelope!");
      break;
    case 2:
      currentSampleIndex = int(theEvent.getGroup().getValue());
      //println("got from samples!");
      break;
    default:
      //println("nothing found");
      break;
    }
    println("retrieved item "+ int(theEvent.getGroup().getValue()) +" from "+theEvent.getGroup());
  }
}

void setUpOSC() {
  // start oscP5, telling it to listen for incoming messages at port 5001 */
  oscP5 = new OscP5(this, 57120);

  // set the remote location to be the localhost on port 5001
  myRemoteLocation = new NetAddress("localhost", 57120);
}

void draw() {
  background(0);

  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      if ((i & 1) == 0) {
        // even rows white
        grid[i][j].display(255);
      } 
      else {
        // odd rows gray
        grid[i][j].display(220);
      }
    }

    selectorSlot.display(255);

    if (play == true) {
      int j;
      if (millis() - starttime < delaytime) {      
        count_up = (millis() - starttime);
        count_down = delaytime - count_up;
        steptimer = floor(steps / (delaytime / count_up));     
        fill(0);
        textSize(12);
        text(steptimer, mouseX, mouseY);
        for (j = 0; j < rows; j++) {
          grid[steptimer][j].display(120);
          grid[steptimer][j].trigger(steptimer, j);
          if (steptimer != oldsteptimer) {
            grid[steptimer][j].sendMessage();
          }
        }
      } 
      else {
        starttime = millis();
        j = 0;
      }
      oldsteptimer = steptimer;
    }
  }

  // turn off buttons
  toggleButtons();
}

void toggleButtons() {
  if (storedSequenceCount < 1) {
    removeButton.setColorBackground(color(150));
    removeButton.setLock(true);
  } 
  else {
    removeButton.setLock(false); 
    removeButton.setColorBackground(color(255, 90, 90));
  }
}

void readSwitches() {

  if (selectorVal != oldSelectorVal) {
    selectorSlot.pressed();
    if (selectorSlot.getActive()) {
      println("we can update values!!");
      canUpdate = true;
    } 
    else {
      println("NO VALUE UPDATING");
      canUpdate = false;
      disableControls();
    }
  }


  for (int i = 0; i < switchVals.length-1; i++) {
    if (switchVals[i] != oldSwitchVals[i]) {
      grid[i][0].setSampleIndex(currentSampleIndex);
      grid[i][0].setEnvelopeType(currentEnvelopeType);
      grid[i][0].setVolume(volume);
      grid[i][0].setAttack(attack);
      grid[i][0].setDecay(decay);
      grid[i][0].setSustain(sustain);
      grid[i][0].setRelease(release);
      grid[i][0].pressed();
    }
  }


  oldSelectorVal = selectorVal;
  arrayCopy(switchVals, oldSwitchVals);
}

void disableControls() {
  samplesList.setColorBackground(color(60));
  envelopeTypeList.setColorBackground(color(60));
}

void mousePressed() {
  if (mouseButton == RIGHT) {
    starttime = millis(); 
    if (play == true) { 
      play = false;
    }
    else { 
      play = true;
    }
  }
}

