int state = 0;
int startTime;
int duration = 30;   // survive this many seconds to win

// --- LIVES ---
int lives = 3;

// --- HIT COOLDOWN (prevents losing all lives in one touch) ---
boolean canHit = true;
int lastHitTime = 0;
int hitCooldownMs = 800;

// --- PLAYER POSITION ---
float px = 350;
float py;               // set in setup() based on groundY

// --- PLAYER VELOCITY ---
float vx = 0;
float vy = 0;

// --- PLAYER PHYSICS ---
float accel     = 0.6;
float friction  = 0.88;
float gravity   = 0.55;
float jumpForce = -13;
float pR        = 20;    // player radius

// --- GROUND ---
float groundY = 300;     // y position of ground surface

// --- ENEMIES (arrays) ---
int n = 8;
float[] ex  = new float[n];
float[] ey  = new float[n];
float[] evx = new float[n];
float[] evy = new float[n];
float eR = 14;           // enemy radius

// --- SCORE ---
int score = 0;
int lastScoreTime = 0;   // for adding +1 score per second

// ─────────────────────────────────────────────────────────
void setup() {
  size(700, 350);
  frameRate(60);
  py = groundY;          // player starts on the ground
}

void initEnemies() {
  for (int i = 0; i < n; i++) {
    ex[i]  = random(eR, width - eR);
    ey[i]  = random(eR, height - 80);   // keep above ground area
    evx[i] = random(-3.5, 3.5);
    evy[i] = random(-3.5, 3.5);
    if (abs(evx[i]) < 1) evx[i] = 2.0;
    if (abs(evy[i]) < 1) evy[i] = -2.0;
  }
}

void draw() {
  background(30, 32, 48);   // dark navy background

  if (state == 0) drawStartScreen();
  if (state == 1) drawGame();
  if (state == 2) drawGameOverScreen();
  if (state == 3) drawWinScreen();
}

void drawStartScreen() {
  // Title
  textAlign(CENTER, CENTER);
  fill(80, 180, 255);
  textSize(34);
  text("DODGE & SURVIVE", width/2, height/2 - 80);

  // Instructions
  fill(200);
  textSize(15);
  text("LEFT / RIGHT  →  Move (smooth acceleration)", width/2, height/2 - 25);
  text("SPACE         →  Jump", width/2, height/2 + 5);
  text("Avoid the red enemies for 30 seconds!", width/2, height/2 + 35);
  text("You have 3 lives.", width/2, height/2 + 60);

  // Start prompt
  fill(80, 220, 130);
  textSize(20);
  text("Press ENTER to Start", width/2, height/2 + 110);
}

void drawGame() {

  // ── Timer check ──
  int elapsed  = (millis() - startTime) / 1000;
  int timeLeft = duration - elapsed;

  // Score +1 every second survived
  if (millis() - lastScoreTime >= 1000) {
    score++;
    lastScoreTime = millis();
  }

  if (timeLeft <= 0) {
    state = 3;   // WIN
    return;
  }

  // ── Hit cooldown reset ──
  if (!canHit && millis() - lastHitTime > hitCooldownMs) {
    canHit = true;
  }

  // ── Player: horizontal acceleration + friction ──
  if (keyPressed) {
    if (keyCode == RIGHT) vx += accel;
    if (keyCode == LEFT)  vx -= accel;
  }
  vx *= friction;
  px += vx;
  px = constrain(px, pR, width - pR);

  // ── Player: gravity + vertical movement ──
  vy += gravity;
  py += vy;

  // ── Ground collision ──
  if (py >= groundY) {
    py = groundY;
    vy = 0;
  }

  // ── Draw ground ──
  stroke(80, 90, 120);
  strokeWeight(2);
  line(0, groundY + pR, width, groundY + pR);
  noStroke();

  // ── Draw player ──
  // Flash white briefly after getting hit
  if (!canHit) {
    fill(255, 100, 100);   // red tint when hurt
  } else {
    fill(80, 160, 255);    // normal blue
  }
  ellipse(px, py, pR*2, pR*2);

  // Player eye detail (small white dot)
  fill(255);
  ellipse(px + 6, py - 5, 7, 7);
  fill(20);
  ellipse(px + 7, py - 5, 4, 4);

  // ── Enemies: move + bounce + draw ──
  for (int i = 0; i < n; i++) {
    ex[i] += evx[i];
    ey[i] += evy[i];

    if (ex[i] > width - eR  || ex[i] < eR)  evx[i] *= -1;
    if (ey[i] > height - eR || ey[i] < eR)  evy[i] *= -1;

    // Clamp so they don't escape
    ex[i] = constrain(ex[i], eR, width - eR);
    ey[i] = constrain(ey[i], eR, height - eR);

    // Draw enemy
    fill(255, 80, 100);
    ellipse(ex[i], ey[i], eR*2, eR*2);

    // Enemy spike detail
    fill(255, 140, 100);
    ellipse(ex[i], ey[i], eR, eR);

    // ── Collision detection ──
    float d = dist(px, py, ex[i], ey[i]);
    if (d < pR + eR && canHit) {
      lives--;
      canHit = false;
      lastHitTime = millis();

      if (lives <= 0) {
        state = 2;   // GAME OVER
      }
    }
  }

  // ── HUD: Timer ──
  textAlign(LEFT, TOP);
  fill(255);
  textSize(16);
  text("Time: " + timeLeft + "s", 15, 15);

  // ── HUD: Score ──
  text("Score: " + score, 15, 38);

  // ── HUD: Lives ──
  textAlign(RIGHT, TOP);
  text("Lives: " + livesDisplay(), width - 15, 15);

  // ── Timer warning (flash red when low) ──
  if (timeLeft <= 10) {
    textAlign(CENTER, TOP);
    if (frameCount % 30 < 15) {   // blink effect
      fill(255, 80, 80);
      textSize(14);
      text("HURRY!", width/2, 40);
    }
  }
}

// Draw lives as hearts
String livesDisplay() {
  String s = "";
  for (int i = 0; i < lives; i++) s += "♥ ";
  return s.trim();
}

//  GAME OVER SCREEN
void drawGameOverScreen() {
  textAlign(CENTER, CENTER);

  fill(255, 80, 80);
  textSize(36);
  text("GAME OVER", width/2, height/2 - 70);

  fill(220);
  textSize(18);
  text("You survived " + score + " seconds", width/2, height/2 - 10);
  text("Better luck next time!", width/2, height/2 + 25);

  fill(80, 200, 255);
  textSize(20);
  text("Press R to Restart", width/2, height/2 + 80);
}

//  WIN SCREEN
void drawWinScreen() {
  textAlign(CENTER, CENTER);

  // Animated background flash
  fill(30 + sin(frameCount * 0.1) * 20,
       80 + sin(frameCount * 0.07) * 30,
       48);
  rect(0, 0, width, height);

  fill(80, 255, 150);
  textSize(38);
  text("YOU WIN!", width/2, height/2 - 80);

  fill(255, 220, 80);
  textSize(22);
  text("Score: " + score, width/2, height/2 - 20);
  text("Lives remaining: " + livesDisplay(), width/2, height/2 + 20);

  fill(200);
  textSize(16);
  text("You survived all 30 seconds!", width/2, height/2 + 60);

  fill(80, 200, 255);
  textSize(20);
  text("Press R to Play Again", width/2, height/2 + 110);
}

//  KEY PRESSED
void keyPressed() {

  // ENTER → start game
  if (state == 0 && keyCode == ENTER) {
    state      = 1;
    startTime  = millis();
    lastScoreTime = millis();
    lives      = 3;
    score      = 0;
    canHit     = true;
    px         = width / 2;
    py         = groundY;
    vx         = 0;
    vy         = 0;
    initEnemies();
  }

  // SPACE → jump (only when on the ground)
  if (state == 1 && key == ' ' && py >= groundY) {
    vy = jumpForce;
  }

  // R → restart from game over or win screen
  if ((state == 2 || state == 3) && (key == 'r' || key == 'R')) {
    state = 0;
  }
}
