import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class SalonModal extends StatefulWidget {
  SalonModal({Key? key}) : super(key: key);

  @override
  _SalonModalState createState() => _SalonModalState();
}

/// Classe d'état du widget Modale
class _SalonModalState extends State<SalonModal> {
  bool _modalOpen = true;
  late bool _dontShowAgain = false;
  int index = 1;
  int numberOfPages = 5;

  @override
  void initState() {
    super.initState();
    getChecked();
  }

  void getChecked() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _dontShowAgain = prefs.getBool('dontShowAgainSalon') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height * 0.8;
    final double screenWidth = MediaQuery.of(context).size.width * 0.8;
    final player = AudioPlayer();

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        height: screenHeight,
        width: screenWidth,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Bienvenue sur Chronochroma !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: screenWidth * 0.60,
                  height: screenHeight * 0.70,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SingleChildScrollView(
                      child: getContent(index),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(16),
                  height: screenHeight * 0.60,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          IconButton(
                            onPressed: () {
                              if (index > 1) {
                                player.play(
                                    AssetSource('audio/interface_click.wav'));
                              }
                              setState(() {
                                index = index <= 1 ? 1 : index - 1;
                              });
                            },
                            icon: Icon(Icons.arrow_back_ios,
                                color: index == 1 ? Colors.grey : Colors.blue),
                          ),
                          Text(
                            '$index/$numberOfPages',
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              if (index < numberOfPages) {
                                player.play(
                                    AssetSource('audio/interface_click.wav'));
                              }
                              setState(() {
                                index = index >= numberOfPages
                                    ? numberOfPages
                                    : index + 1;
                              });
                            },
                            icon: Icon(Icons.arrow_forward_ios,
                                color: index == numberOfPages
                                    ? Colors.grey
                                    : Colors.blue),
                          ),
                        ]),
                        index == numberOfPages
                            ? Column(children: [
                                Row(
                                  children: [
                                    const Text('Ne plus afficher'),
                                    Checkbox(
                                      key: UniqueKey(),
                                      value: _dontShowAgain,
                                      onChanged: (value) {
                                        setState(() {
                                          _dontShowAgain = value!;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    player.play(AssetSource(
                                        'audio/interface_click.wav'));
                                    close();
                                  },
                                  child: const Text('Fermer'),
                                ),
                              ])
                            : Container(),
                      ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget getContent(int index) {
    switch (index) {
      case 1:
        return const Text(
          'Chrono Chroma est un jeu de plateforme dans lequel vous devez traverser des niveaux le plus rapidement possible.\n\nLes environnements s\'enchainent aléatoirement, sachez vous adapter.\n\nVous pouvez choisir une graine de génération (seed) au lancement pour bloquer cet aléatoire.',
          style: TextStyle(
            fontSize: 16,
          ),
        );
      case 2:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Flexible(
              child: Container(
                width: 280,
                child: const Text(
                  'La vie de votre personnage diminue si vous êtes blessé, mais aussi à mesure que le temps s\'écoule. Faites vite.\n\nLa santé de votre personnage a également un étroit lien avec la couleur affichée à l\'écran. Plus vous vous rapprocherez des portes de la mort, moins celle-ci sera présente.',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const Image(
              image: AssetImage('assets/images/waitGif.gif'),
              fit: BoxFit.fill,
              height: 120,
            ),
          ],
        );
      case 3:
        return Column(
          children: [
            const Text(
              'Pour espérer atteindre la fin, récupérez des pièces, tuer des ennemis, terminez des niveaux et utilisez votre butin pour acheter des améliorations.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                Image(
                    image: AssetImage('assets/images/coinTuto.png'),
                    fit: BoxFit.fill,
                    height: 40),
                Image(
                    image: AssetImage('assets/images/monsterTuto.png'),
                    fit: BoxFit.fill,
                    height: 75),
                Image(
                    image: AssetImage('assets/images/upgrades/speed.png'),
                    fit: BoxFit.fill,
                    height: 50),
              ],
            ),
          ],
        );
      case 4:
        return const Text(
          'Si vous êtes connecté, votre meilleur score sera sauvegarder dans le leaderboard accessible à l\'aide du bouton "SCORES".\n\nSi vous n\'avez pas de compte, pensez-y, votre progression sera alors sauvegardée.',
          style: TextStyle(
            fontSize: 16,
          ),
        );
      case 5:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Flexible(
              child: SizedBox(
                width: 280,
                child: Text(
                  'Vous pouvez vous mouvoir avec le joystick, courir, vous accroupir et glissez sur le sol.\n\n Le saut se situe sur son propre bouton.\n\nEnfin, l\'attaque a aussi un bouton dédié. Vous pouvez attaquer debout ou accroupi, mais pas durant une chute.',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            Column(
              children: const [
                Image(
                    image: AssetImage('assets/images/joystick_example.png'),
                    fit: BoxFit.fill,
                    height: 50),
                SizedBox(height: 16),
                Image(
                    image: AssetImage('assets/images/icons/jumpIcon.png'),
                    fit: BoxFit.fill,
                    height: 50),
                SizedBox(height: 16),
                Image(
                    image: AssetImage('assets/images/icons/swordIcon.png'),
                    fit: BoxFit.fill,
                    height: 50),
              ],
            )
          ],
        );
      default:
        return const Text(
          'Bon jeu !',
          style: TextStyle(
            fontSize: 16,
          ),
        );
    }
  }

  void close() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('dontShowAgainSalon', _dontShowAgain);
    setState(() {
      _modalOpen = false;
    });
    Navigator.of(context).pop();
  }

  void open() async {
    setState(() {
      _modalOpen = true;
    });
  }
}
