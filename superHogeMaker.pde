import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;

import processing.serial.*;

Serial serial;
Minim minim;

AudioPlayer bgm;
AudioPlayer jumpSound, fin, brokenSound, itemSound, itemGet, gameover, crush, button, hitEne, addBlock;

//モード共通で使う変数
int n;  //拡大倍率
int m=3;  //背景の枚数。ステージの長さ
int page;  //どの画面にいるか
int backX;  //背景X座標
PImage [] back=new PImage[m];  //背景
PImage title, start, play, make, battle, returnButton;  //タイトルと各種ボタン
PImage howto1, howto2;
Block block;

//あそぶモード用変数
PImage goal, stageClear;  //ゴールの旗、クリア文字
int eneNumber;  //敵出現タイミング・数管理
Player player;
ArrayList<Item> items;
ArrayList<Enemy> enemy;
ArrayList<int[]> broken;  //こわれたブロック

//つくるモード用変数
boolean move;  //画面表示の移動フラグ

//対戦モード用変数
Block block2;  //対戦用のブロック配列
int boardPoint, boardCount, oldBoardCount, comp, playerPoint, pointValueB, pointValueP;  //それぞれのポイント
PImage [] numbers = new PImage[10];  //数字
PImage clock, pointP, pointB, win_b, win_p, tie;  //アイコン、勝敗
int startTime, remainTime, timeLimit;
String oldstr;

void settings() {
  if (displayHeight*20/12 < displayWidth) {
    n = displayHeight / (16 * 12);
  } else {
    n = displayWidth / (16 * 20);
  }
  size(320*n, 192*n);
  noSmooth();  //ぼかさない処理
}

void setup() {
  frameRate(30);

  //シリアル
  if (Serial.list().length>0) {
    println("serial="+Serial.list());
    serial=new Serial(this, Serial.list()[0], 9600);
    serial.write('a');
  }

  minim = new Minim( this );
  bgm = minim.loadFile( "BGM.mp3" );
  jumpSound = minim.loadFile("jump01.mp3");
  fin = minim.loadFile("fin.mp3");
  brokenSound = minim.loadFile("broken.mp3");
  itemSound = minim.loadFile("nyu2.mp3");
  itemGet = minim.loadFile("decision-3.mp3");
  gameover = minim.loadFile("gameover.mp3");
  crush = minim.loadFile("crushed.mp3");
  button = minim.loadFile("decision3.mp3");
  hitEne = minim.loadFile("cancel6.mp3");
  addBlock = minim.loadFile("button40.mp3");

  title=loadImage("title.png");
  start=loadImage("startButton2.png");
  play=loadImage("playButtonBig.png");
  make=loadImage("makeButtonBig.png");
  battle=loadImage("battle1.png");
  returnButton=loadImage("returnButton2.png");
  back[0]=loadImage("GameBackground4.png");
  for (int i=0; i<back.length; i++) {
    back[i]=back[0];
  }
  howto1 = loadImage("howtoplay.png");
  howto2 = loadImage("howtoplay2.png");
  goal=loadImage("flag2.png");
  stageClear=loadImage("stageClear.png");
  PImage num = loadImage("numbers_line.png");
  for (int i=0; i<10; i++) {
    numbers[i] = num.get(8*i, 0, 8, 16);
  }
  clock = loadImage("clock2.png");
  pointP = loadImage("walk1BW.png");
  pointB = loadImage("block1BW.png");
  win_b = loadImage("win_b.png");
  win_p = loadImage("win_p.png");
  tie = loadImage("tie.png");

  block = new Block(m, n);
  player=new Player(100, 10, n);
  items= new ArrayList<Item>();
  enemy= new ArrayList<Enemy>();
  broken=new ArrayList<int[]>();

  block2 = new Block(1, n);
  pointValueB = 15;
  pointValueP = 25;

  initialize();
}


void draw() {
  println(frameRate);

  switch(page) {

  case 0:
    //スタート画面
    image(back[0], 0, 0, width, height);
    image(title, width/2-title.width*n/2, 16*3*n, title.width*n, title.height*n);
    image(start, width/2-64*n/2, 16*7*n, 64*n, 16*n);
    break;

  case 1:
    //モード選択画面
    image(back[0], 0, 0, width, height);
    image(play, 16*2*n, 16*4*n, 48*n, 32*n);
    image(battle, 16*7*n, 16*4*n, 16*6*n, 32*n);
    image(make, 16*15*n, 16*4*n, 48*n, 32*n);
    image(returnButton, width/2-64*n/2, 16*8*n, 64*n, 16*n);
    break;

  case 2:
    //あそぶモード


    //キャラの動きに合わせてスクロール
    if (player.posX>-backX+500 && player.right && backX>-width*(m-1)-48*n ) {
      backX-=player.speedX*n;
    }

    //背景描画
    for (int i=0; i<back.length; i++) {
      image(back[i], backX+width*i, 0, width, height);
    }
    image(goal, backX+width*m, 0, 48*n, height);

    if (!bgm.isPlaying()&&player.alive) {
      bgm.rewind();
      bgm.play();
    }

    pushMatrix();
    translate(backX, 0);


    for (int[] b : broken) {
      /*
      壊れたブロック消滅の時間を計る。
       b[0],b[1]でブロックの座標、
       b[2]で叩かれてからの時間を保存している。
       */
      b[2]++;
      if (b[2]>6) {
        block.brick[b[0]][b[1]]=0;
        broken.remove(b);
        break;
      }
    }
    block.display();


    if (frameCount%3==0) {
      //キャラ・敵の落下用にtimeを増やす
      player.time++;
      for (Enemy e : enemy) {
        e.time++;
      }
    }


    //キャラ移動など

    if (player.right && player.posX<width*m+32*n && !block.isRight(player.posX+16*n, player.posY+14*n)) {
      player.moveRight();

      //キャラが一定座標まで来たら敵を出現
      if (player.posX+16*n>eneNumber*width && eneNumber<m) {
        //空からor地上から
        int eneY=(int)random(2);
        if (eneY==1) {
          eneY=height-48*n;
        }
        enemy.add(new Enemy((int)random(width/4, width)+eneNumber*width, eneY, n, (int)random(2)));
        eneNumber++;
      }
      //finish
      if (player.posX>width*m+16*n) {
        player.time=0;
        player.finish=true;
        fin.rewind();
        fin.play();
        stop();
      }
    }

    if (player.left && player.posX>-backX && !block.isLeft(player.posX, player.posY+14*n)) {
      player.moveLeft();
    }

    //床座標取得
    int floor;
    floor = block.isFloor(player.posX+8*n, player.posY+8*n);
    player.move(floor);


    //頭突き判定
    if (block.isTop(player.posX+8*n, player.posY)!=0 && player.jumping) {
      player.touch=false;
      player.jumping=false;
      int []chara=block.squares(player.posX+8*n, player.posY);
      if (block.brick[chara[0]][chara[1]]==2) {
        //アイテムブロックに頭突きしたらアイテム出現
        itemSound.rewind();
        itemSound.play();
        int kind = int(random(2));
        items.add(new Item(chara[0], chara[1], n, kind) );
        block.brick[chara[0]][chara[1]]=3;
      } else if (block.brick[chara[0]][chara[1]]==1) {
        //普通のブロックに頭突きしたらブロック破壊
        brokenSound.rewind();
        brokenSound.play();
        block.brick[chara[0]][chara[1]]=4;
        broken.add(new int[] {
          chara[0], chara[1], 0
          }
          );
      }
    }

    //ジャンプ
    if (player.jumping&&player.touch==true) {
      player.jump();
    }
    player.draw();


    //アイテム
    for (Item i : items) {
      if (i.isItem(player.posX+8*n, player.posY+8*n)) {
        //キャラとぶつかったら使用されて消滅
        itemGet.rewind();
        itemGet.play();
        items.remove(i);
        playerPoint+=pointValueP;
        break;
      }
    }
    /*
      displayとremoveを同じfor文にいれると、
     removeされたときbreakしなければならないため、
     removeされたものより後ろのリストのアイテムが
     一瞬描画されなくなる。なのでfor文を分ける。
     */
    for (Item i : items) {
      i.display();
    }

    //敵
    for (Enemy e : enemy) {
      if (dist(e.posX, e.posY, player.posX, player.posY)<=12*n && e.alive && player.alive) {
        if (player.posY<e.posY && player.alive && e.touch) {
          //キャラのほうが上にいるなら敵消滅
          e.alive=false;
          e.time=0;
          crush.rewind();
          crush.play();
          playerPoint+=pointValueP;
        } else {
          //ゲームオーバー
          gameover.rewind();
          gameover.play();
          player.alive=false;
          player.time=0;
          player.right=false;
          player.left=false;
          player.jumping=false;
          stop();
        }
      }
      if (!e.alive && e.time>4) {
        //踏まれてしばらくしたら消える
        enemy.remove(e);
        break;
      }
      if (e.posX+16*n<0) {
        //ステージ外に行ったら消える
        enemy.remove(e);
        break;
      }
    }
    /*
      アイテムと同じ理由で
     removeとdrawのfor文を別にしている
     */
    for (Enemy e : enemy) {
      int eneFloor=block.isFloor(e.posX+12*n, e.posY);
      e.move(eneFloor);
      if (e.isFacingRight && block.isRight(e.posX+16*n, e.posY+14*n)) {
        e.isFacingRight = false;
      } else
        if (!e.isFacingRight && block.isLeft(e.posX, e.posY+14*n)) {
          e.isFacingRight = true;
        }
      if (e.touch && e.alive) {
        if (e.isFacingRight) {
          e.moveRight();
        } else {
          e.moveLeft();
        }
      }
      e.draw();
    }

    popMatrix();

    //ポイント表示
    image(pointP, 16*n, 11*16*n, 16*n, 16*n);
    drawPoints(2*16*n, 11*16*n, playerPoint, 4);

    //クリア表示
    if (player.finish) {
      image(stageClear, width/2-(stageClear.width/2)*n, 4*16*n, stageClear.width*n, stageClear.height*n);
    }

    /*
    ゲームオーバーから3秒くらいしたら
     初期化してスタート画面へ
     変数増やしたくないのでplayerのtimeで代用
     */
    if (!player.alive && player.time>=30) {
      initialize();
    } else if (player.finish && player.time>=60) {
      initialize();
    }
    break;

    /*-----------------------*/

  case 3:
    //つくるモード

    //画面スクロール(背景の移動)
    if (move) {
      backX-=64;
      if (backX<=-width/2*(block.area-1)) {
        backX=-width/2*(block.area-1);
        move=false;
      }
    }

    //背景描画
    for (int i=0; i<back.length; i++) {
      image(back[i], backX+width*i, 0, width, height);
    }

    //ブロックの情報取得
    if (Serial.list().length>0) {
      if (serial.available()>0 && !move) {
        String str = serial.readStringUntil('e');
        //println(str);
        block.getSerialData_(str);
        serial.write('a');
      } else {
        println("not available");
      }
    }

    pushMatrix();
    translate(backX, 0);

    //ブロック描画
    block.display();

    //編集可能範囲の表示
    noStroke();
    fill(0, 0, 0, 100);
    rect(0, 0, width*m, 16*3*n);
    rect(0, 9*16*n, width*m, 16*3*n);
    fill(0, 0, 0, 30);
    rect((block.area-2)*16*10*n, 3*16*n, 20*16*n, 6*16*n);
    rect((block.area+1)*16*10*n, 3*16*n, 10*16*n, 6*16*n);
    strokeWeight(n);
    stroke(255, 0, 0);
    noFill();
    rect(block.area*10*16*n, 3*16*n, 10*16*n, 6*16*n);

    popMatrix();

    break;


    /*-----------------------*/


  case 4:
    //対戦

    //背景描画
    image(back[0], 0, 0, width, height);

    strokeWeight(n);
    stroke(77, 69, 64, 120);
    noFill();
    rect(5*16*n, 3*16*n, 10*16*n, 6*16*n);

    //ブロック

    //ブロックの情報取得
    if (Serial.list().length>0) {
      if (serial.available()>0 && !move) {
        String str = serial.readStringUntil('e');
        //println(str);
        block2.getSerialData_battle(str);
        serial.write('a');

        //ボード側ポイント処理用
        if (!str.equals(oldstr)) {
          comp++;
        }
        oldstr = str;
      } else {
        println("not available");
      }
    }

    block2.countDown();

    for (int[] b : broken) {
      /*
      壊れたブロック消滅の時間を計る。
       b[0],b[1]でブロックの座標、
       b[2]で叩かれてからの時間を保存している。
       */
      b[2]++;
      if (b[2]>6) {
        block2.brick[b[0]][b[1]]=0;
        broken.remove(b);
        break;
      }
    }
    block2.display();


    if (!bgm.isPlaying()&&player.alive) {
      bgm.rewind();
      bgm.play();
    }

    //キャラ

    if (frameCount%3==0) {
      //キャラ・敵・アイテムの落下用にtimeを増やす
      player.time++;
      player.killTime++;
      for (Enemy e : enemy) {
        e.time++;
      }
      for (Item i : items) {
        i.time++;
      }
    }


    //キャラ移動など

    if (player.right && player.posX<width-16*n && !block2.isRight(player.posX+16*n, player.posY+14*n)) {
      player.moveRight();
    }

    if (player.left && player.posX>0 && !block2.isLeft(player.posX, player.posY+14*n)) {
      player.moveLeft();
    }

    //床座標取得
    floor = block2.isFloor(player.posX+8*n, player.posY+8*n);
    player.move(floor);


    //頭突き判定
    if (block2.isTop(player.posX+8*n, player.posY)!=0 && player.jumping) {
      player.touch=false;
      player.jumping=false;
      int []chara=block2.squares(player.posX+8*n, player.posY);
      if (block2.brick[chara[0]][chara[1]]==2) {
        //アイテムブロックに頭突きしたらアイテム出現
        itemSound.rewind();
        itemSound.play();
        items.add(new Item(chara[0], chara[1], n, int(random(2))) );
        block2.brick[chara[0]][chara[1]]=3;
      } else if (block2.brick[chara[0]][chara[1]]==1) {
        //普通のブロックに頭突きしたらブロック破壊
        brokenSound.rewind();
        brokenSound.play();
        block2.brick[chara[0]][chara[1]]=4;
        broken.add(new int[] {
          chara[0], chara[1], 0
          }
          );
        boardPoint-=int(pointValueB*3/5);
      }
    }

    //ジャンプ
    if (player.jumping&&player.touch==true) {
      player.jump();
    }
    player.draw();


    //アイテム
    for (Item i : items) {
      if (i.isItem(player.posX+8*n, player.posY+8*n)) {
        //キャラとぶつかったら使用されて消滅
        itemGet.rewind();
        itemGet.play();
        items.remove(i);
        playerPoint+=pointValueP;
        break;
      }
    }
    /*
      displayとremoveを同じfor文にいれると、
     removeされたときbreakしなければならないため、
     removeされたものより後ろのリストのアイテムが
     一瞬描画されなくなる。なのでfor文を分ける。
     */
    for (Item i : items) {
      int itemFloor = block2.isFloor(i.posX+8*n, i.posY+8*n);
      i.move(itemFloor);

      i.display();
    }


    //敵

    //一定時間たったら敵を出現
    if (frameCount % 60 == 0 && player.alive) {
      //進行方向
      int eneX = (int)random(2);
      if (eneX==0) {
        eneX=-4*n;
      } else {
        eneX=width+4*n;
      } 

      //出現場所（高さ）
      int eneY=(int)random(-5, 5);

      if (eneY<=0) {
        //空から
        eneY=-16*n;
        enemy.add(new Enemy((int)random(16*n*6, width-16*n*5), eneY, n, (int)random(2)));
      } else if (eneY>=1 && eneY<=3) {
        //途中のブロックの上
        eneY=(2*eneY-2+3)*16*n-4;
        enemy.add(new Enemy(eneX, eneY, n, (int)random(2)));
      } else {
        //地面
        eneY=height-16*3*n-4;
        enemy.add(new Enemy(eneX, eneY, n, (int)random(2)));
      }

      //進行方向設定
      if (eneX<=0) {
        enemy.get(enemy.size()-1).isFacingRight = true;
      } else {
        enemy.get(enemy.size()-1).isFacingRight = false;
      }
      eneNumber++;
    }


    for (Enemy e : enemy) {

      //キャラとの当たり判定
      if (dist(e.posX+(16*n)/2, e.posY+(16*n)/2, player.posX+(16*n)/2, player.posY+(12*n)/2)<=16*n && e.alive && player.alive && player.killTime>11) {
        if (player.posY+(6*n)<e.posY && player.alive && e.touch) {
          //キャラのほうが上にいるなら敵消滅
          e.alive=false;
          e.time=0;
          crush.rewind();
          crush.play();
          playerPoint+=pointValueP;
        } else {
          //キャラ死亡、一時操作ストップ
          hitEne.rewind();
          hitEne.play();
          player.alive=false;
          player.time=0;
          player.right=false;
          player.left=false;
          player.jumping=false;
          playerPoint-=int(pointValueP*3/5);
          //boardPoint+=pointValueB*1/5;
          player.killTime = 0;
        }
      }
      if (!e.alive && e.time>4) {
        //敵死亡からしばらくしたら消える
        enemy.remove(e);
        break;
      }
      if (e.posX<-16*n-4 || e.posX>width+16*n+4) {
        //ステージ外に行ったら消える
        enemy.remove(e);
        break;
      }
    }
    /*
      displayとremoveを同じfor文にいれると、
     removeされたときbreakしなければならないため、
     removeされたものより後ろのリストの敵が
     一瞬描画されなくなる。なのでfor文を分ける。
     */
    for (Enemy e : enemy) {
      int eneFloor;
      if (e.isFacingRight) {
        eneFloor=block2.isFloor(e.posX+4*n, e.posY);
      } else {
        eneFloor=block2.isFloor(e.posX+12*n, e.posY);
      }
      e.move(eneFloor);
      if (block2.isRight(e.posX+16*n, e.posY+14*n)) {
        e.isFacingRight = false;
      } else if (block2.isLeft(e.posX, e.posY+14*n)) {
        e.isFacingRight = true;
      }
      if (e.touch && e.alive) {
        if (e.isFacingRight) {
          e.moveRight();
        } else {
          e.moveLeft();
        }
      }
      e.draw();
    }

    //ポイント
    //ボード側点数カウント
    boardCount=0;
    for (int i=5; i<15; i++) {
      for (int j=0; j<6; j++) {
        if (block2.brick[i][j]>0) {
          boardCount++;
        }
      }
    }

    //println("comp:" + comp);
    if (frameCount%60==0 && boardCount<=5) {
      //5個以下なら2秒ごとにポイント減
      boardPoint-=pointValueB;
    } 
    if (boardCount>=5 && comp>3) {
      //一定以上配置を変更したらポイント増
      boardPoint+=pointValueB;
      comp = 0;
    }

    if (oldBoardCount<boardCount) {
      addBlock.rewind();
      addBlock.play();
    }
    oldBoardCount = boardCount;

    if (playerPoint<0) {
      playerPoint=0;
    }
    if (boardPoint<0) {
      boardPoint=0;
    }


    //ポイント表示
    image(pointP, 16*n, 11*16*n, 16*n, 16*n);
    drawPoints(2*16*n, 11*16*n, playerPoint, 4);
    image(pointB, 16*16*n, 11*16*n, 16*n, 16*n);
    drawPoints(17*16*n, 11*16*n, boardPoint, 4);

    //残り時間
    remainTime = timeLimit-(millis()/1000-startTime);
    if (remainTime<0) {
      remainTime = 0;
      player.time = 0;
      player.finish = true;
      fin.rewind();
      fin.play();
      stop();
      page = 5;
    }
    drawPoints(18*16*n, 0, remainTime, 2);
    image(clock, 17*16*n, 0, 16*n, 16*n);

    //敵に当たって少し経ったら生き返る
    if (!player.alive && player.time>=5) {
      player.alive = true;
    }

    break;

  case 5:
    //こうぼうせん勝敗表示
    image(back[0], 0, 0, width, height);
    PImage img;

    if (boardPoint>playerPoint) {
      img = win_b;
    } else if (boardPoint<playerPoint) {
      img =  win_p;
    } else {
      img = tie;
    }
    image(img, width/2-(img.width/2)*n, 3*16*n, img.width*n, img.height*n);
    image(pointP, 4*16*n, 6*16*n, 16*n, 16*n);
    drawPoints(5*16*n, 6*16*n, playerPoint, 4);
    image(pointB, 13*16*n, 6*16*n, 16*n, 16*n);
    drawPoints(14*16*n, 6*16*n, boardPoint, 4);
    image(returnButton, width/2-64*n/2, 16*8*n, 64*n, 16*n);
    break;

  case 6:
    image(howto2, 0, 0, width, height);
    break;

  case 7:
    image(howto1, 0, 0, width, height);
    break;
  }
}

//---------------------------------

void keyPressed() {

  if (keyCode==RIGHT) {
    if ((page==2 || page==4) && (player.alive && !player.finish)) {
      player.right=true;
      player.isFacingRight=true;
    } else if (page==3) {
      //つくるモード：右キーで編集エリア移動
      if (block.area<m*2-1) {
        block.area++;
        move=true;
      } else {
        //最後までいったらスタート画面へ
        initialize();
      }
      block.saveToFile();
    }
  }

  if (keyCode==LEFT && (page==2 || page==4) && player.alive && !player.finish) {
    player.left=true;
    player.isFacingRight=false;
  }

  if (keyCode==UP && (page==2 || page==4) && player.alive && !player.finish) {
    if (!player.jumping&&player.touch) {
      jumpSound.rewind();
      jumpSound.play();
      player.time=0;
      player.jumping=true;
    }
  }
}

void keyReleased() {
  if (page==2 || page==4) {
    if (keyCode==RIGHT) {
      player.right=false;
    }
    if (keyCode==LEFT) {
      player.left=false;
    }
  } else if (page==1) {
    if (key == 'h') {
      page=6;
    }
  } else if (page==6) {
    if (keyCode == RIGHT) {
      page=7;
    }
  } else if (page==7) {
    if (keyCode == LEFT) {
      page=6;
    }
  }
  if (key == 'b') {
    stop();
    initialize();
  } else if (key == 's') {
    save(  "screenshot/" + frameCount+".png" );
  } else if (key == 'm') {
    button.rewind();
    button.play();
    startTime = millis()/1000;
    timeLimit=100;
    page=4;
  }
}

//-----------------------------

void mousePressed() {
  switch(page) {
  case 0:
    if (mouseX>=16*8*n && mouseX<=16*12*n && mouseY>=16*7*n && mouseY<=16*8*n) {
      button.rewind();
      button.play();
      page=1;
    }
    break;

  case 1:
    if (mouseY>=16*4*n && mouseY<=16*6*n) {
      if (mouseX>=16*2*n && mouseX<=16*5*n) {
        button.rewind();
        button.play();
        page=2;
      } else if (mouseX>=16*15*n && mouseX<=18*16*n) {
        button.rewind();
        button.play();
        page=3;
      } else if (mouseX>=16*7*n && mouseX<=16*13*n) {
        button.rewind();
        button.play();
        startTime = millis()/1000;
        timeLimit = 30;
        page=4;
      }
    } else if (mouseX>=16*8*n && mouseX<=16*12*n && mouseY>=16*8*n && mouseY<=16*9*n) {
      button.rewind();
      button.play();
      page=0;
    }

    break;

  case 3:
    //置かれたブロックをクリックすると種類の変更
    int mX=mouseX-backX;
    int mY=mouseY;
    for (int i=0; i<block.brick.length; i++) {
      for (int j=0; j<6; j++) {
        if (block.brick[i][j]>0 && mX>i*16*n && mX<i*16*n+16*n && mY>(j+3)*16*n && mY<(j+3)*16*n+16*3) {
          block.brick[i][j]++;
          if (block.brick[i][j]>=3) {
            block.brick[i][j]=1;
          }
        }
      }
    }

    break;

  case 5:
    if (mouseX>=16*8*n && mouseX<=16*12*n && mouseY>=16*8*n && mouseY<=16*9*n) {
      button.rewind();
      button.play();
      initialize();
    }
    break;
  }
}

//---------------------------

void initialize() {
  //スタートに戻る＆いろいろと初期化
  page=0;
  backX=0;
  player.right=false;
  player.left=false;
  player.jumping=false;
  eneNumber=1;
  move=false;
  player.alive=true;
  player.posX=100;
  player.posY=10;
  player.isFacingRight = true;
  block.loadFromFile();
  items.clear();  //前回のアイテムが残らないようリストを空にする
  enemy.clear();  //前回の敵以下同文
  broken.clear();
  enemy.add(new Enemy((int)random(width/2, width), 0, n, (int)random(2)) );  //最初の一匹
  minim=new Minim(this);
  bgm = minim.loadFile( "BGM.mp3" );
  player.finish=false;
  block.area = 0;
  block2.area = 0;
  setBrick();  //こうぼうせんブロック初期配置
  startTime = 0;
  playerPoint = 0;
  boardPoint = 0;
  oldBoardCount = 0;
}

void stop() {
  bgm.rewind();
  bgm.close();

  minim.stop();
}

void setBrick() {
  //対戦スタート時のブロック初期配置

  for (int i=0; i<20; i++) {
    for (int j=0; j<6; j++) {
      block2.brick[i][j] = 0;
    }
  }

  ArrayList<int[]> initPos = new ArrayList<int[]>();
  initPos.add(new int[] {
    0, 1
    }
    );
  initPos.add(new int[] {
    1, 1
    }
    );

  for (int i=0; i<3; i++) {
    initPos.add(new int[] {
      i, 3
      }
      );
  }
  for (int i=0; i<4; i++) {
    initPos.add(new int[] {
      i, 5
      }
      );
  }

  initPos.add(new int[] {
    19, 1
    }
    );
  initPos.add(new int[] {
    18, 1
    }
    );
  for (int i=0; i<3; i++) {
    initPos.add(new int[] {
      19-i, 3
      }
      );
  }
  for (int i=0; i<4; i++) {
    initPos.add(new int[] {
      19-i, 5
      }
      );
  }

  for (int[] b : initPos) {
    block2.brick[b[0]][b[1]] = 1;
  }
  /*for (int i=0; i<5; i++) {
   int k = (int)random(initPos.size());
   int[] b = initPos.get(k);
   block2.brick[b[0]][b[1]] = 2;
   initPos.remove(k);
   }*/
}

void drawPoints(int x, int y, int point, int digit) {
  //ポイント表示
  int p = 0;
  PImage img = new PImage();
  if (point<0) {
    point = 0;
  }
  for (int i=digit-1; i>=0; i--) {
    p = point%10;
    point = point/10;
    img = numbers[p];
    image(img, x+(i*8*n), y, 8*n, 16*n);
  }
}