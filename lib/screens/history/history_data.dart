import 'package:hugeicons/hugeicons.dart';
import 'history_model.dart';
import 'history_styles.dart';

class HistoryData {
  static const List<HistoryTopic> topics = [
    // 1. Biblical Roots & Spiritual Awakening
    HistoryTopic(
      id: 'biblical_roots',
      title: 'The Spirit of Truth',
      subtitle: 'Biblical Foundations & the Living Holy Spirit',
      category: TopicCategory.origins,
      readTimeMinutes: 3,
      icon: HugeIcons.strokeRoundedSun02,
      primaryColor: HistoryStyles.azurePrimary,
      gradientColors: HistoryStyles.azureGradient,
      didYouKnow:
          'Long before the modern church was incorporated, early Filipinos recognized the promise of the Holy Spirit through profound spiritual gifts and natural healing.',
      summary:
          'At the very heart of Spiritism is the living promise of Jesus Christ—the pouring out of the Holy Spirit to teach, guide, heal, and bring spiritual understanding to all humanity.',
      sections: [
        HistorySection(
          heading: 'The Holy Spirit in Filipino Culture',
          body:
              'Since the 16th century, Filipinos maintained a unique and deeply personal relationship with the Holy Spirit. In the teachings of Jesus, believers discovered the promise of the Spirit of Truth—a divine Comforter and Helper who reveals spiritual mysteries when humankind is prepared to understand them.',
        ),
        HistorySection(
          heading: 'Scriptural Foundations',
          body:
              'Filipino Spiritism is rooted in sacred Scripture, where the Holy Spirit actively communicates with and guides the faithful.',
          bulletPoints: [
            'Joel 2:28-29: "I will pour out my Spirit on all people. Your sons and daughters will prophesy, your old men will dream dreams, your young men will see visions."',
            'Acts 1:8: "You will receive power when the Holy Spirit comes on you; and you will be my witnesses."',
            'John 14:26: "The Helper, the Holy Spirit, whom the Father will send in my name, He will teach you all things."',
            'Romans 8:14: "For as many as are led by the Spirit of God, these are sons of God."',
          ],
        ),
        HistorySection(
          heading: 'Healing and Elevation of the Soul',
          body:
              'The teachings emphasize that earthly life is not the final chapter, but an important classroom for moral growth. Physical healing, mental clarity, and spiritual purity work together, calling every believer to subordinate material desires to the eternal spirit.',
        ),
      ],
      keyScriptures: [
        'Joel 2:28-29',
        'John 14:26',
        'Acts 1:8',
        'Romans 8:14',
      ],
      quote:
          'Physical death is not the end of life and consciousness, but a transition from an earthly dwelling to a spiritual state.',
      quoteAuthor: 'UECFI Historical Records',
    ),

    // 2. Revolution & The Quest for Spiritual Freedom
    HistoryTopic(
      id: 'revolution_freedom',
      title: 'Awakening & Freedom',
      subtitle: 'The 1890s Revolution & Indigenous Faith',
      category: TopicCategory.freedom,
      readTimeMinutes: 3,
      icon: HugeIcons.strokeRoundedFlag01,
      primaryColor: HistoryStyles.rubyPrimary,
      gradientColors: HistoryStyles.rubyGradient,
      didYouKnow:
          'Many revolutionary leaders in 1896 were Spiritists who championed religious freedom alongside national sovereignty.',
      summary:
          'During centuries of colonial rule, indigenous spiritual practices were suppressed. In the late 19th century, Filipinos discovered European spiritist philosophy, validating their heritage and fueling their cry for religious liberty.',
      sections: [
        HistorySection(
          heading: 'Suppression and Resistance',
          body:
              'For nearly four centuries of Spanish rule, strict colonial laws forbade mediumship and indigenous spiritual expressions. In 1856, mediumship was officially declared prohibited by church authorities, pushing spiritual seekers underground.',
        ),
        HistorySection(
          heading: 'European Enlightenment & Kardec',
          body:
              'In 1858, Allan Kardec published "The Spirits\' Book" in France. Filipino intellectuals studying abroad in Europe encountered these works and brought them home. For the first time, native spiritual insights found philosophical vindication against claims of superstition.',
        ),
        HistorySection(
          heading: 'The Cry of 1896',
          body:
              'When the Philippine Revolution erupted, religious freedom was one of the central cries. Revolutionary heroes and Katipuneros saw Spiritism as an essential pillar of a free Filipino identity—free to seek God directly through love, reason, and spiritual communication.',
        ),
      ],
      quote:
          'Among the cry of the revolution of 1896 was the freedom of religion... free from colonial oppression and free to worship in spirit and truth.',
      quoteAuthor: 'UECFI Heritage Archives',
    ),

    // 3. The Pioneers & First Centers
    HistoryTopic(
      id: 'pioneers_first_centers',
      title: 'The First Centers',
      subtitle: 'Manila and Pangasinan (1900–1901)',
      category: TopicCategory.pioneers,
      readTimeMinutes: 3,
      icon: HugeIcons.strokeRoundedUserGroup,
      primaryColor: HistoryStyles.violetPrimary,
      gradientColors: HistoryStyles.violetGradient,
      didYouKnow:
          'The first organized Spiritist gathering in Manila met for regular spiritual services called "consultas familiares", combining prayer, doctrine, and healing.',
      summary:
          'At the dawn of the 20th century, two visionary leaders—Don Agustin dela Rosa in Manila and Don Juan Alvear in Pangasinan—established the first spiritual centers that sparked nationwide propagation.',
      sections: [
        HistorySection(
          heading: 'The Manila Pioneers (Early 1900)',
          body:
              'In early 1900, Don Agustin dela Rosa and dedicated co-believers established the first Spiritist center in the City of Manila under the guidance of the Holy Spirit. The founding circle included Inocencio Echarri, Candido Dula, Marta Lopez de Dula, Pio Candido, Telesforo Candido, Manuel Candido, and Jose Gonzales.',
          bulletPoints: [
            'Regular services focused on worshipping God in Spirit and Truth.',
            'Spiritual consultations and healing sessions were freely provided to the community.',
            'Propagation quickly expanded to Bulacan, Pampanga, Rizal, Cavite, Laguna, Batangas, and Southern Quezon.',
          ],
        ),
        HistorySection(
          heading: 'Don Juan Alvear & "La Perseverancia" (1901)',
          body:
              'In 1901, Don Juan Alvear established the first center in Northern Luzon at San Fabian, Pangasinan, naming it "La Perseverancia". Together with Florentino Soriano and Alejo Baltazar, the message was carried throughout Ilocos, Tarlac, Nueva Ecija, Nueva Vizcaya, Cagayan Valley, Benguet, and beyond.',
        ),
      ],
      quote:
          'From small humble prayer gatherings in Manila and Pangasinan, the light of the Spirit ignited a movement across the entire archipelago.',
      quoteAuthor: 'History of Filipino Spiritism',
    ),

    // 4. The Grand Merger & Official Birth
    HistoryTopic(
      id: 'grand_merger_1909',
      title: 'The Great Union',
      subtitle: 'Merger and Legal Incorporation (1905–1909)',
      category: TopicCategory.origins,
      readTimeMinutes: 4,
      icon: HugeIcons.strokeRoundedCheckmarkBadge01,
      primaryColor: HistoryStyles.emeraldPrimary,
      gradientColors: HistoryStyles.emeraldGradient,
      didYouKnow:
          'It took over 3 years of careful testing and prayerful evaluation before the Manila and Pangasinan groups agreed to formally merge into one national body.',
      summary:
          'On February 19, 1909, the leaders of Manila and Pangasinan officially merged, signed the Articles of Incorporation (Escritura Social), and on February 29, 1909, UECFI was legally recognized by the government.',
      sections: [
        HistorySection(
          heading: 'The Historic Dialogue of 1905',
          body:
              'On February 19, 1905, Don Juan Alvear sent delegates led by Florentino Soriano and Alejo Baltazar to meet with Don Agustin dela Rosa in Manila. Rather than rushing into registration, the leaders spent more than three years studying, seeking proof, and verifying the authentic guidance of the Holy Spirit Protector.',
        ),
        HistorySection(
          heading: 'The "Escritura Social" of 1909',
          body:
              'Fully convinced of their divine alignment, the two groups agreed to stand together as one family. On February 19, 1909, they signed the Articles of Incorporation known as the "Escritura Social" before Notary Public Don Luciano dela Rosa.',
        ),
        HistorySection(
          heading: 'First General Assembly & SEC Approval',
          body:
              'With 15 affiliated centers represented at the first General Meeting in Manila, Don Agustin dela Rosa was elected the first President General. On February 29, 1909, the official incorporation was approved, marking the official birthday of Union Espiritista Cristiana de Filipinas, Inc.',
        ),
      ],
      quote:
          'On February 29, 1909, the registration of the Union was officially approved, formally establishing UECFI under the laws of the land.',
      quoteAuthor: 'Articles of Incorporation Record',
    ),

    // 5. The Sacred Mottos (Lemma)
    HistoryTopic(
      id: 'sacred_mottos',
      title: 'The Four Pillars',
      subtitle: 'The Inspiring Mottos of UECFI',
      category: TopicCategory.mottos,
      readTimeMinutes: 2,
      icon: HugeIcons.strokeRoundedShieldCheck,
      primaryColor: HistoryStyles.goldPrimary,
      gradientColors: HistoryStyles.goldGradient,
      didYouKnow:
          'The Latin & Spanish mottos chosen in 1909 emphasize that faith and scientific reason must work together alongside selfless charity.',
      summary:
          'The founding fathers adopted four guiding maxims that define the moral, spiritual, and social mission of every UECFI member.',
      sections: [
        HistorySection(
          heading: '1. Hacia Dios Por La Ciencia Y El Amor',
          body:
              '"Towards God Through Science and Love." Faith should never be blind. We approach our Creator through both genuine spiritual love and rational, enlightened understanding.',
        ),
        HistorySection(
          heading: '2. Guerra a la Ignorancia y al Fanatismo',
          body:
              '"War Against Ignorance and Fanaticism." Spiritual knowledge liberates the mind. Members are called to seek truth, reject superstition, and cultivate discernment.',
        ),
        HistorySection(
          heading: '3. Sin Caridad No Hay Salvacion Posible',
          body:
              '"Without Charity, There Is No Possible Salvation." Loving service and benevolence toward others is the supreme demonstration of spiritual progress.',
        ),
        HistorySection(
          heading: '4. Todos Para Uno Y Uno Para Todos',
          body:
              '"All For One, and One For All." A call to unbreakable unity, brotherhood, and communal solidarity among all believers.',
        ),
      ],
      quote:
          'Towards God through Science and Love: where spiritual truth enlightens the mind, and selfless charity redeems the soul.',
      quoteAuthor: 'UECFI Fundamental Lemma',
    ),
  ];

  // --- MILESTONES / TIMELINE DATA ---
  static const List<TimelineEvent> timelineEvents = [
    TimelineEvent(
      year: '1900',
      title: 'First Center in Manila',
      description:
          'Don Agustin dela Rosa and founding brethren hold regular spiritual services (consultas familiares) and healing circles in Manila.',
      badgeText: 'Pioneering Era',
      gradientColors: HistoryStyles.violetGradient,
      icon: HugeIcons.strokeRoundedLocation01,
    ),
    TimelineEvent(
      year: '1901',
      title: 'Center "La Perseverancia"',
      description:
          'Don Juan Alvear establishes the pioneer center in San Fabian, Pangasinan, leading the expansion of Spiritism across Northern Luzon.',
      badgeText: 'Northern Expansion',
      gradientColors: HistoryStyles.azureGradient,
      icon: HugeIcons.strokeRoundedChurch,
    ),
    TimelineEvent(
      year: '1905',
      title: 'The Great Historic Conference',
      description:
          'On February 19, delegates from Pangasinan travel to Manila to begin formal dialogues with the Manila group for national unity.',
      badgeText: 'Dialogue of Unity',
      gradientColors: HistoryStyles.amberGradient,
      icon: HugeIcons.strokeRoundedHandPrayer,
    ),
    TimelineEvent(
      year: '1909',
      title: 'Formal Incorporation of UECFI',
      description:
          'Escritura Social signed on Feb 19; SEC registration approved on Feb 29. Don Agustin dela Rosa is elected as the first President General.',
      badgeText: 'Official Birth',
      gradientColors: HistoryStyles.emeraldGradient,
      icon: HugeIcons.strokeRoundedCheckmarkBadge01,
    ),
    TimelineEvent(
      year: '1959',
      title: 'First 50-Year Corporate Renewal',
      description:
          'Following 50 golden years of continuous spiritual growth, the Union renews its corporate registration for another half-century.',
      badgeText: '50-Year Golden Jubilee',
      gradientColors: HistoryStyles.goldGradient,
      icon: HugeIcons.strokeRoundedBookOpen01,
    ),
    TimelineEvent(
      year: '2005',
      title: 'Centennial Anniversary Celebration',
      description:
          'UECFI celebrates 100 years of the historic 1905 union, joined by leaders from the International Spiritualist Federation (ISF), UK.',
      badgeText: 'Centennial (100 Years)',
      gradientColors: HistoryStyles.rubyGradient,
      icon: HugeIcons.strokeRoundedAward01,
    ),
    TimelineEvent(
      year: '2009',
      title: 'Renewal Extending to 2059',
      description:
          'UECFI re-incorporates under SEC Reg. No. 15147 for another 50 years, ensuring its sacred corporate mission until February 2059.',
      badgeText: 'SEC Reg. No. 15147',
      gradientColors: HistoryStyles.azureGradient,
      icon: HugeIcons.strokeRoundedLegalDocument01,
    ),
    TimelineEvent(
      year: '2059',
      title: 'The Vision for the Future',
      description:
          'Carrying forward the spiritual banner with modern technology, active youth chapters (KKEP/FYS), and centers worldwide.',
      badgeText: 'Future Horizon',
      gradientColors: HistoryStyles.violetGradient,
      icon: HugeIcons.strokeRoundedRocket,
    ),
  ];
}
