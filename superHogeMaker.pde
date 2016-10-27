import processing.serial.*;
import ddf.minim.*;

Serial serial;
Minim minim;
AudioPlayer bgm;
AudioPlayer jumpSound, fin, brokenSound, itemSound, bird, gameover, crush, button;

//モード共通で使う変数
int n=3;  //拡大倍率
int m=3;  //背景の枚数。ステージの長さ
int page;  //どの画面にいるか
int backX;  //背景X座標
PImage [] back=new PImage[m];  //背景
PImage title, start, play, make, battle, returnButton;  //タイトルと各種ボタン
Block block;

//あそぶモード用変数
PImage goal;  //ゴールの旗
PImage FMS;  //おれは(略
int eneNumber;  //敵出現タイミング・数管理
Player player;
ArrayList<Item> items;
ArrayList<Enemy> enemy;
ArrayList<int[]> broken;  //こわれたブロック
ArrayList<int[]> tweet;  //アイテムの効果(つぶやき)
boolean bgmFlg=false;

//つくるモード用変数
boolean move;  //画面表示の移動フラグ

//対戦モード用変数
Block block2;  //対戦用のブロック配列

void settings() {
  size(320*n, 192*n);
  noSmooth();  //ぼかさない処理
}

void setup() {
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
  bird = minim.loadFile("bird.mp3");
  gameover = minim.loadFile("gameover.mp3");
  crush = minim.loadFile("crushed.mp3");
  button = minim.loadFile("decision3.mp3");

  title=loadImage("titlelogo2.png");
  start=loadImage("startButton.png");
  play=loadImage("playButtonBig.png");
  make=loadImage("makeButtonBig.png");
  battle=loadImage("battle1.png");
  returnButton=loadImage("returnButton.png");
  back[0]=loadImage("GameBackground4.png");
  for (int i=0; i<back.length; i++) {
    back[i]=back[0];
  }
  goal=loadImage("flag2.png");
  FMS=loadImage("tweet_big.png");

  block = new Block(m, n);
  player=new Player(100, 10);
  items= new ArrayList<Item>();
  enemy= new ArrayList<Enemy>();
  broken=new ArrayList<int[]>();
  tweet=new ArrayList<int[]>();

  block2 = new Block(1, n);

  initialize();
}


void draw() {

  switch(page) {

  case 0:
    //スタート画面
    image(back[0], 0, 0, width, height);
    image(title, width/2-192*n/2, 16*4*n, 192*n, 24*n);
    image(start, width/2-64*n/2, 16*7*n, 64*n, 16*n);
    break;

  case 1:
    //モード選択画面
    image(back[0], 0, 0, width, height);
    image(play, 16*2*n, 16*5*n, 48*n, 32*n);
    image(battle, 16*7*n, 16*5*n, 16*6*n, 32*n);
    image(make, 16*15*n, 16*5*n, 48*n, 32*n);
    image(returnButton, 0, 0, 48*n, 16*n);
    break;

  case 2:
    //あそぶモード

    //背景描画
    for (int i=0; i<back.length; i++) {
      image(back[i], backX+width*i, 0, width, height);
    }
    image(goal, backX+width*m, 0, 48*n, height);

    if (!bgmFlg&&player.alive) {
      bgm.rewind();
      bgm.play();
      bgmFlg=true;
    }

    //キャラの動きに合わせてスクロール
    if (player.posX>-backX+500 && player.right && backX>-width*(m-1)-48*n ) {
      backX-=4;
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


    //  println("time="+player.time);
    if (frameCount%6==0) {
      //キャラ・敵の落下用にtimeを増やす
      player.time++;
      for (Enemy e : enemy) {
        e.time++;
      }
    }


    //キャラ移動など

    if (player.right && player.posX<width*m+32*n && !block.isRight(player.posX+16*n, player.posY+14*n)) {
      //if(!block.rightBlock(player.posX,player.posY))
      player.moveRight();

      //キャラが一定座標まで来たら敵を出現
      if (player.posX+16*n>eneNumber*width && eneNumber<m) {
        //空からor地上から
        int eneY=(int)random(2);
        if (eneY==1) {
          eneY=height-48*n;
        }
        enemy.add(new Enemy((int)random(width/4, width)+eneNumber*width, eneY));
        eneNumber++;
      }
      //finish
      if (player.posX>width*m+16*n) {
        player.time=0;
        player.finish=true;
        player.time=0;
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
        items.add(new Item(chara[0], chara[1], n) );
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
        //つぶやく
        tweet.add(new int[] {
          (int)random(-16, 48), (int)random(4, 24)
          }
          );
        bird.rewind();
        bird.play();
        items.remove(i);
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
      if (dist(e.posX, e.posY, player.posX, player.posY)<=12*n && e.alive) {
        if (player.posY<e.posY) {
          //キャラのほうが上にいるなら敵消滅
          e.alive=false;
          e.time=0;
          crush.rewind();
          crush.play();
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
      if (e.touch && e.alive) {
        e.moveLeft();
      }
      e.draw();
    }

    //つぶやき
    for (int[] t : tweet) {
      image(FMS, player.posX-t[0]*n, player.posY-t[1]*n, 80*(n-1), 16*(n-1));
    }

    popMatrix();

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
    //println(bgmFlg);
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
        println(str);
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


    //ブロック

    //ブロックの情報取得
    if (Serial.list().length>0) {
      if (serial.available()>0 && !move) {
        String str = serial.readStringUntil('e');
        //println(str);
        block2.getSerialData_battle(str);
        serial.write('a');
      } else {
        println("not available");
      }
    }

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



    //キャラ
    if (!bgmFlg&&player.alive) {
      bgm.rewind();
      bgm.play();
      bgmFlg=true;
    }

    //  println("time="+player.time);
    if (frameCount%6==0) {
      //キャラ・敵の落下用にtimeを増やす
      player.time++;
      for (Enemy e : enemy) {
        e.time++;
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
    //int floor;
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
        items.add(new Item(chara[0], chara[1], n) );
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
        //つぶやく
        tweet.add(new int[] {
          (int)random(-16, 48), (int)random(4, 24)
          }
          );
        bird.rewind();
        bird.play();
        items.remove(i);
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

    //つぶやき
    for (int[] t : tweet) {
      image(FMS, player.posX-t[0]*n, player.posY-t[1]*n, 80*(n-1), 16*(n-1));
    }


    //敵

    //一定時間たったら敵を出現
    if (frameCount % 100 == 0 && player.alive) {
      //進行方向
      int eneX = (int)random(2);
      if (eneX==0) {
        eneX=-4*n;
      } else {
        eneX=width+4*n;
      } 

      //出現場所（高さ）
      int eneY=(int)random(-5, 5);
      println("pos="+eneY);

      //空から
      if (eneY<=0) {
        eneY=-16*n;
        enemy.add(new Enemy((int)random(16*n*6, width-16*n*5), eneY));
      } else if (eneY>=1 && eneY<=3) {
        //途中のブロックの上
        eneY=(2*eneY-2+3)*16*n-4;
        enemy.add(new Enemy(eneX, eneY));
      } else {
        //地面
        eneY=height-16*3*n-4;
        enemy.add(new Enemy(eneX, eneY));
      }

      //進行方向設定
      if (eneX<=0) {
        enemy.get(enemy.size()-1).isFacingRight = true;
      } else {
        enemy.get(enemy.size()-1).isFacingRight = false;
      }
      eneNumber++;

      //println(eneX+", "+eneY+", "+enemy.get(enemy.size()-1).isFacingRight);
    }
    //i*16*n, (j+3)*16*n

    for (Enemy e : enemy) {

      //キャラとの当たり判定
      if (dist(e.posX, e.posY, player.posX, player.posY)<=12*n && e.alive) {
        if (player.posY<e.posY && player.alive) {
          //キャラのほうが上にいるなら敵消滅
          e.alive=false;
          e.time=0;
          crush.rewind();
          crush.play();
        } else {
          //キャラ死亡でゲームオーバー
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
      if (e.touch && e.alive) {
        if (e.isFacingRight) {
          e.moveRight();
        } else {
          e.moveLeft();
        }
      }
      e.draw();
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
  }
  if (key == 'b') {
    stop();
    initialize();
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
    if (mouseY>=16*5*n && mouseY<=16*7*n) {
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
        page=4;
      }
    } else if (mouseY<=16*n && mouseX<=48*n) {
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
  block.loadFromFile();
  items.clear();  //前回のアイテムが残らないようリストを空にする
  enemy.clear();  //前回の敵以下同文
  broken.clear();
  tweet.clear();
  enemy.add(new Enemy((int)random(width/2, width), 0) );  //最初の一匹
  minim=new Minim(this);
  bgm = minim.loadFile( "BGM.mp3" );
  player.finish=false;
  bgmFlg=false;
  block.area=0;
  block2.area = 0;
  setBrick();  //初期配置
}

void stop() {
  bgm.rewind();
  bgmFlg=false;
  bgm.close();

  minim.stop();
}

void setBrick() {
  //対戦スタート時のブロック初期配置

  block2.brick[1][1] = 1;
  for (int i=0; i<3; i++) {
    block2.brick[i][3] = 1;
  }
  for (int i=0; i<4; i++) {
    block2.brick[i][5] = 1;
  }

  block2.brick[19][1] = 1;
  block2.brick[18][1] = 1;
  for (int i=0; i<3; i++) {
    block2.brick[19-i][3] = 1;
  }
  for (int i=0; i<4; i++) {
    block2.brick[19-i][5] = 1;
  }

  block2.brick[0][1] = 2;
  block2.brick[18][3] = 2;
  block2.brick[1][5] = 2;
  block2.brick[17][5] = 2;
}