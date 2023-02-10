import 'package:chronochroma/chronochroma.dart';
import 'package:chronochroma/components/attackHitbox.dart';
import 'package:chronochroma/helpers/directions.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'worldCollides.dart';
import 'attackHitbox.dart';

class Player extends SpriteAnimationComponent
    with HasGameRef<Chronochroma>, CollisionCallbacks {
  int health = 100;

  // Attributs de direction et d'animation
  bool needUpdate = true;
  double gravity = 1.03;
  Vector2 velocity = Vector2(0, 0);
  Direction direction = Direction.none;
  late final SpriteAnimation _idleAnimation;
  late final SpriteAnimation _crouchAnimation;
  late final SpriteAnimation _jumpAnimation;
  late final SpriteAnimation _runAnimation;
  late final SpriteAnimation _slideAnimation;
  late final SpriteAnimation _attackAnimation;
  late final SpriteAnimation _crouchAttackAnimation;

  // Vitesse d'animation : plus c'est haut, plus c'est lent
  final double _idleAnimationSpeed = 0.25;
  final double _crouchAnimationSpeed = 0.25;
  final double _jumpAnimationSpeed = 0.25;
  final double _runAnimationSpeed = 0.08;
  final double _slideAnimationSpeed = 0.12;
  final double _attackAnimationSpeed = 0.12;
  final double _crouchAttackAnimationSpeed = 0.12;

  final double _moveSpeed = 5;
  final double jumpMultiplier = 2.1;
  final double downMultiplier = 0.5;
  final double xVelocityMax = 10;
  final double yVelocityMax = 8;
  double fallingVelocity = 0;

  bool facingRight = true;
  bool canJump = true;
  bool canSlide = true;
  bool canCrouch = true;
  bool isCrouching = false;
  bool canAttack = true;
  bool isAttacking = false;

  late RectangleHitbox topHitBox;
  late RectangleHitbox frontHitBox;
  late RectangleHitbox bottomHitBox;
  late AttackHitbox attackHitBox;

  final RectangleHitbox topHitBoxStandModel = (RectangleHitbox(
    size: Vector2(28, 30),
    position: Vector2(256 / 2 - 12, 16),
  ));
  final RectangleHitbox frontHitBoxStandModel = (RectangleHitbox(
    size: Vector2(16, 76),
    position: Vector2(256 / 2 + 16, 24),
  ));
  final RectangleHitbox bottomHitBoxStandModel = (RectangleHitbox(
    size: Vector2(28, 30),
    position: Vector2(256 / 2 - 12, 86),
  ));

  final RectangleHitbox topHitBoxSlideModel = (RectangleHitbox(
    size: Vector2(28, 30),
    position: Vector2(256 / 2 - 12, 36),
  ));
  final RectangleHitbox frontHitBoxSlideModel = (RectangleHitbox(
    size: Vector2(16, 40),
    position: Vector2(256 / 2 + 16, 56),
  ));
  final RectangleHitbox bottomHitBoxSlideModel = (RectangleHitbox(
    size: Vector2(28, 30),
    position: Vector2(256 / 2 - 12, 86),
  ));

  Player() : super(size: Vector2(256, 128), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await _loadAnimations().then((_) => {animation = _idleAnimation});

    topHitBox = RectangleHitbox(
      size: topHitBoxStandModel.size,
      position: topHitBoxStandModel.position,
    );
    frontHitBox = RectangleHitbox(
      size: frontHitBoxStandModel.size,
      position: frontHitBoxStandModel.position,
    );
    bottomHitBox = RectangleHitbox(
      size: bottomHitBoxStandModel.size,
      position: bottomHitBoxStandModel.position,
    );

    topHitBox.debugMode = true;
    topHitBox.debugColor = Colors.red;
    bottomHitBox.debugMode = true;
    bottomHitBox.debugColor = Colors.red;
    frontHitBox.debugMode = true;
    frontHitBox.debugColor = Colors.orange;
    
    setUpAttackHitbox();

    add(topHitBox);
    add(bottomHitBox);
    add(frontHitBox);
  }

// Animations correspondantes à des états pour le personnage
  Future<void> _loadAnimations() async {
    final idleSpriteSheet = SpriteSheet.fromColumnsAndRows(
      image: await gameRef.images.load('character/Idle.png'),
      columns: 2,
      rows: 4,
    );
    final crouchSpriteSheet = SpriteSheet.fromColumnsAndRows(
        image: await gameRef.images.load('character/crouch_idle.png'),
        columns: 2,
        rows: 4);
    final jumpSpriteSheet = SpriteSheet.fromColumnsAndRows(
        image: await gameRef.images.load('character/Jump.png'),
        columns: 2,
        rows: 4);
    final runSpriteSheet = SpriteSheet.fromColumnsAndRows(
      image: await gameRef.images.load('character/Run.png'),
      columns: 2,
      rows: 4,
    );
    final slideSpriteSheet = SpriteSheet.fromColumnsAndRows(
      image: await gameRef.images.load('character/Slide.png'),
      columns: 4,
      rows: 3,
    );
    final attackSpriteSheet = SpriteSheet.fromColumnsAndRows(
      image: await gameRef.images.load('character/Attacks.png'),
      columns: 8,
      rows: 5,
    );
    final crouchAttackSpriteSheet = SpriteSheet.fromColumnsAndRows(
      image: await gameRef.images.load('character/crouch_attacks.png'),
      columns: 2,
      rows: 4,
    );

    _idleAnimation = idleSpriteSheet.createAnimation(
        row: 0, stepTime: _idleAnimationSpeed, from: 0, to: 7);

    _crouchAnimation = crouchSpriteSheet.createAnimation(
        row: 0, stepTime: _crouchAnimationSpeed, from: 0, to: 7);

    _jumpAnimation = jumpSpriteSheet.createAnimation(
        row: 0, stepTime: _jumpAnimationSpeed, from: 0, to: 7);

    _runAnimation = runSpriteSheet.createAnimation(
        row: 0, stepTime: _runAnimationSpeed, from: 0, to: 7);

    _slideAnimation = slideSpriteSheet.createAnimation(
        row: 0, stepTime: _slideAnimationSpeed, from: 3, to: 8);

    _attackAnimation = attackSpriteSheet.createAnimation(
        row: 0, stepTime: _attackAnimationSpeed, from: 0, to: 6, loop: false);

    _crouchAttackAnimation = crouchAttackSpriteSheet.createAnimation(
        row: 0, stepTime: _crouchAttackAnimationSpeed, from: 0, to: 6, loop: false);
  }

  int frame = 0;
  double playerDt = 0;

// dt pour delta time, c'est le temps de raffraichissement
  @override
  void update(double dt) async {
    if (dt >= 0.01 || playerDt >= 0.01) {
      playerDt = 0;
      super.update(dt);

      frame++;

      // Augmente la vitesse de chute si le personnage n'est pas sur le sol, sinon annule la vitesse de chute
      if (!bottomHitBox.isColliding) {
        if (fallingVelocity > gravity * 1.5) {
          fallingVelocity *= gravity;
        } else {
          fallingVelocity += gravity * 5;
        }
        if (velocity.y + fallingVelocity < yVelocityMax) {
          velocity.y += fallingVelocity;
        } else {
          velocity.y = yVelocityMax;
        }
      } else {
        fallingVelocity = 0;
      }
      
      applyMovements();

      velocity.x = 0;
      velocity.y = 0;

      updatePosition();

      if (needUpdate) {
        needUpdate = false;
        await Future.delayed(Duration(seconds: 1)).then((_) async {
          print(frame);
          frame = 0;
          await Future.delayed(Duration(seconds: 1))
              .then((_) => {needUpdate = true});
        });
      }
    } else {
      playerDt += dt;
    }
  }

// Déplacement du personnage
  updatePosition() {
    switch (direction) {
      case Direction.up:
        reduceHitBox(false);
        if (!topHitBox.isColliding && canJump) {
          velocity.y = -_moveSpeed * jumpMultiplier;
        }
        break;
      case Direction.down:
        reduceHitBox(canCrouch);
        velocity.x = 0;
        if (!bottomHitBox.isColliding && velocity.y.abs() < yVelocityMax) {
          velocity.y += _moveSpeed * downMultiplier;
        }
        break;
      case Direction.left:
        reduceHitBox(false);
        if (!frontHitBox.isColliding && !facingRight) {
          velocity.x = -_moveSpeed;
        } else {
          velocity.x = 0;
        }
        break;
      case Direction.right:
        reduceHitBox(false);
        if (!frontHitBox.isColliding && facingRight) {
          velocity.x = _moveSpeed;
        } else {
          velocity.x = 0;
        }
        break;
      case Direction.upLeft:
        reduceHitBox(false);
        if (!topHitBox.isColliding && canJump) {
          velocity.y = -_moveSpeed * jumpMultiplier;
        }
        if (!frontHitBox.isColliding && !facingRight) {
          velocity.x = -_moveSpeed;
        } else {
          velocity.x = 0;
        }
        break;
      case Direction.upRight:
        reduceHitBox(false);
        if (!topHitBox.isColliding && canJump) {
          velocity.y = -_moveSpeed * jumpMultiplier;
        }
        if (!frontHitBox.isColliding && facingRight) {
          velocity.x = _moveSpeed;
        }
        break;
      case Direction.downLeft:
        reduceHitBox(canSlide);
        if (!bottomHitBox.isColliding && velocity.y.abs() < yVelocityMax) {
          velocity.y = _moveSpeed * (downMultiplier / 2);
        }
        if (!frontHitBox.isColliding && !facingRight) {
          velocity.x = -_moveSpeed;
        } else {
          velocity.x = 0;
        }
        break;
      case Direction.downRight:
        reduceHitBox(canSlide);
        if (!bottomHitBox.isColliding && velocity.y.abs() < yVelocityMax) {
          velocity.y += _moveSpeed * (downMultiplier / 2);
        }
        if (!frontHitBox.isColliding && facingRight) {
          velocity.x = _moveSpeed;
        } else {
          velocity.x = 0;
        }
        break;
      case Direction.none:
          reduceHitBox((isAttacking && isCrouching));
        break;
    }
    updateAnimation();
  }

  // Détecteur de collision
  @override
  void onCollision(intersectionPoints, other) {
    super.onCollision(intersectionPoints, other);
    if (other is WorldCollides) {
      if (topHitBox.isColliding) {
        //print("top hit");
        if (canJump == true && !bottomHitBox.isColliding) {
          canJump = false;
        }
      }
      if (bottomHitBox.isColliding) {
        //print("bottom hit");
        if (canJump == false) {
          canJump = true;
        }
      }
      if (frontHitBox.isColliding) {
        //print("front hit");
      }
    }
  }

  // Redimensionnement des hitbox du personnage, true pour la version basse, false pour la version haute
  void reduceHitBox(bool bool) {
    if (bool) {
      isCrouching = true;
      topHitBox.size = topHitBoxSlideModel.size;
      topHitBox.position = topHitBoxSlideModel.position;
      frontHitBox.size = frontHitBoxSlideModel.size;
      frontHitBox.position = frontHitBoxSlideModel.position;
      bottomHitBox.size = bottomHitBoxSlideModel.size;
      bottomHitBox.position = bottomHitBoxSlideModel.position;
    } else {
      if (!topHitBox.isColliding) {
        isCrouching = false;
        topHitBox.size = topHitBoxStandModel.size;
        topHitBox.position = topHitBoxStandModel.position;
        frontHitBox.size = frontHitBoxStandModel.size;
        frontHitBox.position = frontHitBoxStandModel.position;
        bottomHitBox.size = bottomHitBoxStandModel.size;
        bottomHitBox.position = bottomHitBoxStandModel.position;
      }
    }
  }

  void applyMovements() async {
    if (!isAttacking) {
      velocity.x = velocity.x.ceilToDouble();
      int i = 1;
      while (!frontHitBox.isColliding && i <= velocity.x.abs()) {
        if (facingRight) {
          position.x += 1;
        } else {
          position.x -= 1;
        }
        i++;
      }
      velocity.y = velocity.y.ceilToDouble();
      int j = 1;
      while (j <= velocity.y.abs()) {
        if (velocity.y > 0 && !bottomHitBox.isColliding) {
          position.y += 1;
        } else if (velocity.y < 0 && !topHitBox.isColliding) {
          position.y -= 1;
        } else {
          break;
        }
        j++;
      }
    }
  }

  // Met à jour l'animation du personnage et sa direction
  void updateAnimation() async {
    //////// Gère l'orientation du personnage
    if (!isAttacking) {
      canCrouch = true;
      canSlide = true;
      canAttack = true;
      canJump = true;
      if (facingRight &&
        (direction == Direction.left ||
            direction == Direction.upLeft ||
            direction == Direction.downLeft)) {
        flipHorizontallyAroundCenter();
        facingRight = false;
      } else if (!facingRight &&
        (direction == Direction.right ||
            direction == Direction.upRight ||
            direction == Direction.downRight)) {
        flipHorizontallyAroundCenter();
        facingRight = true;
      }
    }
    //////// Gère l'animation du personnage
    if (isCrouching && !isAttacking) {
        if (velocity.x == 0) {
          // Accroupi, pas de mouvement
          animation = _crouchAnimation;
        } else {
          if (canSlide) {
            // Accroupi, en mouvement
            canAttack = false;
            animation = _slideAnimation;
          }
      }
    } else {
      if (isAttacking) {
        if (!isCrouching) {
          canSlide = false;
          canCrouch = false;
          animation = _attackAnimation;
          if (canAttack) {
            setUpAttackHitbox();
            add(attackHitBox);
            canAttack = false;
          }
          _attackAnimation.onComplete = () {
            print("attack done");
            remove(attackHitBox);
            isAttacking = false;
            canAttack = true;
            canSlide = true;
            canCrouch = true;
            _attackAnimation.reset();
          };
        } else {
          canSlide = false;
          animation = _crouchAttackAnimation;
          if (canAttack) {
            setUpAttackHitbox();
            add(attackHitBox);
            canAttack = false;
          }
          _crouchAttackAnimation.onComplete = () {
            print("attack done");
            remove(attackHitBox);
            isAttacking = false;
            canAttack = true;
            canSlide = true;
            _crouchAttackAnimation.reset();
          };
        }
      } else {
        if (bottomHitBox.isColliding) {
          canAttack = true;
          if (velocity.x == 0) {
            // Debout, bloqué par sol, pas de mouvement
            animation = _idleAnimation;
          } else {
            // Debout, bloqué par sol, en mouvement
            animation = _runAnimation;
          }
        } else {
          canAttack = false;
          if (topHitBox.isColliding) {
            // Debout, bloqué par plafond
            animation = _jumpAnimation;
          } else {
            // Debout, pas de blocage
            animation = _jumpAnimation;
          }
        }
      }
    }
  }

  // Instancie à nouveau la hitbox d'attaque
  void setUpAttackHitbox() {
    attackHitBox = AttackHitbox();
    attackHitBox.debugMode = true;
    attackHitBox.debugColor = Colors.green;
  }

  // Téléporte le personnage à la position donnée
  void teleport(Vector2 position) {
    this.position = position;
  }
}
