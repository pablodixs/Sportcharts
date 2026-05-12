import SwiftUI

// MARK: - Team Colors

struct F1TeamColors {
	let primary: Color
	let secondary: Color
	let accent: Color
	
	init(primary: String, secondary: String, accent: String) {
		self.primary   = Color(hex: primary)
		self.secondary = Color(hex: secondary)
		self.accent    = Color(hex: accent)
	}
}

// MARK: - Nationality

struct F1Nationality {
	let nome: String    // em português
	let flag: String    // emoji da bandeira
	
	static let all: [String: F1Nationality] = [
		"British":       F1Nationality(nome: "Britânico",    flag: "🇬🇧"),
		"Australian":    F1Nationality(nome: "Australiano",  flag: "🇦🇺"),
		"Italian":       F1Nationality(nome: "Italiano",     flag: "🇮🇹"),
		"Dutch":         F1Nationality(nome: "Holandês",     flag: "🇳🇱"),
		"French":        F1Nationality(nome: "Francês",      flag: "🇫🇷"),
		"Monégasque":    F1Nationality(nome: "Monegasco",    flag: "🇲🇨"),
		"Thai":          F1Nationality(nome: "Tailandês",    flag: "🇹🇭"),
		"Spanish":       F1Nationality(nome: "Espanhol",     flag: "🇪🇸"),
		"New Zealander": F1Nationality(nome: "Neozelandês",  flag: "🇳🇿"),
		"Canadian":      F1Nationality(nome: "Canadense",    flag: "🇨🇦"),
		"German":        F1Nationality(nome: "Alemão",       flag: "🇩🇪"),
		"Brazilian":     F1Nationality(nome: "Brasileiro",   flag: "🇧🇷"),
		"Argentine":     F1Nationality(nome: "Argentino",    flag: "🇦🇷"),
		"Mexican":       F1Nationality(nome: "Mexicano",     flag: "🇲🇽"),
		"Finnish":       F1Nationality(nome: "Finlandês",    flag: "🇫🇮"),
	]
}

// MARK: - Constructor

struct F1Constructor: Identifiable {
	let id: String              // slug único (ex: "mclaren")
	let nome: String            // nome oficial exibido
	let pais: String            // país de origem
	let flagPais: String        // emoji da bandeira do país
	let sede: String            // cidade/país da sede
	let fundacao: Int           // ano de fundação
	let motorFornecedor: String // fornecedor do motor em 2026
	let titulos: Int            // títulos de construtores na F1
	let vitorias: Int           // vitórias totais na F1 (até 2025)
	let estreiaF1: Int          // ano de estreia na F1
	let colors: F1TeamColors
	let logoURL: URL?
	let bio: String             // resumo em português
}

// MARK: - F1Team enum

enum F1Team: String, Codable, CaseIterable, Identifiable {
	case mclaren      = "McLaren"
	case mercedes     = "Mercedes"
	case redBull      = "Red Bull Racing"
	case ferrari      = "Ferrari"
	case williams     = "Williams"
	case racingBulls  = "Racing Bulls"
	case astonMartin  = "Aston Martin"
	case haas         = "Haas"
	case audi         = "Audi"
	case alpine       = "Alpine"
	case cadillac     = "Cadillac"
	
	var id: String { rawValue }
	
	var constructor: F1Constructor { F1Constructors.all[self]! }
	var colors: F1TeamColors { constructor.colors }
	var logoURL: URL? { constructor.logoURL }
}

// MARK: - URL Helpers

private func teamLogoURL(_ slug: String, _ filename: String) -> URL? {
	let base = "https://media.formula1.com/image/upload/c_lfill,w_140/q_auto/v1740000001/common/f1/2026"
	return URL(string: "\(base)/\(slug)/\(filename)")
}

private func f1DriverImageURL(_ path: String) -> URL? {
	let base     = "https://media.formula1.com/image/upload/c_lfill,w_440/q_auto"
	let fallback = "/d_common:f1:2026:fallback:driver:2026fallbackdriverright.webp"
	let cdn      = "/v1740000001/common/f1/2026"
	return URL(string: "\(base)\(fallback)\(cdn)/\(path)")
}

// MARK: - Constructors Data

struct F1Constructors {
	
	static let all: [F1Team: F1Constructor] = [
		
		.mclaren: F1Constructor(
			id: "mclaren",
			nome: "McLaren",
			pais: "Reino Unido",
			flagPais: "🇬🇧",
			sede: "Woking, Inglaterra",
			fundacao: 1963,
			motorFornecedor: "Mercedes",
			titulos: 10,
			vitorias: 183,
			estreiaF1: 1966,
			colors: F1TeamColors(primary: "#FF8000", secondary: "#2D2D2D", accent: "#47C7FC"),
			logoURL: teamLogoURL("mclaren", "2026mclarenlogowhite.webp"),
			bio: "Fundada por Bruce McLaren em 1963 e sediada em Woking, a McLaren é uma das equipes mais vitoriosas da história da F1 com 10 títulos de construtores. Viveu sua era de ouro nos anos 1980 e 1990 com pilotos como Senna, Prost, Häkkinen e Coulthard. Após anos difíceis no meio da tabela, ressurgiu como força dominante em 2024 e 2025, conquistando dois títulos consecutivos de construtores. Em 2026 defende o campeonato com Norris e Piastri, considerada a dupla mais forte do grid."
		),
		
			.mercedes: F1Constructor(
				id: "mercedes",
				nome: "Mercedes-AMG Petronas",
				pais: "Alemanha / Reino Unido",
				flagPais: "🇩🇪",
				sede: "Brackley, Inglaterra",
				fundacao: 2010,
				motorFornecedor: "Mercedes",
				titulos: 8,
				vitorias: 125,
				estreiaF1: 2010,
				colors: F1TeamColors(primary: "#00D2BE", secondary: "#000000", accent: "#C0C0C0"),
				logoURL: teamLogoURL("mercedes", "2026mercedeslogowhite.webp"),
				bio: "A Mercedes como equipe de fábrica existe desde 2010, mas sua herança remonta a 1954, quando a marca alemã dominou o mundial com Juan Manuel Fangio. A era moderna foi absolutamente dominante: 8 títulos de construtores consecutivos entre 2014 e 2021, uma sequência sem precedentes na história da F1. Com Toto Wolff no comando, a equipe mantém Russell e Antonelli para 2026 e é apontada como favorita às novas regulamentações, tendo vencido os dois primeiros GPs da temporada."
			),
		
			.redBull: F1Constructor(
				id: "redbullracing",
				nome: "Red Bull Racing",
				pais: "Áustria",
				flagPais: "🇦🇹",
				sede: "Milton Keynes, Inglaterra",
				fundacao: 2005,
				motorFornecedor: "Red Bull Powertrains / Ford",
				titulos: 6,
				vitorias: 117,
				estreiaF1: 2005,
				colors: F1TeamColors(primary: "#1E5BC6", secondary: "#DC052D", accent: "#F7C300"),
				logoURL: teamLogoURL("redbullracing", "2026redbullracinglogowhite.webp"),
				bio: "Fundada em 2005 após a Red Bull adquirir a Jaguar Racing, a equipe austríaca rapidamente se tornou uma potência. Conquistou 4 títulos consecutivos com Sebastian Vettel (2010–2013) e depois 4 mais com Max Verstappen (2021–2024). Em 2026 estreia com motor próprio desenvolvido pela Red Bull Powertrains em parceria com a Ford, uma virada histórica após anos usando propulsores da Renault e da Honda."
			),
		
			.ferrari: F1Constructor(
				id: "ferrari",
				nome: "Scuderia Ferrari HP",
				pais: "Itália",
				flagPais: "🇮🇹",
				sede: "Maranello, Itália",
				fundacao: 1929,
				motorFornecedor: "Ferrari",
				titulos: 16,
				vitorias: 245,
				estreiaF1: 1950,
				colors: F1TeamColors(primary: "#DC0000", secondary: "#111111", accent: "#F7D117"),
				logoURL: teamLogoURL("ferrari", "2026ferrarilogowhite.webp"),
				bio: "A Scuderia Ferrari é a única equipe que competiu em todas as temporadas da F1 desde 1950, sendo a mais vitoriosa da história com 16 títulos de construtores e 245 vitórias. Fundada por Enzo Ferrari, é sinônimo do esporte. O último título foi em 2008 com Kimi Räikkönen. Em 2025, contratou Lewis Hamilton para fazer dupla com Charles Leclerc, apostando na combinação de experiência e velocidade pura para reconquistar o topo com o novo regulamento de 2026."
			),
		
			.williams: F1Constructor(
				id: "williams",
				nome: "Williams Racing",
				pais: "Reino Unido",
				flagPais: "🇬🇧",
				sede: "Grove, Inglaterra",
				fundacao: 1977,
				motorFornecedor: "Mercedes",
				titulos: 9,
				vitorias: 114,
				estreiaF1: 1978,
				colors: F1TeamColors(primary: "#005AFF", secondary: "#041E42", accent: "#FFFFFF"),
				logoURL: teamLogoURL("williams", "2026williamslogowhite.webp"),
				bio: "Fundada por Frank Williams em 1977, a Williams foi uma das equipes mais dominantes dos anos 1980 e 1990, com 9 títulos de construtores e pilotos lendários como Mansell, Prost, Damon Hill e Jacques Villeneuve. Após décadas de dificuldades, a equipe renasceu em 2025 com Albon e Sainz, terminando em 5º no campeonato de construtores — o melhor resultado desde 2016. Em 2026 mantém a mesma dupla apostando na continuidade."
			),
		
			.racingBulls: F1Constructor(
				id: "racingbulls",
				nome: "Racing Bulls",
				pais: "Itália",
				flagPais: "🇮🇹",
				sede: "Faenza, Itália",
				fundacao: 2006,
				motorFornecedor: "Red Bull Powertrains / Ford",
				titulos: 0,
				vitorias: 2,
				estreiaF1: 2006,
				colors: F1TeamColors(primary: "#2647D8", secondary: "#FFFFFF", accent: "#E10600"),
				logoURL: teamLogoURL("racingbulls", "2026racingbullslogowhite.webp"),
				bio: "A Racing Bulls — anteriormente conhecida como Toro Rosso, AlphaTauri e VCARB — é a equipe satélite da Red Bull, sediada em Faenza, Itália. Serve historicamente como celeiro de talentos do programa júnior da Red Bull, tendo revelado pilotos como Vettel, Verstappen e Gasly. Em 2026 estreia com motor Red Bull Powertrains/Ford e tem Liam Lawson como líder, ao lado do único rookeiro da temporada, Arvid Lindblad."
			),
		
			.astonMartin: F1Constructor(
				id: "astonmartin",
				nome: "Aston Martin Aramco",
				pais: "Reino Unido",
				flagPais: "🇬🇧",
				sede: "Silverstone, Inglaterra",
				fundacao: 2018,
				motorFornecedor: "Honda",
				titulos: 0,
				vitorias: 0,
				estreiaF1: 2021,
				colors: F1TeamColors(primary: "#006F62", secondary: "#111111", accent: "#CEDC00"),
				logoURL: teamLogoURL("astonmartin", "2026astonmartinlogowhite.webp"),
				bio: "A Aston Martin F1 é a reencarnação da Racing Point, adquirida por Lawrence Stroll em 2018. A marca Aston Martin voltou à F1 em 2021 pela primeira vez desde 1960. Em 2026 vive sua maior aposta: contratou Adrian Newey — o mais bem-sucedido designer da história da F1 — como diretor técnico e fechou parceria com a Honda para o novo motor. A dupla Alonso-Stroll espera que a combinação Newey + Honda traga a equipe ao patamar de título."
			),
		
			.haas: F1Constructor(
				id: "haasf1team",
				nome: "Haas F1 Team",
				pais: "Estados Unidos",
				flagPais: "🇺🇸",
				sede: "Kannapolis, Carolina do Norte, EUA",
				fundacao: 2016,
				motorFornecedor: "Ferrari",
				titulos: 0,
				vitorias: 0,
				estreiaF1: 2016,
				colors: F1TeamColors(primary: "#FFFFFF", secondary: "#000000", accent: "#E10600"),
				logoURL: teamLogoURL("haasf1team", "2026haasf1teamlogowhite.webp"),
				bio: "A Haas é a única equipe norte-americana da F1, fundada pelo empresário Gene Haas em 2016. É a equipe mais recente da F1 antes da entrada da Cadillac em 2026. Opera em modelo único: chassi construído na Europa (Dallara) e motor Ferrari, com sede administrativa nos EUA. Em 2025, a chegada de Bearman e Ocon trouxe nova identidade à equipe, que busca consistência nos pontos e sua primeira vitória na categoria."
			),
		
			.audi: F1Constructor(
				id: "audi",
				nome: "Audi F1 Team",
				pais: "Alemanha",
				flagPais: "🇩🇪",
				sede: "Hinwil, Suíça",
				fundacao: 2026,
				motorFornecedor: "Audi",
				titulos: 0,
				vitorias: 0,
				estreiaF1: 2026,
				colors: F1TeamColors(primary: "#C00000", secondary: "#000000", accent: "#FFFFFF"),
				logoURL: teamLogoURL("audi", "2026audilogowhite.webp"),
				bio: "A Audi estreia na F1 em 2026 como equipe de fábrica, após adquirir a Sauber — uma das equipes mais tradicionais da F1 — em 2024. A equipe competiu em 2025 como Kick Sauber durante a transição. A infraestrutura permanece em Hinwil, Suíça, mas com identidade e motor Audi. É o retorno da marca alemã às corridas após anos no WEC e no DTM. Hülkenberg lidera a estrutura ao lado do brasileiro Gabriel Bortoleto em uma das histórias mais aguardadas de 2026."
			),
		
			.alpine: F1Constructor(
				id: "alpine",
				nome: "BWT Alpine F1 Team",
				pais: "França",
				flagPais: "🇫🇷",
				sede: "Enstone, Inglaterra / Viry-Châtillon, França",
				fundacao: 1981,
				motorFornecedor: "Mercedes",
				titulos: 2,
				vitorias: 21,
				estreiaF1: 1986,
				colors: F1TeamColors(primary: "#0090FF", secondary: "#111111", accent: "#FF87BC"),
				logoURL: teamLogoURL("alpine", "2026alpinelogowhite.webp"),
				bio: "Sediada em Enstone, a Alpine carrega a linhagem da lendária Benetton e da equipe de fábrica da Renault, que venceu títulos com Schumacher (1994–1995) e Alonso (2005–2006). Em 2026 vive uma grande ruptura: abandonou o motor Renault — primeiro ano sem ele desde 2000 — e adotou o propulsor Mercedes como equipe cliente. Gasly e Colapinto formam a nova dupla após uma temporada 2025 turbulenta marcada por trocas de piloto e diretoria."
			),
		
			.cadillac: F1Constructor(
				id: "cadillac",
				nome: "Cadillac F1 Team",
				pais: "Estados Unidos",
				flagPais: "🇺🇸",
				sede: "Concord, Carolina do Norte, EUA",
				fundacao: 2026,
				motorFornecedor: "Ferrari",
				titulos: 0,
				vitorias: 0,
				estreiaF1: 2026,
				colors: F1TeamColors(primary: "#111111", secondary: "#FFFFFF", accent: "#C8102E"),
				logoURL: teamLogoURL("cadillac", "2026cadillaclogowhite.webp"),
				bio: "A Cadillac é o 11º time da F1 — o primeiro a estrear na categoria desde a própria Haas em 2016. Fruto de uma longa batalha de aprovação pela FIA, a equipe é operada pela TWG Global (anteriormente Andretti Global) com a marca Cadillac da General Motors. Em 2026 usa motor e câmbio Ferrari como cliente, com planos de desenvolver motor próprio da GM para 2029. A dupla de veteranos Pérez e Bottas foi escolhida para dar solidez à estrutura em seu primeiro ano na F1."
			),
	]
}

// MARK: - Driver

struct F1Driver: Identifiable {
	let id: Int                  // número do carro (chave única)
	let number: Int
	let firstName: String
	let lastName: String
	let abbreviation: String     // código FIA de 3 letras
	let nationalityKey: String   // chave para F1Nationality.all
	let team: F1Team
	let isRookie: Bool
	let imageURL: URL?           // foto do piloto (CDN F1)
	let bio: String              // resumo em português
	
	var fullName: String { "\(firstName) \(lastName)" }
	var nationality: F1Nationality? { F1Nationality.all[nationalityKey] }
	var flagEmoji: String { nationality?.flag ?? "🏁" }
	var nationalityName: String { nationality?.nome ?? nationalityKey }
	
	// Atalhos via equipe
	var teamColors: F1TeamColors { team.colors }
	var teamLogoURL: URL? { team.logoURL }
	var constructor: F1Constructor { team.constructor }
}

// MARK: - 2026 Grid

struct F1Grid2026 {
	
	static let drivers: [F1Driver] = [
		
		// ── McLaren  #FF8000 ───────────────────────────────────────────────────
		F1Driver(
			id: 1, number: 1,
			firstName: "Lando", lastName: "Norris", abbreviation: "NOR",
			nationalityKey: "British", team: .mclaren, isRookie: false,
			imageURL: f1DriverImageURL("mclaren/lannor01/2026mclarenlannor01right.webp"),
			bio: "Campeão Mundial de 2025, Lando Norris compete na F1 desde 2019, sempre pela McLaren. Nascido em Bristol em 1999, foi vice-campeão em 2024 antes de conquistar seu primeiro título. É conhecido pelo estilo agressivo de pilotagem e pela personalidade descontraída nas redes sociais."
		),
		F1Driver(
			id: 81, number: 81,
			firstName: "Oscar", lastName: "Piastri", abbreviation: "PIA",
			nationalityKey: "Australian", team: .mclaren, isRookie: false,
			imageURL: f1DriverImageURL("mclaren/oscpia01/2026mclarenoscpia01right.webp"),
			bio: "Oscar Piastri estreou na F1 em 2023 pela McLaren após ser campeão da F3 e da F2 em suas temporadas de estreia em cada categoria. Em 2025 liderou o campeonato por grande parte do ano, mas cedeu o título a Norris nas etapas finais. Nascido em Melbourne em 2001, é considerado um dos maiores talentos da sua geração."
		),
		
		// ── Mercedes  #00D2BE ──────────────────────────────────────────────────
		F1Driver(
			id: 63, number: 63,
			firstName: "George", lastName: "Russell", abbreviation: "RUS",
			nationalityKey: "British", team: .mercedes, isRookie: false,
			imageURL: f1DriverImageURL("mercedes/georus01/2026mercedesgeorus01right.webp"),
			bio: "George Russell estreou na F1 em 2019 pela Williams e migrou para a Mercedes em 2022. Campeão da F2 e da F3 em seu ano de estreia em cada série. Em 2026 é apontado como um dos favoritos ao título com as novas regulamentações. Nascido em King's Lynn em 1998."
		),
		F1Driver(
			id: 12, number: 12,
			firstName: "Andrea Kimi", lastName: "Antonelli", abbreviation: "ANT",
			nationalityKey: "Italian", team: .mercedes, isRookie: false,
			imageURL: f1DriverImageURL("mercedes/andant01/2026mercedesandant01right.webp"),
			bio: "Kimi Antonelli é o prodígio italiano da Mercedes que pulou diretamente da F2 para a F1 em 2025. Com apenas 18 anos na estreia, conquistou três pódios e uma pole de sprint. Em 2026 venceu o GP da China e assumiu a segunda posição no campeonato. Nascido em Bolonha em 2006."
		),
		
		// ── Red Bull Racing  #1E5BC6 ───────────────────────────────────────────
		F1Driver(
			id: 3, number: 3,
			firstName: "Max", lastName: "Verstappen", abbreviation: "VER",
			nationalityKey: "Dutch", team: .redBull, isRookie: false,
			imageURL: f1DriverImageURL("redbullracing/maxver01/2026redbullracingmaxver01right.webp"),
			bio: "Quadricampeão Mundial (2021–2024), Max Verstappen é considerado um dos maiores pilotos da história da F1. Estreou em 2015 pela Toro Rosso com apenas 17 anos, tornando-se o mais jovem piloto a competir na categoria. Nascido em Hasselt, Bélgica, em 1997, corre sob bandeira holandesa."
		),
		F1Driver(
			id: 6, number: 6,
			firstName: "Isack", lastName: "Hadjar", abbreviation: "HAD",
			nationalityKey: "French", team: .redBull, isRookie: false,
			imageURL: f1DriverImageURL("redbullracing/isahad01/2026redbullracingisahad01right.webp"),
			bio: "Isack Hadjar estreou na F1 em 2025 pela Racing Bulls e foi promovido à Red Bull principal para 2026. Vice-campeão da F2 em 2024, o francês de origem argelina nasceu em Paris em 2004. Conquistou seu primeiro pódio na F1 em Zandvoort em 2025."
		),
		
		// ── Ferrari  #DC0000 ───────────────────────────────────────────────────
		F1Driver(
			id: 16, number: 16,
			firstName: "Charles", lastName: "Leclerc", abbreviation: "LEC",
			nationalityKey: "Monégasque", team: .ferrari, isRookie: false,
			imageURL: f1DriverImageURL("ferrari/chalec01/2026ferrarichalec01right.webp"),
			bio: "Charles Leclerc é o rosto da Ferrari moderna. Nascido em Monte Carlo em 1997, estreou na F1 em 2018 pela Sauber antes de chegar à Scuderia em 2019. Vencedor de múltiplos GPs, tem contrato com a Ferrari até pelo menos 2029 e busca seu primeiro título mundial com o novo regulamento."
		),
		F1Driver(
			id: 44, number: 44,
			firstName: "Lewis", lastName: "Hamilton", abbreviation: "HAM",
			nationalityKey: "British", team: .ferrari, isRookie: false,
			imageURL: f1DriverImageURL("ferrari/lewham01/2026ferrarilewham01right.webp"),
			bio: "Heptacampeão Mundial, Lewis Hamilton é o maior vencedor da história da F1 com mais de 100 vitórias. Nascido em Stevenage em 1985, defendeu as cores da McLaren (2007–2012) e da Mercedes (2013–2024) antes de realizar o sonho de pilotar pela Ferrari em 2025. Ícone dentro e fora das pistas."
		),
		
		// ── Williams  #005AFF ──────────────────────────────────────────────────
		F1Driver(
			id: 23, number: 23,
			firstName: "Alexander", lastName: "Albon", abbreviation: "ALB",
			nationalityKey: "Thai", team: .williams, isRookie: false,
			imageURL: f1DriverImageURL("williams/alealb01/2026williamsalealb01right.webp"),
			bio: "Alexander Albon nasceu em Londres em 1996 e corre sob a bandeira tailandesa. Após passagem pela Red Bull (2019–2020), retornou à F1 pela Williams em 2022 e se tornou o líder da equipe. Em 2025 ajudou a Williams a alcançar o 5º lugar no campeonato de construtores pela primeira vez em oito anos."
		),
		F1Driver(
			id: 55, number: 55,
			firstName: "Carlos", lastName: "Sainz", abbreviation: "SAI",
			nationalityKey: "Spanish", team: .williams, isRookie: false,
			imageURL: f1DriverImageURL("williams/carsai01/2026williamscarsai01right.webp"),
			bio: "Carlos Sainz Júnior nasceu em Madrid em 1994, filho do bicampeão mundial de rali. Passou por Toro Rosso, Renault, McLaren e Ferrari antes de ingressar na Williams em 2025. Vencedor de quatro GPs pela Ferrari, trouxe experiência e dois pódios à Williams em sua primeira temporada."
		),
		
		// ── Racing Bulls  #2647D8 ──────────────────────────────────────────────
		F1Driver(
			id: 41, number: 41,
			firstName: "Arvid", lastName: "Lindblad", abbreviation: "LIN",
			nationalityKey: "British", team: .racingBulls, isRookie: true,
			imageURL: f1DriverImageURL("racingbulls/arvlin01/2026racingbullsarvlin01right.webp"),
			bio: "Arvid Lindblad é o único rookeiro do grid 2026. Nascido em 2006 no Reino Unido, o sueco-britânico se tornou o vencedor mais jovem da história da F2. Membro do programa júnior da Red Bull, realizou três sessões de treinos livres em 2025 antes de ser confirmado na Racing Bulls."
		),
		F1Driver(
			id: 30, number: 30,
			firstName: "Liam", lastName: "Lawson", abbreviation: "LAW",
			nationalityKey: "New Zealander", team: .racingBulls, isRookie: false,
			imageURL: f1DriverImageURL("racingbulls/lialaw01/2026racingbullslialaw01right.webp"),
			bio: "Liam Lawson nasceu em Hastings, Nova Zelândia, em 2002. Estreou na F1 em 2023 como substituto temporário e teve uma passagem conturbada pela Red Bull no início de 2025, sendo rebaixado à Racing Bulls. Recuperou a confiança com resultados sólidos e garantiu sua permanência para 2026."
		),
		
		// ── Aston Martin  #006F62 ──────────────────────────────────────────────
		F1Driver(
			id: 14, number: 14,
			firstName: "Fernando", lastName: "Alonso", abbreviation: "ALO",
			nationalityKey: "Spanish", team: .astonMartin, isRookie: false,
			imageURL: f1DriverImageURL("astonmartin/feralo01/2026astonmartinferalo01right.webp"),
			bio: "Fernando Alonso é bicampeão mundial (2005 e 2006) e o piloto mais experiente do grid em 2026, vivendo sua 23ª temporada na F1. Nascido em Oviedo em 1981, é reconhecido como um dos maiores pilotos de todos os tempos. Na Aston Martin, trabalha ao lado de Adrian Newey na busca pelo seu terceiro título."
		),
		F1Driver(
			id: 18, number: 18,
			firstName: "Lance", lastName: "Stroll", abbreviation: "STR",
			nationalityKey: "Canadian", team: .astonMartin, isRookie: false,
			imageURL: f1DriverImageURL("astonmartin/lanstr01/2026astonmartinlanstr01right.webp"),
			bio: "Lance Stroll nasceu em Montreal em 1998, filho do bilionário e dono da Aston Martin F1, Lawrence Stroll. Estreou na F1 em 2017 pela Williams. Em 2026 vive sua 10ª temporada na categoria e 8ª com a equipe de Silverstone, buscando alavancar o potencial do carro projetado por Adrian Newey."
		),
		
		// ── Haas  #E10600 ─────────────────────────────────────────────────────
		F1Driver(
			id: 87, number: 87,
			firstName: "Oliver", lastName: "Bearman", abbreviation: "BEA",
			nationalityKey: "British", team: .haas, isRookie: false,
			imageURL: f1DriverImageURL("haasf1team/olibea01/2026haasf1teamolibea01right.webp"),
			bio: "Oliver Bearman nasceu em Chelmsford em 2005 e chamou a atenção mundial ao substituir Carlos Sainz na Ferrari no GP da Arábia Saudita de 2024, pontuando de imediato. Assinou contrato de vários anos com a Haas e completa seu segundo ano completo na F1 em 2026."
		),
		F1Driver(
			id: 31, number: 31,
			firstName: "Esteban", lastName: "Ocon", abbreviation: "OCO",
			nationalityKey: "French", team: .haas, isRookie: false,
			imageURL: f1DriverImageURL("haasf1team/estoco01/2026haasf1teamestoco01right.webp"),
			bio: "Esteban Ocon nasceu em Évreux, França, em 1996. Após passagens por Force India, Racing Point, Renault e Alpine, ingressou na Haas em 2025. Vencedor do GP da Hungria de 2021, é um piloto experiente que traz solidez à equipe americana em sua segunda temporada."
		),
		
		// ── Audi  #C00000 ──────────────────────────────────────────────────────
		F1Driver(
			id: 27, number: 27,
			firstName: "Nico", lastName: "Hülkenberg", abbreviation: "HUL",
			nationalityKey: "German", team: .audi, isRookie: false,
			imageURL: f1DriverImageURL("audi/nichul01/2026audinichul01right.webp"),
			bio: "Nico Hülkenberg nasceu em Emmerich, Alemanha, em 1987. Lidera a Audi em sua temporada inaugural como equipe de fábrica. Conhecido por nunca ter conquistado um pódio apesar de mais de 200 corridas, o veterano é peça-chave na transição da equipe para a era Audi."
		),
		F1Driver(
			id: 5, number: 5,
			firstName: "Gabriel", lastName: "Bortoleto", abbreviation: "BOR",
			nationalityKey: "Brazilian", team: .audi, isRookie: false,
			imageURL: f1DriverImageURL("audi/gabbor01/2026audigabbor01right.webp"),
			bio: "Gabriel Bortoleto é o brasileiro do grid 2026. Nascido em São Paulo em 2004, foi campeão da F3 em 2023 e da F2 em 2024, tornando-se o primeiro piloto a vencer os dois campeonatos em anos consecutivos. Protegido de Fernando Alonso, estreou brilhantemente na F1 com a Audi em 2025."
		),
		
		// ── Alpine  #0090FF ────────────────────────────────────────────────────
		F1Driver(
			id: 10, number: 10,
			firstName: "Pierre", lastName: "Gasly", abbreviation: "GAS",
			nationalityKey: "French", team: .alpine, isRookie: false,
			imageURL: f1DriverImageURL("alpine/piegas01/2026alpinepiegas01right.webp"),
			bio: "Pierre Gasly nasceu em Rouen, França, em 1996. Venceu o GP da Itália de 2020 pela AlphaTauri numa das maiores surpresas da história recente da F1. Após passagens por Red Bull e AlphaTauri, ingressou na Alpine em 2023 e é o líder experiente da equipe francesa."
		),
		F1Driver(
			id: 43, number: 43,
			firstName: "Franco", lastName: "Colapinto", abbreviation: "COL",
			nationalityKey: "Argentine", team: .alpine, isRookie: false,
			imageURL: f1DriverImageURL("alpine/fracol01/2026alpinefracol01right.webp"),
			bio: "Franco Colapinto nasceu em Pilar, Argentina, em 2003 e virou febre na América Latina ao ser chamado pela Williams a meio da temporada 2024. Em 2026 garantiu uma vaga de titular na Alpine após superar Paul Aron pela disputa da segunda cadeira. É o representante sul-americano mais jovem no grid."
		),
		
		// ── Cadillac  #111111 ──────────────────────────────────────────────────
		F1Driver(
			id: 11, number: 11,
			firstName: "Sergio", lastName: "Pérez", abbreviation: "PER",
			nationalityKey: "Mexican", team: .cadillac, isRookie: false,
			imageURL: f1DriverImageURL("cadillac/serper01/2026cadillacserper01right.webp"),
			bio: "Sergio 'Checo' Pérez nasceu em Guadalajara, México, em 1990. Após perder sua vaga na Red Bull ao fim de 2024, retornou ao grid pela Cadillac. Vencedor de múltiplos GPs e um dos pilotos com mais corridas no grid, sua experiência é fundamental para a equipe americana se estabelecer na categoria."
		),
		F1Driver(
			id: 77, number: 77,
			firstName: "Valtteri", lastName: "Bottas", abbreviation: "BOT",
			nationalityKey: "Finnish", team: .cadillac, isRookie: false,
			imageURL: f1DriverImageURL("cadillac/valbot01/2026cadillacvalbot01right.webp"),
			bio: "Valtteri Bottas nasceu em Nastola, Finlândia, em 1989. Foi companheiro de Lewis Hamilton na Mercedes de 2017 a 2021, vencendo dez GPs. Após passagem pela Alfa Romeo/Sauber, ficou fora da F1 em 2025 como reserva da Mercedes antes de retornar com a novata Cadillac. Um dos mais experientes com mais de 200 largadas."
		),
	]
	
	// MARK: - Helpers
	
	static var constructors: [F1Constructor] {
		F1Team.allCases.compactMap { F1Constructors.all[$0] }
	}
	
	static func drivers(for team: F1Team) -> [F1Driver] {
		drivers.filter { $0.team == team }
	}
	
	static func driver(byNumber number: Int) -> F1Driver? {
		drivers.first { $0.number == number }
	}
	
	static func driver(byAbbreviation abbr: String) -> F1Driver? {
		drivers.first { $0.abbreviation.uppercased() == abbr.uppercased() }
	}
	
	static var rookies: [F1Driver] {
		drivers.filter { $0.isRookie }
	}
	
	static var brazilians: [F1Driver] {
		drivers.filter { $0.nationalityKey == "Brazilian" }
	}
}
