import 'package:chronochroma/chronochroma.dart';
import 'package:chronochroma/components/entities/attack_hitbox.dart';
import 'package:chronochroma/components/map/coin.dart';
import 'package:chronochroma/helpers/directions.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

class Player extends SpriteAnimationComponent
    with HasGameRef<Chronochroma>, CollisionCallbacks {
  // Attributs de vie

  late int health;
  late final int maxHealth;
  final List<int> healthLevels = [1700, 2500, 3500, 4500, 5600];

  // Attributs de direction et d'effets
  final double gravity = 1.03;
  Vector2 velocity = Vector2(0, 0);
  double fallingVelocity = 0;
  Direction direction = Direction.none;
  double saturation = 0;
  late int damageDeal;
  final List<int> damageDealLevels = [10, 15, 20, 25, 30];

  // Attributs d'animation
  late final SpriteAnimation _idleAnimation;
  late final SpriteAnimation _crouchAnimation;
  late final SpriteAnimation _jumpAnimation;
  late final SpriteAnimation _runAnimation;
  late final SpriteAnimation _slideAnimation;
  late final SpriteAnimation _attackAnimation;
  late final SpriteAnimation _crouchAttackAnimation;

  // Attributs de vitesse d'animation
  final double _idleAnimationSpeed = 0.15;
  final double _crouchAnimationSpeed = 0.15;
  final double _jumpAnimationSpeed = 0.15;
  final double _runAnimationSpeed = 0.08;
  final double _slideAnimationSpeed = 0.12;
  late final double _attackAnimationSpeed;
  late final double _crouchAttackAnimationSpeed;
  final List<double> attackAnimationSpeedLevels = [
    0.10,
    0.09,
    0.08,
    0.07,
    0.05
  ];

  // Attributs de déplacement
  final double _moveSpeed = 5;
  final double jumpMultiplier = 2.2;
  final double downMultiplier = 0.5;
  late final double xMultiplier;
  final List<double> xMultiplierLevels = [1, 1.1, 1.2, 1.3, 1.4];
  final double yVelocityMax = 8;

  // Attributs d'états et de permissions
  bool facingRight = true;
  bool canJump = true;
  bool isJumping = false;
  bool canSlide = true;
  bool canCrouch = true;
  bool isCrouching = false;
  bool canAttack = true;
  bool isAttacking = false;
  bool jumpCooldown = false;
  bool needSaturationUpdate = true;
  bool isInvincible = false;

  // Attributs hitboxes effectives
  late RectangleHitbox topHitBox;
  late RectangleHitbox frontHitBox;
  late RectangleHitbox bottomHitBox;

  // Attributs hitboxes de référence pour le joueur debout
  final RectangleHitbox topHitBoxStandModel = (RectangleHitbox(
    size: Vector2(18, 24),
    position: Vector2(256 / 2 - 8, 16),
  ));
  final RectangleHitbox frontHitBoxStandModel = (RectangleHitbox(
    size: Vector2(16, 78),
    position: Vector2(256 / 2 + 16, 24),
    isSolid: true,
  ));
  final RectangleHitbox bottomHitBoxStandModel = (RectangleHitbox(
    size: Vector2(18, 30),
    position: Vector2(256 / 2 - 8, 86),
    isSolid: true,
  ));

  // Attributs hitboxes de référence pour le joueur accroupi
  final RectangleHitbox topHitBoxSlideModel = (RectangleHitbox(
    size: Vector2(18, 24),
    position: Vector2(256 / 2 - 8, 36),
  ));
  final RectangleHitbox frontHitBoxSlideModel = (RectangleHitbox(
    size: Vector2(16, 36),
    position: Vector2(256 / 2 + 16, 56),
    isSolid: true,
  ));
  final RectangleHitbox bottomHitBoxSlideModel = (RectangleHitbox(
    size: Vector2(18, 30),
    position: Vector2(256 / 2 - 8, 86),
    isSolid: true,
  ));

  // Constructeur du joueur
  Player() : super(size: Vector2(256, 128), anchor: Anchor.center) {
    // Définition des hitboxes
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

    // Définition des couleurs de debug
    topHitBox.debugMode = false;
    topHitBox.debugColor = Colors.red;
    bottomHitBox.debugMode = false;
    bottomHitBox.debugColor = Colors.red;
    frontHitBox.debugMode = false;
    frontHitBox.debugColor = Colors.orange;

    // Ajout des hitboxes au joueur
    add(topHitBox);
    add(bottomHitBox);
    add(frontHitBox);
  }

  // Chargement des animations
  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Récupération des améliorations

    // maxHealth = healthLevels[((gameRef.compte?.persoVieMax)! - 1) ?? 0]; // Vie
    maxHealth = (gameRef.compte?.persoVieMax != null)
        ? healthLevels[gameRef.compte!.persoVieMax! - 1]
        : healthLevels[0]; // Vie
    // damageDeal =
    //     damageDealLevels[((gameRef.compte?.persoForceMax)! - 1) ?? 0]; // Degats
    damageDeal = (gameRef.compte?.persoForceMax != null)
        ? damageDealLevels[gameRef.compte!.persoForceMax! - 1]
        : damageDealLevels[0]; // Degats
    // xMultiplier = xMultiplierLevels[((gameRef.compte?.persoVitesseMax)! - 1) ??
    //     0]; // Vitesse de déplacement
    xMultiplier = (gameRef.compte?.persoVitesseMax != null)
        ? xMultiplierLevels[gameRef.compte!.persoVitesseMax! - 1]
        : xMultiplierLevels[0]; // Vitesse de déplacement
    // _attackAnimationSpeed = attackAnimationSpeedLevels[
    //     ((gameRef.compte?.persoVitesseMax!)! - 1) ?? 0]; // Vitesse d'attaque
    _attackAnimationSpeed = (gameRef.compte?.persoVitesseMax != null)
        ? attackAnimationSpeedLevels[gameRef.compte!.persoVitesseMax! - 1]
        : attackAnimationSpeedLevels[0]; // Vitesse d'attaque
    // _crouchAttackAnimationSpeed = _attackAnimationSpeed;
    _crouchAttackAnimationSpeed = _attackAnimationSpeed;

    health = maxHealth;
    await _loadAnimations().then((_) => {animation = _idleAnimation});
  }

  // Paramètrages des animations pour le personnage
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
        row: 0, stepTime: _attackAnimationSpeed, from: 2, to: 6, loop: false);

    _crouchAttackAnimation = crouchAttackSpriteSheet.createAnimation(
        row: 0,
        stepTime: _crouchAttackAnimationSpeed,
        from: 0,
        to: 6,
        loop: false);
  }

// REMOVE : debug FPS
  int frame = 0;
  bool needFrameDisplay = true;

  // dt pour delta time, c'est le temps de rafraichissement
  @override
  void update(double dt) async {
    super.update(dt);
    frame++;
    if (canJump && (velocity.y + fallingVelocity) > 0) {
      canJump = false;
      isJumping = false;
    }

    if (gameRef.currentLevelIter > 1 && health > 0) {
      health--;

      if (health == 0) {
        gameRef.gameOver();
      }

      if (needSaturationUpdate) {
        needSaturationUpdate = false;
        saturation = (health / maxHealth) - 1;
        await Future.delayed(const Duration(milliseconds: 500)).then((_) async {
          needSaturationUpdate = true;
        });
      }
    }

    if (needFrameDisplay) {
      needFrameDisplay = false;
      await Future.delayed(const Duration(milliseconds: 1000)).then((_) async {
        frame = 0;
        needFrameDisplay = true;
      });
    }

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
      if (velocity.y < -10) {
        if (fallingVelocity > yVelocityMax) {
          fallingVelocity = yVelocityMax;
        }
      } else {
        fallingVelocity = 0;
      }
    }

    applyMovements();

    velocity.x = 0;
    velocity.y = 0;

    updatePosition();
  }

// Donne de la vélocité au personnage en fonction de la direction et de l'état
  updatePosition() {
    if (isJumping) {
      reduceHitBox(false);
      if ((direction == Direction.upLeft || direction == Direction.left) &&
          isJumping) {
        if (!topHitBox.isColliding) {
          velocity.y = -_moveSpeed * jumpMultiplier;
        }
        if (!frontHitBox.isColliding && !facingRight) {
          velocity.x = -_moveSpeed * xMultiplier;
        } else {
          velocity.x = 0;
        }
      } else if ((direction == Direction.upRight ||
              direction == Direction.right) &&
          isJumping) {
        if (!topHitBox.isColliding) {
          velocity.y = -_moveSpeed * jumpMultiplier;
        }
        if (!frontHitBox.isColliding && facingRight) {
          velocity.x = _moveSpeed * xMultiplier;
        }
      } else if (isJumping) {
        if (!topHitBox.isColliding) {
          velocity.y = -_moveSpeed * jumpMultiplier;
        }
      }
    } else {
      switch (direction) {
        case Direction.down:
          reduceHitBox(canCrouch);
          velocity.x = 0;
          if (!bottomHitBox.isColliding && velocity.y.abs() < yVelocityMax) {
            velocity.y += _moveSpeed * downMultiplier;
          }
          break;
        case Direction.upLeft:
        case Direction.left:
          reduceHitBox(false);
          if (!frontHitBox.isColliding && !facingRight) {
            velocity.x = -_moveSpeed * xMultiplier;
          } else {
            velocity.x = 0;
          }
          break;
        case Direction.upRight:
        case Direction.right:
          reduceHitBox(false);
          if (!frontHitBox.isColliding && facingRight) {
            velocity.x = _moveSpeed * xMultiplier;
          } else {
            velocity.x = 0;
          }
          break;
        case Direction.downLeft:
          reduceHitBox(canSlide);
          if (!bottomHitBox.isColliding && velocity.y.abs() < yVelocityMax) {
            velocity.y = _moveSpeed * (downMultiplier / 2);
          }
          if (!frontHitBox.isColliding && !facingRight) {
            velocity.x = -_moveSpeed * xMultiplier;
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
            velocity.x = _moveSpeed * xMultiplier;
          } else {
            velocity.x = 0;
          }
          break;
        case Direction.up:
        case Direction.none:
          reduceHitBox((isAttacking && isCrouching));
          break;
      }
    }
    updateAnimation();
  }

  // Détecteur de collision
  @override
  void onCollision(intersectionPoints, other) async {
    super.onCollision(intersectionPoints, other);
    if (other is! Coin) {
      if (topHitBox.isColliding) {
        if (isJumping) {
          isJumping = false;
        }
      }
      if (bottomHitBox.isColliding) {
        if (canJump == false && jumpCooldown == false) {
          jumpCooldown = true;
          await Future.delayed(const Duration(milliseconds: 100))
              .then((_) async {
            canJump = true;
            jumpCooldown = false;
          });
        }
      }
      if (frontHitBox.isColliding) {}
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

  // Effectue les déplacements du personnage en fonction de la vélocité
  void applyMovements() async {
    if (!isAttacking) {
      velocity.x = velocity.x.ceilToDouble();
      int i = 1;
      while (!frontHitBox.isColliding && i <= velocity.x.abs()) {
        if (facingRight) {
          position.x += 1;
          Transform.translate(offset: const Offset(1, 0));
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
      canAttack = true;
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
            if (facingRight) {
              gameRef.attackHitbox = AttackHitbox(
                  Vector2(65, 80), Vector2(position.x, position.y - 40));
            } else {
              gameRef.attackHitbox = AttackHitbox(
                  Vector2(65, 80), Vector2(position.x - 70, position.y - 40));
            }
            gameRef.add(gameRef.attackHitbox);
            canAttack = false;
          }
          _attackAnimation.onComplete = () {
            gameRef.attackHitbox.removeFromParent();

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
            if (facingRight) {
              gameRef.attackHitbox = AttackHitbox(
                  Vector2(65, 65), Vector2(position.x, position.y - 20));
            } else {
              gameRef.attackHitbox = AttackHitbox(
                  Vector2(65, 65), Vector2(position.x - 70, position.y - 20));
            }
            gameRef.add(gameRef.attackHitbox);
            canAttack = false;
          }
          _crouchAttackAnimation.onComplete = () {
            gameRef.attackHitbox.removeFromParent();
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

  // Téléporte le personnage à la position donnée
  void teleport(Vector2 position) {
    this.position = position;
  }

  void teleportRelative(Vector2 position) {
    this.position += position;
  }

  Future<void> subirDegat(int degat) async {
    if (isInvincible) return;
    if ((health - degat) <= 0) {
      health = 0;
      gameRef.gameOver();
    } else {
      gameRef.camera.shake(intensity: 1, duration: 0.4);
      ColorEffect effect = ColorEffect(
          const Color.fromARGB(255, 212, 8, 8),
          const Offset(0.0, 0.5),
          EffectController(
            duration: 0.4,
            reverseDuration: 0.4,
          ));
      add(effect);
      health -= degat;
      isInvincible = true;
      await Future.delayed(const Duration(milliseconds: 1000))
          .then((_) => isInvincible = false);
    }
  }

  @override
  double get x => position.x;
}
