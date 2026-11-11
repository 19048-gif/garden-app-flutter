class Client {
  final int? id;
  final String name;
  final String phone;
  final String address;
  final String soilType;
  final String sunExposure;
  final String irrigationType;
  final String petsInfo;
  final double gardenArea;

  const Client({
    this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.soilType = 'Não especificado',
    this.sunExposure = 'Não especificado',
    this.irrigationType = 'Não especificado',
    this.petsInfo = 'Sem informação',
    this.gardenArea = 0.0,
  });

  factory Client.fromMap(Map<String, Object?> m) => Client(
        id: m['id'] as int?,
        name: m['name'] as String,
        phone: (m['phone'] as String?) ?? '',
        address: (m['address'] as String?) ?? '',
        soilType: (m['soil_type'] as String?) ?? 'Não especificado',
        sunExposure: (m['sun_exposure'] as String?) ?? 'Não especificado',
        irrigationType: (m['irrigation_type'] as String?) ?? 'Não especificado',
        petsInfo: (m['pets_info'] as String?) ?? 'Sem informação',
        gardenArea: (m['garden_area'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'soil_type': soilType,
        'sun_exposure': sunExposure,
        'irrigation_type': irrigationType,
        'pets_info': petsInfo,
        'garden_area': gardenArea,
      };
}

class Service {
  final int? id;
  final int clientId;
  final String clientName;
  final DateTime date;
  final String type;
  final String notes;
  final bool done;
  final double price;
  final String? photoBeforePath;
  final String? photoAfterPath;
  final int likes;
  final int durationMinutes;
  final double expenses;
  final String? diagnosticPhotoPath;
  final String diagnosticNotes;

  const Service({
    this.id,
    required this.clientId,
    this.clientName = '',
    required this.date,
    required this.type,
    this.notes = '',
    this.done = false,
    this.price = 0.0,
    this.photoBeforePath,
    this.photoAfterPath,
    this.likes = 0,
    this.durationMinutes = 0,
    this.expenses = 0.0,
    this.diagnosticPhotoPath,
    this.diagnosticNotes = '',
  });

  double get netProfit => price - expenses;

  /// Getter de compatibilidade para código antigo
  String? get photoPath => photoAfterPath ?? photoBeforePath;

  factory Service.fromMap(Map<String, Object?> m) => Service(
        id: m['id'] as int?,
        clientId: m['client_id'] as int,
        clientName: (m['client_name'] as String?) ?? '',
        date: DateTime.parse(m['date'] as String),
        type: m['type'] as String,
        notes: (m['notes'] as String?) ?? '',
        done: (m['done'] as int) == 1,
        price: (m['price'] as num?)?.toDouble() ?? 0.0,
        photoBeforePath: m['photo_before'] as String? ?? m['photo_path'] as String?,
        photoAfterPath: m['photo_after'] as String?,
        likes: (m['likes'] as int?) ?? 0,
        durationMinutes: (m['duration_minutes'] as int?) ?? 0,
        expenses: (m['expenses'] as num?)?.toDouble() ?? 0.0,
        diagnosticPhotoPath: m['diagnostic_photo'] as String?,
        diagnosticNotes: (m['diagnostic_notes'] as String?) ?? '',
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'client_id': clientId,
        'date': date.toIso8601String(),
        'type': type,
        'notes': notes,
        'done': done ? 1 : 0,
        'price': price,
        'photo_before': photoBeforePath,
        'photo_after': photoAfterPath,
        'photo_path': photoPath,
        'likes': likes,
        'duration_minutes': durationMinutes,
        'expenses': expenses,
        'diagnostic_photo': diagnosticPhotoPath,
        'diagnostic_notes': diagnosticNotes,
      };

  Service copyWith({
    bool? done,
    double? price,
    String? photoBeforePath,
    String? photoAfterPath,
    int? likes,
    int? durationMinutes,
    double? expenses,
    String? diagnosticPhotoPath,
    String? diagnosticNotes,
  }) =>
      Service(
        id: id,
        clientId: clientId,
        clientName: clientName,
        date: date,
        type: type,
        notes: notes,
        done: done ?? this.done,
        price: price ?? this.price,
        photoBeforePath: photoBeforePath ?? this.photoBeforePath,
        photoAfterPath: photoAfterPath ?? this.photoAfterPath,
        likes: likes ?? this.likes,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        expenses: expenses ?? this.expenses,
        diagnosticPhotoPath: diagnosticPhotoPath ?? this.diagnosticPhotoPath,
        diagnosticNotes: diagnosticNotes ?? this.diagnosticNotes,
      );
}

class Equipment {
  final int? id;
  final String name;
  final String category;
  final String powerType;
  final String status; // 'Operacional', 'Necessita Revisão', 'Avariado'
  final DateTime? lastMaintenance;
  final DateTime? nextMaintenance;
  final String notes;

  const Equipment({
    this.id,
    required this.name,
    required this.category,
    this.powerType = 'Combustível',
    this.status = 'Operacional',
    this.lastMaintenance,
    this.nextMaintenance,
    this.notes = '',
  });

  factory Equipment.fromMap(Map<String, Object?> m) => Equipment(
        id: m['id'] as int?,
        name: m['name'] as String,
        category: m['category'] as String,
        powerType: (m['power_type'] as String?) ?? 'Combustível',
        status: (m['status'] as String?) ?? 'Operacional',
        lastMaintenance: m['last_maintenance'] != null
            ? DateTime.tryParse(m['last_maintenance'] as String)
            : null,
        nextMaintenance: m['next_maintenance'] != null
            ? DateTime.tryParse(m['next_maintenance'] as String)
            : null,
        notes: (m['notes'] as String?) ?? '',
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'category': category,
        'power_type': powerType,
        'status': status,
        'last_maintenance': lastMaintenance?.toIso8601String(),
        'next_maintenance': nextMaintenance?.toIso8601String(),
        'notes': notes,
      };
}

class ServiceReview {
  final int? id;
  final int serviceId;
  final String clientName;
  final String comment;
  final int rating;
  final DateTime createdAt;

  const ServiceReview({
    this.id,
    required this.serviceId,
    required this.clientName,
    required this.comment,
    this.rating = 5,
    required this.createdAt,
  });

  factory ServiceReview.fromMap(Map<String, Object?> m) => ServiceReview(
        id: m['id'] as int?,
        serviceId: m['service_id'] as int,
        clientName: m['client_name'] as String,
        comment: m['comment'] as String,
        rating: (m['rating'] as int?) ?? 5,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'service_id': serviceId,
        'client_name': clientName,
        'comment': comment,
        'rating': rating,
        'created_at': createdAt.toIso8601String(),
      };
}

enum Role { gardener, client }

class Session {
  final Role role;
  final int? clientId; // só para o perfil cliente
  final String? clientName;
  const Session(this.role, {this.clientId, this.clientName});
  bool get isGardener => role == Role.gardener;
}

class PlantTip {
  final String name;
  final String category; // 'Flores', 'Árvores', 'Plantas', 'Serviços'
  final String priceRange;
  final String watering;
  final String pruningSeason;
  final String description;
  final String solutions;
  final String imageUrl;
  final String iconName;
  final List<String> pruningSteps;
  final String recommendedFertilizer;
  final String sunExposure;
  final String idealSoil;

  const PlantTip({
    required this.name,
    required this.category,
    required this.priceRange,
    required this.watering,
    required this.pruningSeason,
    required this.description,
    required this.solutions,
    required this.imageUrl,
    required this.iconName,
    this.pruningSteps = const [],
    this.recommendedFertilizer = 'Adubo orgânico equilibrado (N-P-K 10-10-10)',
    this.sunExposure = 'Exposição solar direta / Meia-sombra',
    this.idealSoil = 'Solo bem drenado e fértil',
  });
}

class PriceItem {
  final String title;
  final String category;
  final String price;
  final String unit;
  final String description;
  final String solution;
  final String imageUrl;

  const PriceItem({
    required this.title,
    required this.category,
    required this.price,
    required this.unit,
    required this.description,
    required this.solution,
    required this.imageUrl,
  });
}

const serviceTypes = [
  'Corte de relva',
  'Poda',
  'Plantação',
  'Rega / Sistema de rega',
  'Limpeza de jardim',
  'Manutenção de máquinas',
  'Outro',
];

const priceTableCatalog = [
  // --- MANUTENÇÃO ---
  PriceItem(
    title: 'Corte de Relvado Tradicional',
    category: 'Manutenção',
    price: '0,50 €',
    unit: 'por m² (Mínimo 25 €)',
    description: 'Corte completo de relva com acerto mecânico de bordas e aspiração de restos vegetais.',
    solution: '💡 Solução Encontrada: Regulação precisa da altura da lâmina para evitar a queimadura da raiz no Verão e afinação de contornos de canteiro.',
    imageUrl: 'https://images.unsplash.com/photo-1592417817098-8f3d6ef23a85?auto=format&fit=crop&w=600&q=80',
  ),
  PriceItem(
    title: 'Adubação & Nutrição do Solo',
    category: 'Manutenção',
    price: '30,00 €',
    unit: 'por aplicação / relvado',
    description: 'Aplicação de adubo de libertação lenta com azoto, fósforo e potássio.',
    solution: '💡 Solução Encontrada: Recuperação de relvados amarelados e fracos em apenas 10 dias com fertilização orgânica de alta absorção.',
    imageUrl: 'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?auto=format&fit=crop&w=600&q=80',
  ),
  PriceItem(
    title: 'Escarificação e Arejamento do Solo',
    category: 'Manutenção',
    price: '1,20 €',
    unit: 'por m²',
    description: 'Remoção mecânica de musgo e feltro vegetal acumulado na superfície do relvado.',
    solution: '💡 Solução Encontrada: Descompactação do solo permitindo que a água de rega, ar e nutrientes cheguem diretamente às raízes profundas.',
    imageUrl: 'https://images.unsplash.com/photo-1558904541-efa843a96f01?auto=format&fit=crop&w=600&q=80',
  ),
  PriceItem(
    title: 'Acerto de Bordaduras e Canteiros',
    category: 'Manutenção',
    price: '20,00 €',
    unit: 'por hora de trabalho',
    description: 'Recorte manual e mecânico das bordas do relvado junto a caminhos, passeios e canteiros.',
    solution: '💡 Solução Encontrada: Delimitação com pedras decorativas e telas anti-ervas para impedir o avanço descontrolado da relva.',
    imageUrl: 'https://images.unsplash.com/photo-1558904541-efa843a96f01?auto=format&fit=crop&w=600&q=80',
  ),
  PriceItem(
    title: 'Limpeza e Varredura de Folhas Secas',
    category: 'Manutenção',
    price: '25,00 €',
    unit: 'por intervenção',
    description: 'Remoção mecânica com soprador e aspiração de folhas caídas no Outono/Inverno.',
    solution: '💡 Solução Encontrada: Limpeza periódica que impede a proliferação de fungos foliares e a sufocação da relva debaixo das folhas.',
    imageUrl: 'https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?auto=format&fit=crop&w=600&q=80',
  ),
  PriceItem(
    title: 'Aplicação de Mulching com Casca de Pinho',
    category: 'Manutenção',
    price: '18,00 €',
    unit: 'por m²',
    description: 'Cobertura vegetal de canteiros e floreiras com casca de pinho tratada.',
    solution: '💡 Solução Encontrada: Retenção de até 50% da humidade do solo e redução drástica da necessidade de rega e aparecimento de ervas daninhas.',
    imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?auto=format&fit=crop&w=600&q=80',
  ),
  PriceItem(
    title: 'Manutenção & Afiação de Máquinas de Jardinagem',
    category: 'Manutenção',
    price: '35,00 €',
    unit: 'por equipamento',
    description: 'Afiação profissional de lâminas, troca de velas, filtros de ar e óleo do motor.',
    solution: '💡 Solução Encontrada: Lâminas afiadas garantem cortes limpos nas folhas de relva, prevenindo pontas secas e amareladas.',
    imageUrl: 'https://images.unsplash.com/photo-1592417817098-8f3d6ef23a85?auto=format&fit=crop&w=600&q=80',
  ),
  PriceItem(
    title: 'Manutenção de Caldeiras e Anéis de Árvores',
    category: 'Manutenção',
    price: '15,00 €',
    unit: 'por árvore',
    description: 'Sachagem manual e limpeza da base de árvores de fruto e ornamentais.',
    solution: '💡 Solução Encontrada: Criação de depressão para retenção de água e adubação direta na zona radicular.',
    imageUrl: 'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?auto=format&fit=crop&w=600&q=80',
  ),

  // --- PODA ---
  PriceItem(
    title: 'Poda de Formação & Arbustos',
    category: 'Poda',
    price: '35,00 €',
    unit: 'por árvore / arbusto',
    description: 'Poda de arbustos e árvores de pequeno porte para estimular o crescimento ordenado e floração.',
    solution: '💡 Solução Encontrada: Remoção de ramos cruzados e secos, garantindo máxima entrada de luz solar no interior da copa.',
    imageUrl: 'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?auto=format&fit=crop&w=600&q=80',
  ),
  PriceItem(
    title: 'Poda de Altura & Árvores Grandes',
    category: 'Poda',
    price: '75,00 €',
    unit: 'por árvore grande',
    description: 'Poda técnica de segurança em árvores de grande porte com arnês e cordas de sustentação.',
    solution: '💡 Solução Encontrada: Poda seletiva de ramos pesados com risco de queda sobre telhados e vedações durante tempestades.',
    imageUrl: 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=600&q=80',
  ),
  PriceItem(
    title: 'Poda de Sebes & Topiaria Geométrica',
    category: 'Poda',
    price: '18,00 €',
    unit: 'por metro linear',
    description: 'Corte mecânico de sebes divisórias (buxos, cedros, fotínias) mantendo o formato alinhado.',
    solution: '💡 Solução Encontrada: Alinhamento preciso e corte com corta-sebes de lâmina dupla garantindo densidade foliar uniforme.',
    imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?auto=format&fit=crop&w=600&q=80',
  ),
  PriceItem(
    title: 'Poda de Rejuvenescimento de Árvores Velhas',
    category: 'Poda',
    price: '90,00 €',
    unit: 'por intervenção',
    description: 'Poda drástica estruturada de oliveiras e fruteiras antigas para renovação de ramos.',
    solution: '💡 Solução Encontrada: Estimulação de novos rebentos florais produtivos em espécimes centenários.',
    imageUrl: 'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?auto=format&fit=crop&w=600&q=80',
  ),
  PriceItem(
    title: 'Limpeza de Palmeiras e Desramação',
    category: 'Poda',
    price: '65,00 €',
    unit: 'por palmeira',
    description: 'Remoção de palmas secas, cachos de frutos e limpeza do tronco com aplicação de pasta defensiva.',
    solution: '💡 Solução Encontrada: Proteção preventiva contra o escaravelho das palmeiras e melhoria do aspeto estético.',
    imageUrl: 'https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?auto=format&fit=crop&w=600&q=80',
  ),

  // --- SISTEMAS DE REGA ---
  PriceItem(
    title: 'Instalação de Rega Automática',
    category: 'Sistemas de Rega',
    price: '250,00 €',
    unit: 'base de projeto',
    description: 'Montagem de circuito subterrâneo com aspersores pop-up e programador digital inteligente.',
    solution: '💡 Solução Encontrada: Automatização de rega noturna reduzindo a evaporação da água e poupando até 40% na fatura de água.',
    imageUrl: 'https://images.unsplash.com/photo-1563298723-dcfebaa392e3?auto=format&fit=crop&w=600&q=80',
  ),
  PriceItem(
    title: 'Rega Gota a Gota para Canteiros',
    category: 'Sistemas de Rega',
    price: '120,00 €',
    unit: 'por circuito instalado',
    description: 'Instalação de tubagem microperfurada para irrigação direta na raiz de sebes e flores.',
    solution: '💡 Solução Encontrada: Aplicação localizada de humidade diretamente na raíz, prevenindo o aparecimento de fungos nas folhas.',
    imageUrl: 'https://images.unsplash.com/photo-1528183429752-a97d0bf99b5a?auto=format&fit=crop&w=600&q=80',
  ),
  PriceItem(
    title: 'Reparação e Afinação de Válvulas',
    category: 'Sistemas de Rega',
    price: '40,00 €',
    unit: 'por intervenção',
    description: 'Diagnóstico e reparação de fuga de água, substituição de solenóides e desentupimento de boquilhas.',
    solution: '💡 Solução Encontrada: Deteção célere de perdas ocultas de água na tubagem e calibração do raio dos aspersores.',
    imageUrl: 'https://images.unsplash.com/photo-1563298723-dcfebaa392e3?auto=format&fit=crop&w=600&q=80',
  ),
  PriceItem(
    title: 'Instalação de Programadores Wi-Fi / Bluetooth',
    category: 'Sistemas de Rega',
    price: '85,00 €',
    unit: 'por equipamento',
    description: 'Instalação de controlador de rega conectado à rede de internet com sensor de chuva.',
    solution: '💡 Solução Encontrada: Suspensão automática de rega em dias chuvosos via dados meteorológicos em tempo real.',
    imageUrl: 'https://images.unsplash.com/photo-1563298723-dcfebaa392e3?auto=format&fit=crop&w=600&q=80',
  ),

  // --- LIMPEZA ---
  PriceItem(
    title: 'Limpeza Geral & Desmatação de Terrenos',
    category: 'Limpeza',
    price: '0,80 €',
    unit: 'por m²',
    description: 'Corte intensivo de mato alto, remoção de silvas e limpeza de vegetação rasteira inflamável.',
    solution: '💡 Solução Encontrada: Desmatação com roçadora pesada em conformidade com as regras legais de prevenção de incêndios.',
    imageUrl: 'https://images.unsplash.com/photo-1558904541-efa843a96f01?auto=format&fit=crop&w=600&q=80',
  ),
  PriceItem(
    title: 'Lavagem de Pátios e Caminhos de Pedra',
    category: 'Limpeza',
    price: '2,50 €',
    unit: 'por m²',
    description: 'Lavagem profunda a alta pressão para remoção de limo, musgo, verdete e manchas de sujidade.',
    solution: '💡 Solução Encontrada: Remoção eficaz de pavimentos escorregadios em calçada e pedra natural eliminando limo e verdete.',
    imageUrl: 'https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?auto=format&fit=crop&w=600&q=80',
  ),
  PriceItem(
    title: 'Recolha e Biotrituração de Entulho Vegetal',
    category: 'Limpeza',
    price: '50,00 €',
    unit: 'por carga tratada',
    description: 'Recolha de sobrantes de poda, ramos e relva com carregamento e transporte para vazadouro autorizado.',
    solution: '💡 Solução Encontrada: Biotrituração no local transformando ramos secos em estilha de madeira para cobertura vegetal.',
    imageUrl: 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=600&q=80',
  ),
  PriceItem(
    title: 'Limpeza de Calhas e Goteiras de Telhado',
    category: 'Limpeza',
    price: '45,00 €',
    unit: 'por intervenção',
    description: 'Desobstrução manual de calhas de escoamento acumuladas com folhas secas e musgo.',
    solution: '💡 Solução Encontrada: Prevenção de infiltrações de água da chuva nas paredes da habitação durante o Inverno.',
    imageUrl: 'https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?auto=format&fit=crop&w=600&q=80',
  ),

  // --- PLANTAÇÃO ---
  PriceItem(
    title: 'Plantação de Flores & Canteiros Coloridos',
    category: 'Plantação',
    price: '15,00 €',
    unit: 'por m² / vaso',
    description: 'Preparação do solo com substrato enriquecido e plantação de flores sazonais ou vivazes.',
    solution: '💡 Solução Encontrada: Seleção estratégica de flores sazonais com mulching de casca de pinho para reter a humidade.',
    imageUrl: 'https://images.unsplash.com/photo-1563241527-3004b7be0ffd?auto=format&fit=crop&w=600&q=80',
  ),
  PriceItem(
    title: 'Plantação de Sebes de Privacidade',
    category: 'Plantação',
    price: '25,00 €',
    unit: 'por metro linear',
    description: 'Abertura de vala, fertilização de fundo e plantação alinhada de cedros ou fotínias.',
    solution: '💡 Solução Encontrada: Barreira vegetal densa que proporciona privacidade e reduz ruídos de vias públicas.',
    imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?auto=format&fit=crop&w=600&q=80',
  ),
  PriceItem(
    title: 'Plantação de Árvores de Fruto & Ornamentais',
    category: 'Plantação',
    price: '45,00 €',
    unit: 'por árvore instalada',
    description: 'Abertura de caldeira espaçosa, fixação de tutor de madeira e primeira rega enraizadora.',
    solution: '💡 Solução Encontrada: Instalação de estacas de proteção contra ventos fortes e fertilizante enraizador.',
    imageUrl: 'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?auto=format&fit=crop&w=600&q=80',
  ),
  PriceItem(
    title: 'Colocação de Tapete de Relva em Rolo',
    category: 'Plantação',
    price: '8,50 €',
    unit: 'por m²',
    description: 'Nivelamento do terreno, instalação de relva natural em rolo de colocação rápida.',
    solution: '💡 Solução Encontrada: Obtenção de um relvado verde denso e pronto a utilizar em apenas 24 horas.',
    imageUrl: 'https://images.unsplash.com/photo-1558904541-efa843a96f01?auto=format&fit=crop&w=600&q=80',
  ),

  // --- SAÚDE VEGETAL ---
  PriceItem(
    title: 'Tratamento Fitossanitário contra Pragas',
    category: 'Saúde Vegetal',
    price: '45,00 €',
    unit: 'por aplicação',
    description: 'Aplicação pulverizada de tratamentos biológicos ou ecológicos contra pulgões, cochonilha e lagartas.',
    solution: '💡 Solução Encontrada: Pulverização ecológica eliminando pulgões e cochonilha sem prejudicar insetos benéficos como abelhas.',
    imageUrl: 'https://images.unsplash.com/photo-1591857177580-dc82b9ac4e1e?auto=format&fit=crop&w=600&q=80',
  ),
  PriceItem(
    title: 'Análise e Correção de pH do Solo',
    category: 'Saúde Vegetal',
    price: '35,00 €',
    unit: 'por teste e correção',
    description: 'Medição de acidez/alcalinidade do solo e adição de calcário agrícola ou enxofre para acerto de pH.',
    solution: '💡 Solução Encontrada: Adição de calcário agrícola em solos ácidos que impediam as plantas de absorver nutrientes.',
    imageUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=600&q=80',
  ),
  PriceItem(
    title: 'Tratamento de Doenças Fúngicas (Míldio / Óidio)',
    category: 'Saúde Vegetal',
    price: '50,00 €',
    unit: 'por tratamento completo',
    description: 'Aplicação cúprica e fúngica preventiva em vinhas, oliveiras, fruteiras e plantas ornamentais.',
    solution: '💡 Solução Encontrada: Proteção foliar cúprica impedindo a propagação de fungos após chuvas prolongadas.',
    imageUrl: 'https://images.unsplash.com/photo-1534531141161-e41604052327?auto=format&fit=crop&w=600&q=80',
  ),
  PriceItem(
    title: 'Combate à Processionária do Pinheiro',
    category: 'Saúde Vegetal',
    price: '60,00 €',
    unit: 'por intervenção',
    description: 'Remoção mecânica de ninhos e aplicação de injeção no tronco (endoterapia vegetal).',
    solution: '💡 Solução Encontrada: Tratamento sistémico de segurança evitando urticária severa em crianças e animais de estimação.',
    imageUrl: 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=600&q=80',
  ),
];

const plantGuideCatalog = [
  // --- FLORES ---
  PlantTip(
    name: 'Roseiras (Rosa spp.)',
    category: 'Flores',
    priceRange: '12,50 € / muda',
    watering: '2-3 vezes por semana (evitar molhar as folhas)',
    pruningSeason: 'Finais de Janeiro a Fevereiro',
    description: 'Flores clássicas, muito perfumadas e ornamentais. Exigem exposição solar direta.',
    solutions: 'Solução para Pragas: Tratamento com sabão de potássio contra pulgões e fungos de mancha preta.',
    imageUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=600&q=80',
    iconName: 'local_florist',
    sunExposure: 'Sol direto (6+ horas diárias)',
    idealSoil: 'Solo argilo-arenoso rico em matéria orgânica',
    recommendedFertilizer: 'Adubo orgânico específico para roseiras rico em Fósforo (P) e Potássio (K)',
    pruningSteps: [
      '1. Desinfete as tesouras de poda antes de cortar para evitar contaminação por fungos.',
      '2. Realize o corte em ângulo de 45° a 5mm acima de um gomo voltado para fora.',
      '3. Remova todos os ramos secos, doentes ou cruzados no centro da planta.',
      '4. Mantenha 3 a 5 hastes principais fortes e bem arejadas.',
    ],
  ),
  PlantTip(
    name: 'Alfazema / Lavanda (Lavandula)',
    category: 'Flores',
    priceRange: '6,50 € / vaso',
    watering: 'Rega moderada. Muito resistente à seca.',
    pruningSeason: 'Após a floração no final do Verão',
    description: 'Excelente para canteiros e bordaduras. Atrai abelhas polinizadoras e repele pragas.',
    solutions: 'Solução de Solo: Adicionar areia ao solo para garantir excelente drenagem e evitar podridão radicular.',
    imageUrl: 'https://images.unsplash.com/photo-1528183429752-a97d0bf99b5a?auto=format&fit=crop&w=600&q=80',
    iconName: 'local_florist',
    sunExposure: 'Sol pleno e clima seco',
    idealSoil: 'Solo pobre, bem drenado, calcário ou arenoso',
    recommendedFertilizer: 'Fertilizante orgânico de libertação lenta baixo em Azoto (evita folhagem mole)',
    pruningSteps: [
      '1. Aguarde o fim da floração principal no final de Agosto / Setembro.',
      '2. Recorte cerca de 1/3 do crescimento jovem da época.',
      '3. NUNCA corte fundo na madeira velha e lenhosa sem rebentos verdes.',
      '4. Molde a planta em forma de cúpula arredondada para máxima densidade.',
    ],
  ),
  PlantTip(
    name: 'Hortênsia (Hydrangea)',
    category: 'Flores',
    priceRange: '18,00 € / vaso',
    watering: 'Abundante no Verão / Solo sempre húmido',
    pruningSeason: 'Finais do Inverno (remover ramos velhos e flores secas)',
    description: 'Prefere meia-sombra. O pH do solo define a cor da flor (solo ácido = flor azul, alcalino = rosa).',
    solutions: 'Solução para Cor: Aplicar sulfato de alumínio para intensificar o azul ou calcário para tons rosados.',
    imageUrl: 'https://images.unsplash.com/photo-1563241527-3004b7be0ffd?auto=format&fit=crop&w=600&q=80',
    iconName: 'local_florist',
    sunExposure: 'Meia-sombra ou luz filtrada',
    idealSoil: 'Solo húmido, rico em húmus e acidófilo',
    recommendedFertilizer: 'Adubo especial para plantas acidófilas com quelato de ferro',
    pruningSteps: [
      '1. Elimine apenas os ramos secos e inflorescências murchas do ano anterior.',
      '2. Faça o corte logo acima do primeiro par de gomos volumosos e saudáveis.',
      '3. Preserve as hastes verdes jovens que vão florir no ano corrente.',
      '4. Aplique pasta cicatrizante nas pontas cortadas.',
    ],
  ),
  PlantTip(
    name: 'Margaridas (Bellis perennis)',
    category: 'Flores',
    priceRange: '4,50 € / vaso',
    watering: 'Rega regular sem encharcar',
    pruningSeason: 'Poda de limpeza contínua de flores secas',
    description: 'Flores resistentes que trazem vivacidade ao jardim durante a primavera e verão.',
    solutions: 'Solução para Duração: Adubação rica em fósforo a cada 3 semanas para floração prolongada.',
    imageUrl: 'https://images.unsplash.com/photo-1606041008023-472dfb5e530f?auto=format&fit=crop&w=600&q=80',
    iconName: 'local_florist',
    sunExposure: 'Sol direto ou meia-sombra leve',
    idealSoil: 'Solo fértil, solto e com boa drenagem',
    recommendedFertilizer: 'Adubo líquido com alto teor de Fósforo a cada 3 semanas na floração',
    pruningSteps: [
      '1. Remova regularmente as flores secas puxando pelo pedúnculo.',
      '2. No final do Outono, realize um corte ligeiro junto à base.',
      '3. Divida as touceiras a cada 2 anos na Primavera para renovar a planta.',
    ],
  ),

  // --- ÁRVORES ---
  PlantTip(
    name: 'Oliveira (Olea europaea)',
    category: 'Árvores',
    priceRange: '45,00 € a 150,00 €',
    watering: 'Rega reduzida / Moderada na fase jovem',
    pruningSeason: 'Fim do Inverno / Início da Primavera (Fevereiro/Março)',
    description: 'Árvore emblemática mediterrânica, extremamente resistente e de longa vida.',
    solutions: 'Solução de Poda: Poda de arejamento central da copa para entrada de luz e prevenção de fungos.',
    imageUrl: 'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?auto=format&fit=crop&w=600&q=80',
    iconName: 'park',
    sunExposure: 'Sol direto intenso',
    idealSoil: 'Solo calcário, seco e bem drenado',
    recommendedFertilizer: 'Adubo orgânico granulado rico em Azoto e Boro no final do Inverno',
    pruningSteps: [
      '1. Poda efetuada entre Fevereiro e Março antes da brotação.',
      '2. Abra a copa no centro (formato de taça) para permitir luz e ventilação.',
      '3. Elimine os ramos "ladrões" (rebentos verticais vigorosos na base e tronco).',
      '4. Aplique calda bordalesa nos cortes para proteção fúngica.',
    ],
  ),
  PlantTip(
    name: 'Limoeiro & Laranjeira (Cítricos)',
    category: 'Árvores',
    priceRange: '35,00 € / árvore',
    watering: 'Regular no Verão (2 a 3 vezes por semana)',
    pruningSeason: 'Início da Primavera (após a colheita do fruto)',
    description: 'Árvores de fruto perfumadas. Exigem sol pleno e proteção contra ventos fortes.',
    solutions: 'Solução para Folhas Amarelas: Aplicação de quelato de ferro e adubo rico em azoto e potássio.',
    imageUrl: 'https://images.unsplash.com/photo-1534531141161-e41604052327?auto=format&fit=crop&w=600&q=80',
    iconName: 'eco',
    sunExposure: 'Sol pleno e abrigo contra vento frio',
    idealSoil: 'Solo profundo, permeável e ligeiramente ácido',
    recommendedFertilizer: 'Adubo específico para cítricos com Magnésio, Zinco e Quelato de Ferro',
    pruningSteps: [
      '1. Realize a poda logo após a colheita dos frutos na Primavera.',
      '2. Retire ramos secos, partidos ou atacados pela praga da minadora.',
      '3. Desbaste o centro da árvore para equilibrar o peso dos frutos.',
      '4. Pince as pontas muito longas para favorecer a ramificação.',
    ],
  ),
  PlantTip(
    name: 'Magnólia (Magnolia grandiflora)',
    category: 'Árvores',
    priceRange: '55,00 € / muda grande',
    watering: 'Rega abundante durante os primeiros anos',
    pruningSeason: 'Após a floração na primavera',
    description: 'Árvore nobre com flores gigantes e folhagem verde-escuro brilhante.',
    solutions: 'Solução para Solo: Mulching (cobertura vegetal) na base para reter humidade e proteger as raízes.',
    imageUrl: 'https://images.unsplash.com/photo-1588628566587-dbd176de562b?auto=format&fit=crop&w=600&q=80',
    iconName: 'park',
    sunExposure: 'Sol direto ou sombra parcial',
    idealSoil: 'Solo fresco, profundo, rico em matéria orgânica',
    recommendedFertilizer: 'Substrato orgânico enriquecido com terriço de folhas e adubo de libertação lenta',
    pruningSteps: [
      '1. Requer pouca poda; faça apenas manutenção leve.',
      '2. Remova ramos partidos ou mal orientados no final da Primavera.',
      '3. Evite podas drásticas para não danificar o porte majestoso.',
    ],
  ),

  // --- PLANTAS & ARBUSTOS ---
  PlantTip(
    name: 'Relvado (Escalracho / Bermuda)',
    category: 'Plantas',
    priceRange: '4,50 € / m²',
    watering: '2-3 vezes por semana no verão / 1 vez na primavera',
    pruningSeason: 'Corte semanal na primavera e verão',
    description: 'Relva densa e resistente para lazer, jogos e passeios em família.',
    solutions: 'Solução para Musgo e Ervas Daninhas: Escarificação na primavera e aplicação de adubo seletivo.',
    imageUrl: 'https://images.unsplash.com/photo-1558904541-efa843a96f01?auto=format&fit=crop&w=600&q=80',
    iconName: 'grass',
    sunExposure: 'Sol direto pleno',
    idealSoil: 'Solo arejado, nivelado com camada de areia de sílica',
    recommendedFertilizer: 'Adubo de libertação controlada de Azoto no Verão e Potássio no Outono',
    pruningSteps: [
      '1. Mantenha a altura de corte entre 3 a 5 cm.',
      '2. Nunca remova mais de 1/3 da altura da folha num único corte.',
      '3. Afie as lâminas da corta-relva para evitar pontas secas.',
      '4. Escarifique 1 a 2 vezes por ano para remover o feltro acastanhado.',
    ],
  ),
  PlantTip(
    name: 'Buxos & Sebes (Buxus sempervirens)',
    category: 'Plantas',
    priceRange: '15,00 € / muda',
    watering: 'Moderada / Evitar encharcamento',
    pruningSeason: 'Maio e Setembro (Poda de conformação)',
    description: 'Ideal para topiaria e divisões de jardim. Permite criar formatos geométricos perfeitos.',
    solutions: 'Solução para Pragas: Inspeção preventiva contra a traça do buxo e tratamento biológico com Bacillus thuringiensis.',
    imageUrl: 'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?auto=format&fit=crop&w=600&q=80',
    iconName: 'nature_people',
    sunExposure: 'Sol direto ou meia-sombra',
    idealSoil: 'Solo bem drenado, neutro a ligeiramente calcário',
    recommendedFertilizer: 'Adubo específico para buxos e sebes com magnésio para verde intenso',
    pruningSteps: [
      '1. Realize o corte em Maio e Setembro em dias nublados.',
      '2. Utilize guia de cordel esticado para garantir alinhamento perfeito.',
      '3. Mantenha a base da sebe ligeiramente mais larga que o topo para apanhar luz.',
      '4. Lave as aparas de folha com água após a poda.',
    ],
  ),
  PlantTip(
    name: 'Catos & Suculentas Decorativas',
    category: 'Plantas',
    priceRange: '3,50 € a 12,00 €',
    watering: 'Rega quinzenal no Verão / Mensal no Inverno',
    pruningSeason: 'Sem necessidade de poda regular',
    description: 'Ótimas para rochedos e jardins de baixa manutenção (xerofitismo).',
    solutions: 'Solução para Excesso de Humidade: Substrato específico para cactos com cascalho e perlite.',
    imageUrl: 'https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?auto=format&fit=crop&w=600&q=80',
    iconName: 'eco',
    sunExposure: 'Sol direto e alta luminosidade',
    idealSoil: 'Substrato poroso para cactos com cascalho, brita e perlite',
    recommendedFertilizer: 'Adubo líquido para cactos diluído 1 vez por mês no Verão',
    pruningSteps: [
      '1. Retire apenas hastes florais secas ou folhas murchas na base.',
      '2. Utilize luvas de proteção grossas e pinças.',
      '3. Replante as mudas laterais para propagar novas plantas.',
    ],
  ),

  // --- SERVIÇOS & SOLUÇÕES ---
  PlantTip(
    name: 'Corte e Manutenção de Relvado',
    category: 'Serviços',
    priceRange: '0,50 € / m² (Mínimo 25,00 €)',
    watering: 'Recomendação de rega após corte',
    pruningSeason: 'Serviço Quinzenal ou Semanal',
    description: 'Corte com máquina profissional, acerto de bordaduras e recolha de aparas.',
    solutions: 'Solução Profissional: Ajuste da altura de corte conforme a estação para evitar a dessecação da raiz.',
    imageUrl: 'https://images.unsplash.com/photo-1592417817098-8f3d6ef23a85?auto=format&fit=crop&w=600&q=80',
    iconName: 'content_cut',
    sunExposure: 'N/A',
    idealSoil: 'N/A',
    recommendedFertilizer: 'Adubo de manutenção de relvado de libertação lenta',
    pruningSteps: [
      '1. Verificação inicial do relvado e remoção de pedras/objetos.',
      '2. Corte com lâmina afiada ajustada à altura ideal.',
      '3. Acerto de bordas com aparador mecânico.',
      '4. Aspiração e remoção de restos de relva.',
    ],
  ),
  PlantTip(
    name: 'Poda de Altura & Limpeza de Árvores',
    category: 'Serviços',
    priceRange: 'A partir de 60,00 € / árvore',
    watering: 'N/A',
    pruningSeason: 'Novembro a Fevereiro',
    description: 'Poda de segurança, remoção de ramos secos, perigosos ou doentes com equipamento adequado.',
    solutions: 'Solução de Segurança: Selagem de cortes grandes com pasta cicatrizante para impedir entrada de fungos.',
    imageUrl: 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=600&q=80',
    iconName: 'park',
    sunExposure: 'N/A',
    idealSoil: 'N/A',
    recommendedFertilizer: 'Pasta cicatrizante com fungicida para cortes de grande diâmetro',
    pruningSteps: [
      '1. Avaliação de segurança e ancoragem de arneses de subida.',
      '2. Remoção seletiva de ramos secos e com risco de queda.',
      '3. Desbaste técnico de arejamento da estrutura.',
      '4. Trituração e transporte de resíduos vegetais.',
    ],
  ),
  PlantTip(
    name: 'Instalação de Sistema de Rega Automática',
    category: 'Serviços',
    priceRange: 'A partir de 250,00 €',
    watering: 'Programação personalizada por zonas',
    pruningSeason: 'Manutenção anual na Primavera',
    description: 'Instalação de aspersores pop-up, rega gota a gota e programadores inteligentes com sensor de chuva.',
    solutions: 'Solução de Eficiência: Redução de até 40% no consumo de água com rega noturna automatizada.',
    imageUrl: 'https://images.unsplash.com/photo-1563298723-dcfebaa392e3?auto=format&fit=crop&w=600&q=80',
    iconName: 'water_drop',
    sunExposure: 'N/A',
    idealSoil: 'N/A',
    recommendedFertilizer: 'N/A',
    pruningSteps: [
      '1. Dimensionamento de caudais e desenho do esquema técnico de rega.',
      '2. Escavação de valas e passagem de tubagem PEAD.',
      '3. Montagem de eletroválvulas e aspersores escamoteáveis.',
      '4. Calibração do programador e testes de estanqueidade.',
    ],
  ),
  PlantTip(
    name: 'Plantação de Sebes & Canteiros',
    category: 'Serviços',
    priceRange: '15,00 € / metro linear',
    watering: 'Inclusa primeira rega com estimulante enraizador',
    pruningSeason: 'Todo o ano (exceto geadas severas)',
    description: 'Preparação do solo, fertilização de fundo, plantação alinhada e acabamento com casca de pinho.',
    solutions: 'Solução Estética & Térmica: Aumenta a privacidade e reduz ruídos externos no seu jardim.',
    imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?auto=format&fit=crop&w=600&q=80',
    iconName: 'grass',
    sunExposure: 'N/A',
    idealSoil: 'N/A',
    recommendedFertilizer: 'Adubo de fundo enriquecido com matéria orgânica e enraizador',
    pruningSteps: [
      '1. Abertura de vala contínua e descompactação do solo.',
      '2. Adição de substrato enriquecido e adubo de fundo.',
      '3. Alinhamento rigoroso dos espécimes e rega enraizadora.',
      '4. Aplicação de tela anti-ervas e cobertura de casca de pinho.',
    ],
  ),
  PlantTip(
    name: 'Tratamento Fitossanitário & Pragas',
    category: 'Serviços',
    priceRange: '45,00 € / aplicação',
    watering: 'N/A',
    pruningSeason: 'Aplicações Preventivas e Curativas',
    description: 'Diagnóstico e combate a pragas (pulgões, lagartas, cochonilha) e doenças fúngicas em plantas.',
    solutions: 'Solução Ecológica: Utilização prioritária de produtos homologados de baixo impacto ambiental.',
    imageUrl: 'https://images.unsplash.com/photo-1591857177580-dc82b9ac4e1e?auto=format&fit=crop&w=600&q=80',
    iconName: 'bug_report',
    sunExposure: 'N/A',
    idealSoil: 'N/A',
    recommendedFertilizer: 'Tratamento ecológico biológico (Sabão de potássio, óleo de neem ou cobre)',
    pruningSteps: [
      '1. Inspeção clínica das folhas e caule para identificação do agente.',
      '2. Preparação da mistura fitossanitária com dosagem homologada.',
      '3. Pulverização fina cobrindo a página superior e inferior das folhas.',
      '4. Agendamento de sessão de reforço após 10 a 14 dias.',
    ],
  ),
];

const _months = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
];

String ptMonth(DateTime d) => '${_months[d.month - 1]} ${d.year}';
String two(int n) => n.toString().padLeft(2, '0');
String fmtDate(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';
String fmtTime(DateTime d) => '${two(d.hour)}:${two(d.minute)}';
String fmtCurrency(double amount) => '${amount.toStringAsFixed(2)} €';
String dayKey(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';
