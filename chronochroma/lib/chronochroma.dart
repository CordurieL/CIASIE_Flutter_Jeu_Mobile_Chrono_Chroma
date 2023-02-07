import 'dart:math';

import 'package:chronochroma/components/monster.dart';
import 'package:chronochroma/components/unstableFloor.dart';
import 'package:chronochroma/components/worldCollides.dart';
import 'package:flame/components.dart';
import 'dart:developer';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:chronochroma/helpers/directions.dart';
import 'package:chronochroma/components/player.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'components/barrel.dart';
import 'components/worldCollides.dart';


class Chronochroma extends FlameGame with HasCollisionDetection {
  final Player player = Player();
  late TiledComponent homeMap;


  @override
  Future<void> onLoad() async {
    await super.onLoad();
    homeMap = await TiledComponent.load('newMethods.tmx', Vector2.all(32));

    final worldLayer = homeMap.tileMap.getLayer<ObjectGroup>('ground');

    for (final object in worldLayer!.objects) {
      add(WorldCollides(
        size: Vector2(object.width, object.height),
        position: Vector2(object.x, object.y),
      ));
    }

    add(homeMap);

    final barrelLayer =
        homeMap.tileMap.getLayer<ObjectGroup>('barrels')!.objects;

    for (final object in barrelLayer) {
      if (Random().nextBool()) {
        add(Barrel(object));
      }
    }

    final unstableFloorLayer =
        homeMap.tileMap.getLayer<ObjectGroup>('unstableFloors')!.objects;

    for (final object in unstableFloorLayer) {
      add(UnstableFloor(object));
    }

    final bebou =
        homeMap.tileMap.getLayer<ObjectGroup>('bebou')!.objects;
    
    for (final object in bebou) {
      add(Monster(object));
    }


    add(player);
    camera.followComponent(player);
  }

  // Influence la direction du joueur
  onArrowKeyChanged(Direction direction) {
    player.direction = direction;
  }
}
