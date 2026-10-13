import '../domain/models.dart';

/// A deterministic story adapter, not a generative AI provider.
/// It NEVER changes hit points, equipment or other rule-controlled facts.
class MockGameMaster {
  const MockGameMaster();

  String respond(Campaign campaign, String input, CharacterSheet hero) {
    final command = input.toLowerCase().trim();
    final heroName = hero.name;
    if (command.isEmpty) return '$heroName, was möchtest du tun?';
    if (RegExp(r'würfel|w20|w6|angriff|schieß|schies|kämpf').hasMatch(command)) {
      return '$heroName, für diese Handlung ist möglicherweise eine Probe nötig. Öffne den Würfelbereich und gib dein natürliches Würfelergebnis ein oder würfle digital. Unbestätigte Attribute werden nicht erfunden.';
    }
    if (campaign.id == 'heart-eternity') {
      if (RegExp(r'amulett|untersuch|ritter|körper').hasMatch(command)) {
        return '$heroName, das rote Amulett glüht an der Brust des gefallenen Schattenritters. Die Elfenmagierin beobachtet es angespannt. Möchtest du es aus der Nähe betrachten oder zuerst die Elfin befragen?';
      }
      if (RegExp(r'elf|magierin|frag|sprech|rede').hasMatch(command)) {
        return '$heroName, die Elfenmagierin senkt die Stimme: „Das ist das Zeichen des Schattenkönigs. Wir dürfen es nicht unbedacht berühren.“ Welche Frage stellst du ihr?';
      }
      return '$heroName, auf dem Marktplatz von Silberhain flackert das rote Amulett. Die Elfenmagierin wartet auf deine Entscheidung. Was tust du als Nächstes?';
    }
    if (RegExp(r'wald|spur|erkund|such').hasMatch(command)) {
      return '$heroName, im Nebelwald findest du frische Fußspuren zwischen silbernen Farnen. Weiter vorn hörst du eine Glocke. Folgst du den Spuren oder näherst du dich dem Geräusch?';
    }
    if (RegExp(r'tor|tempel|ruine').hasMatch(command)) {
      return '$heroName, die alten Torsteine tragen Zeichen, die im Abendlicht aufleuchten. Dahinter bewegt sich ein Schatten. Wie gehst du vor?';
    }
    return '$heroName, der Wind trägt ferne Stimmen durch Aetheria. Deine Entscheidung verändert den weiteren Weg. Was möchtest du als Nächstes unternehmen?';
  }
}
