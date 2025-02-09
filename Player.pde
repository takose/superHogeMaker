class Player {
  int time, posX, posY, speedX, speedY, killTime;
  PImage [] walkR=new PImage[6];  //歩き右向き
  PImage [] walkL=new PImage[6];  //歩き左向き
  PImage [] jumpR=new PImage[2];  //ジャンプ右向き
  PImage [] jumpL=new PImage[2];  //ジャンプ左向き
  PImage [] throwR=new PImage[2];
  PImage [] throwL=new PImage[2];
  PImage dead;  //死に顔
  int size, n;
  int beforeFloor;
  boolean touch;  //床についてるか(jump中はtrue)
  boolean isFacingRight;  //どっち向いてるか(右でtrue)
  boolean alive, finish;  //生死
  boolean right, left, jumping;  //左右に進んでいるか
  boolean throwing;

  Player(int x, int y, int s, int _n) {
    n = _n;
    size = s;
    touch=false;
    alive=true;
    finish=false;
    posX=x;
    posY=y;
    speedX=2;
    speedY=9;
    time=0;
    isFacingRight=true;
    throwing=false;

    PImage _walkR=loadImage("walkR.png");
    for (int i=0; i<4; i++) {
      walkR[i]=_walkR.get(16*i, 0, 16, 16);
    }
    walkR[4]=walkR[2];
    walkR[5]=walkR[1];

    PImage _walkL=loadImage("walkL.png");
    for (int i=0; i<4; i++) {
      walkL[i]=_walkL.get(16*i, 0, 16, 16);
    }
    walkL[4]=walkL[2];
    walkL[5]=walkL[1];

    jumpR[0]=loadImage("jumpR1.png");
    jumpR[1]=loadImage("jumpR2.png");

    jumpL[0]=loadImage("jumpL1.png");
    jumpL[1]=loadImage("jumpL2.png");

    throwR[0]=loadImage("throwR1.png");
    throwR[1]=loadImage("throwR2.png");

    throwL[0]=loadImage("throwL1.png");
    throwL[1]=loadImage("throwL2.png");

    dead=loadImage("dead.png");
  }





  void move(int floor) {
    //落下時
    if (posY<floor) {
      //歩いてて床がなくなって落下する時time初期化
      if (touch && !jumping) {
        time=0;
        touch=false;
      }
      down();


      //着地判定 着地してから次のジャンプができるように
      //この条件分岐はjumpをfalseにしてしまうので，
      //着地直後に一回だけ呼び出したい
      //よってこの次のelseじゃなくてここに書く

      if (posY>floor) {
        posY=floor;
        time=0;
        jumping=false;
      }
    } else {
      touch=true;
    }

    if (throwing && time>3) {
      throwing = false;
    }
  }

  void moveRight() {
    posX+=speedX*n;
  }

  void moveLeft() {
    posX-=speedX*n;
  }

  void down() {
    posY+=n*11*time/10;
  }

  void jump() {
    if (time>1) {
      posY-=speedY*n;
    }
  }

  void draw() {
    if (!alive) {
      image(dead, posX, posY, size, size);
    } else if (jumping) {
      if (isFacingRight) {
        if (time<=1) {
          image(jumpR[0], posX, posY, size, size);
        } else {
          image(jumpR[1], posX, posY, size, size);
        }
      } else {
        if (time<=1) {
          image(jumpL[0], posX, posY, size, size);
        } else {
          image(jumpL[1], posX, posY, size, size);
        }
      }
    } else if (left && !right) {
      isFacingRight=false;
      image(walkL[time%6], posX, posY, size, size);
    } else if (right && !left) {
      isFacingRight=true;
      image(walkR[time%6], posX, posY, size, size);
    } else if (throwing) {
      if (isFacingRight) {
        if (time<=1) {
          image(throwR[0], posX, posY, size, size);
        } else {
          image(throwR[1], posX, posY, size, size);
        }
      } else {
        if (time<=1) {
          image(throwL[0], posX, posY, size, size);
        } else {
          image(throwL[1], posX, posY, size, size);
        }
      }
    } else {
      if (isFacingRight) {
        image(walkR[2], posX, posY, size, size);
      } else {
        image(walkL[2], posX, posY, size, size);
      }
    }
  }
}