class Item {
  int posX, posY;
  PImage img;
  int n, kind, time;
  boolean touch;

  Item(int x, int y, int num, int _kind) {
    n=num;
    posX=x*16*n;
    posY=y*16*n+32*n;
    kind = _kind;
    time = 0;
    touch = true;
    switch(kind) {
    case 0:
      img=loadImage("stone.png");
      break;
    case 1:
      img=loadImage("amethyst.png");
      break;
    default:
      break;
    }
    kind = _kind;
  }

  void display() {
    image(img, posX, posY, img.width*n, img.height*n);
  }

  boolean isItem(int _x, int _y) {
    //キャラとのあたり判定用
    if (dist(_x, _y, posX+8*n, posY+8*n)<=12*n) {
      return true;
    }
    return false;
  }

  void move(int floor) {
    println("posY "+posY);
    println("floor "+floor);
    if (posY<floor) {
      if (touch) {
        time = 0;
        touch = false;
      }
      posY+=n*9.8*time/10;
      if (posY>floor) {
        posY = floor;
        time = 0;
      }
    } else {
      touch = true;
    }
  }
}