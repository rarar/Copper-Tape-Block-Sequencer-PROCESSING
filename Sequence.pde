class Sequence {
  int sequenceSize;
  int delayTime;
  Cell[] cells;
  
  
  Sequence(int size) {
    int sequenceSize = size;
    cells = new Cell[size];
  }
 
  void setSize(int s) {
    sequenceSize = s;
  } 
}
