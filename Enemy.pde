class Enemy extends Player {
  int kind;
  PImage [] eneL = new PImage[4];
  PImage [] eneR = new PImage[4];

  Enemy(int ex, int ey, int num, int _kind) {
    super(ex, ey, num);
    kind = _kind;
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
      image(dead, posX, posY, 16*n, 16*n);
    } else if (touch==true) {
      if (isFacingRight) {
        image(eneR[time%4], posX, posY, 16*n, 16*n);
      } else {
        image(eneL[time%4], posX, posY, 16*n, 16*n);
      }
    } else {
      if (isFacingRight) {
        image(eneR[1], posX, posY, 16*n, 16*n);
      } else {
        image(eneL[1], posX, posY, 16*n, 16*n);
      }
    }
  }
}