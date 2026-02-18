// Education content for the Lanista Education Module.
// Covers the college soccer recruiting process, transfer portal,
// ID camps, divisions, international transfers, and gap year academies.

class EducationArticle {
  final String id;
  final String title;
  final String titleEs;
  final String summary;
  final String summaryEs;
  final String emoji;
  final String category;
  final String readTime;
  final bool isPremium;
  final List<EducationSection> sections;

  const EducationArticle({
    required this.id,
    required this.title,
    required this.titleEs,
    required this.summary,
    required this.summaryEs,
    required this.emoji,
    required this.category,
    required this.readTime,
    required this.sections,
    this.isPremium = false,
  });
}

class EducationSection {
  final String heading;
  final String headingEs;
  final String body;
  final String bodyEs;

  const EducationSection({
    required this.heading,
    required this.headingEs,
    required this.body,
    required this.bodyEs,
  });
}

class EducationData {
  static const List<String> categories = [
    'All',
    'The System',
    'Divisions',
    'ID Camps',
    'Transfer Portal',
    'International',
    'Gap Year',
    'Academic',
  ];

  static const List<EducationArticle> articles = [
    EducationArticle(
      id: 'e1',
      title: 'The State of College Soccer Recruiting in 2026',
      titleEs: 'El Estado del Reclutamiento de Fútbol Universitario en 2026',
      summary: 'Why the system is broken — and how Lanista is fixing it.',
      summaryEs: 'Por qué el sistema está roto — y cómo Lanista lo está arreglando.',
      emoji: '⚽',
      category: 'The System',
      readTime: '5 min read',
      sections: [
        EducationSection(
          heading: 'The Problem',
          headingEs: 'El Problema',
          body:
              'College soccer coaches today are overwhelmed — and they have a clear order of priorities: first the transfer portal, then international transfers, and finally, if they have time, high school recruits. The result? Thousands of talented high school players go unrecruited every year, not because they lack ability, but because no one is watching.\n\nTop youth leagues like MLS NEXT and ECNL are full of players with D1 potential who never get a single college offer. Meanwhile, coaches at smaller programs struggle to find the right fit. Both sides are failing each other.',
          bodyEs:
              'Los entrenadores universitarios de fútbol hoy están abrumados — y tienen un orden claro de prioridades: primero el portal de transferencias, luego las transferencias internacionales y, finalmente, si tienen tiempo, los reclutas de preparatoria. El resultado: miles de jugadores talentosos de preparatoria no son reclutados cada año, no porque les falte habilidad, sino porque nadie los está observando.',
        ),
        EducationSection(
          heading: 'The Transfer Portal Effect',
          headingEs: 'El Efecto del Portal de Transferencias',
          body:
              'Since the NCAA opened unrestricted transfer eligibility in 2021, college coaches have dramatically shifted their recruiting focus. A player already at the college level — even a backup — is a known quantity. A high school junior is a two-year bet. This means coaches now fill up to 60–70% of their roster needs through the portal, leaving very few scholarships for high school seniors.',
          bodyEs:
              'Desde que la NCAA abrió la elegibilidad de transferencia sin restricciones en 2021, los entrenadores universitarios han cambiado dramáticamente su enfoque de reclutamiento. Un jugador ya en el nivel universitario — incluso un suplente — es una cantidad conocida. Un jugador de preparatoria en su penúltimo año es una apuesta de dos años.',
        ),
        EducationSection(
          heading: 'What This Means for You',
          headingEs: 'Qué Significa Esto para Ti',
          body:
              'You cannot wait to be discovered. You need to be proactive. Research programs, email coaches, attend the right ID camps, build a highlight reel, and make sure your academic profile opens doors. Lanista is designed to help you do all of this — and to help coaches find you.',
          bodyEs:
              'No puedes esperar a ser descubierto. Necesitas ser proactivo. Investiga programas, escribe correos a entrenadores, asiste a los campamentos ID correctos, crea un video de highlights y asegúrate de que tu perfil académico abra puertas.',
        ),
      ],
    ),

    EducationArticle(
      id: 'e2',
      title: 'D1 vs D2 vs D3: Which Division Is Right for You?',
      titleEs: 'D1 vs D2 vs D3: ¿Qué División Es la Correcta para Ti?',
      summary: 'Understanding the real differences — beyond the rankings.',
      summaryEs: 'Entendiendo las diferencias reales — más allá de los rankings.',
      emoji: '🏆',
      category: 'Divisions',
      readTime: '6 min read',
      sections: [
        EducationSection(
          heading: 'NCAA Division I',
          headingEs: 'NCAA División I',
          body:
              'D1 is the highest level of college soccer. Programs can offer up to 9.9 scholarships for men (divided among many players) and 14 full scholarships for women. Training demands are intense — 20+ hours per week during season. D1 requires a minimum 2.3 GPA in 16 core courses and an academic index meeting NCAA standards.\n\nThe reality: most D1 offers are partial scholarships. A "full ride" at D1 is extremely rare. Many D1 players receive 25–50% scholarship and make up the rest through financial aid.',
          bodyEs:
              'D1 es el nivel más alto del fútbol universitario. Los programas pueden ofrecer hasta 9.9 becas para hombres y 14 becas completas para mujeres. Los entrenamientos son intensos — más de 20 horas por semana durante la temporada.',
        ),
        EducationSection(
          heading: 'NCAA Division II',
          headingEs: 'NCAA División II',
          body:
              'D2 is often the sweet spot for serious players who want athletic scholarships and still have a real college academic experience. Programs can offer up to 9.0 scholarships for men and 9.9 for women. Academic standards are similar to D1. Competition level is high — many D2 players could compete at D1 level.',
          bodyEs:
              'D2 es a menudo el punto ideal para jugadores serios que desean becas atléticas y aún así tener una experiencia universitaria académica real.',
        ),
        EducationSection(
          heading: 'NCAA Division III',
          headingEs: 'NCAA División III',
          body:
              'D3 programs cannot offer athletic scholarships — but they can offer generous academic merit aid that, combined with need-based aid, can equal or exceed a partial D1 athletic scholarship. D3 programs emphasize the student-athlete balance, often offer more playing time, and the academic institutions are often exceptional (MIT, NYU, Amherst, Williams).',
          bodyEs:
              'Los programas D3 no pueden ofrecer becas atléticas — pero pueden ofrecer generosas ayudas académicas por mérito que, combinadas con ayuda basada en necesidad, pueden igualar o superar una beca atlética parcial de D1.',
        ),
        EducationSection(
          heading: 'NAIA and Junior College',
          headingEs: 'NAIA y Colegios Comunitarios (JUCO)',
          body:
              'NAIA programs can be very competitive and offer athletic scholarships without the strict NCAA eligibility requirements. Junior colleges (JUCO) are a great pathway if your grades need improvement or you want to prove yourself at the college level before transferring to a 4-year program.',
          bodyEs:
              'Los programas NAIA pueden ser muy competitivos y ofrecer becas atléticas sin los estrictos requisitos de elegibilidad de la NCAA. Los colegios comunitarios (JUCO) son un gran camino si tus calificaciones necesitan mejorar.',
        ),
      ],
    ),

    EducationArticle(
      id: 'e3',
      title: 'ID Camps: Genuine Opportunity or Money Grab?',
      titleEs: 'Campamentos ID: ¿Oportunidad Genuina o Negocio?',
      summary: 'How to tell the difference and which ones are worth your time.',
      summaryEs: 'Cómo distinguir y cuáles valen la pena.',
      emoji: '🎪',
      category: 'ID Camps',
      readTime: '5 min read',
      sections: [
        EducationSection(
          heading: 'What Is an ID Camp?',
          headingEs: '¿Qué Es un Campamento ID?',
          body:
              'Identification (ID) camps are camps hosted by college programs where coaches evaluate players. At legitimate ID camps, the head coach — not just assistants — is actively observing and evaluating players. They are a real way for coaches to see you in a controlled environment.',
          bodyEs:
              'Los campamentos de Identificación (ID) son campamentos organizados por programas universitarios donde los entrenadores evalúan jugadores. En los campamentos ID legítimos, el entrenador principal — no solo los asistentes — observa y evalúa activamente.',
        ),
        EducationSection(
          heading: 'Red Flags to Watch For',
          headingEs: 'Señales de Alerta',
          body:
              '• Camp run primarily by assistant coaches (head coach not present)\n• Very large camp size (100+ players) — coaches cannot evaluate everyone\n• Camp fee significantly higher than market rate (\$500+)\n• No personalized feedback at the end\n• Third-party organizer, not the school itself\n• School has no realistic spot for your graduation year\n\nSome ID camps exist primarily as revenue generators for assistant coaches, with no real recruiting intent. They take your \$300–500 and provide nothing in return.',
          bodyEs:
              '• Campamento dirigido principalmente por entrenadores asistentes\n• Tamaño de campamento muy grande — los entrenadores no pueden evaluar a todos\n• Tarifa significativamente más alta del mercado\n• Sin retroalimentación personalizada al final\n• Organizador externo, no la escuela misma',
        ),
        EducationSection(
          heading: 'Green Flags: Legitimate Camps',
          headingEs: 'Señales Positivas: Campamentos Legítimos',
          body:
              '• Head coach is present and actively evaluating\n• Small camp size (under 60 players per position group)\n• Coach has expressed specific interest in your graduation year\n• You receive detailed position-specific feedback\n• Follow-up communication after the camp\n• School\'s roster actually has a need for your position\n\nLanista\'s education module will flag which programs are actively recruiting your graduation year — helping you choose camps strategically.',
          bodyEs:
              '• El entrenador principal está presente y evalúa activamente\n• Tamaño de campamento pequeño (menos de 60 jugadores por grupo de posición)\n• El entrenador ha expresado interés específico en tu año de graduación\n• Recibes retroalimentación detallada específica de tu posición',
        ),
      ],
    ),

    EducationArticle(
      id: 'e4',
      title: 'The Transfer Portal: What Players Need to Know',
      titleEs: 'El Portal de Transferencias: Lo Que los Jugadores Necesitan Saber',
      summary: 'How the portal works and how it affects your recruiting chances.',
      summaryEs: 'Cómo funciona el portal y cómo afecta tus posibilidades de reclutamiento.',
      emoji: '🔄',
      category: 'Transfer Portal',
      readTime: '4 min read',
      sections: [
        EducationSection(
          heading: 'What Is the Transfer Portal?',
          headingEs: '¿Qué Es el Portal de Transferencias?',
          body:
              'The NCAA Transfer Portal is a database where college athletes can declare their intent to transfer. Since 2021, the portal has been open to all athletes — any player can transfer once without sitting out a year. This fundamentally changed college soccer.',
          bodyEs:
              'El Portal de Transferencias de la NCAA es una base de datos donde los atletas universitarios pueden declarar su intención de transferirse. Desde 2021, el portal está abierto a todos los atletas.',
        ),
        EducationSection(
          heading: 'Why It Hurts High School Recruiting',
          headingEs: 'Por Qué Afecta el Reclutamiento de Preparatoria',
          body:
              'Before the portal, coaches had to plan 2–3 years ahead to fill roster needs. Now they can wait until May or June — after spring semester — and fill gaps with proven college players. This has compressed the recruiting timeline and made coaches more cautious about high school recruits who are still developing.',
          bodyEs:
              'Antes del portal, los entrenadores tenían que planificar 2–3 años antes para cubrir necesidades del plantel. Ahora pueden esperar hasta mayo o junio y cubrir vacantes con jugadores universitarios probados.',
        ),
        EducationSection(
          heading: 'How to Use This to Your Advantage',
          headingEs: 'Cómo Usar Esto a Tu Favor',
          body:
              'Understand that coaches are always watching the portal. If you are committed to a school and the coach brings in a portal transfer at your position — do not panic, but do communicate. Ask about your role. Also: if you end up at a school where you are not getting playing time, the portal is available to you too. Use it wisely.',
          bodyEs:
              'Entiende que los entrenadores siempre están mirando el portal. Si estás comprometido con una escuela y el entrenador trae un jugador del portal en tu posición — no entres en pánico, pero comunícate. Pregunta sobre tu rol.',
        ),
      ],
    ),

    EducationArticle(
      id: 'e5',
      title: 'Gap Year Academies in Europe: Spain, England, France',
      titleEs: 'Academias de Año Sabático en Europa: España, Inglaterra, Francia',
      summary: 'A legitimate path to college soccer through elite European training.',
      summaryEs: 'Un camino legítimo al fútbol universitario a través del entrenamiento europeo de élite.',
      emoji: '🌍',
      category: 'Gap Year',
      readTime: '7 min read',
      isPremium: true,
      sections: [
        EducationSection(
          heading: 'What Are Gap Year Soccer Academies?',
          headingEs: '¿Qué Son las Academias de Año Sabático de Fútbol?',
          body:
              'Gap year programs like Eture (Spain), Generation Adidas International, and various UK-based academies allow post-senior high school players to spend 6–12 months training with professional or semi-professional clubs in Europe. The dual goal: improve your game dramatically and build a highlight reel that college coaches in the US cannot ignore.',
          bodyEs:
              'Los programas de año sabático como Eture (España), Generation Adidas International y varias academias del Reino Unido permiten a los jugadores post-preparatoria pasar 6–12 meses entrenando con clubes profesionales o semiprofesionales en Europa.',
        ),
        EducationSection(
          heading: 'Who Should Consider This Path?',
          headingEs: '¿Quién Debería Considerar Este Camino?',
          body:
              'Gap year academies are best suited for players who:\n• Did not receive offers at their target division level\n• Want to significantly improve their technical and tactical game\n• Have the maturity and independence to live abroad\n• Have parents supportive of the investment (\$15,000–40,000 for a full year program)\n• Have a clear plan to re-enter the college recruiting process after the year',
          bodyEs:
              'Las academias de año sabático son más adecuadas para jugadores que:\n• No recibieron ofertas en su nivel de división objetivo\n• Quieren mejorar significativamente su juego técnico y táctico\n• Tienen la madurez e independencia para vivir en el extranjero',
        ),
        EducationSection(
          heading: 'Top Programs to Research',
          headingEs: 'Principales Programas para Investigar',
          body:
              'Spain: Eture Academy (Seville/Madrid region) — partnered with several LaLiga affiliate clubs. Strong track record of placing players at D1/D2 schools.\n\nEngland: Several programs in the Championship/League One ecosystem, often based in Manchester, London, or Leeds.\n\nFrance: Programs linked to Ligue 2 academies, particularly strong in the south (Marseille, Montpellier region).\n\nAlways verify: Is the program registered? Do they have college placement data? Can you speak to alumni?',
          bodyEs:
              'España: Eture Academy (región de Sevilla/Madrid) — asociada con varios clubes afiliados de LaLiga. Historial sólido en colocación de jugadores en escuelas D1/D2.\n\nInglaterra: Varios programas en el ecosistema de Championship/League One.\n\nFrancia: Programas vinculados a academias de Ligue 2.',
        ),
      ],
    ),

    EducationArticle(
      id: 'e6',
      title: 'Your Highlight Reel: What Coaches Actually Watch',
      titleEs: 'Tu Video de Highlights: Lo Que los Entrenadores Realmente Ven',
      summary: 'The science of creating a reel that gets coaches to call you.',
      summaryEs: 'La ciencia de crear un video que haga que los entrenadores te llamen.',
      emoji: '🎥',
      category: 'The System',
      readTime: '4 min read',
      sections: [
        EducationSection(
          heading: 'The 30-Second Rule',
          headingEs: 'La Regla de los 30 Segundos',
          body:
              'College coaches receive hundreds of highlight videos. Research shows they make a preliminary evaluation in the first 30 seconds. If those 30 seconds do not grab them, the rest does not matter. Lead with your absolute best 2–3 plays — not your warm-up, not the full game, not a missed shot.',
          bodyEs:
              'Los entrenadores universitarios reciben cientos de videos de highlights. Las investigaciones muestran que hacen una evaluación preliminar en los primeros 30 segundos. Comienza con tus 2–3 mejores jugadas absolutas.',
        ),
        EducationSection(
          heading: 'What to Include (and Exclude)',
          headingEs: 'Qué Incluir (y Excluir)',
          body:
              'INCLUDE:\n• Position-specific moments (if you\'re a CB, show defending — not your one goal from a corner)\n• Full-field camera angle (coaches need context)\n• Plays that show your best quality (speed, vision, first touch, etc.)\n• 1v1 situations where you win\n\nEXCLUDE:\n• Sideline/parent angle footage\n• Music that drowns out the action\n• More than 5 minutes of total length\n• Plays where you made an error, even if the team scored',
          bodyEs:
              'INCLUYE:\n• Momentos específicos de posición\n• Ángulo de cámara de campo completo\n• Jugadas que muestren tu mejor cualidad\n\nEXCLUYE:\n• Metraje de la banda\n• Más de 5 minutos de duración total',
        ),
      ],
    ),
  ];
}
