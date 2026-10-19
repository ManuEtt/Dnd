import 'ability_generation.dart';
import 'models.dart';
import 'srd_character_classes.dart';

/// An honest SRD 5.2.1 creation audit: missing or unimplemented choices are
/// surfaced instead of silently pretending a character is fully legal.
enum CreationStepStatus { confirmed, missing, notAutomated }

class CreationStep {
  const CreationStep(this.id, this.title, this.status, this.detail);
  final String id, title, detail;
  final CreationStepStatus status;
}

class SrdCharacterCreationAudit {
  const SrdCharacterCreationAudit._();

  static List<CreationStep> inspect(HeroCharacter hero) {
    final definition = findSrdClass(hero.className);
    final knownBackground = SrdBackground.values.any(
      (entry) => entry.label == hero.background,
    );
    final skillsValid = definition != null &&
        hero.skills
            .where((skill) => definition.skillChoices.contains(skill))
            .toSet()
            .length >= definition.skillCount;
    final savesValid = definition != null &&
        definition.savingThrows.every(
          hero.savingThrowProficiencies.contains,
        );
    final knownAbilityScores = abilityNames.every(
      (ability) => hero.abilities[ability] != null,
    );
    return List.unmodifiable([
      CreationStep(
        'origin.species',
        'Spezies',
        hero.species.trim().isNotEmpty
            ? CreationStepStatus.confirmed
            : CreationStepStatus.missing,
        'Spezies und Bewegungsrate müssen den gewählten SRD-Regeln entsprechen.',
      ),
      CreationStep(
        'origin.background',
        'Hintergrund und Attributserhöhungen',
        hero.background.trim().isEmpty
            ? CreationStepStatus.missing
            : knownBackground
                ? CreationStepStatus.confirmed
                : CreationStepStatus.notAutomated,
        knownBackground
            ? 'SRD-Hintergrund notiert; vollständige weitere Herkunftsmerkmale '
                'müssen getrennt bestätigt werden.'
            : 'Der Assistent kennt aktuell vier SRD-Hintergründe mit '
                'Attributserhöhungen; freie Hintergründe bleiben ungeprüft.',
      ),
      CreationStep(
        'abilities.scores',
        'Sechs Attributswerte',
        knownAbilityScores
            ? CreationStepStatus.confirmed
            : CreationStepStatus.missing,
        'Standardverteilung oder Punktekauf im Attributassistenten auswählen.',
      ),
      CreationStep(
        'class.selection',
        'SRD-Klasse',
        definition == null
            ? CreationStepStatus.missing
            : CreationStepStatus.confirmed,
        'Zwölf SRD-Klassen stehen zur Verfügung.',
      ),
      CreationStep(
        'class.skills',
        'Klassenfertigkeiten',
        skillsValid
            ? CreationStepStatus.confirmed
            : CreationStepStatus.missing,
        'Benötigt die bestätigte Anzahl unterschiedlicher Klassenfertigkeiten.',
      ),
      CreationStep(
        'class.saving-throws',
        'Klassenrettungswürfe',
        savesValid
            ? CreationStepStatus.confirmed
            : CreationStepStatus.missing,
        'Erste Klassenstufe gewährt nur die zugehörigen Rettungswurf-Übungen.',
      ),
      CreationStep(
        'class.hit-points',
        'Start-Trefferpunkte',
        hero.maxHitPoints != null && hero.hitPoints != null
            ? CreationStepStatus.confirmed
            : CreationStepStatus.missing,
        'Maximaler Trefferwürfel der ersten Klasse plus KO-Modifikator.',
      ),
      CreationStep(
        'combat.armor-speed',
        'Rüstungsklasse und Bewegung',
        hero.armorClass != null && hero.speed != null
            ? CreationStepStatus.confirmed
            : CreationStepStatus.missing,
        'Unbekannte Werte nicht erraten; angelegte Rüstung separat bestätigen.',
      ),
      CreationStep(
        'class.equipment',
        'Startausrüstung oder Gold',
        hero.inventory.isNotEmpty || hero.gold != null
            ? CreationStepStatus.confirmed
            : CreationStepStatus.missing,
        'Eine konkrete Starterausrüstung oder ausdrücklich gewählte Gold-Option.',
      ),
      const CreationStep(
        'origin.feat',
        'Herkunftstalent',
        CreationStepStatus.notAutomated,
        'Vollständige Prüfung, Auswahl und automatische Wirkung '
            'aller Herkunftstalente noch nicht implementiert.',
      ),
      const CreationStep(
        'class.choices',
        'Spezielle Klassenwahlen und Zauber',
        CreationStepStatus.notAutomated,
        'Klassenmerkmale, vorbereitete Zauber, Expertise oder '
            'ähnliche Entscheidungen sind noch nicht für jede Klasse '
            'vollständig automatisiert.',
      ),
    ]);
  }
}
