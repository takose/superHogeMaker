class Enemy extends Player {
  int kind, killTime;
  PImage [] eneL = new PImage[4];
  PImage [] eneR = new PImage[4];

  Enemy(int posX, int posY, int size, int n, int _kind) {
    super(posX, posY, size, n);
    kind = _kind;
    speedX = 1;
    if (kind==0) {
      PImage _eneL = loadImage("walkEneL.png");
      PImage _eneR = loadImage("walkEneR.png");
      for (int i=0; i<3; i++) {
        eneL[i] = _eneL.get(16*i, 0, 16, 16);
        eneR[i] = _eneR.get(16*i, 0, 16, 16);
      }
      eneL[3] = eneL[1];
      eneR[3] = eneR[1];
      dead = loadImage("walkEneDead.png");
    } else {
      for (int i=0; i<3; i++) {
        eneL[i] = loadImage("ghostL.png");
        eneR[i] = loadImage("ghostR.png");
      }
      eneL[3] = loadImage("ghostL2.png");
      eneR[3] = loadImage("ghostR2.png");
      dead = loadImage("ghostDead.png");
    }
    isFacingRight = false;  //あそぶモードでは全部左向きのため
  }

  void draw() {
    if (!alive) {
      image(dead, posX, posY, dead.width*n, dead.height*n);
    } else if (touch==true) {
      if (isFacingRight) {
        image(eneR[time%4], posX, posY, eneR[time%4].width*n, eneR[time%4].height*n);
      } else {
        image(eneL[time%4], posX, posY, eneL[time%4].width*n, eneL[time%4].height*n);
      }
    } else {
      if (isFacingRight) {
        image(eneR[1], posX, posY, eneR[1].width*n, eneR[1].height*n);
      } else {
        image(eneL[1], posX, posY, eneR[2].width, eneL[1].height*n);
      }
    }
  }
}