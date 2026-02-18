// Roadmap data models for the player development roadmap feature.

enum RoadmapPhase {
  foundation,  // 6th-8th grade
  development, // 9th-10th grade
  recruitment, // 11th grade
  commitment,  // 12th grade
}

enum StepStatus { locked, available, inProgress, completed }

enum StepCategory {
  technical,
  physical,
  academic,
  recruiting,
  mental,
}

class RoadmapStep {
  final String id;
  final String title;
  final String description;
  final String descriptionEs;
  final RoadmapPhase phase;
  final StepCategory category;
  final StepStatus status;
  final int orderIndex;
  final List<String> actionItems;
  final String? resourceUrl;
  final String? completedAt;
  final bool isPremium;

  const RoadmapStep({
    required this.id,
    required this.title,
    required this.description,
    required this.descriptionEs,
    required this.phase,
    required this.category,
    required this.status,
    required this.orderIndex,
    required this.actionItems,
    this.resourceUrl,
    this.completedAt,
    this.isPremium = false,
  });
}

class RoadmapData {
  // Static default roadmap steps — will be personalized via AI in production
  static List<RoadmapStep> defaultStepsForGrade(int grade) {
    final steps = <RoadmapStep>[];

    if (grade <= 8) {
      steps.addAll(_foundationSteps);
    } else if (grade <= 10) {
      steps.addAll(_foundationSteps.map((s) => RoadmapStep(
            id: s.id,
            title: s.title,
            description: s.description,
            descriptionEs: s.descriptionEs,
            phase: s.phase,
            category: s.category,
            status: StepStatus.completed,
            orderIndex: s.orderIndex,
            actionItems: s.actionItems,
          )));
      steps.addAll(_developmentSteps);
    } else if (grade == 11) {
      steps.addAll(_foundationSteps.map((s) => _asCompleted(s)));
      steps.addAll(_developmentSteps.map((s) => _asCompleted(s)));
      steps.addAll(_recruitmentSteps);
    } else {
      steps.addAll(_foundationSteps.map((s) => _asCompleted(s)));
      steps.addAll(_developmentSteps.map((s) => _asCompleted(s)));
      steps.addAll(_recruitmentSteps.map((s) => _asCompleted(s)));
      steps.addAll(_commitmentSteps);
    }

    return steps;
  }

  static RoadmapStep _asCompleted(RoadmapStep s) => RoadmapStep(
        id: s.id,
        title: s.title,
        description: s.description,
        descriptionEs: s.descriptionEs,
        phase: s.phase,
        category: s.category,
        status: StepStatus.completed,
        orderIndex: s.orderIndex,
        actionItems: s.actionItems,
      );

  static const List<RoadmapStep> _foundationSteps = [
    RoadmapStep(
      id: 'f1',
      title: 'Join a Competitive Club Team',
      description:
          'Start playing for a ECNL, MLS NEXT, or top regional club. Club soccer is where college coaches do most of their recruiting.',
      descriptionEs:
          'Únete a un equipo de club competitivo como ECNL o MLS NEXT. Los entrenadores universitarios reclutan principalmente a través del fútbol de club.',
      phase: RoadmapPhase.foundation,
      category: StepCategory.technical,
      status: StepStatus.available,
      orderIndex: 1,
      actionItems: [
        'Research top clubs in your area',
        'Attend tryouts for ECNL or MLS NEXT clubs',
        'If not ready, join a strong state league club',
        'Commit to year-round training',
      ],
    ),
    RoadmapStep(
      id: 'f2',
      title: 'Learn the College Recruiting Process',
      description:
          'Understand how college soccer recruiting works — transfer portal, international transfers, ID camps, and how coaches discover high school players.',
      descriptionEs:
          'Entiende cómo funciona el reclutamiento universitario — el portal de transferencias, transferencias internacionales, campamentos ID y cómo los entrenadores descubren jugadores.',
      phase: RoadmapPhase.foundation,
      category: StepCategory.recruiting,
      status: StepStatus.available,
      orderIndex: 2,
      actionItems: [
        'Read the Lanista Education module',
        'Watch documentaries on college soccer recruiting',
        'Talk to older players who went through the process',
        'Follow college soccer programs on social media',
      ],
    ),
    RoadmapStep(
      id: 'f3',
      title: 'Register with the NCAA Eligibility Center',
      description:
          'Register at ncaaeligibilitycenter.org early. NCAA requires 16 core courses with minimum GPA. Start tracking now.',
      descriptionEs:
          'Regístrate en ncaaeligibilitycenter.org temprano. La NCAA requiere 16 cursos básicos con GPA mínimo.',
      phase: RoadmapPhase.foundation,
      category: StepCategory.academic,
      status: StepStatus.available,
      orderIndex: 3,
      actionItems: [
        'Create account at ncaaeligibilitycenter.org',
        'Map out your 16 core courses across high school',
        'Aim for 2.3+ unweighted GPA (D1 minimum)',
        'Keep transcripts organized for future submission',
      ],
    ),
    RoadmapStep(
      id: 'f4',
      title: 'Start Your Highlight Reel',
      description:
          'Begin recording training sessions and games. A 3–5 minute highlight reel is your #1 recruiting tool with college coaches.',
      descriptionEs:
          'Comienza a grabar entrenamientos y partidos. Un video de highlights de 3–5 minutos es tu herramienta #1 de reclutamiento.',
      phase: RoadmapPhase.foundation,
      category: StepCategory.recruiting,
      status: StepStatus.available,
      orderIndex: 4,
      actionItems: [
        'Get a tripod and wide-angle lens for your phone',
        'Record every game and training session',
        'Save your best clips in a dedicated folder',
        'Create a Hudl, Wyscout, or Taka account',
      ],
    ),
  ];

  static const List<RoadmapStep> _developmentSteps = [
    RoadmapStep(
      id: 'd1',
      title: 'Build Your Athletic Profile',
      description:
          'Work with your club coach to assess your athletic benchmarks — speed, vertical, agility — and create a training plan to hit D1/D2 standards.',
      descriptionEs:
          'Trabaja con tu entrenador para evaluar tus capacidades atléticas y crear un plan de entrenamiento.',
      phase: RoadmapPhase.development,
      category: StepCategory.physical,
      status: StepStatus.available,
      orderIndex: 5,
      actionItems: [
        'Get tested: 40-yard dash, vertical, T-drill agility',
        'Set target benchmarks for your position',
        'Add position-specific strength training 3x/week',
        'Work with a speed coach if possible',
      ],
    ),
    RoadmapStep(
      id: 'd2',
      title: 'Create Your First Highlight Reel',
      description:
          'Edit your best clips into a professional 3–5 minute video. Lead with your best 30 seconds. Coaches decide in the first minute.',
      descriptionEs:
          'Edita tus mejores clips en un video profesional de 3–5 minutos. Empieza con tus mejores 30 segundos.',
      phase: RoadmapPhase.development,
      category: StepCategory.recruiting,
      status: StepStatus.available,
      orderIndex: 6,
      actionItems: [
        'Select 8–12 best clips from your footage',
        'Lead with your 3 best plays in first 30 seconds',
        'Add name, position, graduation year overlay',
        'Upload to Hudl and share link with coaches',
      ],
    ),
    RoadmapStep(
      id: 'd3',
      title: 'Research Target Programs',
      description:
          'Identify 20–30 programs at your target division level. Consider playing time, program culture, location, and major fit — not just prestige.',
      descriptionEs:
          'Identifica 20–30 programas en tu nivel de división objetivo. Considera tiempo de juego, cultura del programa y carrera académica.',
      phase: RoadmapPhase.development,
      category: StepCategory.recruiting,
      status: StepStatus.available,
      orderIndex: 7,
      actionItems: [
        'Use Lanista to filter programs by division and location',
        'Watch 3 games for each target school',
        'Research their recent recruiting classes',
        'Note the coach\'s system of play',
      ],
      isPremium: true,
    ),
    RoadmapStep(
      id: 'd4',
      title: 'Begin SAT/ACT Prep',
      description:
          'D1 and D2 programs look at test scores. Even a 100-point SAT improvement can open doors to better academic scholarships.',
      descriptionEs:
          'Los programas D1 y D2 consideran los resultados de pruebas. Incluso una mejora de 100 puntos en el SAT puede abrir más puertas.',
      phase: RoadmapPhase.development,
      category: StepCategory.academic,
      status: StepStatus.available,
      orderIndex: 8,
      actionItems: [
        'Take a baseline practice SAT/ACT',
        'Identify your weakest areas',
        'Use Khan Academy (free) for SAT prep',
        'Plan to take the SAT/ACT by end of 10th grade',
      ],
    ),
  ];

  static const List<RoadmapStep> _recruitmentSteps = [
    RoadmapStep(
      id: 'r1',
      title: 'Send Initial Emails to Coaches',
      description:
          'Reach out to your target coaches with a personalized email, your highlight reel, and academic profile. NCAA allows coaches to respond after June 15 of sophomore year.',
      descriptionEs:
          'Contacta a los entrenadores objetivo con un email personalizado, tu video y perfil académico.',
      phase: RoadmapPhase.recruitment,
      category: StepCategory.recruiting,
      status: StepStatus.available,
      orderIndex: 9,
      actionItems: [
        'Write a personalized 3-paragraph email template',
        'Reference the coach\'s specific system and why you fit',
        'Attach highlight reel link and academic stats',
        'Follow up every 3 weeks if no response',
      ],
    ),
    RoadmapStep(
      id: 'r2',
      title: 'Attend College ID Camps',
      description:
          'Attend 3–5 ID camps at target schools. Genuine ID camps are run by the head coach — avoid ones run only by assistant coaches or third parties.',
      descriptionEs:
          'Asiste a 3–5 campamentos ID en escuelas objetivo. Los campamentos genuinos son dirigidos por el entrenador principal.',
      phase: RoadmapPhase.recruitment,
      category: StepCategory.recruiting,
      status: StepStatus.available,
      orderIndex: 10,
      actionItems: [
        'Research which camps are run by head vs. assistant coaches',
        'Prioritize camps at top 5 target schools',
        'Prepare questions for the coaching staff',
        'Follow up with a thank-you email within 24 hours',
      ],
    ),
    RoadmapStep(
      id: 'r3',
      title: 'Take Official Campus Visits',
      description:
          'NCAA D1 allows 5 official visits (program pays). D2 allows unlimited official visits. Use these to evaluate the program, team culture, and academics.',
      descriptionEs:
          'La NCAA D1 permite 5 visitas oficiales (el programa paga). D2 permite visitas oficiales ilimitadas.',
      phase: RoadmapPhase.recruitment,
      category: StepCategory.recruiting,
      status: StepStatus.available,
      orderIndex: 11,
      actionItems: [
        'Request official visits from interested programs',
        'Prepare a list of 10+ questions for each visit',
        'Talk to current players without coaches present',
        'Evaluate practice facilities, dorms, and team culture',
      ],
      isPremium: true,
    ),
    RoadmapStep(
      id: 'r4',
      title: 'Prepare Your NLI / Verbal Offer Decision',
      description:
          'Understand the National Letter of Intent process. Verbal offers are non-binding. NLI signing day is your formal commitment.',
      descriptionEs:
          'Entiende el proceso de la Carta de Intención Nacional. Las ofertas verbales no son vinculantes.',
      phase: RoadmapPhase.recruitment,
      category: StepCategory.recruiting,
      status: StepStatus.available,
      orderIndex: 12,
      actionItems: [
        'Understand the difference between verbal offers and NLI',
        'Compare financial aid packages across offers',
        'Consult with your family and mentor',
        'Don\'t feel pressured by artificial deadlines',
      ],
    ),
  ];

  static const List<RoadmapStep> _commitmentSteps = [
    RoadmapStep(
      id: 'c1',
      title: 'Sign Your NLI or Acceptance',
      description:
          'Signing Day! Sign your National Letter of Intent or submit your enrollment deposit. Notify other coaches you were in contact with as a courtesy.',
      descriptionEs:
          '¡Día de Firma! Firma tu Carta de Intención Nacional o envía tu depósito de inscripción.',
      phase: RoadmapPhase.commitment,
      category: StepCategory.recruiting,
      status: StepStatus.available,
      orderIndex: 13,
      actionItems: [
        'Sign the NLI or enrollment deposit',
        'Send thank-you emails to coaches who recruited you',
        'Notify all other programs of your decision',
        'Announce your commitment on social media if desired',
      ],
    ),
    RoadmapStep(
      id: 'c2',
      title: 'Prepare for College Training',
      description:
          'College soccer is a massive step up. Use senior year to train at the highest level possible and arrive ready to compete.',
      descriptionEs:
          'El fútbol universitario es un gran salto. Usa el año senior para entrenar al más alto nivel posible.',
      phase: RoadmapPhase.commitment,
      category: StepCategory.physical,
      status: StepStatus.available,
      orderIndex: 14,
      actionItems: [
        'Request a pre-season training plan from your future coach',
        'Train with purpose — simulate college intensity',
        'Work on any specific weaknesses your coach identified',
        'Stay injury-free — the last thing you want is surgery before college',
      ],
    ),
  ];
}
